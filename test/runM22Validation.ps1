[CmdletBinding()]
param(
    [string]$OctaveCommand='octave-cli',
    [string]$LatexmkCommand='latexmk',
    [string]$PdfToPpmCommand='pdftoppm',
    [string]$PythonCommand='python',
    [string]$OutputDirectory=''
)

$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
if(!$OutputDirectory){$OutputDirectory=Join-Path $repo '.audit\m2.2\layout-validation'}
$OutputDirectory=[IO.Path]::GetFullPath($OutputDirectory)
$logs=Join-Path $OutputDirectory 'logs';$cache=Join-Path $OutputDirectory 'texmf-cache'
New-Item -ItemType Directory -Force $OutputDirectory,$logs,$cache|Out-Null
$env:TEXMFVAR=$cache;$env:TEXMFCACHE=$cache

function Invoke-Captured([string]$Command,[string[]]$Arguments,[string]$Log){
    $old=$ErrorActionPreference;$ErrorActionPreference='Continue'
    try{& $Command @Arguments 2>&1|Set-Content -LiteralPath $Log -Encoding utf8;return $LASTEXITCODE}
    finally{$ErrorActionPreference=$old}
}
function Octave-Literal([string]$Value){$Value.Replace('\','/').Replace("'","''")}

$test=Octave-Literal $PSScriptRoot;$out=Octave-Literal $OutputDirectory
$expression="addpath('$test');runM22ReaderTests('$out');runM22RendererTests('$out');generateM22LayoutFixtures('$out');"
$octaveExit=Invoke-Captured $OctaveCommand @('--quiet','--eval',$expression) (Join-Path $logs 'octave-validation.log')
if($octaveExit -ne 0){throw 'M2.2 Octave validation failed.'}

$names=@('two_independent','subplot_2x1','subplot_1x2','subplot_2x2','manual_position', `
         'unequal_widths','unequal_heights','overlapping_axes','different_scales','mixed_series_axes')
$compileRows=[Collections.Generic.List[object]]::new();$failures=0
foreach($pipeline in @('legacy','m22')){
    foreach($name in $names){
        $tex=Join-Path $OutputDirectory "tex\$pipeline\$name.tex"
        $pdfDir=Join-Path $OutputDirectory "pdf\$pipeline\$name";New-Item -ItemType Directory -Force $pdfDir|Out-Null
        $log=Join-Path $logs "$pipeline-$name-lualatex.log";$timer=[Diagnostics.Stopwatch]::StartNew()
        $exit=Invoke-Captured $LatexmkCommand @('-lualatex','-gg','-interaction=nonstopmode','-halt-on-error','-file-line-error',"-outdir=$pdfDir",$tex) $log
        $timer.Stop();if($exit -eq 0){$status='PASS'}else{$status='FAIL';$failures++}
        $compileRows.Add([pscustomobject]@{pipeline=$pipeline;case=$name;status=$status;exit_code=$exit;seconds=[math]::Round($timer.Elapsed.TotalSeconds,6);log=$log})
    }
}
$compileRows|Export-Csv -Delimiter "`t" -NoTypeInformation -LiteralPath (Join-Path $OutputDirectory 'compile-results.tsv')

$visualRows=[Collections.Generic.List[object]]::new()
if($failures -eq 0){
    $raster=Join-Path $OutputDirectory 'raster';$diff=Join-Path $OutputDirectory 'visual-diff'
    New-Item -ItemType Directory -Force $raster,$diff|Out-Null
    foreach($name in $names){
        $legacyPdf=Join-Path $OutputDirectory "pdf\legacy\$name\$name.pdf"
        $m22Pdf=Join-Path $OutputDirectory "pdf\m22\$name\$name.pdf"
        $legacyPrefix=Join-Path $raster "$name-legacy";$m22Prefix=Join-Path $raster "$name-m22"
        & $PdfToPpmCommand -f 1 -singlefile -r 150 -png $legacyPdf $legacyPrefix|Out-Null
        & $PdfToPpmCommand -f 1 -singlefile -r 150 -png $m22Pdf $m22Prefix|Out-Null
        if($LASTEXITCODE -ne 0){throw "Rasterization failed for $name"}
        $difference=Join-Path $diff "$name-difference.png"
        $pixelJson=& $PythonCommand (Join-Path $PSScriptRoot 'm2VisualCompare.py') "$legacyPrefix.png" "$m22Prefix.png" $difference
        if($LASTEXITCODE -ne 0){throw "Pixel comparison failed for $name"};$pixel=$pixelJson|ConvertFrom-Json
        $expectedAxes=if($name -eq 'subplot_2x2'){4}elseif($name -eq 'manual_position'){1}else{2}
        $geometryJson=& $PythonCommand (Join-Path $PSScriptRoot 'm22PdfGeometry.py') $legacyPdf $m22Pdf $expectedAxes
        if($LASTEXITCODE -ne 0){throw "PDF geometry extraction failed for $name"};$geometry=$geometryJson|ConvertFrom-Json
        $visualRows.Add([pscustomobject]@{case=$name;normalized_mae=$pixel.normalized_mae;changed_fraction=$pixel.changed_fraction;axes=$expectedAxes;max_center_delta=$geometry.max_center_delta;max_width_delta=$geometry.max_width_delta;max_height_delta=$geometry.max_height_delta;mean_geometry_delta=$geometry.mean_geometry_delta;old_default_mean_geometry_delta=$geometry.old_default_mean_geometry_delta;legacy_boxes=(ConvertTo-Json -InputObject $geometry.legacy_boxes -Compress);m22_boxes=(ConvertTo-Json -InputObject $geometry.m22_boxes -Compress);difference=$difference})
    }
}
$visualRows|Export-Csv -Delimiter "`t" -NoTypeInformation -LiteralPath (Join-Path $OutputDirectory 'visual-geometry-results.tsv')
$compileRows|Format-Table pipeline,case,status,seconds -AutoSize
Write-Host "M2.2 compile failures: $failures; visual geometry pairs: $($visualRows.Count)"
exit ([int]($failures -gt 0))
