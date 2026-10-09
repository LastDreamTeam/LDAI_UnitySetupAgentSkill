[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [ValidateSet('Auto', 'Hub', 'Editor', 'Module', 'VisualStudio', 'VSCode', 'Git')]
    [string]$Kind = 'Auto',

    [ValidateSet('Human', 'Json')]
    [string]$OutputFormat = 'Human'
)

$ErrorActionPreference = 'Stop'

try {
    $resolved = (Resolve-Path -LiteralPath $Path).Path
    $item = Get-Item -LiteralPath $resolved
    if ($item.PSIsContainer) {
        throw 'The supplied path is a directory.'
    }

    $signature = Get-AuthenticodeSignature -LiteralPath $resolved
    $versionInfo = $item.VersionInfo
    $product = [string]$versionInfo.ProductName
    $version = [string]$versionInfo.ProductVersion
    $company = [string]$versionInfo.CompanyName
    $signer = if ($signature.SignerCertificate) { [string]$signature.SignerCertificate.Subject } else { '' }
    $detectedKind = $Kind

    if ($Kind -eq 'Auto') {
        if ($product -match '(?i)Tuanjie|\u56e2\u7ed3') { $detectedKind = 'Hub' }
        elseif ($product -match '(?i)^Unity Hub$') { $detectedKind = 'Hub' }
        elseif ($product -match '(?i)^Unity($|\s)') { $detectedKind = 'Editor' }
        elseif ($signer -match '(?i)Microsoft Corporation') { $detectedKind = 'VisualStudio' }
        else { $detectedKind = 'Auto' }
    }

    $reasons = New-Object System.Collections.Generic.List[string]
    if ([string]$signature.Status -ne 'Valid') {
        $reasons.Add("Authenticode status is $($signature.Status).")
    }
    if (($product + ' ' + $company + ' ' + $signer) -match '(?i)Tuanjie|\u56e2\u7ed3|\u4f18\u4e09\u7f14') {
        $reasons.Add('Tuanjie/Unity China product or signer identity detected.')
    }

    switch ($detectedKind) {
        'Hub' {
            if ($product -ne 'Unity Hub') { $reasons.Add("Expected product name 'Unity Hub', got '$product'.") }
            if ($signer -notmatch '(?i)Unity Technologies') { $reasons.Add('Hub signer is not Unity Technologies.') }
        }
        'Editor' {
            if ($product -notmatch '(?i)^Unity($|\s)') { $reasons.Add("Expected a Unity Editor product, got '$product'.") }
            if ($version -match '(?i)(?:c|t)\d+(?:_|$)') { $reasons.Add("Editor version '$version' has a China/Tuanjie suffix.") }
            if ($signer -notmatch '(?i)Unity Technologies') { $reasons.Add('Editor signer is not Unity Technologies.') }
        }
        'Module' {
            if ($product -notmatch '(?i)Unity') { $reasons.Add("Expected a Unity module product, got '$product'.") }
            if ($version -match '(?i)(?:c|t)\d+(?:_|$)') { $reasons.Add("Module version '$version' has a China/Tuanjie suffix.") }
            if ($signer -notmatch '(?i)Unity Technologies') { $reasons.Add('Module signer is not Unity Technologies.') }
        }
        'VisualStudio' {
            if ($signer -notmatch '(?i)Microsoft Corporation') { $reasons.Add('Visual Studio installer is not signed by Microsoft Corporation.') }
        }
        'VSCode' {
            if ($signer -notmatch '(?i)Microsoft Corporation') { $reasons.Add('VS Code installer is not signed by Microsoft Corporation.') }
        }
        'Git' {
            $reasons.Add('Git publisher provenance requires current official release verification; a nonempty signer alone is insufficient.')
        }
        default {
            $reasons.Add('Unrecognized product identity; specify an appropriate supported kind and verify current official provenance.')
        }
    }

    $result = [pscustomobject]@{
        Verdict = if ($reasons.Count -eq 0) { 'PASS' } else { 'FAIL' }
        Kind = $detectedKind
        Path = $resolved
        ProductName = $product
        ProductVersion = $version
        CompanyName = $company
        SignatureStatus = [string]$signature.Status
        Signer = $signer
        Sha256 = (Get-FileHash -LiteralPath $resolved -Algorithm SHA256).Hash
        Reasons = @($reasons)
    }

    if ($OutputFormat -eq 'Json') {
        $result | ConvertTo-Json -Depth 5
    }
    else {
        $result | Format-List
    }

    if ($reasons.Count -gt 0) { exit 2 }
    exit 0
}
catch {
    $failure = [pscustomobject]@{
        Verdict = 'FAIL'
        Kind = $Kind
        Path = $Path
        Reasons = @($_.Exception.Message)
    }
    if ($OutputFormat -eq 'Json') { $failure | ConvertTo-Json -Depth 4 } else { $failure | Format-List }
    exit 2
}
