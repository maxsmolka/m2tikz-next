function summary = runM33ImageTests(outputDirectory)
%RUNM33IMAGETESTS Validate scalar image semantics through reader and workflows.
    repositoryRoot = fileparts(fileparts(mfilename('fullpath')));
    if nargin < 1
        outputDirectory = fullfile(repositoryRoot, '.audit', 'm33-image');
    end
    addpath(fullfile(repositoryRoot, 'src'));
    resetDirectory(outputDirectory);

    cases = { ...
        'H1_basic_imagesc_matrix', @() basicMatrix(outputDirectory); ...
        'H2_explicit_xy_coordinates', @() explicitCoordinates(outputDirectory); ...
        'H3_reversed_y_direction', @() yDirection(outputDirectory, 'reverse'); ...
        'H4_normal_y_direction', @() yDirection(outputDirectory, 'normal'); ...
        'H5_custom_clim', @() customLimits(outputDirectory); ...
        'H6_custom_colormap', @() customColormap(outputDirectory); ...
        'H7_colorbar', @() colorbarExport(outputDirectory); ...
        'H8_publication_profile', @() profileExport(outputDirectory); ...
        'H9_multiple_axes_with_image', @() multipleAxes(outputDirectory); ...
        'H10_export_set_image', @() setExport(outputDirectory); ...
        'H11_nan_cell', @() nanCell(outputDirectory); ...
        'H12_deterministic_tex', @() deterministicTex(); ...
        'H13_25x25_fixture', @() renderSize(25); ...
        'H14_100x100_fixture', @() renderSize(100); ...
        'H15_rgb_hybrid', @() supportedRgb(outputDirectory); ...
        'H16_alpha_hybrid', @() supportedAlpha(outputDirectory); ...
        'H17_inf_unsupported', @() unsupportedInf(outputDirectory); ...
        'H18_json_replay', @() jsonReplay()};
    rows = cell(size(cases, 1), 4); failures = 0;
    for k = 1:size(cases, 1)
        try
            detail = cases{k, 2}(); status = 'PASS';
        catch err
            status = 'FAIL'; failures = failures + 1;
            detail = sprintf('%s: %s', identifierText(err.identifier), oneLine(err.message));
        end
        rows(k, :) = {cases{k, 1}, status, detail, 'image'};
    end
    resultPath = fullfile(outputDirectory, 'image-results.tsv');
    writeRows(resultPath, rows);
    summary = struct('failures', failures, 'tests', size(rows, 1), ...
                     'resultPath', resultPath);
    if failures > 0
        fprintf(2, 'M3.3 image diagnostics from %s:\n%s', resultPath, fileread(resultPath));
        error('M2T:M33ImageTestsFailed', '%d M3.3 image tests failed.', failures);
    end
end

function detail = basicMatrix(root)
    [fig, ax, cleanup] = imageFigure([1 2 3; 4 5 6]);
    ir = m2t2.reader.readFigure(fig); image = onlyImage(ir);
    assert(isequal(image.cdata, [1 2 3; 4 5 6]));
    assert(isequal(image.x, 1:3) && isequal(image.y, 1:2));
    result = m2t.export(fig, fullfile(root, 'h1-basic'));
    assertSuccess(result); tex = fileread(result.texPath);
    assertOrdered(tex, {'1 1 1 ','2 1 2 ','3 1 3 ','1 2 4 ','2 2 5 ','3 2 6 '});
    detail = 'exact 2x3 row-major matrix and implicit centers compiled';
    clear cleanup; %#ok<NASGU>
end

function detail = explicitCoordinates(root)
    fig = figure('Visible', 'off'); cleanup = onCleanup(@() closeFigure(fig));
    ax = axes('Parent', fig); imagesc(ax, [-2 0 2], [-1 -1/3 1/3 1], reshape(1:12, 4, 3));
    ir = m2t2.reader.readFigure(fig); image = onlyImage(ir);
    assert(max(abs(image.x - [-2 0 2])) < 1e-12);
    assert(max(abs(image.y - [-1 -1/3 1/3 1])) < 1e-12);
    result = m2t.export(fig, fullfile(root, 'h2-explicit'));
    assertSuccess(result); detail = 'runtime endpoint extents normalized to cell centers';
    clear cleanup;
end

function detail = yDirection(root, direction)
    [fig, ax, cleanup] = imageFigure([1 2; 3 4]);
    set(ax, 'YDir', direction);
    ir = m2t2.reader.readFigure(fig); assert(strcmp(ir.axes{1}.ydirection, direction));
    result = m2t.export(fig, fullfile(root, ['h-y-' direction])); assertSuccess(result);
    assert(containsText(fileread(result.texPath), ['y dir=' direction]));
    detail = [direction ' Y direction explicit and compiled']; clear cleanup;
end

function detail = customLimits(root)
    [fig, ax, cleanup] = imageFigure([1 2; 3 4]); set(ax, 'CLim', [-2 7]);
    ir = m2t2.reader.readFigure(fig); assert(isequal(ir.axes{1}.colorMapping.limits, [-2 7]));
    result = m2t.export(fig, fullfile(root, 'h5-clim')); assertSuccess(result);
    tex = fileread(result.texPath);
    assert(containsText(tex, 'point meta min=-2') && containsText(tex, 'point meta max=7'));
    detail = 'CLim [-2,7] owned by axes and compiled'; clear cleanup;
end

function detail = customColormap(root)
    map = [0 0 0; 0.123456789012345 0.5 0.75; 1 1 1];
    [fig, ax, cleanup] = imageFigure([1 2; 3 4]); colormap(ax, map);
    ir = m2t2.reader.readFigure(fig); assert(isequal(ir.axes{1}.colorMapping.colormap, map));
    tex = m2t2.render.renderPgfplots(ir, true);
    assert(containsText(tex, '0.123456789012345'));
    assert(containsText(tex, 'colormap access=direct'));
    result = m2t.export(fig, fullfile(root, 'h6-colormap')); assertSuccess(result);
    detail = 'explicit RGB stops serialized with 15 significant digits'; clear cleanup;
end

function detail = colorbarExport(root)
    [fig, ax, cleanup] = imageFigure([1 2; 3 4]);
    cb = colorbar(ax); ylabel(cb, 'Intensity');
    ir = m2t2.reader.readFigure(fig);
    assert(numel(ir.elements) == 1 && strcmp(ir.elements{1}.kind, 'm2t2.colorbar'));
    assert(strcmp(ir.elements{1}.owner.id, ir.axes{1}.id));
    result = m2t.export(fig, fullfile(root, 'h7-colorbar')); assertSuccess(result);
    detail = 'existing axes-owned ColorbarIR reused'; clear cleanup;
end

function detail = profileExport(root)
    [fig, ax, cleanup] = imageFigure(peaks(20)); colorbar(ax);
    original = m2t2.reader.readFigure(fig);
    result = m2t.export(fig, fullfile(root, 'h8-profile'), ...
                        'Profile', 'publication');
    assertSuccess(result); assert(strcmp(result.profile.name, 'publication'));
    current = m2t2.reader.readFigure(fig);
    assert(isequaln(onlyImage(original).cdata, onlyImage(current).cdata));
    assert(isequal(original.axes{1}.colorMapping, current.axes{1}.colorMapping));
    detail = 'publication profile compiles without changing image semantics'; clear cleanup;
end

function detail = multipleAxes(root)
    fig = figure('Visible', 'off'); cleanup = onCleanup(@() closeFigure(fig));
    first = subplot(1, 2, 1, 'Parent', fig); plot(first, 1:3, [1 3 2]);
    second = subplot(1, 2, 2, 'Parent', fig); imagesc(second, [1 2; 3 4]);
    ir = m2t2.reader.readFigure(fig); assert(numel(ir.axes) == 2);
    kinds = cellfun(@(item) item.series{1}.kind, ir.axes, 'UniformOutput', false);
    assert(any(strcmp(kinds, 'm2t2.line')) && any(strcmp(kinds, 'm2t2.image')));
    result = m2t.export(fig, fullfile(root, 'h9-multiple')); assertSuccess(result);
    detail = 'line and image axes preserve separate placements'; clear cleanup;
end

function detail = setExport(root)
    [fig, ax, cleanup] = imageFigure(peaks(12)); colorbar(ax);
    entries = struct('figure', fig, 'name', 'heatmap');
    result = m2t.exportSet(entries, fullfile(root, 'h10-set'), ...
                           'Profile', 'publication');
    assert(result.success && result.summary.succeeded == 1);
    assert(exist(result.manifestPath, 'file') == 2);
    detail = 'ordinary exportSet entry and manifest compiled'; clear cleanup;
end

function detail = nanCell(root)
    [fig, ax, cleanup] = imageFigure([1 NaN; 3 4]); %#ok<ASGLU>
    ir = m2t2.reader.readFigure(fig); assert(isnan(onlyImage(ir).cdata(1, 2)));
    result = m2t.export(fig, fullfile(root, 'h11-nan')); assertSuccess(result);
    assert(containsText(fileread(result.texPath), '2 1 nan nan'));
    detail = 'NaN emitted as PGFPlots missing cell'; clear cleanup;
end

function detail = deterministicTex()
    [fig, ax, cleanup] = imageFigure(peaks(10)); %#ok<ASGLU>
    ir = m2t2.reader.readFigure(fig);
    first = m2t2.render.renderPgfplots(ir, true);
    second = m2t2.render.renderPgfplots(ir, true);
    assert(strcmp(first, second));
    detail = sprintf('byte-identical repeated TeX bytes=%d', numel(first)); clear cleanup;
end

function detail = renderSize(count)
    [fig, ax, cleanup] = imageFigure(reshape(1:(count * count), count, count)); %#ok<ASGLU>
    started = tic; ir = m2t2.reader.readFigure(fig); readerSeconds = toc(started);
    started = tic; tex = m2t2.render.renderPgfplots(ir, true); rendererSeconds = toc(started);
    expectedRows = count * count;
    assert(countText(tex, sprintf('\n')) > expectedRows);
    detail = sprintf('%dx%d reader=%.4gs renderer=%.4gs bytes=%d', ...
                     count, count, readerSeconds, rendererSeconds, numel(tex));
    clear cleanup;
end

function detail = supportedRgb(root)
    rgb = zeros(2, 3, 3); rgb(:, :, 1) = 1;
    fig = figure('Visible', 'off'); cleanup = onCleanup(@() closeFigure(fig));
    ax = axes('Parent', fig); image(ax, rgb);
    item=onlyImage(m2t2.reader.readFigure(fig));
    assert(strcmp(item.colorMode,'rgb') && strcmp(item.mapping,'none'));
    result=m2t.export(fig,fullfile(root,'h15-rgb'),'ImageBackend','hybrid');
    assertSuccess(result); detail = 'truecolor RGB normalized and compiled through hybrid'; clear cleanup;
end

function detail = supportedAlpha(root)
    [fig, ax, cleanup] = imageFigure([1 2; 3 4]);
    imageHandle = findobj(ax, 'Type', 'image'); set(imageHandle, 'AlphaData', 0.5);
    item=onlyImage(m2t2.reader.readFigure(fig));
    assert(strcmp(item.alphaMode,'constant') && item.alphaData==0.5);
    result=m2t.export(fig,fullfile(root,'h16-alpha'),'ImageBackend','hybrid');
    assertSuccess(result); detail = 'constant alpha normalized and compiled through hybrid'; clear cleanup;
end

function detail = unsupportedInf(root)
    [fig, ax, cleanup] = imageFigure([1 Inf; -Inf 4]); %#ok<ASGLU>
    assertUnsupported(fig, fullfile(root, 'h17-inf'), 'M2T2:E047:MalformedImageCData');
    detail = 'positive and negative Inf rejected without clamping'; clear cleanup;
end

function detail = jsonReplay()
    [fig, ax, cleanup] = imageFigure([1 NaN 3; 4 5 6]); %#ok<ASGLU>
    source = m2t2.reader.readFigure(fig);
    replay = m2t2.ir.fromJson(jsonencode(source));
    image = onlyImage(replay);
    assert(isequaln(image.cdata, [1 NaN 3; 4 5 6]));
    assert(isequal(image.x, source.axes{1}.series{1}.x));
    assert(isequal(image.y, source.axes{1}.series{1}.y));
    first = m2t2.render.renderPgfplots(source, true);
    second = m2t2.render.renderPgfplots(replay, true);
    assert(strcmp(first, second));
    detail = 'ImageIR JSON replay is valid and byte-identical'; clear cleanup;
end

function [fig, ax, cleanup] = imageFigure(data)
    fig = figure('Visible', 'off'); cleanup = onCleanup(@() closeFigure(fig));
    ax = axes('Parent', fig); imagesc(ax, data);
end

function image = onlyImage(ir)
    assert(numel(ir.axes) == 1 && numel(ir.axes{1}.series) == 1);
    image = ir.axes{1}.series{1}; assert(strcmp(image.kind, 'm2t2.image'));
end

function assertUnsupported(fig, outputBase, code)
    analysis = m2t.internal.analyzeFigure(fig);
    assert(strcmp(analysis.classification, 'unsupported'));
    assert(strcmp(analysis.diagnostics(1).code, code));
    result = m2t.export(fig, outputBase);
    assert(~result.success && strcmp(result.status, 'unsupported'));
    assert(strcmp(result.diagnostics(1).code, code));
    assert(exist([outputBase '.tex'], 'file') ~= 2);
    entry = struct('figure', fig, 'name', 'unsupported-image');
    setResult = m2t.exportSet(entry, [outputBase '-set']);
    assert(~setResult.success && strcmp(setResult.status, 'failed'));
    assert(setResult.summary.unsupported == 1);
    assert(strcmp(setResult.entries(1).result.diagnostics(1).code, code));
end

function assertSuccess(result)
    assert(result.success && strcmp(result.status, 'success'));
    assert(exist(result.texPath, 'file') == 2 && exist(result.pdfPath, 'file') == 2);
end

function assertOrdered(text, values)
    prior = 0;
    for k = 1:numel(values)
        found = strfind(text, values{k}); assert(~isempty(found) && found(1) > prior);
        prior = found(1);
    end
end

function yes = containsText(text, pattern), yes = ~isempty(strfind(text, pattern)); end %#ok<STREMP>
function count = countText(text, pattern), count = numel(strfind(text, pattern)); end %#ok<STREMP>
function closeFigure(fig), if ishandle(fig), close(fig); end, end
function resetDirectory(path), if exist(path, 'dir') == 7, rmdir(path, 's'); end, mkdir(path); end
function value = oneLine(value), value = regexprep(value, '[\r\n\t]+', ' '); end
function value = identifierText(value), if isempty(value), value = '<none>'; end, end

function writeRows(path, rows)
    fid = fopen(path, 'wb'); assert(fid >= 0); cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, 'case\tstatus\tdetail\tlayer\n');
    for k = 1:size(rows, 1), fprintf(fid, '%s\t%s\t%s\t%s\n', rows{k, :}); end
    clear cleanup;
end
