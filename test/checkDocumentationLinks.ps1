[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path $PSScriptRoot -Parent
$documents = @(
    'README.md','NOTICE.md','CONTRIBUTING.md','SECURITY.md',
    'docs/INSTALLATION.md','docs/SUPPORT.md'
)
$missing = [System.Collections.Generic.List[string]]::new()

foreach ($relativeDocument in $documents) {
    $document = Join-Path $repositoryRoot $relativeDocument
    $content = Get-Content -Raw -LiteralPath $document
    foreach ($match in [regex]::Matches($content, '\[[^\]]+\]\(([^)]+)\)')) {
        $target = $match.Groups[1].Value.Trim('<','>')
        if ($target -match '^(?:https?://|mailto:|#)') { continue }
        $pathPart = ($target -split '#', 2)[0]
        $resolved = Join-Path (Split-Path $document -Parent) $pathPart
        if (!(Test-Path -LiteralPath $resolved)) {
            $missing.Add("${relativeDocument}: $target")
        }
    }
}

if ($missing.Count -gt 0) {
    $missing | ForEach-Object { Write-Error $_ }
    throw 'Documentation link check failed.'
}
Write-Host 'Documentation links: PASS'
