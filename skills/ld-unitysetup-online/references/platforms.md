# Platform-specific coverage

The skill is portable Markdown; that does not make every executable helper cross-platform.

## Windows

PowerShell 5.1+ helpers audit registry/product metadata, Authenticode, Hub data, editors/modules and application caches. Python 3.10+ plus curl handles complete route chains; Git supports online fast-forward maintenance. Use exact registered uninstallers and ordinary UAC for authorized machine changes. No hosts/DNS/security changes are needed for the normal workflow.

## macOS

Use the current official Hub/Editor installation guidance. Inspect the actual app bundle with `codesign --verify --deep --strict`, `codesign -dv --verbose=4`, and `spctl --assess --type execute` as appropriate; compare developer identity with current Unity documentation. A successful route or app name alone is not enough. Read the full Editor version from the bundle and reject cN/tN or Tuanjie identities.

Inventory product-specific applications and user Library data before removal. Prefer the product's supported uninstall process; preserve projects, international licenses and unrelated Library data. Do not translate Windows registry/cache paths into broad `rm -rf` commands. Use recoverable, exact-path removal and disclose leftovers. macOS removal automation has not been exercised by this repository's Windows validation.

## Linux

Use the current Unity-maintained package repository and supported distribution/architecture; verify repository signing and actual package identity. Do not treat a downloaded shell script or an unsigned filename as provenance. Install the project's exact international Editor and needed build modules.

Query installed package ownership and use the appropriate package manager for authorized removal. Review user data separately. Do not remove broad home/config directories, disable repository verification or change machine routing just to reach the download page. Linux setup/removal remains a documented native workflow, not a claim that Windows scripts run there.

Across all platforms, use the same full redirect-chain and product/channel checks. Report unsupported or inaccessible validation as UNKNOWN, not PASS.
