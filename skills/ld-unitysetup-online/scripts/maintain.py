"""Version checks and opt-in fast-forward updates for this complete skill."""
from __future__ import annotations

import argparse
from contextlib import contextmanager
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import urllib.request
from urllib.parse import urlsplit
import zipfile

NAME = 'ld-unitysetup-online'
REPOSITORY = 'LastDreamTeam/LDAI_UnitySetupAgentSkill'
ORIGIN = 'https://github.com/' + REPOSITORY + '.git'
VERSION_URL = 'https://raw.githubusercontent.com/' + REPOSITORY + '/main/skills/' + NAME + '/assets/version.json'
SKILL = Path(__file__).resolve().parents[1]
DEFAULT_CONFIG = {'schema': 1, 'interval_days': 7, 'auto_update': False}


def version(value):
    if not isinstance(value, str) or not re.fullmatch(r'\d+\.\d+\.\d+', value):
        raise ValueError('Expected a stable semantic version')
    return tuple(map(int, value.split('.')))


def read_json(file, default=None):
    if not file.exists() and default is not None:
        return dict(default)
    return json.loads(file.read_text(encoding='utf-8-sig'))


def write_json(file, obj):
    temp = file.with_suffix(file.suffix + '.tmp')
    temp.write_text(json.dumps(obj, indent=2) + '\n', encoding='utf-8')
    temp.replace(file)


def remote_manifest():
    request = urllib.request.Request(VERSION_URL, headers={'User-Agent': NAME})
    with urllib.request.urlopen(request, timeout=10) as response:
        if urlsplit(response.url).hostname != 'raw.githubusercontent.com':
            raise ValueError('Unexpected version endpoint redirect')
        data = json.loads(response.read(65536))
    if data.get('name') != NAME or data.get('repository') != REPOSITORY:
        raise ValueError('Unexpected remote skill identity')
    version(data['version'])
    return data


class Maintainer:
    def __init__(self, skill=SKILL, data_root=None):
        self.skill = Path(skill).resolve()
        self.manifest = read_json(self.skill / 'assets/version.json')
        if self.manifest.get('name') != NAME or self.manifest.get('repository') != REPOSITORY:
            raise ValueError('Unexpected local skill identity')
        version(self.manifest['version'])
        base = Path(data_root) if data_root else Path(os.environ.get('LOCALAPPDATA') or Path.home() / '.local/state') / 'LDUnitySetup'
        instance = hashlib.sha256(str(self.skill).encode()).hexdigest()[:16]
        self.data = base.expanduser().absolute() / NAME / instance
        self.data.mkdir(parents=True, exist_ok=True)
        self.config_file = self.data / 'config.json'
        self.state_file = self.data / 'state.json'

    @contextmanager
    def lock(self):
        file = self.data / 'maintenance.lock'
        descriptor = os.open(file, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
        try:
            os.write(descriptor, str(os.getpid()).encode())
            yield
        finally:
            os.close(descriptor)
            file.unlink()

    def config(self):
        value = read_json(self.config_file, DEFAULT_CONFIG)
        if value.get('schema') != 1 or type(value.get('auto_update')) is not bool or type(value.get('interval_days')) is not int or not 1 <= value['interval_days'] <= 365:
            raise ValueError('Invalid configuration; preserved for inspection')
        if not self.config_file.exists():
            write_json(self.config_file, value)
        return value

    def git(self, *args, check=True):
        result = subprocess.run(['git', '-C', str(self.skill), *args], capture_output=True, text=True,
                                timeout=120, creationflags=getattr(subprocess, 'CREATE_NO_WINDOW', 0))
        if check and result.returncode:
            raise RuntimeError('Git command failed: ' + args[0])
        return result

    def backend(self):
        try:
            repo = Path(self.git('rev-parse', '--show-toplevel').stdout.strip()).resolve()
            origin = self.git('remote', 'get-url', 'origin').stdout.strip()
            if repo / 'skills' / NAME == self.skill and origin.rstrip('/') in (ORIGIN, ORIGIN[:-4]):
                return 'git'
        except (OSError, RuntimeError, subprocess.TimeoutExpired):
            pass
        return 'host-managed-or-copy'

    def show(self):
        return {'status': 'ready', 'name': NAME, 'version': self.manifest['version'], 'backend': self.backend(),
                'skill_dir': str(self.skill), 'data_dir': str(self.data), 'config': self.config(),
                'state': read_json(self.state_file, {})}

    def check(self, force=False):
        config = self.config()
        state = read_json(self.state_file, {})
        now = dt.datetime.now(dt.timezone.utc)
        last = state.get('last_attempt')
        if last and not force and (now - dt.datetime.fromisoformat(last)).total_seconds() < config['interval_days'] * 86400:
            return {'status': 'not_due', 'installed': self.manifest['version'], 'latest': state.get('latest')}
        state['last_attempt'] = now.isoformat()
        try:
            remote = remote_manifest()
        except Exception:
            state['last_error'] = 'official_version_check_failed'
            write_json(self.state_file, state)
            raise RuntimeError('Official version check failed; installed content was not changed')
        state.update(last_success=now.isoformat(), latest=remote['version'], last_error=None)
        write_json(self.state_file, state)
        return {'status': 'update_available' if version(remote['version']) > version(self.manifest['version']) else 'up_to_date',
                'installed': self.manifest['version'], 'latest': remote['version']}

    def sync(self, idle=False, approve=False, force=False):
        checked = self.check(force)
        latest = checked.get('latest')
        if not latest or version(latest) <= version(self.manifest['version']):
            return checked
        if not (approve or self.config()['auto_update']):
            return {**checked, 'status': 'update_confirmation_required'}
        if not idle:
            return {**checked, 'status': 'deferred_until_idle'}
        if self.backend() != 'git':
            return {**checked, 'status': 'use_host_update_manager'}
        if self.git('branch', '--show-current').stdout.strip() != 'main':
            raise RuntimeError('Pinned or non-main branch preserved')
        if self.git('status', '--porcelain', '--untracked-files=all').stdout.strip():
            raise RuntimeError('Local modifications preserved; update stopped')
        self.git('fetch', '--no-tags', 'origin', 'main')
        fetched = json.loads(self.git('show', f'origin/main:skills/{NAME}/assets/version.json').stdout)
        if fetched.get('name') != NAME or fetched.get('repository') != REPOSITORY or fetched.get('version') != latest:
            raise RuntimeError('Upstream changed after the check; check again before updating')
        if self.git('merge-base', '--is-ancestor', 'HEAD', 'origin/main', check=False).returncode:
            raise RuntimeError('History is not fast-forward; update stopped')
        if self.git('status', '--porcelain', '--untracked-files=all').stdout.strip():
            raise RuntimeError('Worktree changed during fetch; update stopped')
        snapshots = self.data / 'backups'
        snapshots.mkdir(exist_ok=True)
        stamp = dt.datetime.now(dt.timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
        snapshot = snapshots / ('skill-' + stamp + '.zip')
        with zipfile.ZipFile(snapshot, 'w', zipfile.ZIP_DEFLATED) as archive:
            for file in self.skill.rglob('*'):
                if file.is_file() and not file.is_symlink():
                    archive.write(file, file.relative_to(self.skill))
        self.git('merge', '--ff-only', '--no-overwrite-ignore', 'origin/main')
        self.manifest = read_json(self.skill / 'assets/version.json')
        if self.manifest['version'] != latest:
            raise RuntimeError('Post-update manifest mismatch; inspect the retained snapshot')
        return {'status': 'updated', 'version': latest, 'snapshot': str(snapshot)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--data-root')
    sub = parser.add_subparsers(dest='command', required=True)
    sub.add_parser('show')
    for name in ('check', 'sync'):
        item = sub.add_parser(name)
        item.add_argument('--force', action='store_true')
        if name == 'sync':
            item.add_argument('--idle', action='store_true')
            item.add_argument('--approve-update', action='store_true')
    item = sub.add_parser('config')
    item.add_argument('--interval-days', type=int, choices=range(1, 366))
    item.add_argument('--auto-update', choices=('on', 'off'))
    args = parser.parse_args()
    try:
        app = Maintainer(data_root=args.data_root)
        with app.lock():
            if args.command == 'show':
                result = app.show()
            elif args.command == 'check':
                result = app.check(args.force)
            elif args.command == 'sync':
                result = app.sync(args.idle, args.approve_update, args.force)
            else:
                config = app.config()
                if args.interval_days is not None:
                    config['interval_days'] = args.interval_days
                if args.auto_update is not None:
                    config['auto_update'] = args.auto_update == 'on'
                write_json(app.config_file, config)
                result = app.show()
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return 0
    except Exception as exc:
        print(json.dumps({'status': 'error', 'reason': str(exc)}, ensure_ascii=False))
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
