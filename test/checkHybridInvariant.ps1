[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path $PSScriptRoot -Parent
$readerDirectory = Join-Path $repositoryRoot 'src\+m2t2\+reader'
$rendererDirectory = Join-Path $repositoryRoot 'src\+m2t2\+render'
$profileDirectory = Join-Path $repositoryRoot 'src\+m2t\+profile'
$compilerPath = Join-Path $repositoryRoot 'src\+m2t\+internal\compileLuaLatex.m'
$violations = [System.Collections.Generic.List[string]]::new()

function Find-Pattern([string]$Directory,[string]$Pattern,[string]$Reason) {
    Get-ChildItem -LiteralPath $Directory -Filter '*.m' -File -Recurse | ForEach-Object {
        $source = Get-Content -Raw -LiteralPath $_.FullName
        if ($source -match $Pattern) {
            $relative = [IO.Path]::GetRelativePath($repositoryRoot,$_.FullName)
            $violations.Add("${relative}: ${Reason}")
        }
    }
}

Find-Pattern $readerDirectory '(?i)imageBackend|imwrite|\.png' `
    'runtime reader contains backend or PNG logic'
Find-Pattern $profileDirectory '(?i)imageBackend|writePng|imwrite' `
    'publication profile contains backend or PNG logic'
Find-Pattern $rendererDirectory '(?i)(?<![\w.])(print|saveas|getframe)\s*\(' `
    'renderer uses a screenshot API'

$compilerSource = Get-Content -Raw -LiteralPath $compilerPath
if ($compilerSource -match '(?i)imwrite|writePng|imageColorIndices|makePgfplotsPlan') {
    $violations.Add('compiler creates or interprets image assets')
}

if ($violations.Count -gt 0) {
    $violations | ForEach-Object { Write-Error $_ }
    throw 'Hybrid architecture invariant failed.'
}

Write-Host 'Hybrid invariant: PASS (reader/profile/compiler separation; no screenshots).'
