[CmdletBinding()]
param(
    [string]$OctaveCommand = 'octave-cli',
    [string]$LatexmkCommand = 'latexmk',
    [string]$OutputDirectory = ''
)

$ErrorActionPreference = 'Stop'
if (!$OutputDirectory) {
    $OutputDirectory = Join-Path $PSScriptRoot 'output\m1a-tex'
}
$repo = Split-Path $PSScriptRoot -Parent
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$logDirectory = Join-Path $OutputDirectory 'logs'
New-Item -ItemType Directory -Force -Path $logDirectory | Out-Null
$texCache = Join-Path $OutputDirectory 'texmf-cache'
New-Item -ItemType Directory -Force -Path $texCache | Out-Null
# LuaTeX needs a writable font cache even in restricted/CI environments.
$env:TEXMFVAR = $texCache
$env:TEXMFCACHE = $texCache

function Convert-ToOctaveLiteral([string]$Value) {
    return ($Value.Replace('\', '/').Replace("'", "''"))
}

function Invoke-Captured([string]$Command, [string[]]$Arguments, [string]$Log) {
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        & $Command @Arguments 2>&1 | Set-Content -LiteralPath $Log -Encoding utf8
        return $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousPreference
    }
}

$testPath = Convert-ToOctaveLiteral $PSScriptRoot
$outputPath = Convert-ToOctaveLiteral $OutputDirectory
$exportLog = Join-Path $logDirectory 'export.log'
$exportExit = Invoke-Captured $OctaveCommand @('--no-gui', '--quiet', '--eval', "addpath('$testPath'); generateM1ATexFixtures('$outputPath');") $exportLog
$exportResults = Join-Path $OutputDirectory 'export-results.tsv'
if ($exportExit -ne 0 -or !(Test-Path -LiteralPath $exportResults)) {
    Write-Host 'EXPORT FAILURE: fixture generator did not complete.'
    exit 1
}

$rows = Import-Csv -Delimiter "`t" -LiteralPath $exportResults
$engines = @(
    @{ Name = 'pdflatex'; Arguments = @('-pdf') },
    @{ Name = 'lualatex'; Arguments = @('-lualatex') }
)
$summary = [System.Collections.Generic.List[object]]::new()
$unexpected = 0

foreach ($row in $rows) {
    if ($row.status -ne 'PASS') {
        $summary.Add([pscustomobject]@{ Case=$row.case; Engine='export'; Classification='EXPORT FAILURE'; ExitCode=1; Log=$exportLog })
        $unexpected++
        continue
    }
    foreach ($engine in $engines) {
        $texFile = Join-Path $OutputDirectory ($row.case + '.tex')
        $engineOut = Join-Path $OutputDirectory $engine.Name
        New-Item -ItemType Directory -Force -Path $engineOut | Out-Null
        $log = Join-Path $logDirectory ($row.case + '-' + $engine.Name + '.log')
        $arguments = @($engine.Arguments) + @('-cd', '-gg', '-interaction=nonstopmode', '-halt-on-error', '-file-line-error', "-outdir=$engineOut", $texFile)
        $exitCode = Invoke-Captured $LatexmkCommand $arguments $log
        if ($exitCode -eq 0) {
            $classification = 'PASS'
        } elseif ($row.case -eq 'unicode' -and $engine.Name -eq 'pdflatex') {
            $classification = 'EXPECTED ENGINE LIMITATION'
        } else {
            $classification = 'TEX COMPILATION FAILURE'
            $unexpected++
        }
        $summary.Add([pscustomobject]@{ Case=$row.case; Engine=$engine.Name; Classification=$classification; ExitCode=$exitCode; Log=$log })
    }
}

$summaryPath = Join-Path $OutputDirectory 'compile-results.tsv'
$summary | Export-Csv -Delimiter "`t" -NoTypeInformation -LiteralPath $summaryPath
$summary | Format-Table -AutoSize
Write-Host "Compile matrix: $($summary.Count) entries, unexpected failures: $unexpected"
exit ([int]($unexpected -gt 0))
