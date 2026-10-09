[CmdletBinding()]
param(
    [switch]$UnityHubChinaCache,
    [switch]$TuanjieUserData,
    [switch]$Apply,
    [string]$QuarantineRoot
)

$ErrorActionPreference = 'Stop'

if (-not $UnityHubChinaCache -and -not $TuanjieUserData) {
    throw 'Select at least one scope: -UnityHubChinaCache or -TuanjieUserData.'
}

$targets = New-Object System.Collections.Generic.List[object]
$roaming = [Environment]::GetFolderPath('ApplicationData')
$local = [Environment]::GetFolderPath('LocalApplicationData')

if ($UnityHubChinaCache) {
    $hub = Join-Path $roaming 'UnityHub'
    $relativeTargets = @(
        'storage\cloudConfig.json',
        'storage\releases.json',
        'releases.json',
        'editors.json',
        'featureFlags.json',
        'graphqlCache',
        'IndexedDB\https_developer.unity.cn_0.indexeddb.leveldb',
        'Service Worker',
        'Cache',
        'Code Cache',
        'GPUCache',
        'Local Storage',
        'Session Storage'
    )
    foreach ($relative in $relativeTargets) {
        $candidate = Join-Path $hub $relative
        if (Test-Path -LiteralPath $candidate) {
            $targets.Add([pscustomobject]@{ Scope = 'UnityHubChinaCache'; Source = $candidate; Relative = $relative })
        }
    }
}

if ($TuanjieUserData) {
    $tuanjieTargets = @(
        (Join-Path $roaming 'TuanjieHub'),
        (Join-Path $local 'Tuanjie'),
        (Join-Path $local 'tuanjiehub-updater')
    )
    foreach ($candidate in $tuanjieTargets) {
        if (Test-Path -LiteralPath $candidate) {
            $targets.Add([pscustomobject]@{ Scope = 'TuanjieUserData'; Source = $candidate; Relative = Split-Path -Leaf $candidate })
        }
    }
}

if ($targets.Count -eq 0) {
    Write-Output 'No matching app-specific user-state targets were found.'
    exit 0
}

$allowedRoots = @(
    ([IO.Path]::GetFullPath($roaming).TrimEnd([char]92) + [char]92),
    ([IO.Path]::GetFullPath($local).TrimEnd([char]92) + [char]92)
)
foreach ($target in $targets) {
    $full = [IO.Path]::GetFullPath($target.Source)
    $allowed = $false
    foreach ($root in $allowedRoots) {
        if ($full.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) { $allowed = $true; break }
    }
    if (-not $allowed) { throw "Refusing out-of-scope target: $full" }
    $pending = New-Object System.Collections.Generic.Stack[string]
    $pending.Push($full)
    while ($pending.Count -gt 0) {
        $candidate = Get-Item -LiteralPath $pending.Pop() -Force
        if ($candidate.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Reparse point requires separate review: $($candidate.FullName)" }
        if ($candidate.PSIsContainer) {
            foreach ($child in Get-ChildItem -LiteralPath $candidate.FullName -Force) { $pending.Push($child.FullName) }
        }
    }
}

$preview = $targets | Select-Object Scope, Source
if (-not $Apply) {
    Write-Output 'PREVIEW ONLY - no files were moved.'
    $preview | Format-Table -Wrap -AutoSize
    Write-Output 'Re-run with -Apply only after reviewing these exact targets and obtaining explicit authorization.'
    exit 0
}

$blockingNames = @('Unity Hub', 'Tuanjie Hub', 'Unity', 'Unity.Licensing.Client', 'Tuanjie.Licensing.Client')
$running = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $blockingNames -contains $_.ProcessName })
if ($running.Count -gt 0) {
    $names = ($running | Select-Object -ExpandProperty ProcessName -Unique) -join ', '
    throw "Close these applications before quarantine: $names"
}

if ([string]::IsNullOrWhiteSpace($QuarantineRoot)) {
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $QuarantineRoot = Join-Path $local "LDUnitySetup\Quarantine\$stamp"
}

$quarantineFull = [IO.Path]::GetFullPath($QuarantineRoot)
$safeQuarantineBase = [IO.Path]::GetFullPath((Join-Path $local 'LDUnitySetup\Quarantine')).TrimEnd([char]92) + [char]92
$quarantineComparable = $quarantineFull.TrimEnd([char]92) + [char]92
if (-not $quarantineComparable.StartsWith($safeQuarantineBase, [StringComparison]::OrdinalIgnoreCase)) {
    throw "QuarantineRoot must remain under $safeQuarantineBase"
}
if (Test-Path -LiteralPath $quarantineFull) {
    throw "Quarantine destination already exists: $quarantineFull"
}

New-Item -Path $quarantineFull -ItemType Directory -Force | Out-Null
$manifest = New-Object System.Collections.Generic.List[object]
$manifestPath = Join-Path $quarantineFull 'manifest.json'
ConvertTo-Json -InputObject @($manifest.ToArray()) -Depth 5 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
$index = 0
foreach ($target in $targets) {
    $index++
    $safeName = ($target.Relative -replace '[\\/:*?"<>|]', '_')
    $scopeFolder = Join-Path $quarantineFull $target.Scope
    if (-not (Test-Path -LiteralPath $scopeFolder)) { New-Item -Path $scopeFolder -ItemType Directory -Force | Out-Null }
    $destination = Join-Path $scopeFolder ("{0:D2}_{1}" -f $index, $safeName)
    if (Test-Path -LiteralPath $destination) { throw "Destination collision: $destination" }
    Move-Item -LiteralPath $target.Source -Destination $destination
    $manifest.Add([pscustomobject]@{ Scope = $target.Scope; OriginalPath = $target.Source; QuarantinedPath = $destination })
    $manifestTemp = Join-Path $quarantineFull 'manifest.tmp'
    ConvertTo-Json -InputObject @($manifest.ToArray()) -Depth 5 | Set-Content -LiteralPath $manifestTemp -Encoding UTF8
    Move-Item -LiteralPath $manifestTemp -Destination $manifestPath -Force
}

Write-Output "Quarantine complete: $quarantineFull"
Write-Output "Manifest: $manifestPath"
Write-Output 'No registry, browser profile, system network, security, service, scheduled-task, or startup setting was changed.'
Write-Output 'Recoverable quarantine is not permanent eradication; disclose any retained installers or executable payloads.'
