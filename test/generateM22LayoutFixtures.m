function summary = generateM22LayoutFixtures(outputDirectory)
%GENERATEM22LAYOUTFIXTURES Export semantic Legacy/M2.2 geometry pairs.
    root = fileparts(fileparts(mfilename('fullpath'))); addpath(fullfile(root, 'src'));
    if nargin < 1, outputDirectory = fullfile(root, '.audit', 'm2.2'); end
    legacyDirectory = fullfile(outputDirectory, 'tex', 'legacy');
    m22Directory = fullfile(outputDirectory, 'tex', 'm22');
    ensureDirectory(legacyDirectory); ensureDirectory(m22Directory);
    names = fixtureNames(); rows = cell(numel(names), 10); failures = 0;
    for k = 1:numel(names)
        fig = [];
        try
            fig = createM22LayoutFixture(names{k});
            legacyPath = fullfile(legacyDirectory, [names{k} '.tex']);
            m22Path = fullfile(m22Directory, [names{k} '.tex']);
            [ir, m22Text] = m2t2.export(fig, m22Path, true);
            matlab2tikz(legacyPath, 'figurehandle', fig, 'standalone', true, ...
                        'showInfo', false, 'externalData', false);
            legacyText = readText(legacyPath);
            expectedGeometry = normalizedGeometryFromIR(ir);
            legacy = signature(legacyText, ir, false, expectedGeometry);
            m22 = signature(m22Text, ir, true, expectedGeometry);
            pass = legacy.pass && m22.pass && legacy.axes == numel(ir.axes) && ...
                   m22.axes == numel(ir.axes) && legacy.geometryError < 0.025 && ...
                   m22.geometryError < 1e-10;
            if pass, status = 'PASS'; detail = '';
            else, status = 'FAIL'; detail = 'axes/ownership/geometry semantic mismatch'; failures = failures + 1; end
            rows(k, :) = {names{k}, status, detail, numel(ir.axes), legacy.axes, ...
                           m22.axes, pointCount(ir), legacy.series, m22.series, ...
                           sprintf('legacy_geometry_max=%g m22_geometry_max=%g', ...
                                   legacy.geometryError, m22.geometryError)};
        catch err
            failures = failures + 1;
            rows(k, :) = {names{k}, 'FAIL', errorDetail(err), NaN, NaN, NaN, ...
                           NaN, NaN, NaN, 'exception'};
        end
        if ~isempty(fig) && ishandle(fig), close(fig); end
    end
    writeRows(fullfile(outputDirectory, 'm22-semantic-results.tsv'), rows);
    summary = struct('failures', failures, 'fixtures', numel(names));
    if failures
        error('M2T2:M22FixtureGenerationFailed', '%d M2.2 comparisons failed.', failures);
    end
end

function result = signature(text, ir, isM22, expectedGeometry)
    blocks = axisBlocks(text); result.axes = numel(blocks); result.series = 0;
    checks = result.axes == numel(ir.axes);
    for k = 1:min(result.axes, numel(ir.axes))
        block = blocks{k}; node = ir.axes{k};
        seriesCount = countText(block, [char(92) 'addplot']);
        result.series = result.series + seriesCount;
        checks(end + 1) = seriesCount == numel(node.series); %#ok<AGROW>
        checks(end + 1) = hasOption(block, 'xmin') && hasOption(block, 'xmax'); %#ok<AGROW>
        checks(end + 1) = hasOption(block, 'ymin') && hasOption(block, 'ymax'); %#ok<AGROW>
        checks(end + 1) = ~isempty(strfind(block, node.title.value)); %#ok<AGROW,STREMP>
        if strcmp(node.xscale, 'log'), checks(end + 1) = hasText(block, 'xmode=log'); end %#ok<AGROW>
        if strcmp(node.yscale, 'log'), checks(end + 1) = hasText(block, 'ymode=log'); end %#ok<AGROW>
        expectedLegends = numel(node.legend.entries);
        checks(end + 1) = countText(block, [char(92) 'addlegendentry']) == expectedLegends; %#ok<AGROW>
    end
    if any(strcmp(fixtureNames(), 'manual_position')) && hasText(text, 'Manual')
        checks(end + 1) = hasText(text, 'zero') && hasText(text, 'three'); %#ok<AGROW>
    end
    geometry = geometryFromText(text);
    if size(geometry, 1) == size(expectedGeometry, 1)
        result.geometryError = max(abs(geometry(:) - expectedGeometry(:)));
    else
        result.geometryError = inf;
    end
    if isM22, checks(end + 1) = hasText(text, 'scale only axis'); end %#ok<AGROW>
    result.pass = all(checks);
end

function blocks = axisBlocks(text)
    bs = char(92);
    pattern = ['(?s)' bs bs 'begin\{axis\}\[(.*?)' bs bs 'end\{axis\}'];
    tokens = regexp(text, pattern, 'tokens'); blocks = cell(1, numel(tokens));
    for k = 1:numel(tokens), blocks{k} = tokens{k}{1}; end
end

function geometry = geometryFromText(text)
    blocks = axisBlocks(text); raw = zeros(numel(blocks), 4);
    for k = 1:numel(blocks)
        width = dimension(blocks{k}, 'width'); height = dimension(blocks{k}, 'height');
        token = regexp(blocks{k}, ...
            'at\s*=\s*\{\(\s*([-+0-9.eE]+)(pt|in|cm)\s*,\s*([-+0-9.eE]+)(pt|in|cm)\s*\)\}', ...
            'tokens', 'once');
        if isempty(token), error('M2T2:GeometryParse', 'Axes at-position missing.'); end
        raw(k, :) = [toInches(str2double(token{1}), token{2}), ...
                     toInches(str2double(token{3}), token{4}), width, height];
    end
    geometry = normalizeGeometry(raw);
end

function value = dimension(block, name)
    token = regexp(block, [name '\s*=\s*([-+0-9.eE]+)(pt|in|cm)'], 'tokens', 'once');
    if isempty(token), error('M2T2:GeometryParse', '%s missing.', name); end
    value = toInches(str2double(token{1}), token{2});
end

function value = toInches(value, unit)
    if strcmp(unit, 'pt'), value = value / 72.27;
    elseif strcmp(unit, 'cm'), value = value / 2.54; end
end

function geometry = normalizedGeometryFromIR(ir)
    raw = zeros(numel(ir.axes), 4);
    for k = 1:numel(ir.axes)
        p = ir.axes{k}.placement; raw(k, :) = [p.x p.y p.width p.height];
    end
    geometry = normalizeGeometry(raw);
end

function geometry = normalizeGeometry(raw)
    minX = min(raw(:,1)); minY = min(raw(:,2));
    spanX = max(raw(:,1) + raw(:,3)) - minX;
    spanY = max(raw(:,2) + raw(:,4)) - minY;
    geometry = [(raw(:,1) - minX) / spanX, (raw(:,2) - minY) / spanY, ...
                raw(:,3) / spanX, raw(:,4) / spanY];
end

function count = pointCount(ir)
    count = 0;
    for a = 1:numel(ir.axes)
        for s = 1:numel(ir.axes{a}.series), count = count + numel(ir.axes{a}.series{s}.x); end
    end
end

function count = countText(text, value), count = numel(strfind(text, value)); end
function yes = hasOption(text, name), yes = ~isempty(regexp(text, [name '\s*='], 'once')); end
function yes = hasText(text, value), yes = ~isempty(strfind(text, value)); end %#ok<STREMP>
function names = fixtureNames()
    names = {'two_independent','subplot_2x1','subplot_1x2','subplot_2x2', ...
             'manual_position','unequal_widths','unequal_heights', ...
             'overlapping_axes','different_scales','mixed_series_axes'};
end
function value = readText(path)
    fid = fopen(path, 'r'); cleanup = onCleanup(@() fclose(fid));
    value = fread(fid, Inf, '*char')'; clear cleanup;
end
function ensureDirectory(path), if exist(path, 'dir') ~= 7, mkdir(path); end, end
function writeRows(path, rows)
    fid = fopen(path, 'w'); cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, ['case\tstatus\tdetail\texpected_axes\tlegacy_axes\tm22_axes\t' ...
                  'expected_points\tlegacy_series\tm22_series\tnote\n']);
    for k = 1:size(rows,1)
        fprintf(fid, '%s\t%s\t%s\t%g\t%g\t%g\t%g\t%g\t%g\t%s\n', rows{k,:});
    end
end
function value = errorDetail(err)
    value = strrep(strrep(err.message, sprintf('\r'), ' '), sprintf('\n'), ' ');
    if ~isempty(err.stack), value = sprintf('%s at %s:%d', value, err.stack(1).name, err.stack(1).line); end
end
