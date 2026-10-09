[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$ExpectedRemovedExecutable,
    [switch]$Apply,
    [switch]$RemoveEmptyProgramDirectory
)
$ErrorActionPreference='Stop'
$exe=[IO.Path]::GetFullPath($ExpectedRemovedExecutable)
if((Split-Path -Leaf $exe) -ne 'Tuanjie Hub.exe' -or (Split-Path -Leaf (Split-Path -Parent $exe)) -ne 'Tuanjie Hub'){
    throw 'This narrow helper only handles the inspected Tuanjie Hub executable.'
}
if(Test-Path -LiteralPath $exe){throw 'The Tuanjie executable still exists; use its verified official uninstaller first.'}
if(Get-Process -Name 'Tuanjie Hub','Tuanjie.Licensing.Client' -ErrorAction SilentlyContinue){throw 'Tuanjie processes are still running.'}
$keys=@(
    @{PS='Registry::HKEY_CURRENT_USER\SOFTWARE\Classes\tuanjiehub';Native='HKCU\SOFTWARE\Classes\tuanjiehub';Name='user'},
    @{PS='Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Classes\tuanjiehub';Native='HKLM\SOFTWARE\Classes\tuanjiehub';Name='machine'}
)
$targets=@()
foreach($key in $keys){
    if(Test-Path -LiteralPath $key.PS){
        $command=[string](Get-Item -LiteralPath ($key.PS+'\shell\open\command')).GetValue('')
        $match=[regex]::Match($command,'^\s*"([^"]+\.exe)"')
        if(-not $match.Success -or [IO.Path]::GetFullPath($match.Groups[1].Value) -ne $exe){throw 'Protocol points at a different executable; refusing cleanup.'}
        $targets+=$key
    }
}
$program=Split-Path -Parent $exe
if($RemoveEmptyProgramDirectory -and (Test-Path -LiteralPath $program)){
    $item=Get-Item -LiteralPath $program -Force
    if($item.Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Program directory is a reparse point.'}
    if(@(Get-ChildItem -LiteralPath $program -Force).Count){throw 'Program directory is not empty.'}
}
if(-not $Apply){
    [pscustomobject]@{Preview=$true;ProtocolKeys=@($targets|ForEach-Object{$_.Native});EmptyDirectory=if($RemoveEmptyProgramDirectory){$program}else{$null}}|ConvertTo-Json
    exit 0
}
$backup=Join-Path $env:LOCALAPPDATA ('LDUnitySetup\Quarantine\protocol-'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
if(Test-Path -LiteralPath $backup){throw 'Backup destination already exists.'}
if($targets.Count){New-Item -Path $backup -ItemType Directory|Out-Null}
foreach($key in $targets){
    & reg.exe export $key.Native (Join-Path $backup ($key.Name+'-tuanjiehub.reg')) /y|Out-Null
    if($LASTEXITCODE -ne 0){throw 'Exact protocol export failed; key preserved.'}
    & reg.exe delete $key.Native /f|Out-Null
    if($LASTEXITCODE -ne 0){throw 'Normal registry utility refused cleanup; do not change ACL or bypass approval.'}
    if(Test-Path -LiteralPath $key.PS){throw 'Protocol key still exists after removal.'}
}
if($RemoveEmptyProgramDirectory -and (Test-Path -LiteralPath $program)){Remove-Item -LiteralPath $program -ErrorAction Stop}
[pscustomobject]@{Completed=$true;RemovedProtocolCount=$targets.Count;Backup=if($targets.Count){$backup}else{$null};EmptyDirectoryAbsent=(-not(Test-Path -LiteralPath $program))}|ConvertTo-Json
