function summary = runM22ReaderTests(outputDirectory)
%RUNM22READERTESTS Verify concrete layout geometry and axes ownership fields.
    root = fileparts(fileparts(mfilename('fullpath')));
    addpath(fullfile(root, 'src'));
    if nargin < 1, outputDirectory = fullfile(root, '.audit', 'm2.2'); end
    names = {'two_independent','subplot_2x1','subplot_1x2','subplot_2x2', ...
             'manual_position','unequal_widths','unequal_heights', ...
             'overlapping_axes','different_scales','mixed_series_axes'};
    rows = cell(numel(names) + 2, 4);
    failures = 0;
    for k = 1:numel(names)
        fig = [];
        try
            fig = createM22LayoutFixture(names{k});
            ir = m2t2.reader.readFigure(fig);
            assertCommon(ir);
            assertFixture(names{k}, ir);
            status = 'PASS'; detail = '';
        catch err
            failures = failures + 1; status = 'FAIL'; detail = oneLine(err.message);
        end
        if ~isempty(fig) && ishandle(fig), close(fig); end
        rows(k, :) = {names{k}, status, detail, 'reader'};
    end
    try
        fig = figure('Visible', 'off');
        axes('Parent', fig, 'Units', 'normalized', 'Position', [-0.1 0.1 0.5 0.5]);
        try
            m2t2.reader.readFigure(fig);
            error('M2T2:ExpectedFailure', 'Invalid placement was accepted.');
        catch err
            assert(strcmp(err.identifier, 'M2T2:E009:InvalidPlacement'));
            detail = oneLine(err.message);
        end
        close(fig); status = 'PASS';
    catch err
        if exist('fig', 'var') && ishandle(fig), close(fig); end
        failures = failures + 1; status = 'FAIL'; detail = oneLine(err.message);
    end
    rows(numel(names) + 1, :) = {'invalid_placement', status, detail, 'reader'};
    try
        fig = figure('Visible', 'off');
        first = subplot(1, 2, 1, 'Parent', fig);
        plot(first, 1:3, 'DisplayName', 'First'); legendHandle = legend(first, 'show');
        second = subplot(1, 2, 2, 'Parent', fig); plot(second, 1:3);
        if hasMutableLegendOwnerAppData(legendHandle)
            rmappdata(legendHandle, '__axes_handle__');
            try
                m2t2.reader.readFigure(fig);
                error('M2T2:ExpectedFailure', 'Unowned legend was accepted.');
            catch err
                assert(strcmp(err.identifier, 'M2T2:E010:UnsupportedSharedLegend'));
                detail = oneLine(err.message);
            end
        else
            ir = m2t2.reader.readFigure(fig);
            assert(ir.axes{1}.legend.visible && ~ir.axes{2}.legend.visible);
            detail = 'runtime legend ownership is not mutable through appdata; native ownership preserved';
        end
        close(fig); status = 'PASS';
    catch err
        if exist('fig', 'var') && ishandle(fig), close(fig); end
        failures = failures + 1; status = 'FAIL'; detail = oneLine(err.message);
    end
    rows(end, :) = {'unsupported_shared_legend', status, detail, 'reader'};
    ensureDirectory(outputDirectory);
    writeRows(fullfile(outputDirectory, 'm22-reader-results.tsv'), rows);
    summary = struct('failures', failures, 'tests', size(rows, 1));
    if failures
        error('M2T2:M22ReaderTestsFailed', '%d M2.2 reader tests failed.', failures);
    end
end

function yes = hasMutableLegendOwnerAppData(legendHandle)
    yes = false;
    try
        yes = isappdata(legendHandle, '__axes_handle__');
    catch
        yes = false;
    end
end

function assertCommon(ir)
    assert(ir.version == 2);
    assert(max(abs(ir.size - [432 324])) < 1e-8);
    ids = cellfun(@(item) item.id, ir.axes, 'UniformOutput', false);
    for k = 1:numel(ids), assert(strcmp(ids{k}, sprintf('axes-%d', k))); end
    for k = 1:numel(ir.axes)
        p = ir.axes{k}.placement;
        assert(all(isfinite([p.x p.y p.width p.height])));
        assert(p.x >= 0 && p.y >= 0 && p.width > 0 && p.height > 0);
        assert(p.x + p.width <= 1 + 1e-10 && p.y + p.height <= 1 + 1e-10);
    end
end

function assertFixture(name, ir)
    switch name
        case 'two_independent'
            assert(numel(ir.axes) == 2 && strcmp(ir.layout.kind, 'freeform'));
            assertPlacement(ir.axes{1}.placement, [0.10 0.55 0.35 0.35]);
            assertPlacement(ir.axes{2}.placement, [0.55 0.10 0.35 0.35]);
        case 'subplot_2x1'
            assertGrid(ir, 2, 1); assert(ir.axes{1}.placement.y > ir.axes{2}.placement.y);
            assertCell(ir.layout.cells{1}, 'axes-1', 1, 1);
            assertCell(ir.layout.cells{2}, 'axes-2', 2, 1);
        case 'subplot_1x2'
            assertGrid(ir, 1, 2); assert(ir.axes{1}.placement.x < ir.axes{2}.placement.x);
            assertCell(ir.layout.cells{1}, 'axes-1', 1, 1);
            assertCell(ir.layout.cells{2}, 'axes-2', 1, 2);
        case 'subplot_2x2'
            assertGrid(ir, 2, 2); assert(numel(ir.axes) == 4);
            expected = [1 1;1 2;2 1;2 2];
            for k = 1:4
                assertCell(ir.layout.cells{k}, sprintf('axes-%d', k), expected(k,1), expected(k,2));
            end
        case 'manual_position'
            assert(numel(ir.axes) == 1 && strcmp(ir.layout.kind, 'freeform'));
            assertPlacement(ir.axes{1}.placement, [0.22 0.18 0.61 0.57]);
        case 'unequal_widths'
            assertGrid(ir, 1, 2);
            assert(ir.axes{1}.placement.width < ir.axes{2}.placement.width);
            assertPlacement(ir.axes{1}.placement, [0.08 0.18 0.25 0.68]);
            assertPlacement(ir.axes{2}.placement, [0.43 0.18 0.50 0.68]);
        case 'unequal_heights'
            assertGrid(ir, 2, 1);
            assert(ir.axes{1}.placement.height < ir.axes{2}.placement.height);
            assertPlacement(ir.axes{1}.placement, [0.18 0.08 0.68 0.25]);
            assertPlacement(ir.axes{2}.placement, [0.18 0.43 0.68 0.50]);
        case 'overlapping_axes'
            assert(numel(ir.axes) == 2 && strcmp(ir.layout.kind, 'freeform'));
            assert(strcmp(ir.axes{2}.overlayOf, 'axes-1'));
            assert(strcmp(ir.axes{1}.title.value, 'Back'));
            assert(strcmp(ir.axes{2}.title.value, 'Front'));
        case 'different_scales'
            assertGrid(ir, 1, 2);
            assert(strcmp(ir.axes{1}.yscale, 'linear'));
            assert(strcmp(ir.axes{2}.yscale, 'log'));
        case 'mixed_series_axes'
            assertGrid(ir, 1, 2);
            assert(numel(ir.axes{1}.series) == 1);
            assert(strcmp(ir.axes{1}.series{1}.kind, 'm2t2.line'));
            assert(ir.axes{1}.legend.visible && strcmp(ir.axes{1}.legend.location, 'north_west'));
            assert(numel(ir.axes{2}.series) == 2);
            assert(strcmp(ir.axes{2}.series{1}.kind, 'm2t2.scatter'));
            assert(strcmp(ir.axes{2}.series{2}.kind, 'm2t2.errorbar'));
            assert(ir.axes{2}.legend.visible && strcmp(ir.axes{2}.legend.location, 'south_east'));
            assert(all(cellfun(@(entry) strncmp(entry.seriesId, 'axes-2-', 7), ...
                               ir.axes{2}.legend.entries)));
    end
end

function assertGrid(ir, rows, columns)
    assert(strcmp(ir.layout.kind, 'grid'));
    assert(ir.layout.rows == rows && ir.layout.columns == columns);
    assert(numel(ir.axes) == rows * columns);
end

function assertPlacement(node, expected)
    actual = [node.x node.y node.width node.height];
    assert(max(abs(actual - expected)) < 1e-8);
end

function assertCell(node, axesId, row, column)
    assert(strcmp(node.axesId, axesId));
    assert(node.row == row && node.column == column);
    assert(node.rowSpan == 1 && node.columnSpan == 1);
end

function ensureDirectory(path)
    if exist(path, 'dir') ~= 7, mkdir(path); end
end

function writeRows(path, rows)
    fid = fopen(path, 'w'); cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, 'case\tstatus\tdetail\tlayer\n');
    for k = 1:size(rows, 1)
        fprintf(fid, '%s\t%s\t%s\t%s\n', rows{k,1}, rows{k,2}, rows{k,3}, rows{k,4});
    end
end

function value = oneLine(value)
    value = strrep(value, sprintf('\r'), ' '); value = strrep(value, sprintf('\n'), ' ');
end
