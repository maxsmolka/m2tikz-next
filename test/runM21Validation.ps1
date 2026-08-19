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
if(!$OutputDirectory){$OutputDirectory=Join-Path $repo '.audit\m2.1'}
$OutputDirectory=[IO.Path]::GetFullPath($OutputDirectory)
$foundation=Join-Path $OutputDirectory 'foundation-validation'
$line=Join-Path $OutputDirectory 'line-validation'
$logs=Join-Path $foundation 'logs'; $cache=Join-Path $foundation 'texmf-cache'
New-Item -ItemType Directory -Force $foundation,$logs,$cache | Out-Null
$env:TEXMFVAR=$cache; $env:TEXMFCACHE=$cache

function Invoke-Captured([string]$Command,[string[]]$Arguments,[string]$Log){
    $old=$ErrorActionPreference;$ErrorActionPreference='Continue'
    try{& $Command @Arguments 2>&1|Set-Content -LiteralPath $Log -Encoding utf8;return $LASTEXITCODE}
    finally{$ErrorActionPreference=$old}
}
function Octave-Literal([string]$Value){$Value.Replace('\','/').Replace("'","''")}
function Parse-Metric([string]$Value){
    [double]::Parse($Value.Replace(',','.'),[Globalization.CultureInfo]::InvariantCulture)
}

& (Join-Path $PSScriptRoot 'runM2LinePrototypeValidation.ps1') -OctaveCommand $OctaveCommand `
  -LatexmkCommand $LatexmkCommand -PdfToPpmCommand $PdfToPpmCommand `
  -PythonCommand $PythonCommand -OutputDirectory $line
if($LASTEXITCODE -ne 0){throw 'M2 line validation failed under the M2.1 implementation.'}

$test=Octave-Literal $PSScriptRoot; $out=Octave-Literal $foundation
$expression="addpath('$test'); runM21ReaderTests('$out'); runM21RendererTests('$out'); generateM21Fixtures('$out');"
$octaveExit=Invoke-Captured $OctaveCommand @('--quiet','--eval',$expression) (Join-Path $logs 'octave-validation.log')
if($octaveExit -ne 0){throw 'M2.1 Octave validation failed.'}

$names=@('manual_x_ticks','manual_y_ticks','reverse_x','reverse_y','box_on','box_off', `
         'plain_text','tex_text','latex_text','legend_on','legend_off','scatter', `
         'errorbar_symmetric','errorbar_asymmetric','mixed_line_scatter','mixed_line_errorbar')
$compileRows=[System.Collections.Generic.List[object]]::new();$failures=0
foreach($pipeline in @('legacy','m21')){
    foreach($name in $names){
        $tex=Join-Path $foundation "tex\$pipeline\$name.tex"
        $pdfDir=Join-Path $foundation "pdf\$pipeline\$name";New-Item -ItemType Directory -Force $pdfDir|Out-Null
        $log=Join-Path $logs "$pipeline-$name-lualatex.log"
        $timer=[Diagnostics.Stopwatch]::StartNew()
        $exit=Invoke-Captured $LatexmkCommand @('-lualatex','-gg','-interaction=nonstopmode','-halt-on-error','-file-line-error',"-outdir=$pdfDir",$tex) $log
        $timer.Stop();if($exit -eq 0){$status='PASS'}else{$status='FAIL';$failures++}
        $compileRows.Add([pscustomobject]@{pipeline=$pipeline;case=$name;status=$status;exit_code=$exit;seconds=[math]::Round($timer.Elapsed.TotalSeconds,6);log=$log})
    }
}
$compileRows|Export-Csv -Delimiter "`t" -NoTypeInformation -LiteralPath (Join-Path $foundation 'compile-results.tsv')

$visualRows=[System.Collections.Generic.List[object]]::new()
if($failures -eq 0){
    $raster=Join-Path $foundation 'raster';$diff=Join-Path $foundation 'visual-diff'
    New-Item -ItemType Directory -Force $raster,$diff|Out-Null
    foreach($name in $names){
        $legacyPdf=Join-Path $foundation "pdf\legacy\$name\$name.pdf"
        $m21Pdf=Join-Path $foundation "pdf\m21\$name\$name.pdf"
        $legacyPrefix=Join-Path $raster "$name-legacy";$m21Prefix=Join-Path $raster "$name-m21"
        & $PdfToPpmCommand -f 1 -singlefile -r 150 -png $legacyPdf $legacyPrefix|Out-Null
        & $PdfToPpmCommand -f 1 -singlefile -r 150 -png $m21Pdf $m21Prefix|Out-Null
        if($LASTEXITCODE -ne 0){throw "Rasterization failed for $name"}
        $difference=Join-Path $diff "$name-difference.png"
        $json=& $PythonCommand (Join-Path $PSScriptRoot 'm2VisualCompare.py') "$legacyPrefix.png" "$m21Prefix.png" $difference
        if($LASTEXITCODE -ne 0){throw "Visual metric failed for $name"};$metric=$json|ConvertFrom-Json
        $visualRows.Add([pscustomobject]@{case=$name;normalized_mae=$metric.normalized_mae;changed_fraction=$metric.changed_fraction;legacy_size="$($metric.legacy_width)x$($metric.legacy_height)";m21_size="$($metric.m2_width)x$($metric.m2_height)";status='INFORMATIONAL';difference=$difference})
    }
}
$visualRows|Export-Csv -Delimiter "`t" -NoTypeInformation -LiteralPath (Join-Path $foundation 'visual-results.tsv')

$beforePath=Join-Path $repo '.audit\m2\visual-results.tsv';$afterPath=Join-Path $line 'visual-results.tsv'
if((Test-Path $beforePath)-and(Test-Path $afterPath)){
    $before=Import-Csv -Delimiter "`t" $beforePath;$after=Import-Csv -Delimiter "`t" $afterPath
    $comparison=foreach($old in $before){
        $new=$after|Where-Object case -eq $old.case
        [pscustomobject]@{case=$old.case;mae_before=$old.normalized_mae;mae_after=$new.normalized_mae;mae_delta=((Parse-Metric $new.normalized_mae)-(Parse-Metric $old.normalized_mae));changed_before=$old.changed_fraction;changed_after=$new.changed_fraction;changed_delta=((Parse-Metric $new.changed_fraction)-(Parse-Metric $old.changed_fraction))}
    }
    $comparison|Export-Csv -Delimiter "`t" -NoTypeInformation -LiteralPath (Join-Path $OutputDirectory 'line-visual-before-after.tsv')
}
$compileRows|Format-Table pipeline,case,status,seconds -AutoSize
Write-Host "M2.1 compile failures: $failures; visual pairs: $($visualRows.Count)"
exit ([int]($failures -gt 0))
