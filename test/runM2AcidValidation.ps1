[CmdletBinding()]
param(
    [string]$BashCommand = 'bash',
    [string]$OctaveCommand = 'octave-cli',
    [string]$OutputDirectory = ''
)

$repo = Split-Path $PSScriptRoot -Parent
if (!$OutputDirectory) { $OutputDirectory = Join-Path $repo '.audit\m2\logs' }
New-Item -ItemType Directory -Force $OutputDirectory | Out-Null
$log = Join-Path $OutputDirectory 'legacy-acid-final.log'
$ErrorActionPreference = 'Continue'
Push-Location $repo
try {
    & $BashCommand ./runtests.sh $OctaveCommand '--no-gui --eval' 2>&1 | Set-Content -LiteralPath $log -Encoding utf8
    $code = $LASTEXITCODE
} finally {
    Pop-Location
}
Set-Content -LiteralPath (Join-Path $OutputDirectory 'legacy-acid-exit.txt') -Value $code -Encoding ascii
exit $code
