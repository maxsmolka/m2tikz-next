[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repositoryRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$extensions = @('.cff','.json','.m','.md','.ps1','.py','.tex','.txt','.yaml','.yml')
$tracked = @(& git -C $repositoryRoot ls-files)
if ($LASTEXITCODE -ne 0) { throw 'Unable to enumerate tracked files.' }

$driveHome = '[A-Za-z]:' + '[\\/]' + 'Users' + '[\\/]'
$unixHome = '/' + '(?:Users|home)' + '/'
$findings = [Collections.Generic.List[string]]::new()

foreach ($relative in $tracked) {
    $path = Join-Path $repositoryRoot $relative
    if (!(Test-Path -LiteralPath $path -PathType Leaf)) { continue }
    if ($extensions -notcontains [IO.Path]::GetExtension($path).ToLowerInvariant()) { continue }
    if ([IO.Path]::GetFullPath($path) -eq [IO.Path]::GetFullPath($PSCommandPath)) { continue }
    $lineNumber = 0
    foreach ($line in [IO.File]::ReadLines($path)) {
        $lineNumber++
        if ($line -match $driveHome -or $line -match $unixHome) {
            $findings.Add("${relative}:${lineNumber}: absolute user-home path")
        }
    }
}

if ($findings.Count) {
    $findings | ForEach-Object { Write-Error $_ }
    throw "Confidentiality check found $($findings.Count) path leak(s)."
}

Write-Host 'Confidentiality check: PASS (no absolute user-home paths in tracked text).'
