[CmdletBinding()]
param(
    [string]$OctaveCommand = 'octave-cli',
    [string]$LatexmkCommand = 'latexmk',
    [string]$ReviewRoot = '',
    [string]$Run1 = '',
    [string]$Run2 = ''
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
if (!$ReviewRoot) { $ReviewRoot = Join-Path $repo '.audit\m1b-golden-review' }
New-Item -ItemType Directory -Force -Path $ReviewRoot | Out-Null
$logs = Join-Path $ReviewRoot 'logs'
New-Item -ItemType Directory -Force -Path $logs | Out-Null
$texCache = Join-Path $ReviewRoot 'texmf-cache'
New-Item -ItemType Directory -Force -Path $texCache | Out-Null
$env:TEXMFVAR = $texCache
$env:TEXMFCACHE = $texCache

function Octave-Literal([string]$Value) {
    $Value.Replace('\', '/').Replace("'", "''")
}
function Invoke-Captured([string]$Command, [string[]]$Arguments, [string]$Log) {
    $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    try {
        & $Command @Arguments 2>&1 | Set-Content -LiteralPath $Log -Encoding utf8
        return $LASTEXITCODE
    } finally { $ErrorActionPreference = $old }
}
function Compile-One([string]$Tex, [string]$Engine, [string]$Out, [string]$Log) {
    New-Item -ItemType Directory -Force -Path $Out | Out-Null
    $mode = if ($Engine -eq 'lualatex') { '-lualatex' } else { '-pdf' }
    $args = @($mode, '-cd', '-gg', '-interaction=nonstopmode', '-halt-on-error',
              '-file-line-error', "-outdir=$Out", $Tex)
    Invoke-Captured $LatexmkCommand $args $Log
}
function Failure-Class([string]$Log, [string]$Engine) {
    $text = Get-Content -Raw -LiteralPath $Log
    if ($text -match 'not found|Missing input file') { return 'ASSET FAILURE' }
    if ($Engine -eq 'pdflatex' -and $text -match 'Unicode character|inputenc Error|not set up for use with LaTeX') {
        return 'EXPECTED ENGINE LIMITATION'
    }
    if ($text -match 'Fatal error|Emergency stop|TeX capacity exceeded|Package .* Error') { return 'TEX FAILURE' }
    return 'UNKNOWN'
}

$testPath = Octave-Literal $PSScriptRoot
$reviewPath = Octave-Literal $ReviewRoot
$exportLog = Join-Path $logs 'export-and-semantic-validation.log'
$generator = "addpath('$testPath'); generateM1BGoldenCandidates('$reviewPath');"
if ($Run1 -and $Run2) {
    $run1Path = Octave-Literal $Run1
    $run2Path = Octave-Literal $Run2
    $generator = "addpath('$testPath'); generateM1BGoldenCandidates('$reviewPath','$run1Path','$run2Path');"
}
$exitCode = Invoke-Captured $OctaveCommand @('--no-gui','--quiet','--eval',
    $generator) $exportLog
if ($exitCode -ne 0) { throw "Golden candidate export failed; see $exportLog" }

$resultsPath = Join-Path $ReviewRoot 'results.tsv'
$rows = Import-Csv -Delimiter "`t" -LiteralPath $resultsPath
foreach ($row in $rows) {
    if ($row.EXPORT_STATUS -ne 'PASS') { continue }
    $caseName = 'ACID-{0:d3}' -f [int]$row.ACID_ID
    $caseRoot = Join-Path $ReviewRoot $caseName
    $tex = Join-Path $caseRoot ('generated-tex\test' + $row.ACID_ID + '-converted.tex')
    $pdfRoot = Join-Path $caseRoot 'compiled-pdf'
    $caseLogRoot = Join-Path $caseRoot 'metadata'
    $luaLog = Join-Path $caseLogRoot 'lualatex.log'
    $pdfLog = Join-Path $caseLogRoot 'pdflatex.log'
    $luaExit = Compile-One $tex 'lualatex' (Join-Path $pdfRoot 'lualatex') $luaLog
    $pdfExit = Compile-One $tex 'pdflatex' (Join-Path $pdfRoot 'pdflatex') $pdfLog
    $classes = [System.Collections.Generic.List[string]]::new()
    if ($luaExit -eq 0) { $luaClass = 'PASS' } else { $luaClass = Failure-Class $luaLog 'lualatex'; $classes.Add($luaClass) }
    if ($pdfExit -eq 0) { $pdfClass = 'PASS' } else { $pdfClass = Failure-Class $pdfLog 'pdflatex'; $classes.Add($pdfClass) }
    $row.TEX_STATUS = "LuaLaTeX=$luaClass;pdfLaTeX=$pdfClass"
    $luaPdf = Test-Path -LiteralPath (Join-Path $pdfRoot ('lualatex\test' + $row.ACID_ID + '-converted.pdf'))
    $pdfPdf = Test-Path -LiteralPath (Join-Path $pdfRoot ('pdflatex\test' + $row.ACID_ID + '-converted.pdf'))
    $row.PDF_STATUS = "LuaLaTeX=$luaPdf;pdfLaTeX=$pdfPdf"
    if ($luaExit -ne 0) {
        $row.REVIEW_STATUS = 'REJECTED'
        $row.NOTES += " LuaLaTeX classification: $luaClass."
    } elseif ($pdfExit -ne 0) {
        $row.NOTES += " pdfLaTeX classification: $pdfClass."
    }
}
$rows | Export-Csv -Delimiter "`t" -NoTypeInformation -LiteralPath $resultsPath

$summary = $rows | Group-Object EXPORT_STATUS | Select-Object Name,Count
$reviews = $rows | Group-Object REVIEW_STATUS | Select-Object Name,Count
$summary | Format-Table -AutoSize
$reviews | Format-Table -AutoSize
Write-Host "Review results: $resultsPath"
