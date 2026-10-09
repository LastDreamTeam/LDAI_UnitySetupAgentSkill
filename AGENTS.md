# Repository development

This repository ships `skills/ld-unitysetup-online`. Keep the fixed skill name and independent semantic version. Changes must preserve user task scope and distinguish verified behavior from product/platform assumptions.

- No credentials, account identifiers, private node definitions, machine-specific paths, project lists, or private incident logs may be committed.
- Public examples use parameters or environment-derived paths, never a maintainer's real workstation.
- Default helpers are read-only or preview-only. An installation request does not authorize cleanup; cleanup does not authorize unrelated network/security changes.
- Preserve host approvals. A rejected permanent deletion must not be retried through a script, different shell, encoding, or another tool.
- New/changed helpers require behavior tests. Windows scripts must parse in Windows PowerShell 5.1 and PowerShell 7. Test destructive paths only in isolated fixtures; do not clean the developer machine as a test.
- Before publication, run unit tests, the skill validator, relative-link checks, and a credential/private-path scan. Commit only intended repository files. Publishing is a separate human-authorized action.
- Never report all operating systems or Agent hosts validated from unit tests on one platform.
