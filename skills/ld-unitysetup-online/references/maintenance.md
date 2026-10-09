# Online maintenance and migration

The fixed skill name is `ld-unitysetup-online`; the repository is `LastDreamTeam/LDAI_UnitySetupAgentSkill`. The local version manifest is `assets/version.json`.

Run helpers from the full skill directory with Python 3.10+:

```sh
python -B scripts/maintain.py show
python -B scripts/maintain.py check --force
python -B scripts/maintain.py sync --idle --approve-update
```

`show` displays/initializes this installation's state. `check` contacts only the official version manifest, never changes skill content, and uses the configured interval unless forced. `sync` may apply an authorized update only on an idle, clean official Git clone on main; it never updates a business repository, stashes, resets or forces history. A manual/native installation can check versions but uses its host manager for actual updates.

Defaults are interval_days=7 and auto_update=false. A one-time `--approve-update` does not enable future automatic updates. Only a human request authorizes `config --auto-update on`. `--force` only changes timing, not content/approval protection. State is isolated by the real installed skill path, outside tracked content; invalid config and concurrent locks fail rather than silently reset. A failed network request is recorded as failure, not a successful check.

Git updates require exact official HTTPS origin, main, clean tracked/untracked state and fast-forward ancestry. Snapshot the current skill before merge; preserve preferences and refuse ignored-file collisions. Read the new skill after a successful update; work already in progress remains on its loaded rules.

No cron, Windows tasks, services or permanent helper processes are installed. Use-time checks require the Agent to call the tool; do not promise background updates while the Agent is not running.

For v1 migration, verify the full online installation first, then archive only the current host's old `ld-unitysetup-v1` outside scanned directories. Keep a recovery path. Do not maintain two automatically selected rule sets or edit unrelated Agent profiles. A frozen/pinned local version is respected.
