[CmdletBinding()]
param(
    [string]$OctaveCommand='octave-cli',
    [string]$LatexmkCommand='latexmk',
    [int]$PointsPerAxes=1000,
    [string]$OutputDirectory=''
)
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
if(!$OutputDirectory){$OutputDirectory=Join-Path $repo 'benchmarks\output\m2.2-layout'}
$logs=Join-Path $OutputDirectory 'logs';$pdf=Join-Path $OutputDirectory 'pdf';$cache=Join-Path $OutputDirectory 'texmf-cache'
New-Item -ItemType Directory -Force $OutputDirectory,$logs,$pdf,$cache|Out-Null
$env:TEXMFVAR=$cache;$env:TEXMFCACHE=$cache
function Literal([string]$Value){$Value.Replace('\','/').Replace("'","''")}
$bench=Literal $PSScriptRoot;$out=Literal $OutputDirectory
& $OctaveCommand --quiet --eval "addpath('$bench');benchmarkM22Layout('$out',$PointsPerAxes);"
if($LASTEXITCODE -ne 0){throw 'M2.2 layout benchmark failed in Octave.'}
$raw=Import-Csv -Delimiter "`t" (Join-Path $OutputDirectory 'layout-performance-raw.tsv')
$rows=foreach($item in $raw){
    $target=Join-Path $pdf ("axes-"+$item.axes);New-Item -ItemType Directory -Force $target|Out-Null
    $log=Join-Path $logs ("axes-"+$item.axes+'-lualatex.log');$timer=[Diagnostics.Stopwatch]::StartNew()
    $old=$ErrorActionPreference;$ErrorActionPreference='Continue'
    try{& $LatexmkCommand -lualatex -gg -interaction=nonstopmode -halt-on-error -file-line-error "-outdir=$target" $item.tex_path 2>&1|Set-Content -LiteralPath $log -Encoding utf8;$exit=$LASTEXITCODE}
    finally{$ErrorActionPreference=$old}
    $timer.Stop();if($exit -ne 0){throw "LuaLaTeX benchmark compile failed for $($item.axes) axes."}
    [pscustomobject]@{axes=$item.axes;total_points=$item.total_points;reader_s=$item.reader_s;renderer_s=$item.renderer_s;total_s=$item.total_s;tex_bytes=$item.tex_bytes;lualatex_s=[math]::Round($timer.Elapsed.TotalSeconds,6);compile='PASS';policy='no-reduction'}
}
$rows|Export-Csv -Delimiter "`t" -NoTypeInformation -LiteralPath (Join-Path $OutputDirectory 'layout-performance.tsv')
$rows|Format-Table -AutoSize
