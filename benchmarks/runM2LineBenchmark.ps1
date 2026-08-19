[CmdletBinding()]
param(
    [string]$OctaveCommand = 'octave-cli',
    [string]$LatexmkCommand = 'latexmk',
    [string]$OutputDirectory = ''
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
if (!$OutputDirectory) { $OutputDirectory = Join-Path $PSScriptRoot 'output\m2-line' }
$logs = Join-Path $OutputDirectory 'logs'
$cache = Join-Path $OutputDirectory 'texmf-cache'
New-Item -ItemType Directory -Force $OutputDirectory,$logs,$cache | Out-Null
$env:TEXMFVAR = $cache
$env:TEXMFCACHE = $cache

function Invoke-Captured([string]$Command, [string[]]$Arguments, [string]$Log) {
    $oldPreference = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    try {
        & $Command @Arguments 2>&1 | Set-Content -LiteralPath $Log -Encoding utf8
        return $LASTEXITCODE
    } finally { $ErrorActionPreference = $oldPreference }
}

$benchLiteral = $PSScriptRoot.Replace('\','/').Replace("'","''")
$outputLiteral = $OutputDirectory.Replace('\','/').Replace("'","''")
$exportExit = Invoke-Captured $OctaveCommand @('--quiet','--eval',"addpath('$benchLiteral'); benchmarkM2LinePrototype('$outputLiteral');") (Join-Path $logs 'export.log')
if ($exportExit -ne 0) { Write-Host 'M2 benchmark export failed.'; exit 1 }

$compileRows = [System.Collections.Generic.List[object]]::new()
$failures = 0
foreach ($pipeline in @('legacy','m2')) {
    foreach ($count in @(100,10000,100000)) {
        $tex = Join-Path $OutputDirectory "$pipeline\line-$count.tex"
        $pdfDirectory = Join-Path $OutputDirectory "pdf\$pipeline\$count"
        New-Item -ItemType Directory -Force $pdfDirectory | Out-Null
        $log = Join-Path $logs "$pipeline-$count-lualatex.log"
        $timer = [System.Diagnostics.Stopwatch]::StartNew()
        $exitCode = Invoke-Captured $LatexmkCommand @('-lualatex','-cd','-gg','-interaction=nonstopmode','-halt-on-error','-file-line-error',"-outdir=$pdfDirectory",$tex) $log
        $timer.Stop()
        if ($exitCode -eq 0) { $status = 'PASS' } else { $status = 'FAIL'; $failures++ }
        $compileRows.Add([pscustomobject]@{pipeline=$pipeline;points=$count;seconds=[math]::Round($timer.Elapsed.TotalSeconds,6);status=$status;exit_code=$exitCode;log=$log})
    }
}
$compileRows | Export-Csv -Delimiter "`t" -NoTypeInformation -LiteralPath (Join-Path $OutputDirectory 'compile-performance.tsv')
$exports = Import-Csv -Delimiter "`t" -LiteralPath (Join-Path $OutputDirectory 'export-performance.tsv')
$combined = foreach ($row in $exports) {
    $legacyCompile = $compileRows | Where-Object { $_.pipeline -eq 'legacy' -and $_.points -eq [int]$row.points }
    $m2Compile = $compileRows | Where-Object { $_.pipeline -eq 'm2' -and $_.points -eq [int]$row.points }
    [pscustomobject]@{
        points=$row.points; legacy_export_s=$row.legacy_export_s; m2_reader_s=$row.m2_reader_s
        m2_renderer_s=$row.m2_renderer_s; m2_total_s=$row.m2_total_s
        legacy_tex_bytes=$row.legacy_tex_bytes; m2_tex_bytes=$row.m2_tex_bytes
        legacy_lualatex_s=$legacyCompile.seconds; m2_lualatex_s=$m2Compile.seconds
        legacy_compile=$legacyCompile.status; m2_compile=$m2Compile.status; policy=$row.policy
    }
}
$combined | Export-Csv -Delimiter "`t" -NoTypeInformation -LiteralPath (Join-Path $OutputDirectory 'performance-results.tsv')
$combined | Format-Table -AutoSize
exit ([int]($failures -gt 0))
