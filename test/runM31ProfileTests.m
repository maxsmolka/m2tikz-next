function summary = runM31ProfileTests(outputDirectory)
%RUNM31PROFILETESTS Validate the opt-in scientific publication profile.
    repositoryRoot = fileparts(fileparts(mfilename('fullpath')));
    if nargin < 1
        outputDirectory = fullfile(repositoryRoot, '.audit', 'm31-profile');
    end
    addpath(fullfile(repositoryRoot, 'src'));
    addpath(fullfile(repositoryRoot, 'test'));
    resetDirectory(outputDirectory);

    cases = { ...
        'P01_basic_line', @() basicLine(outputDirectory); ...
        'P02_scatter', @() scatterExport(outputDirectory); ...
        'P03_errorbar', @() errorbarExport(outputDirectory); ...
        'P04_multiple_axes', @() multipleAxes(outputDirectory); ...
        'P05_colorbar', @() colorbarExport(outputDirectory); ...
        'P06_legend', @() legendExport(outputDirectory); ...
        'P07_single_column_width', @() physicalWidth(outputDirectory, 'single-column', 85); ...
        'P08_double_column_width', @() physicalWidth(outputDirectory, 'double-column', 170); ...
        'P09_unknown_profile', @() unknownProfile(outputDirectory); ...
        'P10_invalid_width', @() invalidWidth(outputDirectory); ...
        'P11_default_none_compatibility', @() defaultCompatibility(outputDirectory); ...
        'P12_deterministic_repeat', @() deterministicRepeat(outputDirectory); ...
        'P13_publication_example', @() publicationExample(repositoryRoot, outputDirectory)};
    rows = cell(size(cases, 1), 4); failures = 0;
    for k = 1:size(cases, 1)
        try
            detail = cases{k, 2}(); status = 'PASS';
        catch err
            status = 'FAIL'; failures = failures + 1;
            detail = sprintf('%s: %s', identifierText(err.identifier), oneLine(err.message));
        end
        rows(k, :) = {cases{k, 1}, status, detail, 'profile'};
    end
    resultPath = fullfile(outputDirectory, 'profile-results.tsv');
    writeRows(resultPath, rows);
    summary = struct('failures', failures, 'tests', size(rows, 1), ...
                     'resultPath', resultPath);
    if failures > 0
        fprintf(2, 'M3.1 profile diagnostics from %s:\n%s', resultPath, fileread(resultPath));
        error('M2T:M31ProfileTestsFailed', '%d M3.1 profile tests failed.', failures);
    end
end

function detail = basicLine(root)
    fig = figure('Visible', 'off'); cleanup = onCleanup(@() closeFigure(fig));
    x = 0:3; plot(x, x .^ 2, '-o', 'DisplayName', 'Measured');
    xlabel('Time'); ylabel('Response'); title('Experiment'); legend('show');
    analysis = m2t.internal.analyzeFigure(fig); assert(strcmp(analysis.classification, 'supported'));
    transformed = m2t.profile.apply(analysis.ir, m2t.profile.getProfile('publication'), []);
    assert(transformed.success); assertScientificContentPreserved(analysis.ir, transformed.ir);
    result = m2t.export(fig, fullfile(root, 'line'), 'Profile', 'publication');
    assertProfileSuccess(result, 'single-column');
    tex = fileread(result.texPath);
    assert(containsText(tex, 'Time') && containsText(tex, 'Response') && ...
           containsText(tex, 'Experiment') && containsText(tex, 'Measured'));
    detail = sprintf('labels/legend preserved; size=%.4gx%.4g pt', result.profile.figureSize);
    clear cleanup;
end

function detail = scatterExport(root)
    fig = figure('Visible', 'off'); cleanup = onCleanup(@() closeFigure(fig));
    scatter(1:4, [2 1 4 3], 49, [0.2 0.4 0.8], 'o'); xlabel('Sample');
    result = m2t.export(fig, fullfile(root, 'scatter'), 'Profile', 'publication');
    assertProfileSuccess(result, 'single-column'); detail = 'constant-style scatter compiled';
    clear cleanup;
end

function detail = errorbarExport(root)
    fig = figure('Visible', 'off'); cleanup = onCleanup(@() closeFigure(fig));
    errorbar(1:4, [2 3 2 4], [0.2 0.3 0.1 0.4]);
    result = m2t.export(fig, fullfile(root, 'errorbar'), 'Profile', 'publication');
    assertProfileSuccess(result, 'single-column'); detail = 'error values compiled unchanged';
    clear cleanup;
end

function detail = multipleAxes(root)
    fig = figure('Visible', 'off'); cleanup = onCleanup(@() closeFigure(fig));
    first = subplot(1, 2, 1, 'Parent', fig); plot(first, 1:3, [1 2 1]);
    second = subplot(1, 2, 2, 'Parent', fig); plot(second, 1:3, [3 1 2]);
    analysis = m2t.internal.analyzeFigure(fig);
    transformed = m2t.profile.apply(analysis.ir, m2t.profile.getProfile('publication'), []);
    assertScientificContentPreserved(analysis.ir, transformed.ir);
    assert(numel(transformed.ir.axes) == 2);
    for k = 1:2, assert(isequaln(analysis.ir.axes{k}.placement, transformed.ir.axes{k}.placement)); end
    result = m2t.export(fig, fullfile(root, 'multiple-axes'), 'Profile', 'publication');
    assertProfileSuccess(result, 'single-column'); detail = 'two relative placements preserved';
    clear cleanup;
end

function detail = colorbarExport(root)
    fig = figure('Visible', 'off'); cleanup = onCleanup(@() closeFigure(fig));
    ax = axes('Parent', fig); imagesc(ax, [1 2; 3 4]); cb = colorbar(ax); ylabel(cb, 'Intensity');
    analysis = m2t.internal.analyzeFigure(fig);
    transformed = m2t.profile.apply(analysis.ir, m2t.profile.getProfile('publication'), []);
    assertScientificContentPreserved(analysis.ir, transformed.ir);
    assert(numel(analysis.ir.elements) == numel(transformed.ir.elements));
    result = m2t.export(fig, fullfile(root, 'colorbar'), 'Profile', 'publication');
    assertProfileSuccess(result, 'single-column'); detail = 'colorbar semantics and placement preserved';
    clear cleanup;
end

function detail = legendExport(root)
    fig = figure('Visible', 'off'); cleanup = onCleanup(@() closeFigure(fig));
    plot(1:3, [1 2 1], 'DisplayName', 'Measured'); hold on;
    plot(1:3, [2 1 2], 'DisplayName', 'Reference'); legend('show');
    analysis = m2t.internal.analyzeFigure(fig); entries = analysis.ir.axes{1}.legend.entries;
    assert(strcmp(entries{1}.text.value, 'Measured') && strcmp(entries{2}.text.value, 'Reference'));
    result = m2t.export(fig, fullfile(root, 'legend'), 'Profile', 'publication');
    assertProfileSuccess(result, 'single-column');
    tex = fileread(result.texPath); measured = strfind(tex, 'Measured'); reference = strfind(tex, 'Reference');
    assert(~isempty(measured) && ~isempty(reference) && measured(1) < reference(1));
    detail = 'legend membership and order preserved'; clear cleanup;
end

function detail = physicalWidth(root, width, expectedMillimeters)
    fig = figure('Visible', 'off'); cleanup = onCleanup(@() closeFigure(fig)); plot(1:3);
    result = m2t.export(fig, fullfile(root, ['width-' width]), ...
                        'Profile', 'publication', 'Width', width);
    assertProfileSuccess(result, width); actualPoints = pdfWidth(result.pdfPath);
    expectedPoints = expectedMillimeters * 72 / 25.4;
    tolerancePoints = 0.05;
    assert(abs(actualPoints - expectedPoints) <= tolerancePoints);
    detail = sprintf('PDF %.4g pt; expected %.4g pt; tolerance %.3g pt', ...
                     actualPoints, expectedPoints, tolerancePoints); clear cleanup;
end

function detail = unknownProfile(root)
    fig = figure('Visible', 'off'); cleanup = onCleanup(@() closeFigure(fig)); plot(1:3);
    result = m2t.export(fig, fullfile(root, 'unknown'), 'Profile', 'paper');
    assert(~result.success); assertDiagnostic(result, 'M2T:PROFILE_UNKNOWN', 'analysis');
    invalidType = m2t.export(fig, fullfile(root, 'unknown-type'), 'Profile', 42);
    assert(~invalidType.success); assertDiagnostic(invalidType, 'M2T:PROFILE_UNKNOWN', 'analysis');
    assert(exist(result.texPath, 'file') ~= 2); detail = result.diagnostics(1).message; clear cleanup;
end

function detail = invalidWidth(root)
    fig = figure('Visible', 'off'); cleanup = onCleanup(@() closeFigure(fig)); plot(1:3);
    result = m2t.export(fig, fullfile(root, 'invalid-width'), ...
                        'Profile', 'publication', 'Width', 'journal-column');
    assert(~result.success); assertDiagnostic(result, 'M2T:PROFILE_WIDTH_INVALID', 'analysis');
    assert(exist(result.texPath, 'file') ~= 2); detail = result.diagnostics(1).message; clear cleanup;
end

function detail = defaultCompatibility(root)
    fig = figure('Visible', 'off'); cleanup = onCleanup(@() closeFigure(fig)); plot(1:3);
    implicit = m2t.export(fig, fullfile(root, 'none-implicit'));
    explicit = m2t.export(fig, fullfile(root, 'none-explicit'), 'Profile', 'none');
    assert(implicit.success && explicit.success);
    assert(strcmp(fileread(implicit.texPath), fileread(explicit.texPath)));
    assert(strcmp(implicit.profile.name, 'none') && strcmp(explicit.profile.name, 'none'));
    detail = 'implicit and explicit none TeX are byte-identical'; clear cleanup;
end

function detail = deterministicRepeat(root)
    fig = figure('Visible', 'off'); cleanup = onCleanup(@() closeFigure(fig));
    plot(1:3, [1 2 1], 'DisplayName', 'Series'); legend('show');
    base = fullfile(root, 'repeat'); first = m2t.export(fig, base, 'Profile', 'publication');
    second = m2t.export(fig, base, 'Profile', 'publication', 'Overwrite', true);
    assert(first.success && second.success);
    firstTex = fileread(first.texPath); assert(strcmp(firstTex, fileread(second.texPath)));
    detail = sprintf('deterministic TeX bytes=%d', numel(firstTex)); clear cleanup;
end

function detail = publicationExample(repositoryRoot, root)
    exampleDirectory = fullfile(repositoryRoot, 'examples', '06-publication-profile');
    addpath(exampleDirectory); pathCleanup = onCleanup(@() rmpath(exampleDirectory));
    results = example_publication_profile(fullfile(root, 'example'));
    assert(results.default.success && results.singleColumn.success && results.doubleColumn.success);
    assert(strcmp(results.default.profile.name, 'none'));
    assert(strcmp(results.publication.profile.name, 'publication'));
    assert(results.singleColumn.profile.widthMillimeters==85&&results.doubleColumn.profile.widthMillimeters==170);
    detail = 'default, 85 mm, and 170 mm publication-profile products compiled'; clear pathCleanup;
end

function assertScientificContentPreserved(source, transformed)
    sourceSize = source.size; transformedSize = transformed.size;
    assert(~isequal(sourceSize, transformedSize)); transformed.size = sourceSize;
    assert(isequaln(source, transformed));
end

function assertProfileSuccess(result, width)
    assert(result.success && strcmp(result.status, 'success'));
    assert(strcmp(result.profile.name, 'publication') && strcmp(result.profile.width, width));
    assert(exist(result.texPath, 'file') == 2 && exist(result.pdfPath, 'file') == 2);
end

function assertDiagnostic(result, code, stage)
    assert(~isempty(result.diagnostics));
    assert(strcmp(result.diagnostics(1).code, code));
    assert(strcmp(result.diagnostics(1).stage, stage));
    assert(strcmp(result.diagnostics(1).severity, 'error'));
end

function points = pdfWidth(path)
    if ispc
        selector = 'findstr /B /C:"Page size"';
    else
        selector = 'grep "^Page size"';
    end
    [status, output] = system(['pdfinfo -enc UTF-8 ' quoteArgument(path) ...
                               ' 2>&1 | ' selector]);
    assert(status == 0, 'pdfinfo failed: %s', output);
    token = regexp(output, 'Page size:\s*([0-9.]+)\s+x\s+([0-9.]+)\s+pts', 'tokens', 'once');
    assert(~isempty(token), 'Could not read PDF page size: %s', output);
    points = str2double(token{1});
end

function value = quoteArgument(value)
    if ispc, value = strrep(value, '\', '/'); end
    assert(isempty(strfind(value, '"'))); value = ['"' value '"'];
end

function yes = containsText(value, pattern), yes = ~isempty(strfind(value, pattern)); end
function closeFigure(fig), if ~isempty(fig) && ishandle(fig), close(fig); end, end
function resetDirectory(path), if exist(path, 'dir') == 7, rmdir(path, 's'); end, mkdir(path); end
function value = oneLine(value), value = regexprep(value, '[\r\n\t]+', ' '); end
function value = identifierText(value), if isempty(value), value = '<none>'; end, end

function writeRows(path, rows)
    fid = fopen(path, 'wb'); assert(fid >= 0); cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, 'case\tstatus\tdetail\tlayer\n');
    for k = 1:size(rows, 1), fprintf(fid, '%s\t%s\t%s\t%s\n', rows{k, :}); end
    clear cleanup;
end
