# Removal evidence and residual cleanup

## Installation time

Read the uninstall entry's InstallDate when present. Directory creation and executable creation can indicate first use and a later upgrade respectively, but copied/restored files can retain or change timestamps. Label these as evidence/inference, not an exact installation date.

## Process boundary

Tuanjie Hub, international Hub, Editor and licensing processes are different scopes. A closed window can leave Hub in the tray. Ask for saving/closing only when necessary, then verify processes; after that explicit confirmation, end only verified residual Hub/licensing paths. Never force an international Editor closed to clean an unrelated Tuanjie folder.

## Official uninstall, then residual checks

Use Get-LDUnityChinaInventory.ps1 to locate exact products and registered uninstallers. Validate the executable signature, product and path before invoking it. Quiet arguments are valid only when documented by the registered official command; parse the executable and arguments, never evaluate an arbitrary command string. User-requested removal is authorization for ordinary scoped uninstallation; a skill should not demand the user manually do a step the Agent can legitimately complete.

After the uninstaller exits, recheck program directory, uninstall registration, shortcuts, `tuanjiehub://`, app data and any genuinely installed cN/tN Editors. Cached editors.json records whose executables are gone are stale metadata, not installed software.

An official uninstall may leave an empty Program Files directory, a product protocol key and an empty publisher key. These can be cleaned only after proving exact ownership:

- Protocol command must point at the inspected, removed Tuanjie executable. Inspect both user and machine Classes keys; export that exact key for recovery before removal.
- A publisher key must be empty; never recursively delete an entire publisher branch that contains other products or values.
- Remove an empty program directory only after verifying its absolute path and absence of reparse points. Nonempty residual folders require separate inventory, not a broad recursive delete.

On Windows, PowerShell's registry provider can return an access error even when an elevated token and normal ACLs permit the operation. After verifying the same scope, the standard `reg.exe` utility can remove the exact product key. Check exit code and absence afterward. Do not take ownership, alter ACLs, disable security or use another identity to force the deletion.

## Quarantine is not eradication

Move-LDUnityChinaUserState.ps1 excludes international token files, project lists, browser profiles and Program Files. It previews exact targets and defaults to a manifest-backed quarantine. References in the manifest are recovery metadata; they do not imply files were permanently deleted.

Report separately:

1. Installed products/processes/protocols removed.
2. User state and cached China release metadata moved out of active paths.
3. Any installers/executables still retained in quarantine or Downloads.
4. Historical logs intentionally retained for diagnosis.

For a human's explicit permanent purge request, resolve exact targets, exclude projects and links/junctions, and use the host's legitimate approval mechanism. If automatic review rejects it, stop that operation, name it and report the stated reason. Do not generate an equivalent helper, change shell/encoding or route through another UI to evade it. Provide the precise remaining path; do not claim total disk cleanup.
