# Unity International integrity checks

## Evidence strength

Use several independent signals.

Strong international signals:

- Authenticode status is valid and the signer subject contains `Unity Technologies`.
- Hub product name is `Unity Hub`.
- Editor product name is `Unity`.
- Full Editor version ends in a normal Unity channel such as `f1`, `f2`, `bN`, or `aN`, without an additional `cN` or `tN` suffix.
- Active configuration uses hosts such as `api.unity.com`, `id.unity.com`, `license.unity3d.com`, `activation.unity3d.com`, `packages.unity.com`, and `download.unity3d.com`.

Strong contamination signals:

- Product name contains `Tuanjie` or `团结`.
- Signer contains `优三缔`, `Tuanjie`, or a non-Unity publisher for a claimed Unity binary.
- Editor versions end in `cN` or `tN`.
- Release metadata returns China/Tuanjie versions or download URLs.
- Active identity, activation, licensing, package, or Asset Store endpoints use `unity.cn`, `unitychina.cn`, `u3d.cn`, `u3dcloud.cn`, or `tuanjie.cn`.
- `tuanjiehub://` is registered or Tuanjie uninstall/product records remain.

Weak signals that need context:

- Chinese UI language.
- A plain `f1` version.
- A `.cn` CDN mirror without product/version evidence.
- Historical browser visits.
- Old log lines predating a verified route change.
- File or directory names containing `Unity` without product metadata.

## Windows locations to inspect

International Hub user state:

- `%APPDATA%\UnityHub`
- `%LOCALAPPDATA%\unityhub-updater`
- `%LOCALAPPDATA%\Unity`
- `%PROGRAMDATA%\Unity`

Tuanjie user state and updater residue:

- `%APPDATA%\TuanjieHub`
- `%LOCALAPPDATA%\Tuanjie`
- `%LOCALAPPDATA%\tuanjiehub-updater`
- `%ProgramFiles%\Tuanjie Hub`

UPM configuration:

- `%USERPROFILE%\.upmconfig.toml`
- `%PROGRAMDATA%\Unity\config\upmconfig.toml`
- `%PROGRAMDATA%\Unity\config\ServiceAccounts\.upmconfig.toml`
- environment variables `UPM_GLOBAL_CONFIG_FILE`, `UPM_USER_CONFIG_FILE`, `UPM_NPM_REGISTRY`, `UPM_CACHE_PATH`, and related cache overrides

Hub evidence:

- `cloudConfig.json`
- `storage\cloudConfig.json`
- `releases.json`
- `storage\releases.json`
- `editors.json` and `editors-v2.json`
- `logs\info-log.json*`
- China-origin IndexedDB, Service Worker, GraphQL, Local Storage, and cache directories

Licensing evidence:

- `%LOCALAPPDATA%\Unity\Unity.Licensing.Client.log*`
- `%LOCALAPPDATA%\Tuanjie\Tuanjie.Licensing.Client.log*`

Never print license contents, token files, Cookie values, `encryptedTokens.json`, `userInfoKey.json`, or private project lists.

## Network and redirect model

Unity components can use different proxy sources: Windows user proxy settings, WinHTTP, process environment variables, Git configuration, application-specific proxy support, or proxy-client routing rules. A visible “proxy enabled” toggle does not prove that every Unity request exits through an international route.

The preflight must inspect every hostname in each redirect chain, including relative redirects. Run scripts/probe_routes.py without browser Cookies for the archive, download entry and installer binary separately. An intermediate China/Tuanjie hop fails strict international installation even when the final hostname is international.

Do not write hosts entries or disable certificate checks as a repair. If certificate revocation or TLS validation fails, report it as a network problem rather than bypassing it.

When authorized, the existing proxy can assign only unity.com and unity3d.com to a verified alternative node, preserving its default node, other rules and Windows proxy values. See [proxy routing](proxy-routing.md). Another site's apparent country, an English locale URL, or a successful Release API call does not prove the archive/CDN is fixed.

## Project-specific checks

When a project path is supplied:

1. Read `ProjectSettings/ProjectVersion.txt` and require that exact Editor.
2. Read `Packages/manifest.json` and flag China/Tuanjie registry hosts.
3. Inspect `.vsconfig` and require its Visual Studio workloads.
4. Inspect `.gitattributes`, Git LFS availability, repository root, branch, and remote host.
5. Infer build modules only from live project evidence or the user's stated targets.
6. Never open the project in an unverified Editor merely to discover requirements.

## Classification

- `PASS`: strong signals agree and no active contamination is found.
- `WARN`: historical residue, incomplete optional tooling, prerelease-only IDE, mixed proxy stacks, or tests that could not run.
- `FAIL`: Tuanjie/China product is installed, active China configuration/feed is present, a binary identity fails, an exact Editor is missing, or the route enters a China/Tuanjie endpoint.
- `UNKNOWN`: evidence is locked, inaccessible, unsupported, or inconclusive.
