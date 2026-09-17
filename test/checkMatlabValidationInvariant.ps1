[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path $PSScriptRoot -Parent
$testPackage = Join-Path $repositoryRoot 'test\+m2t_test'
$productRoots = @(
    (Join-Path $repositoryRoot 'src\+m2t2\+reader'),
    (Join-Path $repositoryRoot 'src\+m2t2\+render'),
    (Join-Path $repositoryRoot 'src\+m2t\+profile'),
    (Join-Path $repositoryRoot 'src\+m2t\+planning')
)
$violations = [System.Collections.Generic.List[string]]::new()

$validationRoots = @($testPackage, (Join-Path $repositoryRoot 'validation/external-acceptance'))
Get-ChildItem -LiteralPath $validationRoots -Filter '*.m' -File | ForEach-Object {
    $source = Get-Content -Raw -LiteralPath $_.FullName
    if ($source -match '(?i)license\s*\(|getenv\s*\(\s*[''\"](?:username|computername)') {
        $violations.Add("$($_.Name): captures forbidden license or identity data")
    }
    if ($_.DirectoryName -like '*external-acceptance*' -and
        $source -match '(?i)\b(?:webwrite|webread|urlwrite|urlread|ftp|sendmail)\s*\(') {
        $violations.Add("$($_.Name): external acceptance must remain local-only")
    }
}
foreach ($root in $productRoots) {
    Get-ChildItem -LiteralPath $root -Filter '*.m' -File -Recurse | ForEach-Object {
        if ((Get-Content -Raw -LiteralPath $_.FullName) -match 'm2t_test|MATLAB-HG-|MATLAB-READER-|runExternalAcceptance') {
            $violations.Add("$($_.FullName): product layer depends on validation infrastructure")
        }
    }
}
if ($violations.Count -gt 0) {
    $violations | ForEach-Object { Write-Error $_ }
    throw 'MATLAB validation preparation invariant failed.'
}
Write-Host 'MATLAB validation invariant: PASS (test-only, privacy-safe, product-decoupled).'
