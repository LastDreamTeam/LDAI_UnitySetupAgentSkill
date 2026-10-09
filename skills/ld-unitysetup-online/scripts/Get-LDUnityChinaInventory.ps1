[CmdletBinding()]
param([ValidateSet('Human','Json')][string]$OutputFormat='Json')
$ErrorActionPreference='Stop'
$roots=@('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*','HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*')
$products=@(Get-ItemProperty $roots -ErrorAction SilentlyContinue | Where-Object {
    $_.DisplayName -match '(?i)Tuanjie|\u56e2\u7ed3' -or
    $_.Publisher -match '(?i)Tuanjie|\u4f18\u4e09\u7f14' -or
    ($_.DisplayName -match '(?i)^Unity' -and $_.DisplayVersion -match '(?i)(?:c|t)\d+(?:_|$)')
} | ForEach-Object {
    $command=[string]$_.UninstallString
    $match=[regex]::Match($command,'^\s*"([^"]+\.exe)"|^\s*(.+?\.exe)(?:\s|$)')
    $executable=if($match.Groups[1].Success){$match.Groups[1].Value}else{$match.Groups[2].Value}
    $sig=if($executable -and (Test-Path -LiteralPath $executable)){Get-AuthenticodeSignature -LiteralPath $executable}else{$null}
    [pscustomobject]@{Name=$_.DisplayName;Version=$_.DisplayVersion;Publisher=$_.Publisher;InstallDate=$_.InstallDate;Uninstaller=$executable;UninstallerExists=($executable -and (Test-Path -LiteralPath $executable));Signature=if($sig){[string]$sig.Status}else{'UNKNOWN'};QuietUninstallRegistered=(-not [string]::IsNullOrWhiteSpace($_.QuietUninstallString));RegistryPath=$_.PSPath}
})
$paths=@((Join-Path $env:ProgramFiles 'Tuanjie Hub'),(Join-Path $env:APPDATA 'TuanjieHub'),(Join-Path $env:LOCALAPPDATA 'Tuanjie'),(Join-Path $env:LOCALAPPDATA 'tuanjiehub-updater'))
$artifacts=@($paths | Where-Object{Test-Path -LiteralPath $_}|ForEach-Object{$item=Get-Item -LiteralPath $_;[pscustomobject]@{Path=$item.FullName;Created=$item.CreationTime;Modified=$item.LastWriteTime;TimeMeaning='Filesystem evidence, not a confirmed installation date'}})
$protocols=@('Registry::HKEY_CURRENT_USER\SOFTWARE\Classes\tuanjiehub','Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Classes\tuanjiehub')
$result=[pscustomobject]@{ReadOnly=$true;Products=$products;Artifacts=$artifacts;Protocols=@($protocols|Where-Object{Test-Path -LiteralPath $_});Processes=@(Get-CimInstance Win32_Process|Where-Object{$_.Name -match '(?i)tuanjie'}|Select-Object ProcessId,Name,ExecutablePath)}
if($OutputFormat -eq 'Json'){$result|ConvertTo-Json -Depth 6}else{$result|Format-List}
