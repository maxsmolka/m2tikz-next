[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path $PSScriptRoot -Parent
$plannerDirectory = Join-Path $repositoryRoot 'src\+m2t\+planning'
$readerDirectory = Join-Path $repositoryRoot 'src\+m2t2\+reader'
$rendererDirectory = Join-Path $repositoryRoot 'src\+m2t2\+render'
$profileDirectory = Join-Path $repositoryRoot 'src\+m2t\+profile'
$setPath = Join-Path $repositoryRoot 'src\+m2t\exportSet.m'
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

Find-Pattern $plannerDirectory '(?i)graphics_toolkit|ishandle|imwrite|writePng|compileLuaLatex|system\s*\(' `
    'planner accesses runtime/toolkit, writes PNGs, or invokes external compilation'
Find-Pattern $readerDirectory '(?i)selectImageBackend|maxVectorCells|dense_scalar_image' `
    'reader chooses an image backend'
Find-Pattern $profileDirectory '(?i)selectImageBackend|maxVectorCells|dense_scalar_image' `
    'profile chooses an image backend'
Find-Pattern $rendererDirectory '(?i)selectImageBackend|maxVectorCells|dense_scalar_image|small_scalar_image' `
    'renderer contains planner policy or heuristics'

$setSource = Get-Content -Raw -LiteralPath $setPath
if ($setSource -match '(?i)maxVectorCells|dense_scalar_image|small_scalar_image') {
    $violations.Add('exportSet implements separate planning logic')
}
if ($violations.Count -gt 0) {
    $violations | ForEach-Object { Write-Error $_ }
    throw 'Backend planner architecture invariant failed.'
}
Write-Host 'Planner invariant: PASS (isolated, handle-free, deterministic policy layer).'
