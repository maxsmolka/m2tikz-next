[CmdletBinding()]
param(
    [string]$OctaveCommand='octave-cli',
    [string]$LatexmkCommand='latexmk',
    [string]$PdfToPpmCommand='pdftoppm',
    [string]$PythonCommand='python',
    [string]$OutputDirectory=''
)
$ErrorActionPreference='Stop';$repo=Split-Path $PSScriptRoot -Parent
if(!$OutputDirectory){$OutputDirectory=Join-Path $repo '.audit\m2.3\validation'}
$OutputDirectory=[IO.Path]::GetFullPath($OutputDirectory);$logs=Join-Path $OutputDirectory 'logs';$cache=Join-Path $OutputDirectory 'texmf'
New-Item -ItemType Directory -Force $OutputDirectory,$logs,$cache|Out-Null;$env:TEXMFVAR=$cache;$env:TEXMFCACHE=$cache
function Capture([string]$Command,[string[]]$Arguments,[string]$Log){$old=$ErrorActionPreference;$ErrorActionPreference='Continue';try{&$Command @Arguments 2>&1|Set-Content -LiteralPath $Log -Encoding utf8;return $LASTEXITCODE}finally{$ErrorActionPreference=$old}}
function OctaveLiteral([string]$Value){$Value.Replace('\','/').Replace("'","''")}
$test=OctaveLiteral $PSScriptRoot;$out=OctaveLiteral $OutputDirectory
$expr="addpath('$test');runM23ReaderTests('$out');runM23RendererTests('$out');generateM23ColorbarFixtures('$out');"
if((Capture $OctaveCommand @('--quiet','--eval',$expr) (Join-Path $logs 'octave-validation.log'))-ne 0){throw 'M2.3 Octave validation failed.'}
$rows=[Collections.Generic.List[object]]::new();$failures=0
foreach($pipeline in @('legacy','m23')){Get-ChildItem -LiteralPath (Join-Path $OutputDirectory "tex\$pipeline") -Filter '*.tex'|ForEach-Object{$pdfDir=Join-Path $OutputDirectory "pdf\$pipeline\$($_.BaseName)";New-Item -ItemType Directory -Force $pdfDir|Out-Null;$exit=Capture $LatexmkCommand @('-cd','-lualatex','-gg','-interaction=nonstopmode','-halt-on-error','-file-line-error',"-outdir=$pdfDir",$_.FullName) (Join-Path $logs "$pipeline-$($_.BaseName).log");if($exit-ne 0){$failures++};$rows.Add([pscustomobject]@{pipeline=$pipeline;case=$_.BaseName;exit=$exit})}}
$rendererNames=@('single_colorbar','manual_colorbar','independent_colorbars','shared_colorbar','shared_legend','shared_xlabel','shared_ylabel','shared_title','json_compatibility')
foreach($name in $rendererNames){$tex=Join-Path $OutputDirectory "$name.tex";$pdfDir=Join-Path $OutputDirectory "pdf\renderer\$name";New-Item -ItemType Directory -Force $pdfDir|Out-Null;$exit=Capture $LatexmkCommand @('-lualatex','-gg','-interaction=nonstopmode','-halt-on-error','-file-line-error',"-outdir=$pdfDir",$tex) (Join-Path $logs "renderer-$name.log");if($exit-ne 0){$failures++};$rows.Add([pscustomobject]@{pipeline='renderer';case=$name;exit=$exit})}
$rows|Export-Csv -Delimiter "`t" -NoTypeInformation -LiteralPath (Join-Path $OutputDirectory 'compile-results.tsv')
$visual=[Collections.Generic.List[object]]::new();$raster=Join-Path $OutputDirectory 'raster';New-Item -ItemType Directory -Force $raster|Out-Null
foreach($name in @('default','westoutside','horizontal','manual','first_only','separate','overlap')){$legacy=Join-Path $OutputDirectory "pdf\legacy\$name\$name.pdf";$m23=Join-Path $OutputDirectory "pdf\m23\$name\$name.pdf";foreach($pair in @(@('legacy',$legacy),@('m23',$m23))){$prefix=Join-Path $raster "$name-$($pair[0])";&$PdfToPpmCommand -f 1 -singlefile -r 150 -png $pair[1] $prefix|Out-Null;if($LASTEXITCODE-ne 0){throw "Rasterization failed: $name"}};$metric=(&$PythonCommand (Join-Path $PSScriptRoot 'm23PdfGeometry.py') $legacy $m23)|ConvertFrom-Json;if(!$metric.all_rectangles_inside_page-or$metric.max_colorbar_axes_overlap_points2-gt 0.01){$failures++};$visual.Add([pscustomobject]@{case=$name;axes=$metric.axes;colorbars=$metric.colorbars;relative_delta=$metric.max_relative_geometry_delta;colorbar_axes_overlap=$metric.max_colorbar_axes_overlap_points2;inside_page=$metric.all_rectangles_inside_page})}
$visual|Export-Csv -Delimiter "`t" -NoTypeInformation -LiteralPath (Join-Path $OutputDirectory 'visual-geometry-results.tsv')
$rows|Format-Table -AutoSize;$visual|Format-Table -AutoSize;exit ([int]($failures-gt 0))
