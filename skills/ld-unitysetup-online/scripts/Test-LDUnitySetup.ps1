[CmdletBinding()]
param(
    [string]$ProjectPath,
    [switch]$SkipNetwork,
    [ValidateSet('Human', 'Json')]
    [string]$OutputFormat = 'Human'
)

$ErrorActionPreference = 'SilentlyContinue'
$findings = New-Object System.Collections.Generic.List[object]

function Add-Finding {
    param(
        [string]$Category,
        [ValidateSet('PASS', 'WARN', 'FAIL', 'UNKNOWN', 'INFO')]
        [string]$Status,
        [string]$Name,
        [string]$Evidence,
        [string]$Recommendation = ''
    )
    $script:findings.Add([pscustomobject]@{
        Category = $Category
        Status = $Status
        Name = $Name
        Evidence = $Evidence
        Recommendation = $Recommendation
    })
}

function Get-SafeValue {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return '' }
    $safe = $Value -replace '(?i)([a-z][a-z0-9+.-]*://)[^/@\s]+@', '$1[redacted]@'
    $safe = $safe -replace '(?i)(token|password|secret|authorization|oauth)[=:][^;\s]+', '$1=[redacted]'
    $safe = $safe -replace '\?[^\s;]*', '?[redacted]'
    return $safe
}

function Get-ExecutableIdentity {
    param([string]$ExecutablePath)
    if (-not (Test-Path -LiteralPath $ExecutablePath)) { return $null }
    $item = Get-Item -LiteralPath $ExecutablePath
    $signature = Get-AuthenticodeSignature -LiteralPath $ExecutablePath
    return [pscustomobject]@{
        Path = $item.FullName
        Product = [string]$item.VersionInfo.ProductName
        Version = [string]$item.VersionInfo.ProductVersion
        Company = [string]$item.VersionInfo.CompanyName
        Signature = [string]$signature.Status
        Signer = if ($signature.SignerCertificate) { [string]$signature.SignerCertificate.Subject } else { '' }
    }
}

function Get-UninstallProducts {
    $roots = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    return @(Get-ItemProperty $roots -ErrorAction SilentlyContinue)
}

function Get-SuspiciousMarkers {
    param([string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return @() }
    $pattern = '(?i)tuanjie|\u56e2\u7ed3|\u4f18\u4e09\u7f14|(?:[a-z0-9-]+\.)*(?:unitychina\.cn|unity\.cn|u3d\.cn|u3dcloud\.cn|tuanjie\.cn)|\b\d+\.\d+\.\d+f\d+c\d+\b|\b\d+\.\d+\.\d+t\d+\b'
    return @([regex]::Matches($Text, $pattern) | ForEach-Object { $_.Value.ToLowerInvariant() } | Sort-Object -Unique)
}

$products = Get-UninstallProducts

# Unity Hub identity
$hubCandidates = New-Object System.Collections.Generic.List[string]
$hubRegistry = Get-ItemProperty 'HKLM:\Software\Unity Technologies\Hub' -ErrorAction SilentlyContinue
if ($hubRegistry -and $hubRegistry.InstallLocation) { $hubCandidates.Add((Join-Path $hubRegistry.InstallLocation 'Unity Hub.exe')) }
$hubCandidates.Add((Join-Path $env:ProgramFiles 'Unity Hub\Unity Hub.exe'))
foreach ($product in @($products | Where-Object { $_.DisplayName -match '(?i)^Unity Hub(?:\s|$)' })) {
    $match = [regex]::Match([string]$product.UninstallString, '^\s*"(?<exe>[^"]+\.exe)"|^\s*(?<exe>.+?\.exe)(?:\s|$)')
    if ($match.Success) { $hubCandidates.Add((Join-Path (Split-Path -Parent $match.Groups['exe'].Value) 'Unity Hub.exe')) }
}
Get-CimInstance Win32_Process -Filter "Name='Unity Hub.exe'" -ErrorAction SilentlyContinue | ForEach-Object {
    if ($_.ExecutablePath) { $hubCandidates.Add($_.ExecutablePath) }
}
$hubIdentities = @($hubCandidates | Sort-Object -Unique | ForEach-Object { Get-ExecutableIdentity $_ } | Where-Object { $_ })
if ($hubIdentities.Count -eq 0) {
    Add-Finding 'Unity Hub' 'FAIL' 'International Hub installed' 'No Unity Hub executable was found.' 'Install a verified international Unity Hub.'
}
else {
    foreach ($identity in $hubIdentities) {
        $isInternational = $identity.Product -eq 'Unity Hub' -and $identity.Signature -eq 'Valid' -and $identity.Signer -match '(?i)Unity Technologies' -and (($identity.Product + $identity.Company + $identity.Signer) -notmatch '(?i)Tuanjie|\u56e2\u7ed3|\u4f18\u4e09\u7f14')
        Add-Finding 'Unity Hub' $(if ($isInternational) { 'PASS' } else { 'FAIL' }) 'Hub executable identity' "$($identity.Product) $($identity.Version); signer=$($identity.Signer); path=$($identity.Path)" 'Use only a valid Unity Technologies-signed Unity Hub.'
    }
}

# Tuanjie products and residue
$tuanjieProducts = @($products | Where-Object { $_.DisplayName -match '(?i)Tuanjie|\u56e2\u7ed3' -or $_.Publisher -match '(?i)Tuanjie|\u4f18\u4e09\u7f14' })
$tuanjieArtifacts = @(
    (Join-Path $env:ProgramFiles 'Tuanjie Hub'),
    (Join-Path $env:APPDATA 'TuanjieHub'),
    (Join-Path $env:LOCALAPPDATA 'Tuanjie'),
    (Join-Path $env:LOCALAPPDATA 'tuanjiehub-updater')
) | Where-Object { Test-Path -LiteralPath $_ }
$tuanjieProtocol = Test-Path 'Registry::HKEY_CLASSES_ROOT\tuanjiehub'
if ($tuanjieProducts.Count -gt 0 -or $tuanjieArtifacts.Count -gt 0 -or $tuanjieProtocol) {
    $names = @($tuanjieProducts | Select-Object -ExpandProperty DisplayName) -join ', '
    Add-Finding 'Unity China/Tuanjie' 'FAIL' 'Tuanjie isolation' "Products=$names; protocol=$tuanjieProtocol; artifacts=$($tuanjieArtifacts -join ', ')" 'Uninstall Tuanjie through Windows Apps, then quarantine app-specific residue with explicit authorization.'
}
else {
    Add-Finding 'Unity China/Tuanjie' 'PASS' 'Tuanjie isolation' 'No Tuanjie products, protocol, or standard user-state paths were found.'
}

$quarantineBase = Join-Path $env:LOCALAPPDATA 'LDUnitySetup\Quarantine'
if (Test-Path -LiteralPath $quarantineBase) {
    $retainedExecutables = @(Get-ChildItem -LiteralPath $quarantineBase -Recurse -File -Filter '*.exe' -ErrorAction SilentlyContinue)
    if ($retainedExecutables.Count -gt 0) {
        Add-Finding 'Cleanup backups' 'WARN' 'Retained executable payloads' "Count=$($retainedExecutables.Count); quarantine=$quarantineBase" 'These are not active installations, but disk-level permanent removal is incomplete. Do not bypass host approval to purge them.'
    }
}

# Installed Editors
$editorCandidates = New-Object System.Collections.Generic.List[string]
Get-CimInstance Win32_Process -Filter "Name='Unity.exe'" -ErrorAction SilentlyContinue | ForEach-Object { if ($_.ExecutablePath) { $editorCandidates.Add($_.ExecutablePath) } }
foreach ($product in @($products | Where-Object { $_.DisplayName -match '^Unity\s+\d' })) {
    $uninstall = [string]$product.UninstallString
    $match = [regex]::Match($uninstall, '(?i)(?<root>[A-Z]:\\.+?)\\Editor\\Uninstall\.exe')
    if ($match.Success) { $editorCandidates.Add((Join-Path $match.Groups['root'].Value 'Editor\Unity.exe')) }
}
$installRoots = New-Object System.Collections.Generic.List[string]
$installRoots.Add((Join-Path $env:ProgramFiles 'Unity\Hub\Editor'))
$secondaryPathFile = Join-Path $env:APPDATA 'UnityHub\secondaryInstallPath.json'
if (Test-Path -LiteralPath $secondaryPathFile) {
    try {
        $secondary = Get-Content -LiteralPath $secondaryPathFile -Raw | ConvertFrom-Json
        if ($secondary -is [string]) { $installRoots.Add($secondary) }
        elseif ($secondary.path) { $installRoots.Add([string]$secondary.path) }
    } catch {}
}
foreach ($root in $installRoots | Sort-Object -Unique) {
    if (Test-Path -LiteralPath $root) {
        Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            $candidate = Join-Path $_.FullName 'Editor\Unity.exe'
            if (Test-Path -LiteralPath $candidate) { $editorCandidates.Add($candidate) }
        }
    }
}
$editorIdentities = @($editorCandidates | Sort-Object -Unique | ForEach-Object { Get-ExecutableIdentity $_ } | Where-Object { $_ })
if ($editorIdentities.Count -eq 0) {
    Add-Finding 'Unity Editor' 'WARN' 'Installed Editors' 'No installed Unity Editor executable was discovered.' 'Install the exact international Editor required by the project.'
}
else {
    foreach ($identity in $editorIdentities) {
        $badSuffix = $identity.Version -match '(?i)(?:c|t)\d+(?:_|$)'
        $trusted = $identity.Product -match '(?i)^Unity($|\s)' -and $identity.Signature -eq 'Valid' -and $identity.Signer -match '(?i)Unity Technologies' -and -not $badSuffix
        Add-Finding 'Unity Editor' $(if ($trusted) { 'PASS' } else { 'FAIL' }) 'Editor executable identity' "$($identity.Product) $($identity.Version); signer=$($identity.Signer); path=$($identity.Path)" 'Use an exact international version with a valid Unity Technologies signature.'

        $editorData = Join-Path (Split-Path -Parent $identity.Path) 'Data'
        $playback = Join-Path $editorData 'PlaybackEngines'
        $moduleNames = if (Test-Path -LiteralPath $playback) { @(Get-ChildItem -LiteralPath $playback -Directory | Select-Object -ExpandProperty Name) } else { @() }
        $variations = Join-Path $playback 'windowsstandalonesupport\Variations'
        $variationNames = if (Test-Path -LiteralPath $variations) { @(Get-ChildItem -LiteralPath $variations -Directory | Select-Object -ExpandProperty Name) } else { @() }
        $normalizedVersion = [string]$identity.Version -replace '_.*$', ''
        Add-Finding 'Unity modules' 'INFO' "Editor $normalizedVersion" "PlaybackEngines=$($moduleNames -join ', '); WindowsVariations=$($variationNames -join ', ')"
    }
}

# Hub configuration, feeds, and web state
$hubData = Join-Path $env:APPDATA 'UnityHub'
$hubEvidenceFiles = @(
    @{ Relative = 'cloudConfig.json'; Active = $true },
    @{ Relative = 'storage\cloudConfig.json'; Active = $true },
    @{ Relative = 'releases.json'; Active = $true },
    @{ Relative = 'storage\releases.json'; Active = $true },
    @{ Relative = 'editors.json'; Active = $true },
    @{ Relative = 'featureFlags.json'; Active = $false }
)
foreach ($entry in $hubEvidenceFiles) {
    $path = Join-Path $hubData $entry.Relative
    if (Test-Path -LiteralPath $path) {
        $text = Get-Content -LiteralPath $path -Raw -ErrorAction SilentlyContinue
        $markers = Get-SuspiciousMarkers $text
        if ($markers.Count -gt 0) {
            Add-Finding 'Hub user state' $(if ($entry.Active) { 'FAIL' } else { 'WARN' }) $entry.Relative "Markers=$($markers -join ', '); path=$path" 'Close Unity applications, preview app-specific quarantine, and regenerate state only through a verified international route.'
        }
        else {
            Add-Finding 'Hub user state' 'PASS' $entry.Relative "No China/Tuanjie markers; path=$path"
        }
    }
}
$indexedDb = Join-Path $hubData 'IndexedDB'
$originDirs = if (Test-Path -LiteralPath $indexedDb) { @(Get-ChildItem -LiteralPath $indexedDb -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '(?i)unity\.cn|unitychina|tuanjie|u3d' }) } else { @() }
if ($originDirs.Count -gt 0) {
    Add-Finding 'Hub user state' 'WARN' 'China-origin web storage' ($originDirs.FullName -join ', ') 'Quarantine only app-specific web cache after closing Unity applications and receiving authorization.'
}

$hubLogs = Join-Path $hubData 'logs'
$logFiles = if (Test-Path -LiteralPath $hubLogs) { @(Get-ChildItem -LiteralPath $hubLogs -Filter 'info-log.json*' -File | Sort-Object LastWriteTime -Descending | Select-Object -First 2) } else { @() }
foreach ($log in $logFiles) {
    $matches = Select-String -LiteralPath $log.FullName -Pattern '(?i)tuanjie|unitychina\.cn|(?:[a-z0-9-]+\.)*(?:unity\.cn|u3d\.cn|u3dcloud\.cn)|\d+\.\d+\.\d+f\d+c\d+|\d+\.\d+\.\d+t\d+' -AllMatches
    if ($matches) {
        $markers = @($matches | ForEach-Object { $_.Matches | ForEach-Object { $_.Value.ToLowerInvariant() } } | Sort-Object -Unique)
        Add-Finding 'Hub logs' 'WARN' 'Recent Hub log contains China/Tuanjie evidence' "Markers=$($markers -join ', '); lastWrite=$($log.LastWriteTime); path=$($log.FullName)" 'Compare timestamps with the last verified route change; require a clean new session before installation.'
    }
}

$licenseLog = Join-Path $env:LOCALAPPDATA 'Unity\Unity.Licensing.Client.log'
if (Test-Path -LiteralPath $licenseLog) {
    $chinaLicense = @(Select-String -LiteralPath $licenseLog -Pattern '(?i)(?:license|activation)\.unity\.cn|public-cdn\.cloud\.unitychina\.cn' -AllMatches)
    $globalLicense = @(Select-String -LiteralPath $licenseLog -Pattern '(?i)(?:license|activation)\.unity3d\.com|public-cdn\.cloud\.unity3d\.com' -AllMatches)
    if ($chinaLicense.Count -eq 0) {
        Add-Finding 'Licensing' 'PASS' 'International licensing endpoint' "No China licensing marker in current log; path=$licenseLog"
    }
    else {
        $lastChinaLine = ($chinaLicense | Select-Object -Last 1).LineNumber
        $lastGlobalLine = if ($globalLicense.Count -gt 0) { ($globalLicense | Select-Object -Last 1).LineNumber } else { 0 }
        Add-Finding 'Licensing' 'WARN' 'Licensing log requires session verification' "ChinaMarkers=$($chinaLicense.Count); lastChinaLine=$lastChinaLine; lastGlobalLine=$lastGlobalLine; path=$licenseLog" 'Log order alone does not prove active contamination. Compare timestamps with repair time and verify a fresh international session; do not erase licenses or logs.'
    }
}

# UPM and project package sources
$upmPaths = @(
    (Join-Path $env:USERPROFILE '.upmconfig.toml'),
    (Join-Path $env:PROGRAMDATA 'Unity\config\upmconfig.toml'),
    (Join-Path $env:PROGRAMDATA 'Unity\config\ServiceAccounts\.upmconfig.toml')
)
foreach ($path in $upmPaths) {
    if (Test-Path -LiteralPath $path) {
        $markers = Get-SuspiciousMarkers (Get-Content -LiteralPath $path -Raw)
        Add-Finding 'UPM' $(if ($markers.Count -gt 0) { 'FAIL' } else { 'INFO' }) 'UPM configuration' "Markers=$($markers -join ', '); path=$path" 'Remove or replace China/Tuanjie registry configuration only after reviewing authentication requirements.'
    }
}

# Proxy and hosts inspection; no values with credentials are printed.
$proxyRows = New-Object System.Collections.Generic.List[string]
foreach ($scope in @('Machine', 'User', 'Process')) {
    $vars = [Environment]::GetEnvironmentVariables($scope)
    foreach ($key in $vars.Keys) {
        if ([string]$key -match '(?i)proxy|^UNITY_PROXY$|^UPM_') {
            $safeValue = if ([string]$key -match '(?i)token|password|secret|auth|key') { '[redacted]' } else { Get-SafeValue ([string]$vars[$key]) }
            $proxyRows.Add("$scope/$key=$safeValue")
        }
    }
}
$internet = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -ErrorAction SilentlyContinue
if ($internet) {
    $proxyRows.Add("WinINET enabled=$($internet.ProxyEnable) server=$(Get-SafeValue ([string]$internet.ProxyServer)) pac=$(Get-SafeValue ([string]$internet.AutoConfigURL))")
}
$winHttp = @((netsh winhttp show proxy 2>$null) | Where-Object { $_ -and $_.Trim() }) -join ' '
if ($winHttp) { $proxyRows.Add("WinHTTP=$winHttp") }
Add-Finding 'Network' 'INFO' 'Proxy sources' ($proxyRows -join '; ') 'Different Unity tools can use different proxy stacks; validate the effective route.'

$hostsPath = Join-Path $env:SystemRoot 'System32\drivers\etc\hosts'
$hostsMatches = if (Test-Path -LiteralPath $hostsPath) { @(Get-Content -LiteralPath $hostsPath | Where-Object { $_ -notmatch '^\s*#' -and $_ -match '(?i)unity|tuanjie|u3d' }) } else { @() }
Add-Finding 'Network' $(if ($hostsMatches.Count -eq 0) { 'PASS' } else { 'FAIL' }) 'Hosts overrides' $(if ($hostsMatches.Count -eq 0) { 'No Unity/Tuanjie hosts overrides.' } else { "$($hostsMatches.Count) matching active hosts entries." }) 'Do not use hosts overrides as an international-Unity repair.'

if (-not $SkipNetwork) {
    Add-Finding 'Network' 'UNKNOWN' 'Full no-Cookie route gate' 'Run scripts/probe_routes.py --json with the effective route; audit alone does not certify archive or binary redirects.' 'Require the independent full-chain probe before installing. Use --proxy only for an existing route.'
}

# Visual Studio
$unityInstances = @()
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
if (Test-Path -LiteralPath $vswhere) {
    $unityJson = & $vswhere -all -prerelease -products * -requires Microsoft.VisualStudio.Workload.ManagedGame -format json
    $parsedUnityInstances = ConvertFrom-Json -InputObject ($unityJson -join "`n")
    $unityInstances = @()
    foreach ($instance in $parsedUnityInstances) { $unityInstances += $instance }
    if ($unityInstances.Count -eq 0) {
        Add-Finding 'Visual Studio' 'FAIL' 'Unity workload' 'No complete Visual Studio instance with Microsoft.VisualStudio.Workload.ManagedGame was found.' 'Install the Unity game-development workload.'
    }
    else {
        $summary = @($unityInstances | ForEach-Object { "$($_.displayName) $($_.installationVersion), prerelease=$($_.isPrerelease), complete=$($_.isComplete), launchable=$($_.isLaunchable)" }) -join '; '
        $usable = @($unityInstances | Where-Object { $_.isComplete -and $_.isLaunchable })
        Add-Finding 'Visual Studio' $(if ($usable.Count -gt 0) { 'PASS' } else { 'FAIL' }) 'Unity workload' $summary 'Prefer a complete, launchable stable Visual Studio 2026; retain older versions only for compatibility.'
        $stable2026 = @($usable | Where-Object { ([version]$_.installationVersion).Major -ge 18 -and -not $_.isPrerelease })
        if ($stable2026.Count -eq 0) {
            $preview2026 = @($usable | Where-Object { ([version]$_.installationVersion).Major -ge 18 })
            Add-Finding 'Visual Studio' $(if ($preview2026.Count -gt 0) { 'WARN' } else { 'INFO' }) 'Stable Visual Studio 2026 preference' $(if ($preview2026.Count -gt 0) { 'Only prerelease/Insiders VS 2026 detected.' } else { 'Stable VS 2026 not detected; an older compatible Visual Studio may still be usable.' })
        }
    }
}
else {
    Add-Finding 'Visual Studio' 'FAIL' 'Visual Studio discovery' 'vswhere.exe was not found.' 'Install Visual Studio with the Game development with Unity workload.'
}

# VS Code
$code = Get-Command code -ErrorAction SilentlyContinue
if ($code) {
    $extensions = @(& $code.Source --list-extensions 2>$null)
    $codeVersion = & $code.Source --version | Select-Object -First 1
    Add-Finding 'VS Code' 'PASS' 'VS Code installed' "$($code.Source); version=$codeVersion"
    Add-Finding 'VS Code' $(if ($extensions -contains 'ms-dotnettools.csharp') { 'PASS' } else { 'WARN' }) 'Microsoft C# extension' $(if ($extensions -contains 'ms-dotnettools.csharp') { 'Installed.' } else { 'Not detected.' }) 'Install from Microsoft after confirmation.'
    Add-Finding 'VS Code' $(if ($extensions -contains 'visualstudiotoolsforunity.vstuc') { 'PASS' } else { 'WARN' }) 'Microsoft Unity extension' $(if ($extensions -contains 'visualstudiotoolsforunity.vstuc') { 'Installed.' } else { 'Not detected.' }) 'Install from Microsoft after confirmation.'
    $codexExtensions = @($extensions | Where-Object { $_ -match '(?i)openai|codex|chatgpt' })
    Add-Finding 'VS Code' $(if ($codexExtensions.Count -gt 0) { 'PASS' } else { 'INFO' }) 'Codex IDE extension' $(if ($codexExtensions.Count -gt 0) { $codexExtensions -join ', ' } else { 'Not detected; optional.' }) 'Use only the extension linked from official OpenAI documentation.'
}
else {
    Add-Finding 'VS Code' 'WARN' 'VS Code installed' 'code command was not found.' 'Install stable VS Code if lightweight editing or Codex IDE integration is wanted.'
}

# Git and GitHub readiness
$git = Get-Command git -ErrorAction SilentlyContinue
if ($git) {
    Add-Finding 'Git' 'PASS' 'Git for Windows' ((& $git.Source --version) -join ' ')
    $lfsText = & $git.Source lfs version 2>$null
    $lfsExit = $LASTEXITCODE
    Add-Finding 'Git' $(if ($lfsExit -eq 0) { 'PASS' } else { 'FAIL' }) 'Git LFS' $(if ($lfsText) { $lfsText -join ' ' } else { 'Not available.' }) 'Install Git LFS before cloning repositories that use LFS.'
    $helper = & $git.Source config --show-origin --get-all credential.helper 2>$null
    Add-Finding 'Git' $(if ($helper) { 'PASS' } else { 'WARN' }) 'Credential helper' $(if ($helper) { 'Configured; helper command text is not emitted.' } else { 'No credential helper configured.' }) 'Use Git Credential Manager for HTTPS or a user-managed SSH path.'
    $longPaths = & $git.Source config --get core.longpaths 2>$null
    Add-Finding 'Git' $(if ($longPaths -eq 'true') { 'PASS' } else { 'WARN' }) 'Long path handling' $(if ($longPaths) { "core.longpaths=$longPaths" } else { 'core.longpaths is unset.' }) 'Set it only after authorization and only when the repository needs it; prefer local scope.'
}
else {
    Add-Finding 'Git' 'FAIL' 'Git for Windows' 'git command was not found.' 'Install Git for Windows with Git Credential Manager.'
}
$gh = Get-Command gh -ErrorAction SilentlyContinue
if ($gh) {
    & $gh.Source auth status *> $null
    $ghAuthenticated = $LASTEXITCODE -eq 0
    Add-Finding 'GitHub' $(if ($ghAuthenticated) { 'PASS' } else { 'WARN' }) 'GitHub CLI authentication' $(if ($ghAuthenticated) { 'GitHub CLI reports an authenticated host.' } else { 'GitHub CLI is installed but no authenticated host was confirmed.' }) 'Authentication must be completed by the user.'
}
else {
    Add-Finding 'GitHub' 'INFO' 'GitHub CLI' 'Not installed; optional but recommended.'
}

# Optional project readiness
if (-not [string]::IsNullOrWhiteSpace($ProjectPath)) {
    try { $project = (Resolve-Path -LiteralPath $ProjectPath).Path } catch { $project = $null }
    if (-not $project -or -not (Test-Path -LiteralPath (Join-Path $project 'ProjectSettings\ProjectVersion.txt'))) {
        Add-Finding 'Project' 'FAIL' 'Unity project path' "Invalid Unity project path: $ProjectPath"
    }
    else {
        $versionFile = Join-Path $project 'ProjectSettings\ProjectVersion.txt'
        $versionLine = Get-Content -LiteralPath $versionFile | Where-Object { $_ -match '^m_EditorVersion:' } | Select-Object -First 1
        $requiredVersion = if ($versionLine) { ($versionLine -split ':', 2)[1].Trim() } else { '' }
        $installedVersions = @($editorIdentities | ForEach-Object { ([string]$_.Version -replace '_.*$', '') })
        Add-Finding 'Project' $(if ($installedVersions -contains $requiredVersion) { 'PASS' } else { 'FAIL' }) 'Exact Editor version' "Required=$requiredVersion; installed=$($installedVersions -join ', ')" 'Install the exact trusted international Editor before opening the project.'

        $requiredEditor = $editorIdentities | Where-Object { ([string]$_.Version -replace '_.*$', '') -eq $requiredVersion } | Select-Object -First 1
        if ($requiredEditor) {
            $requiredPlayback = Join-Path (Join-Path (Split-Path -Parent $requiredEditor.Path) 'Data') 'PlaybackEngines'
            $windowsSupport = Join-Path $requiredPlayback 'windowsstandalonesupport'
            $windowsVariations = Join-Path $windowsSupport 'Variations'
            $il2cppVariations = if (Test-Path -LiteralPath $windowsVariations) { @(Get-ChildItem -LiteralPath $windowsVariations -Directory | Where-Object { $_.Name -match '(?i)il2cpp' }) } else { @() }
            Add-Finding 'Project' $(if ((Test-Path -LiteralPath $windowsSupport) -and $il2cppVariations.Count -gt 0) { 'PASS' } else { 'FAIL' }) 'Windows IL2CPP module' "Editor=$requiredVersion; IL2CPP variations=$($il2cppVariations.Name -join ', ')" 'Install Windows Build Support (IL2CPP) for the exact Editor.'
            $androidSupport = Join-Path $requiredPlayback 'AndroidPlayer'
            Add-Finding 'Project' 'INFO' 'Android module' $(if (Test-Path -LiteralPath $androidSupport) { 'AndroidPlayer is installed for the exact Editor.' } else { 'AndroidPlayer is not installed; add it only when Android builds are required.' })
        }

        $manifest = Join-Path $project 'Packages\manifest.json'
        if (Test-Path -LiteralPath $manifest) {
            $markers = Get-SuspiciousMarkers (Get-Content -LiteralPath $manifest -Raw)
            Add-Finding 'Project' $(if ($markers.Count -eq 0) { 'PASS' } else { 'FAIL' }) 'Package registry sources' $(if ($markers.Count -eq 0) { 'No China/Tuanjie markers in Packages/manifest.json.' } else { "Markers=$($markers -join ', ')" })
        }

        $vsconfig = Join-Path $project '.vsconfig'
        if (Test-Path -LiteralPath $vsconfig) {
            $vsconfigText = Get-Content -LiteralPath $vsconfig -Raw
            $requiresUnity = $vsconfigText -match 'Microsoft\.VisualStudio\.Workload\.ManagedGame'
            Add-Finding 'Project' $(if (-not $requiresUnity -or ($unityInstances -and $unityInstances.Count -gt 0)) { 'PASS' } else { 'FAIL' }) '.vsconfig workloads' $(if ($requiresUnity) { 'Requires Microsoft.VisualStudio.Workload.ManagedGame.' } else { 'No Unity workload entry found.' })
        }

        if ($git) {
            $repoRoot = & $git.Source -C $project rev-parse --show-toplevel 2>$null
            if ($LASTEXITCODE -eq 0) {
                $branch = & $git.Source -C $project branch --show-current 2>$null
                $remotes = @(& $git.Source -C $project remote get-url --all origin 2>$null)
                $remoteHosts = @($remotes | ForEach-Object {
                    if ($_ -match '^https?://') { try { ([Uri]$_).Host } catch { 'unparsed-https-remote' } }
                    elseif ($_ -match '^[^@]+@(?<host>[^:]+):') { $matches['host'] }
                    else { 'local-or-unparsed-remote' }
                } | Sort-Object -Unique)
                Add-Finding 'Project' $(if ($remoteHosts.Count -gt 0) { 'PASS' } else { 'WARN' }) 'Git repository and branch' "root=$repoRoot; branch=$branch; originHosts=$($remoteHosts -join ', ')" 'A real push is never used as an audit test.'

                $attributes = Join-Path $project '.gitattributes'
                $hasLfs = (Test-Path -LiteralPath $attributes) -and (Select-String -LiteralPath $attributes -Pattern 'filter=lfs' -Quiet)
                Add-Finding 'Project' $(if ($hasLfs) { 'PASS' } else { 'WARN' }) 'Git LFS attributes' $(if ($hasLfs) { 'LFS patterns detected.' } else { 'No LFS pattern detected in the root .gitattributes.' }) 'Review large binary asset handling before collaboration.'
            }
            else {
                Add-Finding 'Project' 'FAIL' 'Git repository and branch' 'The project is not inside a readable Git worktree.'
            }
        }
    }
}

$counts = [ordered]@{}
foreach ($status in @('FAIL', 'WARN', 'UNKNOWN', 'PASS', 'INFO')) {
    $counts[$status] = @($findings | Where-Object { $_.Status -eq $status }).Count
}
$verdict = if ($counts.FAIL -gt 0) { 'FAIL' } elseif ($counts.WARN -gt 0 -or $counts.UNKNOWN -gt 0) { 'WARN' } else { 'PASS' }
$outputReport = [ordered]@{
    Verdict = $verdict
    Timestamp = (Get-Date).ToString('o')
    ReadOnly = $true
    ProjectPath = $ProjectPath
    Counts = $counts
    Findings = @($findings.ToArray())
}

if ($OutputFormat -eq 'Json') {
    ConvertTo-Json -InputObject $outputReport -Depth 8
}
else {
    Write-Output "LD Unity Setup audit: $verdict"
    Write-Output "FAIL=$($counts.FAIL) WARN=$($counts.WARN) UNKNOWN=$($counts.UNKNOWN) PASS=$($counts.PASS) INFO=$($counts.INFO)"
    $findings | Sort-Object @{ Expression = { switch ($_.Status) { 'FAIL' { 0 } 'WARN' { 1 } 'UNKNOWN' { 2 } 'PASS' { 3 } default { 4 } } } }, Category, Name | Format-Table Status, Category, Name, Evidence -Wrap -AutoSize
    Write-Output 'Read-only audit complete. No system, application, browser, repository, or account state was changed.'
}

if ($counts.FAIL -gt 0) { exit 2 }
if ($counts.WARN -gt 0 -or $counts.UNKNOWN -gt 0) { exit 1 }
exit 0
