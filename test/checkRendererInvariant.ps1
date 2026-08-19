[CmdletBinding()]
param(
    [string]$RendererDirectory = ''
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path $PSScriptRoot -Parent
if (!$RendererDirectory) {
    $RendererDirectory = Join-Path $repositoryRoot 'src\+m2t2\+render'
}

$forbidden = '(?i)(?<![\w.])(get|set|ishandle|gcf|gca|findobj|findall|allchild|ancestor)\s*\('
$violations = [System.Collections.Generic.List[string]]::new()

Get-ChildItem -LiteralPath $RendererDirectory -Filter '*.m' -File -Recurse | ForEach-Object {
    $path = $_.FullName
    $lineNumber = 0
    Get-Content -LiteralPath $path | ForEach-Object {
        $lineNumber++
        $code = ($_ -split '%', 2)[0]
        if ($code -match $forbidden) {
            $relative = [IO.Path]::GetRelativePath($repositoryRoot, $path)
            $violations.Add("${relative}:${lineNumber}: $($_.Trim())")
        }
    }
}

$imageRenderer = Join-Path $RendererDirectory 'renderImage.m'
if (Test-Path -LiteralPath $imageRenderer) {
    $imageSource = Get-Content -Raw -LiteralPath $imageRenderer
    foreach ($pattern in @('(?i)profile', '(?i)exportSet', '(?i)compileLuaLatex')) {
        if ($imageSource -match $pattern) {
            $violations.Add("src/+m2t2/+render/renderImage.m: forbidden layer dependency: $pattern")
        }
    }
}

if ($violations.Count -gt 0) {
    $violations | ForEach-Object { Write-Error $_ }
    throw 'Renderer invariant failed: runtime graphics access detected.'
}

Write-Host 'Renderer invariant: PASS (no forbidden runtime graphics access).'
