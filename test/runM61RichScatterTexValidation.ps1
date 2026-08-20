[CmdletBinding()]
param(
    [string]$OctaveCommand = 'octave-cli',
    [string]$LatexmkCommand = 'latexmk',
    [string]$OutputDirectory = ''
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
if (!$OutputDirectory) { $OutputDirectory = Join-Path $root '.audit\m61-rich-scatter-tex' }
$OutputDirectory = [IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Force $OutputDirectory | Out-Null
$testPath = $PSScriptRoot.Replace('\','/').Replace("'","''")
$outputPath = $OutputDirectory.Replace('\','/').Replace("'","''")
& $OctaveCommand --quiet --eval "addpath('$testPath'); generateM61RichScatterFixtures('$outputPath');"
if ($LASTEXITCODE -ne 0) { throw 'Rich-scatter TeX fixture generation failed.' }

$env:TEXMFVAR = Join-Path $OutputDirectory 'texmf-var'
$env:TEXMFCACHE = $env:TEXMFVAR
New-Item -ItemType Directory -Force $env:TEXMFVAR | Out-Null
$files = Get-ChildItem -LiteralPath $OutputDirectory -Filter '*.tex' | Sort-Object Name
if ($files.Count -ne 9) { throw "Expected nine rich-scatter TeX fixtures, found $($files.Count)." }
foreach ($file in $files) {
    $pdfDirectory = Join-Path $OutputDirectory ('pdf\' + $file.BaseName)
    New-Item -ItemType Directory -Force $pdfDirectory | Out-Null
    $latexmkLog = Join-Path $OutputDirectory ($file.BaseName + '-latexmk.log')
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        & $LatexmkCommand -cd -lualatex -gg -interaction=nonstopmode -halt-on-error `
            -file-line-error "-outdir=$pdfDirectory" $file.FullName 2>&1 |
            Set-Content -LiteralPath $latexmkLog -Encoding utf8
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $oldPreference
    }
    if ($exitCode -ne 0) {
        if (Test-Path -LiteralPath $latexmkLog) {
            Get-Content -LiteralPath $latexmkLog | Select-Object -Last 200
        }
        $log = Join-Path $pdfDirectory ($file.BaseName + '.log')
        if (Test-Path -LiteralPath $log) { Get-Content -LiteralPath $log | Select-Object -Last 200 }
        throw "LuaLaTeX failed for rich-scatter fixture: $($file.FullName)"
    }
}
Write-Host "M6.1 rich-scatter TeX validation: PASS ($($files.Count)/$($files.Count))"
