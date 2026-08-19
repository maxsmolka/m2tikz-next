function summary = runM3WorkflowTests(outputDirectory)
%RUNM3WORKFLOWTESTS Exercise the public analyze/export/compile workflow.
    repositoryRoot = fileparts(fileparts(mfilename('fullpath')));
    if nargin < 1
        outputDirectory = fullfile(repositoryRoot, '.audit', 'm3-workflow');
    end
    addpath(fullfile(repositoryRoot, 'src'));
    addpath(fullfile(repositoryRoot, 'test'));
    runRoot = fullfile(outputDirectory, 'workflow');
    resetDirectory(runRoot);

    cases = { ...
        'W1_successful_line_export', @() successfulLine(runRoot); ...
        'W2_scatter_export', @() scatterExport(runRoot); ...
        'W3_errorbar_export', @() errorbarExport(runRoot); ...
        'W4_multiple_axes_export', @() multipleAxesExport(runRoot); ...
        'W5_colorbar_export', @() colorbarExport(runRoot); ...
        'W6_unsupported_graphical_object', @() unsupportedObject(runRoot); ...
        'W7_missing_lualatex', @() missingCompiler(runRoot); ...
        'W8_invalid_output_path', @() invalidOutputPath(runRoot); ...
        'W9_existing_output_behavior', @() existingOutput(runRoot); ...
        'W10_deterministic_repeat', @() deterministicRepeat(runRoot)};
    rows = cell(size(cases, 1), 4);
    failures = 0;
    for k = 1:size(cases, 1)
        try
            detail = cases{k, 2}();
            status = 'PASS';
        catch err
            status = 'FAIL';
            detail = sprintf('%s: %s', identifierText(err.identifier), oneLine(err.message));
            failures = failures + 1;
        end
        rows(k, :) = {cases{k, 1}, status, detail, 'workflow'};
    end
    resultPath = fullfile(outputDirectory, 'workflow-results.tsv');
    writeRows(resultPath, rows);
    summary = struct('failures', failures, 'tests', size(rows, 1), ...
                     'resultPath', resultPath);
    if failures > 0
        fprintf(2, 'M3 workflow diagnostics from %s:\n%s', resultPath, fileread(resultPath));
        error('M2T:M3WorkflowTestsFailed', '%d M3 workflow tests failed.', failures);
    end
end

function detail = successfulLine(root)
    fig = figure('Visible', 'off'); cleanup = onCleanup(@() closeFigure(fig));
    plot(0:3, [0 1 4 9]);
    base = fullfile(root, 'path with spaces', 'line figure');
    result = m2t.export(fig, base);
    assertSuccess(result);
    assert(~isempty(strfind(result.texPath, 'path with spaces'))); %#ok<STREMP>
    detail = successDetail(result);
    clear cleanup;
end

function detail = scatterExport(root)
    fig = figure('Visible', 'off'); cleanup = onCleanup(@() closeFigure(fig));
    scatter(1:4, [2 1 4 3], 49, [0.8 0.1 0.2], 'o');
    relativeRoot = fullfile(root, 'relative-parent'); ensureDirectory(relativeRoot);
    oldDirectory = pwd; directoryCleanup = onCleanup(@() cd(oldDirectory)); cd(relativeRoot);
    result = m2t.export(fig, fullfile('relative output', 'scatter'));
    assertSuccess(result);
    assert(isAbsolute(result.texPath));
    detail = successDetail(result);
    clear directoryCleanup cleanup;
end

function detail = errorbarExport(root)
    fig = figure('Visible', 'off'); cleanup = onCleanup(@() closeFigure(fig));
    errorbar(1:4, [2 3 2 4], [0.2 0.3 0.1 0.4]);
    result = m2t.export(fig, fullfile(root, 'errorbar'));
    assertSuccess(result); detail = successDetail(result); clear cleanup;
end

function detail = multipleAxesExport(root)
    fig = figure('Visible', 'off'); cleanup = onCleanup(@() closeFigure(fig));
    first = subplot(1, 2, 1, 'Parent', fig); plot(first, 1:3, [1 2 1]);
    second = subplot(1, 2, 2, 'Parent', fig); plot(second, 1:3, [3 1 2]);
    result = m2t.export(fig, fullfile(root, 'multiple-axes'));
    assertSuccess(result); detail = successDetail(result); clear cleanup;
end

function detail = colorbarExport(root)
    fig = figure('Visible', 'off'); cleanup = onCleanup(@() closeFigure(fig));
    ax = axes('Parent', fig); imagesc(ax, [1 2; 3 4]); colorbar(ax);
    result = m2t.export(fig, fullfile(root, 'colorbar'));
    assertSuccess(result); detail = successDetail(result); clear cleanup;
end

function detail = unsupportedObject(root)
    fig = figure('Visible', 'off'); cleanup = onCleanup(@() closeFigure(fig));
    ax = axes('Parent', fig); plot(ax, 1:3, [1 2 3]);
    patch(ax, [1 2 1], [1 2 2], [0.5 0.5 0.5]);
    result = m2t.export(fig, fullfile(root, 'unsupported'));
    assert(~result.success && strcmp(result.status, 'unsupported'));
    assert(strcmp(result.capability, 'unsupported'));
    assertDiagnostic(result, 'M2T2:E001:UnsupportedObject', 'analysis');
    assert(exist(result.texPath, 'file') ~= 2 && exist(result.pdfPath, 'file') ~= 2);
    detail = result.diagnostics(1).message; clear cleanup;
end

function detail = missingCompiler(root)
    fig = figure('Visible', 'off'); cleanup = onCleanup(@() closeFigure(fig)); plot(1:3);
    oldPath = getenv('PATH'); pathCleanup = onCleanup(@() setenv('PATH', oldPath));
    setenv('PATH', tempdir);
    result = m2t.export(fig, fullfile(root, 'missing-compiler'));
    assert(~result.success && strcmp(result.status, 'compile_failed'));
    assertDiagnostic(result, 'M2T:C001:CompilerNotFound', 'compile');
    assert(exist(result.texPath, 'file') == 2 && exist(result.pdfPath, 'file') ~= 2);
    detail = result.diagnostics(1).message;
    clear pathCleanup cleanup;
end

function detail = invalidOutputPath(root)
    blocker = fullfile(root, 'not-a-directory');
    writeText(blocker, 'file blocks directory creation');
    fig = figure('Visible', 'off'); cleanup = onCleanup(@() closeFigure(fig)); plot(1:3);
    result = m2t.export(fig, fullfile(blocker, 'figure'));
    assert(~result.success && strcmp(result.status, 'export_failed'));
    assert(~isempty(result.diagnostics) && strcmp(result.diagnostics(1).stage, 'export'));
    detail = result.diagnostics(1).message; clear cleanup;
end

function detail = existingOutput(root)
    base = fullfile(root, 'existing'); texPath = [base '.tex'];
    marker = 'preserve this existing file'; writeText(texPath, marker);
    fig = figure('Visible', 'off'); cleanup = onCleanup(@() closeFigure(fig)); plot(1:3);
    result = m2t.export(fig, base);
    assert(~result.success && strcmp(result.status, 'export_failed'));
    assertDiagnostic(result, 'M2T:E003:OutputExists', 'export');
    assert(strcmp(fileread(texPath), marker));
    detail = result.diagnostics(1).message; clear cleanup;
end

function detail = deterministicRepeat(root)
    fig = figure('Visible', 'off'); cleanup = onCleanup(@() closeFigure(fig));
    plot(0:3, [0 1 4 9], 'DisplayName', 'Series'); legend('show');
    base = fullfile(root, 'repeat');
    first = m2t.export(fig, base);
    assertSuccess(first); firstTex = fileread(first.texPath);
    second = m2t.export(fig, base, 'Overwrite', true);
    assertSuccess(second); secondTex = fileread(second.texPath);
    assert(strcmp(firstTex, secondTex));
    detail = sprintf('deterministic TeX bytes=%d', numel(firstTex)); clear cleanup;
end

function assertSuccess(result)
    assert(result.success && strcmp(result.status, 'success'));
    assert(strcmp(result.capability, 'supported'));
    assert(strcmp(result.backend, 'pgfplots') && strcmp(result.compiler, 'lualatex'));
    assert(exist(result.texPath, 'file') == 2 && exist(result.pdfPath, 'file') == 2);
    assert(isempty(result.diagnostics));
    assert(result.timings.analysis >= 0 && result.timings.export >= 0 && ...
           result.timings.compile >= 0 && result.timings.total > 0);
end

function assertDiagnostic(result, code, stage)
    assert(~isempty(result.diagnostics));
    assert(strcmp(result.diagnostics(1).code, code));
    assert(strcmp(result.diagnostics(1).stage, stage));
    assert(strcmp(result.diagnostics(1).severity, 'error'));
end

function detail = successDetail(result)
    detail = sprintf('tex=%s; pdfBytes=%d; total=%.3fs', ...
                     result.texPath, fileSize(result.pdfPath), result.timings.total);
end

function bytes = fileSize(path)
    fid = fopen(path, 'rb'); assert(fid >= 0);
    fseek(fid, 0, 'eof'); bytes = ftell(fid); fclose(fid);
end

function yes = isAbsolute(path)
    if ispc
        yes = ~isempty(regexp(path, '^[A-Za-z]:[\\/]', 'once')) || strncmp(path, '\\', 2);
    else
        yes = strncmp(path, '/', 1);
    end
end

function resetDirectory(path)
    if exist(path, 'dir') == 7, rmdir(path, 's'); end
    ensureDirectory(path);
end

function ensureDirectory(path)
    if exist(path, 'dir') ~= 7, mkdir(path); end
end

function writeText(path, value)
    directory = fileparts(path); ensureDirectory(directory);
    fid = fopen(path, 'wb'); assert(fid >= 0);
    written = fwrite(fid, value, 'char'); fclose(fid); assert(written == numel(value));
end

function closeFigure(fig)
    if ~isempty(fig) && ishandle(fig), close(fig); end
end

function writeRows(path, rows)
    ensureDirectory(fileparts(path));
    fid = fopen(path, 'wb'); cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, 'case\tstatus\tdetail\tlayer\n');
    for k = 1:size(rows, 1)
        fprintf(fid, '%s\t%s\t%s\t%s\n', rows{k, 1}, rows{k, 2}, rows{k, 3}, rows{k, 4});
    end
    clear cleanup;
end

function value = oneLine(value)
    value = strrep(strrep(strrep(value, sprintf('\r'), ' '), sprintf('\n'), ' '), sprintf('\t'), ' ');
end

function value = identifierText(value)
    if isempty(value), value = '<none>'; end
end
