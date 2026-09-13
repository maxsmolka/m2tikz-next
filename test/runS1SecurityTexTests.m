function summary = runS1SecurityTexTests(outputDirectory)
%RUNS1SECURITYTEXTESTS Real compiler checks for paths and shell-escape policy.
    repository = fileparts(fileparts(mfilename('fullpath'))); addpath(fullfile(repository,'src'));
    if nargin < 1, outputDirectory = fullfile(repository,'.audit','s1-security-tex'); end
    if exist(outputDirectory,'dir') ~= 7, mkdir(outputDirectory); end
    root = tempname(outputDirectory); mkdir(root);
    f = figure('Visible','off'); cleanup = onCleanup(@() close(f));
    imagesc(axes('Parent',f), [1 2;3 4]);
    r = m2t.export(f, fullfile(root,'heat map_test.v1'), 'ImageBackend','hybrid');
    assert(r.success && exist(r.pdfPath,'file') == 2);
    r = m2t.export(f, fullfile(root,'heat map_test.v1'), 'ImageBackend','hybrid','Overwrite',true);
    assert(r.success);
    tex = fullfile(root,'shell-policy.tex'); pdf = fullfile(root,'shell-policy.pdf');
    m2t.internal.writeTextFile(tex, sprintf(['\\documentclass{article}\n\\begin{document}\n' ...
        '\\directlua{assert(status.shell_escape == 0)}\nShell escape disabled.\n\\end{document}\n']));
    result = m2t.internal.compileLuaLatex(tex,pdf); assert(result.success);
    summary = struct('tests',3,'failures',0,'outputDirectory',root);
    m2t.internal.writeTextFile(fullfile(root,'security-tex-results.tsv'), sprintf( ...
        'case\tstatus\nspaces_dots_underscore\tPASS\nowned_overwrite\tPASS\nshell_escape_disabled\tPASS\n'));
    clear cleanup;
end
