[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path $PSScriptRoot -Parent
$profileDirectory = Join-Path $repositoryRoot 'src\+m2t\+profile'
$readerDirectory = Join-Path $repositoryRoot 'src\+m2t2\+reader'
$rendererDirectory = Join-Path $repositoryRoot 'src\+m2t2\+render'
$violations = [System.Collections.Generic.List[string]]::new()

function Find-CodePattern([string]$Directory, [string]$Pattern, [string]$Reason) {
    Get-ChildItem -LiteralPath $Directory -Filter '*.m' -File -Recurse | ForEach-Object {
        $path = $_.FullName
        $lineNumber = 0
        Get-Content -LiteralPath $path | ForEach-Object {
            $lineNumber++
            $code = ($_ -split '%', 2)[0]
            if ($code -match $Pattern) {
                $relative = [IO.Path]::GetRelativePath($repositoryRoot, $path)
                $violations.Add("${relative}:${lineNumber}: ${Reason}: $($_.Trim())")
            }
        }
    }
}

Find-CodePattern $profileDirectory `
    '(?i)(?<![\w.])(get|set|ishandle|gcf|gca|findobj|findall|allchild|ancestor)\s*\(' `
    'profile layer accesses runtime graphics'
Find-CodePattern $readerDirectory '(?i)m2t\.profile' 'reader depends on profile layer'
Find-CodePattern $rendererDirectory '(?i)(getProfile|publication)' `
    'renderer depends on a named profile'

if ($violations.Count -gt 0) {
    $violations | ForEach-Object { Write-Error $_ }
    throw 'Profile architecture invariant failed.'
}

Write-Host 'Profile invariant: PASS (handle-free transform; profile-unaware reader and renderer).'
