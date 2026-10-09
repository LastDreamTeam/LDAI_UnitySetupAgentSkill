"""No-Cookie, TLS-verified redirect-chain audit. Python 3.10+, curl on PATH."""
from __future__ import annotations

import argparse
import ipaddress
import json
import re
import shutil
import subprocess
from urllib.parse import urljoin, urlsplit, urlunsplit

CHINA = ('unity.cn', 'unitychina.cn', 'u3d.cn', 'u3dcloud.cn', 'tuanjie.cn')
DEFAULTS = (
    'https://unity.com/releases/editor/archive',
    'https://unity.com/download',
    'https://public-cdn.cloud.unity3d.com/hub/prod/UnityHubSetup-x64.exe',
)


def china_host(host: str | None) -> bool:
    value = (host or '').lower().rstrip('.')
    return any(value == item or value.endswith('.' + item) for item in CHINA)


def public_url(url: str) -> str:
    parts = urlsplit(url)
    host = parts.hostname or ''
    if ':' in host:
        host = '[' + host + ']'
    if parts.port:
        host += ':' + str(parts.port)
    safe_path = re.sub(r'/(conversations|sessions)/[^/]+', r'/\1/[redacted]', parts.path, flags=re.I)
    safe_path = re.sub(r'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12,}', '[redacted]', safe_path, flags=re.I)
    return urlunsplit((parts.scheme, host, safe_path, '', ''))


def validate_url(url: str, allow_loopback: bool = False) -> None:
    p = urlsplit(url)
    if not p.hostname or p.username is not None or p.password is not None:
        raise ValueError('URL must have a host and no embedded credentials')
    if p.scheme == 'https':
        return
    try:
        loopback = ipaddress.ip_address(p.hostname).is_loopback
    except ValueError:
        loopback = p.hostname == 'localhost'
    if not (allow_loopback and p.scheme == 'http' and loopback):
        raise ValueError('Public probes require HTTPS; HTTP is only for explicit loopback fixtures')


def trace(url: str, *, proxy: str | None = None, timeout: int = 15,
          max_hops: int = 8, allow_loopback: bool = False) -> dict:
    validate_url(url, allow_loopback)
    curl = shutil.which('curl.exe') or shutil.which('curl')
    result = {'verdict': 'UNKNOWN', 'url': public_url(url), 'hops': [],
              'readOnly': True, 'browserCookiesUsed': False}
    if not curl:
        result['reason'] = 'curl_not_found'
        return result
    if proxy:
        p = urlsplit(proxy)
        if p.scheme not in ('http', 'https', 'socks5', 'socks5h') or not p.hostname or p.username or p.password:
            raise ValueError('Use an existing proxy URL without embedded credentials')
    visited = set()
    current = url
    for _ in range(max_hops + 1):
        if current in visited:
            result.update(verdict='WARN', reason='redirect_loop')
            return result
        visited.add(current)
        if china_host(urlsplit(current).hostname):
            result['hops'].append({'url': public_url(current), 'notRequested': True})
            result.update(verdict='FAIL', reason='china_or_tuanjie_hop')
            return result
        validate_url(current, allow_loopback)
        binary = bool(re.search(r'\.(exe|msi|dmg|pkg|zip|tar(?:\.gz)?|deb|rpm)$', urlsplit(current).path, re.I))
        args = [curl, '-q', '-sS', '--max-time', str(timeout), '-D', '-', '-o',
                'NUL' if __import__('os').name == 'nt' else '/dev/null', '-w', '\nLD_STATUS:%{http_code}']
        if binary:
            args.append('--head')
        if proxy:
            args += ['--proxy', proxy, '--noproxy', '']
        args.append(current)
        try:
            call = subprocess.run(args, capture_output=True, text=True, timeout=timeout + 3,
                                  creationflags=getattr(subprocess, 'CREATE_NO_WINDOW', 0))
        except (OSError, subprocess.TimeoutExpired):
            result.update(reason='request_did_not_complete')
            return result
        marker = re.search(r'LD_STATUS:(\d+)', call.stdout)
        code = int(marker.group(1)) if marker else 0
        locations = re.findall(r'^location:\s*(.+?)\s*$', call.stdout, re.I | re.M)
        hop = {'url': public_url(current), 'status': code, 'method': 'HEAD' if binary else 'GET'}
        result['hops'].append(hop)
        if call.returncode or not code:
            result.update(reason='curl_failure', curlExitCode=call.returncode)
            return result
        if code in (301, 302, 303, 307, 308):
            if not locations:
                result.update(verdict='WARN', reason='redirect_without_location')
                return result
            current = urljoin(current, locations[-1])
            hop['location'] = public_url(current)
            if china_host(urlsplit(current).hostname):
                result.update(verdict='FAIL', reason='china_or_tuanjie_hop')
                return result
            continue
        result.update(verdict='PASS' if 200 <= code < 300 else 'WARN',
                      reason='international_response' if 200 <= code < 300 else 'http_error',
                      finalUrl=public_url(current), finalStatus=code)
        return result
    result.update(verdict='WARN', reason='max_redirects_exceeded')
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--url', action='append', help='Repeat for each endpoint; defaults to archive/download/Hub binary')
    parser.add_argument('--proxy', help='Existing effective proxy; no embedded credentials')
    parser.add_argument('--timeout', type=int, default=20, choices=range(1, 61))
    parser.add_argument('--max-hops', type=int, default=8, choices=range(0, 17))
    parser.add_argument('--allow-loopback-test', action='store_true')
    parser.add_argument('--json', action='store_true')
    args = parser.parse_args()
    try:
        reports = [trace(u, proxy=args.proxy, timeout=args.timeout, max_hops=args.max_hops,
                         allow_loopback=args.allow_loopback_test) for u in args.url or DEFAULTS]
    except ValueError as exc:
        parser.error(str(exc))
    verdict = 'FAIL' if any(r['verdict'] == 'FAIL' for r in reports) else 'WARN' if any(r['verdict'] != 'PASS' for r in reports) else 'PASS'
    output = {'verdict': verdict, 'readOnly': True, 'routes': reports}
    if args.json:
        print(json.dumps(output, ensure_ascii=False, indent=2))
    else:
        for r in reports:
            print(r['verdict'], r['url'], r.get('reason', ''))
            for hop in r['hops']:
                print(' ', hop.get('status', 'not requested'), hop['url'])
    return 2 if verdict == 'FAIL' else 1 if verdict == 'WARN' else 0


if __name__ == '__main__':
    raise SystemExit(main())
