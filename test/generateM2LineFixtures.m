function summary = generateM2LineFixtures(outputDirectory)
%GENERATEM2LINEFIXTURES Export and semantically compare the ten M2 fixtures.
    repositoryRoot = fileparts(fileparts(mfilename('fullpath')));
    if nargin < 1
        outputDirectory = fullfile(repositoryRoot, '.audit', 'm2');
    end
    addpath(fullfile(repositoryRoot, 'src'));
    m2Directory = fullfile(outputDirectory, 'tex', 'm2');
    legacyDirectory = fullfile(outputDirectory, 'tex', 'legacy');
    ensureDirectory(m2Directory); ensureDirectory(legacyDirectory);
    names = {'minimal','multiple','styled','labels','display_name', ...
             'log_x','log_y','nan_gap','inf_gap','empty'};
    rows = cell(numel(names), 12);
    failures = 0;

    for k = 1:numel(names)
        fig = [];
        try
            [fig, expected] = createM2LineFixture(names{k});
            m2Path = fullfile(m2Directory, [names{k} '.tex']);
            legacyPath = fullfile(legacyDirectory, [names{k} '.tex']);
            [ir, m2Tex] = m2t2.export(fig, m2Path, true);
            repeated = m2t2.render.renderPgfplots(ir, true);
            assert(strcmp(m2Tex, repeated));
            matlab2tikz(legacyPath, 'figurehandle', fig, 'standalone', true, ...
                        'showInfo', false, 'externalData', false);
            legacyTex = readText(legacyPath);
            m2Signature = signature(m2Tex, ir.axes{1}, expected, true);
            legacySignature = signature(legacyTex, ir.axes{1}, expected, false);
            pass = m2Signature.pass && legacySignature.pass;
            sourcePoints = pointCount(ir.axes{1});
            knownDifference = legacySignature.series ~= expected.seriesCount || ...
                              legacySignature.points ~= sourcePoints;
            if pass && knownDifference
                status = 'UNDERSTOOD_DIFFERENCE';
                detail = 'legacy and M2 preserve different empty/non-finite object semantics';
            elseif pass, status = 'PASS'; detail = '';
            else, status = 'FAIL'; detail = [m2Signature.detail ' ' legacySignature.detail]; failures = failures + 1; end
            rows(k, :) = {names{k}, status, detail, expected.seriesCount, ...
                m2Signature.series, legacySignature.series, sourcePoints, ...
                m2Signature.points, legacySignature.points, ...
                fileBytes(m2Path), fileBytes(legacyPath), 'direct-render-repeat-identical'};
        catch err
            failures = failures + 1;
            rows(k, :) = {names{k}, 'FAIL', errorDetail(err), NaN, NaN, NaN, ...
                          NaN, NaN, NaN, NaN, NaN, 'exception'};
        end
        if ~isempty(fig) && ishandle(fig), close(fig); end
    end
    writeRows(fullfile(outputDirectory, 'semantic-results.tsv'), rows);
    summary = struct('failures', failures, 'fixtures', numel(names));
    if failures > 0
        error('M2T2:FixtureGenerationFailed', '%d M2 fixture comparisons failed.', failures);
    end
end

function result = signature(tex, ax, expected, isM2)
    bs = char(92);
    result.series = numel(regexp(tex, [bs bs 'addplot'], 'match'));
    result.points = exportedPointCount(tex, isM2);
    expectedSeries = expected.seriesCount;
    if ~isM2 && strcmp(expected.name, 'empty')
        expectedSeries = 0; % Legacy intentionally omits an empty line object.
    end
    checks = [result.series == expectedSeries, ...
              hasOption(tex, 'xmin'), hasOption(tex, 'xmax'), ...
              hasOption(tex, 'ymin'), hasOption(tex, 'ymax')];
    if ~isempty(expected.xlabel), checks(end + 1) = hasText(tex, expected.xlabel); end
    if ~isempty(expected.ylabel), checks(end + 1) = hasText(tex, expected.ylabel); end
    if ~isempty(expected.title), checks(end + 1) = hasText(tex, expected.title); end
    if strcmp(expected.xscale, 'log'), checks(end + 1) = hasText(tex, 'xmode=log'); end
    if strcmp(expected.yscale, 'log'), checks(end + 1) = hasText(tex, 'ymode=log'); end
    if strcmp(expected.name, 'styled')
        checks(end + 1) = hasText(tex, 'dashed');
        checks(end + 1) = hasText(tex, 'mark=o');
    end
    if strcmp(expected.name, 'display_name')
        checks(end + 1) = hasText(tex, [bs 'addlegendentry{Measured}']);
        checks(end + 1) = hasText(tex, [bs 'addlegendentry{Reference}']);
    end
    if isM2
        checks(end + 1) = numericOptionEquals(tex, 'xmin', ax.xlim(1));
        checks(end + 1) = numericOptionEquals(tex, 'xmax', ax.xlim(2));
        checks(end + 1) = numericOptionEquals(tex, 'ymin', ax.ylim(1));
        checks(end + 1) = numericOptionEquals(tex, 'ymax', ax.ylim(2));
        checks(end + 1) = result.points == pointCount(ax);
    end
    result.pass = all(checks);
    if result.pass, result.detail = '';
    else, result.detail = sprintf('%s semantic checks=%s', ternary(isM2, 'M2', 'legacy'), mat2str(checks)); end
end

function count = exportedPointCount(tex, isM2)
    lines = regexp(tex, '\r\n|\n|\r', 'split');
    count = 0;
    if isM2
        pattern = '^\s*\([^()]*,[^()]*\)\s*$';
    else
        % Legacy inline tables terminate each numeric data row with TeX \\.
        number = '(?:nan|[-+0-9.eE]+)';
        pattern = ['^\s*' number '\s+' number '\\\\\s*$'];
    end
    for k = 1:numel(lines)
        count = count + ~isempty(regexp(lines{k}, pattern, 'once'));
    end
end

function count = pointCount(ax)
    count = 0;
    for k = 1:numel(ax.series), count = count + numel(ax.series{k}.x); end
end

function yes = hasOption(tex, name)
    yes = ~isempty(regexp(tex, [name '\s*='], 'once'));
end

function yes = numericOptionEquals(tex, name, expected)
    token = regexp(tex, [name '\s*=\s*([-+0-9.eE]+)'], 'tokens', 'once');
    yes = ~isempty(token) && abs(str2double(token{1}) - expected) <= 1e-12 * max(1, abs(expected));
end

function yes = hasText(tex, text)
    yes = ~isempty(strfind(tex, text)); %#ok<STREMP>
end

function value = ternary(condition, first, second)
    if condition, value = first; else, value = second; end
end

function bytes = fileBytes(path)
    fid = fopen(path, 'rb');
    if fid < 0, error('M2T2:TestIO', 'Cannot open %s.', path); end
    cleanup = onCleanup(@() fclose(fid));
    fseek(fid, 0, 'eof'); bytes = ftell(fid); clear cleanup;
end

function value = readText(path)
    fid = fopen(path, 'r'); cleanup = onCleanup(@() fclose(fid));
    value = fread(fid, Inf, '*char')'; clear cleanup;
end

function ensureDirectory(path)
    if exist(path, 'dir') ~= 7, mkdir(path); end
end

function writeRows(path, rows)
    fid = fopen(path, 'w'); cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, ['case\tstatus\tdetail\texpected_series\tm2_series\tlegacy_series\t' ...
                  'source_points\tm2_points\tlegacy_points\tm2_bytes\tlegacy_bytes\tdeterminism\n']);
    for k = 1:size(rows, 1)
        fprintf(fid, '%s\t%s\t%s\t%g\t%g\t%g\t%g\t%g\t%g\t%g\t%g\t%s\n', rows{k, :});
    end
    clear cleanup;
end

function value = oneLine(value)
    value = strrep(strrep(value, sprintf('\r'), ' '), sprintf('\n'), ' ');
end

function value = errorDetail(err)
    value = oneLine(err.message);
    if ~isempty(err.stack)
        value = sprintf('%s at %s:%d', value, err.stack(1).name, err.stack(1).line);
    end
end
