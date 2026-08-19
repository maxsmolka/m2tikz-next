[CmdletBinding()]
param(
    [string]$OctaveCommand = 'octave-cli',
    [string]$LatexmkCommand = 'latexmk',
    [string]$PdfToPpmCommand = 'pdftoppm',
    [string]$PythonCommand = 'python',
    [string]$OutputDirectory = ''
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
if (!$OutputDirectory) { $OutputDirectory = Join-Path $repo '.audit\m2.1\line-validation' }
$OutputDirectory = [IO.Path]::GetFullPath($OutputDirectory)
$logDirectory = Join-Path $OutputDirectory 'logs'
$cacheDirectory = Join-Path $OutputDirectory 'texmf-cache'
New-Item -ItemType Directory -Force $OutputDirectory,$logDirectory,$cacheDirectory | Out-Null
$env:TEXMFVAR = $cacheDirectory
$env:TEXMFCACHE = $cacheDirectory

function Convert-ToOctaveLiteral([string]$Value) {
    return $Value.Replace('\', '/').Replace("'", "''")
}

function Invoke-Captured([string]$Command, [string[]]$Arguments, [string]$Log) {
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        & $Command @Arguments 2>&1 | Set-Content -LiteralPath $Log -Encoding utf8
        return $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $oldPreference
    }
}

$testLiteral = Convert-ToOctaveLiteral $PSScriptRoot
$outputLiteral = Convert-ToOctaveLiteral $OutputDirectory
$octaveExpression = "addpath('$testLiteral'); runM2ReaderTests('$outputLiteral'); runM2RendererTests('$outputLiteral'); generateM2LineFixtures('$outputLiteral');"
$octaveLog = Join-Path $logDirectory 'octave-validation.log'
$octaveExit = Invoke-Captured $OctaveCommand @('--quiet','--eval',$octaveExpression) $octaveLog
if ($octaveExit -ne 0) {
    Write-Host "M2 Octave validation failed; see $octaveLog"
    exit 1
}

$names = @('minimal','multiple','styled','labels','display_name','log_x','log_y','nan_gap','inf_gap','empty')
$compileRows = [System.Collections.Generic.List[object]]::new()
$compileFailures = 0
foreach ($pipeline in @('legacy','m2')) {
    foreach ($name in $names) {
        $texFile = Join-Path $OutputDirectory "tex\$pipeline\$name.tex"
        $pdfDirectory = Join-Path $OutputDirectory "pdf\$pipeline\$name"
        New-Item -ItemType Directory -Force $pdfDirectory | Out-Null
        $compileLog = Join-Path $logDirectory "$pipeline-$name-lualatex.log"
        $arguments = @('-lualatex','-cd','-gg','-interaction=nonstopmode','-halt-on-error','-file-line-error',"-outdir=$pdfDirectory",$texFile)
        $timer = [System.Diagnostics.Stopwatch]::StartNew()
        $exitCode = Invoke-Captured $LatexmkCommand $arguments $compileLog
        $timer.Stop()
        if ($exitCode -eq 0) { $status = 'PASS' } else { $status = 'FAIL'; $compileFailures++ }
        $pdfPath = Join-Path $pdfDirectory "$name.pdf"
        $compileRows.Add([pscustomobject]@{
            pipeline=$pipeline; case=$name; status=$status; exit_code=$exitCode
            seconds=[math]::Round($timer.Elapsed.TotalSeconds, 4); pdf=$pdfPath; log=$compileLog
        })
    }
}
$compileRows | Export-Csv -Delimiter "`t" -NoTypeInformation -LiteralPath (Join-Path $OutputDirectory 'compile-results.tsv')

$visualRows = [System.Collections.Generic.List[object]]::new()
if ($compileFailures -eq 0) {
    $rasterDirectory = Join-Path $OutputDirectory 'raster'
    $differenceDirectory = Join-Path $OutputDirectory 'visual-diff'
    New-Item -ItemType Directory -Force $rasterDirectory,$differenceDirectory | Out-Null
    foreach ($name in $names) {
        $legacyPdf = Join-Path $OutputDirectory "pdf\legacy\$name\$name.pdf"
        $m2Pdf = Join-Path $OutputDirectory "pdf\m2\$name\$name.pdf"
        $legacyPrefix = Join-Path $rasterDirectory "$name-legacy"
        $m2Prefix = Join-Path $rasterDirectory "$name-m2"
        & $PdfToPpmCommand -f 1 -singlefile -r 150 -png $legacyPdf $legacyPrefix | Out-Null
        if ($LASTEXITCODE -ne 0 -or !(Test-Path -LiteralPath "$legacyPrefix.png")) { throw "Legacy rasterization failed for $name" }
        & $PdfToPpmCommand -f 1 -singlefile -r 150 -png $m2Pdf $m2Prefix | Out-Null
        if ($LASTEXITCODE -ne 0 -or !(Test-Path -LiteralPath "$m2Prefix.png")) { throw "M2 rasterization failed for $name" }
        $difference = Join-Path $differenceDirectory "$name-difference.png"
        $metricJson = & $PythonCommand (Join-Path $PSScriptRoot 'm2VisualCompare.py') "$legacyPrefix.png" "$m2Prefix.png" $difference
        if ($LASTEXITCODE -ne 0) { throw "Visual metric failed for $name" }
        $metric = $metricJson | ConvertFrom-Json
        $visualRows.Add([pscustomobject]@{
            case=$name; normalized_mae=$metric.normalized_mae; changed_fraction=$metric.changed_fraction
            legacy_size="$($metric.legacy_width)x$($metric.legacy_height)"
            m2_size="$($metric.m2_width)x$($metric.m2_height)"; status='INFORMATIONAL'; difference=$difference
        })
    }
}
$visualRows | Export-Csv -Delimiter "`t" -NoTypeInformation -LiteralPath (Join-Path $OutputDirectory 'visual-results.tsv')
$compileRows | Format-Table pipeline,case,status,seconds -AutoSize
Write-Host "M2 compile failures: $compileFailures; visual comparisons: $($visualRows.Count) (informational)"
exit ([int]($compileFailures -gt 0))
