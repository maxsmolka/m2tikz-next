[CmdletBinding()]
param([string]$MatlabCommand = 'matlab')

$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT') { throw 'This native evidence runner requires Windows.' }
$repository = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$root = Join-Path $repository ('.audit/s1-windows-paths/' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $root -Force | Out-Null
$target = Join-Path $root 'target'
$missingTarget = Join-Path $root 'missing-target'
$ownedLink = Join-Path $root 'owned-assets'
$danglingLink = Join-Path $root 'dangling-assets'
$links = @($ownedLink, $danglingLink)
try {
    New-Item -ItemType Directory -Path $target, $missingTarget | Out-Null
    New-Item -ItemType Junction -Path $ownedLink -Target $target | Out-Null
    New-Item -ItemType Junction -Path $danglingLink -Target $missingTarget | Out-Null
    # Remove only this newly created empty fixture target, not its junction.
    Remove-Item -LiteralPath $missingTarget
    [IO.File]::WriteAllText((Join-Path $target 'sentinel.txt'), 'preserve')
    $matlabRoot = $root.Replace("'", "''")
    $source = (Join-Path $repository 'src').Replace("'", "''")
    $batch = @"
addpath('$source'); root='$matlabRoot'; for name={'owned','dangling'}, p=m2t.internal.normalizeOutputBase(fullfile(root,name{1})); caught=false; try, m2t.internal.checkOutputProducts(p,true); catch err, caught=strcmp(err.identifier,'M2T:E006:UnsafeOutputProduct'); end; assert(caught,'Junction product must be rejected'); end; p=m2t.internal.normalizeOutputBase(fullfile(root,'owned-assets','explicit')); m2t.internal.checkOutputProducts(p,false); assert(strcmp(fileread(fullfile(root,'target','sentinel.txt')),'preserve')); disp('S1_WINDOWS_PATHS_PASS: 3/3');
"@
    & $MatlabCommand -batch $batch
    if ($LASTEXITCODE -ne 0) { throw 'Native Windows path checks failed.' }
    [IO.File]::WriteAllText((Join-Path $root 'results.tsv'), "case`tstatus`nowned_junction`tPASS`ndangling_junction`tPASS`nlinked_explicit_parent`tPASS`n")
} finally {
    foreach ($link in $links) {
        # Delete only the exact generated link itself, never recurse into it.
        $item = Get-Item -LiteralPath $link -Force -ErrorAction SilentlyContinue
        if ($item -and $item.LinkType -eq 'Junction' -and
            [IO.Path]::GetFullPath($link).StartsWith($root + [IO.Path]::DirectorySeparatorChar)) {
            Remove-Item -LiteralPath $link -Force
        }
    }
}
