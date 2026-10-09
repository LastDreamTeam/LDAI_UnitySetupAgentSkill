# Install and remove verified Unity products

## Scope

Honor the current human request. Audit only means read-only; explicit installation or removal covers normal steps for the requested products, without repeated approval for the same targets. Before changing shared-network routing, stopping unsaved applications, elevating, or expanding targets, resolve the actual additional scope/host requirement. Never bypass an automatic rejection.

Do not change system hosts, DNS, certificates, firewall, security/privacy, locale, PAC, proxy settings, services, tasks or startup to force an international install. An explicitly authorized existing application's Unity-only route is a separate, narrow operation described in [proxy routing](proxy-routing.md).

## International installation

1. Read a supplied project's ProjectVersion.txt; require that exact full version and revision. Without a project, choose a human-requested version or consult current official supported-release guidance.
2. Probe the archive, download entry and candidate installer independently using probe_routes.py. Stop installation if any chain enters China/Tuanjie domains or TLS validation is incomplete.
3. Obtain Hub/Editor only from current official primary sources. Do not treat a starting .com URL or filename as proof.
4. Verify the downloaded product, valid Unity Technologies signature and full version with Test-LDUnityInstaller.ps1 on Windows; use the native platform equivalent elsewhere.
5. Run the verified installer within existing authorization and preserve ordinary OS consent. Install Editor first, verify it, then add only necessary build modules for the exact version.
6. Verify installed identity, active Hub release/feed and licensing/UPM endpoints, and the actual project/module readiness. Do not launch or save a target international project with a cN/tN or Tuanjie Editor.

Use installed CLI help plus current official Unity docs before command-line installation. Do not invent headless flags or assume an embedded Hub CLI remains supported. Existing Unity 2022 projects do not become Unity 6 projects merely to satisfy a new tool integration.

## IDE and collaboration tools

Use the production baseline for Visual Studio, VS Code, Git/LFS and credential readiness. A complete Unity setup request can authorize its stated tools; a read-only audit cannot install them. Current official publishers and workload IDs must be verified. Authentication is human-controlled; do not ask for plaintext secrets in chat or persist them in scripts.

## Remove Tuanjie / China Editors

1. Run Get-LDUnityChinaInventory.ps1 and identify exact installed products, full versions, paths, signatures, uninstall entries and filesystem timestamp evidence.
2. Confirm relevant work is saved when shared Hub/cache repair requires closing applications. Verify tray/background processes after the user closes windows. Do not kill unrelated or unsaved international Editors.
3. Validate the registered official uninstaller and invoke it using documented arguments. A registered quiet command can be used when the human requested removal. Parse executable/arguments rather than evaluating the registry string. If the signature, target or publisher is unclear, stop that uninstallation and explain the exact ambiguity.
4. Re-run inventory and audit. Check uninstall registration, protocol, shortcuts, actual Editor executables, program directories and user state. Historical editor records whose executables are absent are not active installations.
5. Preview Move-LDUnityChinaUserState.ps1 -TuanjieUserData and, when warranted, -UnityHubChinaCache. Review sources, close blockers, and apply the same exact scope with -Apply. The script avoids projects, international tokens/licenses, browser profiles, registry and Program Files.
6. For a proven post-uninstall Tuanjie Hub protocol, preview Remove-LDTuanjieProtocol.ps1 -ExpectedRemovedExecutable <inspected path>. Apply only within the explicit cleanup scope and normal OS permissions. -RemoveEmptyProgramDirectory accepts only an empty, non-reparse Tuanjie Hub folder. Empty publisher-key cleanup requires separate inspection of zero child keys and zero values.
7. Recheck exact targets and report remaining quarantined installers or backups. Default quarantine is not permanent purge. An explicitly requested purge still needs exact path validation and the host's approval; a rejected operation stops, regardless of another wrapper or shell being available.

## International Hub China cache

Record Editor/install paths and preserve project lists, tokens and international licensing state. The quarantine helper intentionally excludes those. Start the trusted international Hub only after route validation passes; otherwise it can immediately fetch China-state metadata again. Compare new session logs with repair time; do not erase historical logs to obtain an artificial PASS.

See [cleanup lessons](cleanup-lessons.md) for timestamp uncertainty, residual registry checks and accurate completion labels. Use the browser's own targeted site-data controls only if evidence implicates site data; never edit its profile databases or clear all browsing data as a default fix.
