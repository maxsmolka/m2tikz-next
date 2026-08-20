[CmdletBinding()]
param(
    [string]$OctaveCommand = 'octave-cli',
    [string]$LatexmkCommand = 'latexmk',
    [string]$PythonCommand = 'python',
    [string]$GitCommand = 'git',
    [string]$OutputDirectory = '',
    [switch]$SkipCoreTests,
    [switch]$SkipTexCompilation,
    [switch]$SkipRichExample
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path $PSScriptRoot -Parent
if (!$OutputDirectory) {
    $OutputDirectory = Join-Path $repositoryRoot '.audit\public-preview'
}
$OutputDirectory = [IO.Path]::GetFullPath($OutputDirectory)
$logDirectory = Join-Path $OutputDirectory 'logs'
$texCache = Join-Path $OutputDirectory 'texmf-cache'
New-Item -ItemType Directory -Force $OutputDirectory,$logDirectory,$texCache | Out-Null
$env:TEXMFVAR = $texCache
$env:TEXMFCACHE = $texCache

function Require-Command([string]$Command) {
    if (!(Get-Command $Command -ErrorAction SilentlyContinue)) {
        throw "Required command was not found on PATH: $Command"
    }
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

function Write-TexFailureDiagnostics(
    [string]$TexFile,
    [string]$LatexmkLog,
    [string]$EngineLog
) {
    Write-Host "Failing TeX file: $TexFile"
    $allLines = [System.Collections.Generic.List[string]]::new()
    foreach ($log in @($LatexmkLog,$EngineLog)) {
        if (!(Test-Path -LiteralPath $log)) {
            Write-Warning "TeX failure log was not found: $log"
            continue
        }

        $content = @(Get-Content -LiteralPath $log)
        foreach ($line in $content) { $allLines.Add([string]$line) }
        Write-Host "TeX log tail: $log"
        $content | Select-Object -Last 200 | ForEach-Object { Write-Host $_ }
    }

    $firstError = $allLines | Where-Object { $_ -match '^\s*!' } | Select-Object -First 1
    if ($firstError) { Write-Host "First TeX error: $firstError" }

    $specificErrors = $allLines | Where-Object {
        $_ -match '(?i)(File .+\.(?:sty|cls|def|tex).+not found|font.+(?:not found|cannot be found)|Undefined control sequence|Package .+ Error|LaTeX Error: File)'
    } | Select-Object -Unique
    $specificErrors | ForEach-Object { Write-Host "TeX dependency/command error: $_" }
}

function Octave-Literal([string]$Value) {
    return $Value.Replace('\', '/').Replace("'", "''")
}

Require-Command $OctaveCommand
Require-Command $PythonCommand
Require-Command $GitCommand
if (!$SkipTexCompilation) { Require-Command $LatexmkCommand }

Write-Host "Repository: $repositoryRoot"
Write-Host "Output:     $OutputDirectory"
& $OctaveCommand --version | Select-Object -First 1
if (!$SkipTexCompilation) { & $LatexmkCommand -version | Select-Object -First 2 }
& $PythonCommand --version

$testLiteral = Octave-Literal $PSScriptRoot
$outputLiteral = Octave-Literal $OutputDirectory

if (!$SkipCoreTests) {
    $coreExpression = @"
addpath('$testLiteral');
runM2ReaderTests(fullfile('$outputLiteral','core','m2-reader'));
runM2RendererTests(fullfile('$outputLiteral','core','m2-renderer'));
runM21ReaderTests(fullfile('$outputLiteral','core','m21-reader'));
runM21RendererTests(fullfile('$outputLiteral','core','m21-renderer'));
runM22ReaderTests(fullfile('$outputLiteral','core','m22-reader'));
runM22RendererTests(fullfile('$outputLiteral','core','m22-renderer'));
runM23ReaderTests(fullfile('$outputLiteral','core','m23-reader'));
runM23RendererTests(fullfile('$outputLiteral','core','m23-renderer'));
runM61RichScatterTests(fullfile('$outputLiteral','core','m61-rich-scatter'));
generateM2LineFixtures(fullfile('$outputLiteral','fixtures','m2'));
generateM21Fixtures(fullfile('$outputLiteral','fixtures','m21'));
generateM22LayoutFixtures(fullfile('$outputLiteral','fixtures','m22'));
generateM23ColorbarFixtures(fullfile('$outputLiteral','fixtures','m23'));
"@
    $coreLog = Join-Path $logDirectory 'octave-core.log'
    $coreExit = Invoke-Captured $OctaveCommand @('--quiet','--eval',$coreExpression) $coreLog
    if ($coreExit -ne 0) {
        Get-Content -LiteralPath $coreLog
        throw 'Core M2 through M2.3 validation failed.'
    }
}

$exampleRoot = Join-Path $repositoryRoot 'examples'
$exampleOutput = Join-Path $OutputDirectory 'examples'
New-Item -ItemType Directory -Force $exampleOutput | Out-Null
$examplePaths = @(
    @('01-line','example_line','01-line.tex'),
    @('02-scatter','example_scatter','02-scatter.tex'),
    @('03-errorbar','example_errorbar','03-errorbar.tex'),
    @('04-multiple-axes','example_multiple_axes','04-multiple-axes.tex'),
    @('05-colorbar','example_colorbar','05-colorbar.tex')
)
if (!$SkipRichExample) {
    $examplePaths += ,@('11-rich-scatter','example_rich_scatter','11-rich-scatter.tex')
}
$exampleAdds = ($examplePaths | ForEach-Object {
    "addpath('$(Octave-Literal (Join-Path $exampleRoot $_[0]))');"
}) -join ''
$exampleCalls = ($examplePaths | ForEach-Object {
    "$($_[1])('$(Octave-Literal (Join-Path $exampleOutput $_[2]))');"
}) -join ''
$legacyPath = Join-Path $exampleOutput 'legacy-smoke.tex'
$sourceLiteral = Octave-Literal (Join-Path $repositoryRoot 'src')
$exampleExpression = "addpath('$sourceLiteral');$exampleAdds$exampleCalls" + `
    "f=figure('Visible','off');plot(0:3,[0 1 4 9]);" + `
    "matlab2tikz('$(Octave-Literal $legacyPath)','figurehandle',f,'standalone',true,'showInfo',false,'externalData',false);close(f);"
$exampleLog = Join-Path $logDirectory 'octave-examples.log'
$exampleExit = Invoke-Captured $OctaveCommand @('--quiet','--eval',$exampleExpression) $exampleLog
if ($exampleExit -ne 0) {
    Get-Content -LiteralPath $exampleLog
    throw 'Example generation or legacy smoke export failed.'
}

if (!$SkipTexCompilation) {
    $texFiles = @($examplePaths | ForEach-Object { Join-Path $exampleOutput $_[2] }) + $legacyPath
    foreach ($texFile in $texFiles) {
        if (!(Test-Path -LiteralPath $texFile)) { throw "Expected TeX output missing: $texFile" }
        $name = [IO.Path]::GetFileNameWithoutExtension($texFile)
        $pdfDirectory = Join-Path $OutputDirectory "pdf\$name"
        New-Item -ItemType Directory -Force $pdfDirectory | Out-Null
        $latexmkLog = Join-Path $logDirectory "$name-lualatex.log"
        $exit = Invoke-Captured $LatexmkCommand @(
            '-cd','-lualatex','-gg','-interaction=nonstopmode','-halt-on-error',
            '-file-line-error',"-outdir=$pdfDirectory",$texFile
        ) $latexmkLog
        if ($exit -ne 0) {
            Write-TexFailureDiagnostics $texFile $latexmkLog (Join-Path $pdfDirectory "$name.log")
            throw "LuaLaTeX compilation failed: $texFile"
        }
    }
}

& (Join-Path $PSScriptRoot 'checkRendererInvariant.ps1')
if ($LASTEXITCODE -ne 0) { throw 'Renderer invariant check failed.' }

& (Join-Path $PSScriptRoot 'checkProfileInvariant.ps1')
if ($LASTEXITCODE -ne 0) { throw 'Profile invariant check failed.' }

& (Join-Path $PSScriptRoot 'checkFigureSetInvariant.ps1')
if ($LASTEXITCODE -ne 0) { throw 'Figure-set invariant check failed.' }

& (Join-Path $PSScriptRoot 'checkDocumentationLinks.ps1')
if ($LASTEXITCODE -ne 0) { throw 'Documentation link check failed.' }

& $PythonCommand (Join-Path $PSScriptRoot 'validateCitation.py') `
    (Join-Path $repositoryRoot 'CITATION.cff')
if ($LASTEXITCODE -ne 0) { throw 'CITATION.cff validation failed.' }

$excludedRoots = @(
    [IO.Path]::GetFullPath((Join-Path $repositoryRoot '.git')),
    [IO.Path]::GetFullPath((Join-Path $repositoryRoot '.audit'))
)
$textExtensions = @('.cff','.m','.md','.ps1','.py','.txt','.yml','.yaml')
$publicationFiles = Get-ChildItem -LiteralPath $repositoryRoot -File -Recurse | Where-Object {
    $fullName = $_.FullName
    $outsideExcludedRoots = !($excludedRoots | Where-Object { $fullName.StartsWith($_ + [IO.Path]::DirectorySeparatorChar) })
    $outsideExcludedRoots -and $textExtensions -contains $_.Extension.ToLowerInvariant()
}

$localPath = 'C:' + '\Users' + '\max'
$privateUrl = '(?i)https?://(?:localhost|127\.0\.0\.1|[^/\s]+\.(?:internal|local))(?:[/:]|$)'
$secretPatterns = @(
    'gh[pousr]_[A-Za-z0-9_]{20,}',
    'github_pat_[A-Za-z0-9_]{20,}',
    'AKIA[0-9A-Z]{16}',
    'xox[baprs]-[A-Za-z0-9-]{10,}',
    ('-----BEGIN ' + '(?:RSA |EC |OPENSSH )?' + 'PRIVATE KEY-----')
)
$scanViolations = [System.Collections.Generic.List[string]]::new()
foreach ($file in $publicationFiles) {
    $content = Get-Content -Raw -LiteralPath $file.FullName
    if ($content.Contains($localPath)) { $scanViolations.Add("local path: $($file.FullName)") }
    if ($content -match $privateUrl) { $scanViolations.Add("private URL: $($file.FullName)") }
    foreach ($pattern in $secretPatterns) {
        if ($content -match $pattern) { $scanViolations.Add("secret pattern: $($file.FullName)"); break }
    }
}
if ($scanViolations.Count -gt 0) {
    $scanViolations | ForEach-Object { Write-Error $_ }
    throw 'Current-tree publication scan failed.'
}

if (Test-Path -LiteralPath (Join-Path $repositoryRoot '.git')) {
    & $GitCommand -C $repositoryRoot diff --check
    if ($LASTEXITCODE -ne 0) { throw 'git diff --check failed.' }
}

Write-Host 'Public preview validation: PASS'
Write-Host "Core tests skipped: $([bool]$SkipCoreTests)"
Write-Host "TeX compilation skipped: $([bool]$SkipTexCompilation)"
