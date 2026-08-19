function summary = runM2RendererTests(outputDirectory)
%RUNM2RENDERERTESTS Exercise only hand-built IR and JSON-to-render paths.
    repositoryRoot = fileparts(fileparts(mfilename('fullpath')));
    if nargin < 1
        outputDirectory = fullfile(repositoryRoot, '.audit', 'm2');
    end
    addpath(fullfile(repositoryRoot, 'src'));
    ensureDirectory(outputDirectory);
    irDirectory = fullfile(outputDirectory, 'ir'); ensureDirectory(irDirectory);
    rows = {};
    failures = 0;

    try
        ir = handBuiltIR();
        first = m2t2.render.renderPgfplots(ir, true);
        second = m2t2.render.renderPgfplots(ir, true);
        assert(strcmp(first, second));
        assert(~isempty(strfind(first, [char(92) 'addplot+']))); %#ok<STREMP>
        assert(~isempty(strfind(first, [char(92) 'addlegendentry{Hand-built}']))); %#ok<STREMP>
        rows(end + 1, :) = {'hand_built_ir', 'PASS', '', 'renderer'};
    catch err
        failures = failures + 1;
        rows(end + 1, :) = {'hand_built_ir', 'FAIL', oneLine(err.message), 'renderer'};
    end

    try
        basic = handBuiltIR();
        jsonText = jsonencode(basic);
        jsonPath = fullfile(irDirectory, 'line-v2.json');
        writeText(jsonPath, jsonText);
        decoded = m2t2.ir.fromJson(readText(jsonPath));
        direct = m2t2.render.renderPgfplots(basic, true);
        roundTrip = m2t2.render.renderPgfplots(decoded, true);
        assert(strcmp(direct, roundTrip));
        rows(end + 1, :) = {'json_roundtrip', 'PASS', '', 'renderer'};
    catch err
        failures = failures + 1;
        rows(end + 1, :) = {'json_roundtrip', 'FAIL', oneLine(err.message), 'renderer'};
    end

    try
        v1Path = fullfile(repositoryRoot, 'test', 'fixtures', 'ir', 'line-v1.json');
        migrated = m2t2.ir.fromJson(readText(v1Path));
        assert(migrated.version == 2);
        migratedTex = m2t2.render.renderPgfplots(migrated, true);
        assert(~isempty(strfind(migratedTex, [char(92) 'addplot+']))); %#ok<STREMP>
        assert(~isempty(strfind(migratedTex, [char(92) 'addlegendentry{Hand-built}']))); %#ok<STREMP>
        rows(end + 1, :) = {'v1_json_migration', 'PASS', '', 'renderer'};
    catch err
        failures = failures + 1;
        rows(end + 1, :) = {'v1_json_migration', 'FAIL', oneLine(err.message), 'renderer'};
    end

    try
        invalid = handBuiltIR();
        invalid.axes{1}.series{1}.x(2) = Inf;
        try
            m2t2.render.renderPgfplots(invalid, true);
            error('M2T2:ExpectedFailure', 'Invalid IR was rendered.');
        catch err
            assert(strcmp(err.identifier, 'M2T2:E003:InvalidIR'));
        end
        rows(end + 1, :) = {'invalid_ir_inf', 'PASS', '', 'renderer'};
    catch err
        failures = failures + 1;
        rows(end + 1, :) = {'invalid_ir_inf', 'FAIL', oneLine(err.message), 'renderer'};
    end

    try
        multipleAxes = handBuiltIR();
        second = multipleAxes.axes{1}; second.id = 'axes-2';
        second.series{1}.id = 'axes-2-series-1';
        second.legend.entries{1}.seriesId = second.series{1}.id;
        multipleAxes.axes{2} = second;
        tex = m2t2.render.renderPgfplots(multipleAxes, true);
        assert(numel(strfind(tex, [char(92) 'begin{axis}'])) == 2); %#ok<STREMP>
        rows(end + 1, :) = {'multiple_axes_v2_default', 'PASS', '', 'renderer'};
    catch err
        failures = failures + 1;
        rows(end + 1, :) = {'multiple_axes_v2_default', 'FAIL', oneLine(err.message), 'renderer'};
    end

    writeRows(fullfile(outputDirectory, 'renderer-results.tsv'), rows);
    summary = struct('failures', failures, 'tests', size(rows, 1));
    if failures > 0
        error('M2T2:RendererTestsFailed', '%d M2 renderer tests failed.', failures);
    end
end

function ir = handBuiltIR()
    line = m2t2.ir.makeLineSeries();
    line.x = [0 0.5 1]; line.y = [0 0.25 1];
    line.color = [0.2 0.4 0.6]; line.width = 1.25;
    line.style = 'dashed'; line.marker = 'circle'; line.markerSize = 7;
    line.id = 'axes-1-series-1';
    line.displayName = m2t2.ir.makeText('Hand-built', 'plain');
    ax = m2t2.ir.makeAxes();
    ax.xlim = [0 1]; ax.ylim = [0 1];
    ax.xlabel = m2t2.ir.makeText('x_1', 'plain');
    ax.ylabel = m2t2.ir.makeText('y%', 'plain');
    ax.series = {line};
    ax.legend.visible = true;
    ax.legend.entries = {m2t2.ir.makeLegendEntry(line.id, line.displayName)};
    ir = m2t2.ir.makeFigure({ax});
end

function ensureDirectory(path)
    if exist(path, 'dir') ~= 7, mkdir(path); end
end

function writeText(path, value)
    fid = fopen(path, 'w'); cleanup = onCleanup(@() fclose(fid));
    fwrite(fid, value, 'char'); clear cleanup;
end

function value = readText(path)
    fid = fopen(path, 'r'); cleanup = onCleanup(@() fclose(fid));
    value = fread(fid, Inf, '*char')'; clear cleanup;
end

function writeRows(path, rows)
    fid = fopen(path, 'w'); cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, 'case\tstatus\tdetail\tlayer\n');
    for k = 1:size(rows, 1)
        fprintf(fid, '%s\t%s\t%s\t%s\n', rows{k, 1}, rows{k, 2}, rows{k, 3}, rows{k, 4});
    end
    clear cleanup;
end

function value = oneLine(value)
    value = strrep(strrep(value, sprintf('\r'), ' '), sprintf('\n'), ' ');
end
