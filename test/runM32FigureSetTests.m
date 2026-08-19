function summary = runM32FigureSetTests(outputDirectory)
%RUNM32FIGURESETTESTS Exercise the public M3.2 figure-set workflow.
    repositoryRoot = fileparts(fileparts(mfilename('fullpath')));
    if nargin < 1
        outputDirectory = fullfile(repositoryRoot, '.audit', 'm32-figure-set');
    end
    addpath(fullfile(repositoryRoot, 'src'));
    addpath(fullfile(repositoryRoot, 'test'));
    resetDirectory(outputDirectory);

    cases = { ...
        'S1_two_successful_lines', @() twoLines(outputDirectory); ...
        'S2_mixed_supported_set', @() mixedSet(outputDirectory); ...
        'S3_publication_single_column', @() publicationSet(outputDirectory); ...
        'S4_per_entry_double_column', @() widthOverride(outputDirectory); ...
        'S5_multiple_axes', @() multipleAxes(outputDirectory); ...
        'S6_colorbar', @() colorbarEntry(outputDirectory); ...
        'S7_duplicate_names', @() duplicateNames(outputDirectory); ...
        'S8_path_traversal_name', @() unsafeName(outputDirectory); ...
        'S9_continue_on_error_true', @() continueTrue(outputDirectory); ...
        'S10_continue_on_error_false', @() continueFalse(outputDirectory); ...
        'S11_existing_output', @() existingOutput(outputDirectory); ...
        'S12_deterministic_manifest', @() deterministicManifest(outputDirectory); ...
        'S13_deterministic_tex', @() deterministicTex(outputDirectory); ...
        'S14_output_path_with_spaces', @() pathWithSpaces(outputDirectory); ...
        'S15_profile_none_compatibility', @() profileNone(outputDirectory); ...
        'S16_aggregate_counts', @() aggregateCounts(outputDirectory)};
    rows = cell(size(cases, 1), 4); failures = 0;
    for k = 1:size(cases, 1)
        try
            detail = cases{k, 2}(); status = 'PASS';
        catch err
            status = 'FAIL'; failures = failures + 1;
            detail = sprintf('%s: %s', identifierText(err.identifier), oneLine(err.message));
        end
        rows(k, :) = {cases{k, 1}, status, detail, 'figure-set'};
    end
    resultPath = fullfile(outputDirectory, 'figure-set-results.tsv');
    writeRows(resultPath, rows);
    summary = struct('failures', failures, 'tests', size(rows, 1), ...
                     'resultPath', resultPath);
    if failures > 0
        fprintf(2, 'M3.2 figure-set diagnostics from %s:\n%s', ...
                resultPath, fileread(resultPath));
        error('M2T:M32FigureSetTestsFailed', ...
              '%d M3.2 figure-set tests failed.', failures);
    end
end

function detail = twoLines(root)
    [figures, cleanup] = lineFigures(2);
    entries = makeEntries(figures, {'overview','comparison'});
    result = m2t.exportSet(entries, fullfile(root, 's1'));
    assertSetSuccess(result, 2); assertFiguresAlive(figures);
    detail = 'two TeX/PDF pairs and manifest'; clear cleanup;
end

function detail = mixedSet(root)
    first = figure('Visible', 'off'); plot(1:4, [1 3 2 4]);
    second = figure('Visible', 'off'); scatter(1:4, [2 1 4 3], 36, [0.2 0.4 0.8]);
    third = figure('Visible', 'off'); errorbar(1:4, [2 3 2 4], [0.2 0.1 0.3 0.2]);
    figures = [first second third]; cleanup = onCleanup(@() closeFigures(figures));
    result = m2t.exportSet(makeEntries(figures, {'line','scatter','errorbar'}), ...
                           fullfile(root, 's2'));
    assertSetSuccess(result, 3); assertFiguresAlive(figures);
    detail = 'line/scatter/errorbar compiled'; clear cleanup;
end

function detail = publicationSet(root)
    [figures, cleanup] = lineFigures(2);
    result = m2t.exportSet(makeEntries(figures, {'first','second'}), ...
        fullfile(root, 's3'), 'Profile', 'publication', ...
        'Width', 'single-column');
    assertSetSuccess(result, 2);
    assert(all(arrayfun(@(item) strcmp(item.effective.profile, 'publication') && ...
        strcmp(item.effective.width, 'single-column'), result.entries)));
    detail = 'publication defaults inherited'; clear cleanup;
end

function detail = widthOverride(root)
    [figures, cleanup] = lineFigures(2);
    entries = struct('figure', {figures(1), figures(2)}, ...
                     'name', {'overview','architecture'}, ...
                     'width', {[], 'double-column'});
    result = m2t.exportSet(entries, fullfile(root, 's4'), ...
        'Profile', 'publication', 'Width', 'single-column');
    assertSetSuccess(result, 2);
    assert(strcmp(result.entries(1).effective.width, 'single-column'));
    assert(strcmp(result.entries(2).effective.width, 'double-column'));
    assert(result.entries(2).result.profile.widthMillimeters == 170);
    detail = 'entry override > set default'; clear cleanup;
end

function detail = multipleAxes(root)
    fig = figure('Visible', 'off'); cleanup = onCleanup(@() closeFigures(fig));
    a = subplot(1, 2, 1, 'Parent', fig); plot(a, 1:3, [1 2 1]);
    b = subplot(1, 2, 2, 'Parent', fig); plot(b, 1:3, [3 1 2]);
    result = m2t.exportSet(makeEntries(fig, {'multi-panel'}), fullfile(root, 's5'));
    assertSetSuccess(result, 1); detail = 'multiple axes compiled'; clear cleanup;
end

function detail = colorbarEntry(root)
    fig = figure('Visible', 'off'); cleanup = onCleanup(@() closeFigures(fig));
    ax = axes('Parent', fig); imagesc(ax, [1 2; 3 4]); colorbar(ax);
    result = m2t.exportSet(makeEntries(fig, {'colorbar'}), fullfile(root, 's6'));
    assertSetSuccess(result, 1); detail = 'colorbar entry compiled'; clear cleanup;
end

function detail = duplicateNames(root)
    [figures, cleanup] = lineFigures(2); output = fullfile(root, 's7');
    result = m2t.exportSet(makeEntries(figures, {'Overview','overview'}), output);
    assertInvalid(result, 'M2T:SET_DUPLICATE_NAME'); assert(exist(output, 'dir') ~= 7);
    detail = 'case-insensitive duplicate rejected preflight'; clear cleanup;
end

function detail = unsafeName(root)
    [figures, cleanup] = lineFigures(1); output = fullfile(root, 's8');
    escaped = fullfile(root, 'escape.tex');
    result = m2t.exportSet(makeEntries(figures, {'../escape'}), output);
    assertInvalid(result, 'M2T:SET_INVALID_NAME');
    assert(exist(output, 'dir') ~= 7 && exist(escaped, 'file') ~= 2);
    detail = 'path traversal rejected before output'; clear cleanup;
end

function detail = continueTrue(root)
    [figures, cleanup] = supportedUnsupportedSupported();
    result = m2t.exportSet(makeEntries(figures, {'first','unsupported','third'}), ...
        fullfile(root, 's9'), 'ContinueOnError', true);
    assert(~result.success && strcmp(result.status, 'partial_failure'));
    assertCounts(result, 3, 2, 0, 1, 0);
    assert(strcmp(result.entries(2).result.status, 'unsupported'));
    assert(strcmp(result.entries(3).result.status, 'success'));
    assertManifest(result); detail = 'later figure evaluated after unsupported'; clear cleanup;
end

function detail = continueFalse(root)
    [figures, cleanup] = supportedUnsupportedSupported();
    result = m2t.exportSet(makeEntries(figures, {'first','unsupported','third'}), ...
        fullfile(root, 's10'), 'ContinueOnError', false);
    assert(~result.success && strcmp(result.status, 'partial_failure'));
    assertCounts(result, 3, 1, 0, 1, 1);
    skipped = result.entries(3).result;
    assert(strcmp(skipped.status, 'skipped'));
    assert(strcmp(skipped.diagnostics(1).code, 'M2T:SET_SKIPPED_AFTER_FAILURE'));
    assert(strcmp(skipped.diagnostics(1).stage, 'set'));
    assert(exist(skipped.texPath, 'file') ~= 2); assertManifest(result);
    detail = 'remaining entry explicitly skipped'; clear cleanup;
end

function detail = existingOutput(root)
    [figures, cleanup] = lineFigures(2); output = fullfile(root, 's11');
    ensureDirectory(output); marker = 'preserve'; existing = fullfile(output, 'first.tex');
    writeText(existing, marker);
    result = m2t.exportSet(makeEntries(figures, {'first','second'}), output);
    assertInvalid(result, 'M2T:SET_OUTPUT_EXISTS');
    assert(strcmp(fileread(existing), marker));
    assert(exist(fullfile(output, 'second.tex'), 'file') ~= 2);
    assert(exist(fullfile(output, 'm2t-manifest.json'), 'file') ~= 2);
    detail = 'collision prevents whole build preflight'; clear cleanup;
end

function detail = deterministicManifest(root)
    [figures, cleanup] = lineFigures(2); output = fullfile(root, 's12');
    entries = makeEntries(figures, {'first','second'});
    first = m2t.exportSet(entries, output, 'Profile', 'publication', 'Overwrite', true);
    assertSetSuccess(first, 2); firstText = fileread(first.manifestPath);
    second = m2t.exportSet(entries, output, 'Profile', 'publication', 'Overwrite', true);
    assertSetSuccess(second, 2); assert(strcmp(firstText, fileread(second.manifestPath)));
    assert(isempty(strfind(firstText, output))); %#ok<STREMP>
    detail = sprintf('byte-identical manifest bytes=%d', numel(firstText)); clear cleanup;
end

function detail = deterministicTex(root)
    [figures, cleanup] = lineFigures(1); output = fullfile(root, 's13');
    entries = makeEntries(figures, {'repeat'});
    first = m2t.exportSet(entries, output, 'Overwrite', true); assertSetSuccess(first, 1);
    tex = fileread(first.entries(1).result.texPath);
    second = m2t.exportSet(entries, output, 'Overwrite', true); assertSetSuccess(second, 1);
    assert(strcmp(tex, fileread(second.entries(1).result.texPath)));
    detail = sprintf('byte-identical TeX bytes=%d', numel(tex)); clear cleanup;
end

function detail = pathWithSpaces(root)
    [figures, cleanup] = lineFigures(2); output = fullfile(root, 's14 path with spaces');
    result = m2t.exportSet(makeEntries(figures, {'first','second'}), output);
    assertSetSuccess(result, 2); assert(~isempty(strfind(result.outputDirectory, 'spaces'))); %#ok<STREMP>
    detail = 'space-containing output directory compiled'; clear cleanup;
end

function detail = profileNone(root)
    [figures, cleanup] = lineFigures(1);
    setResult = m2t.exportSet(makeEntries(figures, {'set-default'}), ...
                              fullfile(root, 's15-set'), 'Profile', 'none');
    single = m2t.export(figures(1), fullfile(root, 's15-single', 'default'));
    assertSetSuccess(setResult, 1); assert(single.success);
    assert(strcmp(fileread(setResult.entries(1).result.texPath), fileread(single.texPath)));
    assert(strcmp(setResult.entries(1).effective.width, 'source'));
    detail = 'batch none and single-export default TeX identical'; clear cleanup;
end

function detail = aggregateCounts(root)
    [figures, cleanup] = lineFigures(2); entries = makeEntries(figures, {'failure','skipped'});
    oldPath = getenv('PATH'); pathCleanup = onCleanup(@() setenv('PATH', oldPath));
    setenv('PATH', tempdir);
    result = m2t.exportSet(entries, fullfile(root, 's16'), 'ContinueOnError', false);
    clear pathCleanup;
    assert(~result.success && strcmp(result.status, 'failed'));
    assertCounts(result, 2, 0, 1, 0, 1);
    assert(strcmp(result.entries(1).result.status, 'compile_failed'));
    assert(strcmp(result.entries(2).result.status, 'skipped'));
    assert(result.summary.total == result.summary.succeeded + result.summary.failed + ...
           result.summary.unsupported + result.summary.skipped);
    detail = 'failed/unsupported/skipped counts are disjoint'; clear cleanup;
end

function [figures, cleanup] = lineFigures(count)
    figures = zeros(1, count);
    for k = 1:count
        figures(k) = figure('Visible', 'off');
        plot(1:4, [1 2 1 2] + k, 'DisplayName', sprintf('Series %d', k));
        xlabel('Sample'); ylabel('Value');
    end
    cleanup = onCleanup(@() closeFigures(figures));
end

function [figures, cleanup] = supportedUnsupportedSupported()
    figures = zeros(1, 3);
    figures(1) = figure('Visible', 'off'); plot(1:3, [1 2 1]);
    figures(2) = figure('Visible', 'off'); ax = axes('Parent', figures(2));
    plot(ax, 1:3, [2 1 2]);
    patch(ax, [1 2 1], [1 2 2], [0.5 0.5 0.5]);
    figures(3) = figure('Visible', 'off'); plot(1:3, [3 1 2]);
    cleanup = onCleanup(@() closeFigures(figures));
end

function entries = makeEntries(figures, names)
    entries = repmat(struct('figure', [], 'name', ''), 1, numel(figures));
    for k = 1:numel(figures)
        entries(k).figure = figures(k); entries(k).name = names{k};
    end
end

function assertSetSuccess(result, count)
    assert(result.success && strcmp(result.status, 'success'));
    assertCounts(result, count, count, 0, 0, 0); assert(isempty(result.diagnostics));
    for k = 1:count
        single = result.entries(k).result;
        assert(single.success && exist(single.texPath, 'file') == 2 && ...
               exist(single.pdfPath, 'file') == 2);
    end
    assertManifest(result);
end

function assertManifest(result)
    assert(exist(result.manifestPath, 'file') == 2);
    manifest = jsondecode(fileread(result.manifestPath));
    assert(manifest.schemaVersion == 1);
    assert(numel(manifest.figures) == result.summary.total);
end

function assertInvalid(result, code)
    assert(~result.success && strcmp(result.status, 'invalid_set'));
    assert(isempty(result.entries) && ~isempty(result.diagnostics));
    assert(strcmp(result.diagnostics(1).code, code));
    assert(strcmp(result.diagnostics(1).stage, 'set'));
end

function assertCounts(result, total, succeeded, failed, unsupported, skipped)
    assert(result.summary.total == total && result.summary.succeeded == succeeded && ...
           result.summary.failed == failed && result.summary.unsupported == unsupported && ...
           result.summary.skipped == skipped);
end

function assertFiguresAlive(figures)
    assert(all(arrayfun(@ishandle, figures)));
end

function closeFigures(figures)
    for k = 1:numel(figures), if ishandle(figures(k)), close(figures(k)); end, end
end

function resetDirectory(path), if exist(path, 'dir') == 7, rmdir(path, 's'); end, mkdir(path); end
function ensureDirectory(path), if exist(path, 'dir') ~= 7, mkdir(path); end, end
function value = oneLine(value), value = regexprep(value, '[\r\n\t]+', ' '); end
function value = identifierText(value), if isempty(value), value = '<none>'; end, end

function writeText(path, value)
    ensureDirectory(fileparts(path)); fid = fopen(path, 'wb'); assert(fid >= 0);
    written = fwrite(fid, value, 'char'); fclose(fid); assert(written == numel(value));
end

function writeRows(path, rows)
    fid = fopen(path, 'wb'); assert(fid >= 0); cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, 'case\tstatus\tdetail\tlayer\n');
    for k = 1:size(rows, 1), fprintf(fid, '%s\t%s\t%s\t%s\n', rows{k, :}); end
    clear cleanup;
end
