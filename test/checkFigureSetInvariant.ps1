[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path $PSScriptRoot -Parent
$exportSetPath = Join-Path $repositoryRoot 'src\+m2t\exportSet.m'
$rendererDirectory = Join-Path $repositoryRoot 'src\+m2t2\+render'
$source = Get-Content -Raw -LiteralPath $exportSetPath
$violations = [System.Collections.Generic.List[string]]::new()

if ($source -notmatch '(?m)m2t\.export\s*\(') {
    $violations.Add('exportSet does not delegate entry work to m2t.export.')
}
foreach ($pattern in @('m2t2\.render','m2t2\.reader','compileLuaLatex','analyzeFigure')) {
    if ($source -match $pattern) {
        $violations.Add("exportSet contains forbidden parallel-pipeline dependency: $pattern")
    }
}
Get-ChildItem -LiteralPath $rendererDirectory -Filter '*.m' -File -Recurse | ForEach-Object {
    if ((Get-Content -Raw -LiteralPath $_.FullName) -match '(?i)exportSet|m2t-manifest') {
        $relative = [IO.Path]::GetRelativePath($repositoryRoot, $_.FullName)
        $violations.Add("Renderer is figure-set aware: $relative")
    }
}

if ($violations.Count -gt 0) {
    $violations | ForEach-Object { Write-Error $_ }
    throw 'Figure-set architecture invariant failed.'
}

Write-Host 'Figure-set invariant: PASS (m2t.export delegation; set-unaware renderer).'
