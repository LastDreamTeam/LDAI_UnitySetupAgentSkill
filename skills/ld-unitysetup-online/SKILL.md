---
name: ld-unitysetup-online
description: Install and verify international Unity workstations, remove Tuanjie or Unity China products with authorization, and repair Unity website/CDN region redirects through scoped existing proxy routes. Use for Unity Hub/Editor setup, cN/tN builds, installer provenance, China-state cleanup, or exact-version workstation readiness; not Unity project code changes.
metadata:
  version: "0.2.0"
---

# LD Unity Setup Online

Replace `ld-unitysetup-v1`; use only this skill for the same task. Keep Unity International and Unity China/Tuanjie separate. Chinese UI and language modules are allowed; they do not identify a China build.

## Start

1. Identify OS, current task scope, actual installed binaries and any supplied project's exact version. Do not import another machine's paths, node choices, credentials or project requirements.
2. If online maintenance is due, run `python -B scripts/maintain.py check`. A user request to check updates uses `check --force`. Finish active work on the loaded version; apply an approved update only at an idle boundary and reread the new skill.
3. Audit requests are read-only. A clear install, removal or repair request authorizes normal steps within that scope; do not repeat confirmations already given. New privileges, unsaved work, unrelated products or shared-network changes require a concrete scope decision.

## Route the work

- **Audit / installer trust:** read [international integrity](references/international-integrity.md). Windows: `powershell -NoProfile -File scripts/Test-LDUnitySetup.ps1 -SkipNetwork -OutputFormat Json`, then run the route probe below. Verify a candidate with `scripts/Test-LDUnityInstaller.ps1 -Path <file> -Kind Hub|Editor|Module` before running it.
- **Install / reproduce a workstation:** read [installation and removal](references/install-and-repair.md) and [production baseline](references/production-baseline.md). Consult current primary docs in [sources](references/sources.md). Use the exact international Editor and required modules, not an automatic patch upgrade. Do not open the project in an unverified Editor.
- **Website / Hub / CDN redirects:** read [scoped route repair](references/proxy-routing.md). Run `python -B scripts/probe_routes.py --json` with the current effective route; supply `--proxy <existing proxy URL>` when needed. Probe the archive, download entry and installer independently. Never infer Unity's region decision from another site's IP geolocation.
- **Download fallback / NoUnityCN:** read [download routes](references/download-fallbacks.md). Separate official metadata, third-party discovery, Hub deep links, direct installers, reviewed GitHub Hub assets and verified offline transfer. Lock the exact version/revision and keep the existing integrity gates; multiple frontends may share the same failed upstream.
- **Supplied blog / Zhihu articles:** read [historical auxiliary references](references/community-reference-notes.md). Existing verified practice takes priority. A provider's past success is not a current reproduction; inaccessible or outdated advice must not become a default installation rule.
- **Remove Tuanjie / China state:** read [installation and removal](references/install-and-repair.md) and [cleanup lessons](references/cleanup-lessons.md). Start with `scripts/Get-LDUnityChinaInventory.ps1`; invoke only a verified, registered product-specific uninstaller. Preview `scripts/Move-LDUnityChinaUserState.ps1 -TuanjieUserData -UnityHubChinaCache`, then apply within the already-authorized targets after applications are closed. Handle specific protocol residue as documented; do not use a broad registry cleaner.
- **macOS / Linux:** read [platforms](references/platforms.md). Use native official validation and removal. Windows helper coverage does not prove another OS is clean.
- **Skill installation / update / old-version migration:** read [maintenance](references/maintenance.md) and the repository's [Agent installation guide](https://github.com/LastDreamTeam/LDAI_UnitySetupAgentSkill/blob/main/skills/install.md).

## Integrity and scope invariants

- Require product identity, valid publisher signature, full version, source/feed, service endpoints and route evidence to agree. `cN`/`tN` suffixes and Tuanjie identities are strong exclusion signals. A filename, `.com` starting URL, Chinese text or plain `f1` is not sufficient.
- No-Cookie tests must inspect every redirect, including relative Location headers. A final international page does not erase an intermediate China hop. Keep TLS verification enabled. Preserve URL query secrets, Cookie values, tokens and account data from reports.
- Repair an existing application route only with applicable authorization. Prefer Unity-only rules and an actually tested existing node; preserve all other rules and the default node, back up, briefly restart only the necessary existing component, and verify page plus binary downloads. No persistent helper or new subscription by default.
- Do not change hosts, system DNS/proxy/PAC, certificates, firewall/security/privacy, system locale, services, tasks or startup merely to make Unity international. Do not edit browser Cookie/History/Login databases. Do not silently sign in or extract credentials for publication.
- Use signed official uninstallers before residual cleanup. Do not force-close an Editor with unsaved work, delete projects, wipe international licenses or infer installed China Editors from stale cached records alone.
- Default cleanup is recoverable quarantine with a manifest. Clearly distinguish installed, historical, quarantined and permanently removed content. An explicit purge request needs exact reviewed targets and host approval; never retry a rejected deletion through an equivalent tool/script. Retained installers in quarantine mean disk-level eradication is incomplete.
- Elevation is only for the specific authorized machine-level operation. Never take registry ownership or change ACL/security to force removal. A provider failure may justify the normal registry utility against the same reviewed product key, not a permission bypass.

## Completion

Lead with `PASS`, `WARN`, `FAIL` or `UNKNOWN`, scoped to the tested outcome. Report actual changes, preserved international tools/projects, exact route endpoints, remaining residue/backups, validation limits and any required user action. Separate filesystem timestamp inference from a recorded installation date; log history alone is not active contamination. Record generalized lessons without credentials or machine-specific facts.
