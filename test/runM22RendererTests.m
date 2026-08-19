function summary = runM22RendererTests(outputDirectory)
%RUNM22RENDERERTESTS Exercise layout rendering with hand-written, figure-free IR.
    root = fileparts(fileparts(mfilename('fullpath')));
    addpath(fullfile(root, 'src'));
    if nargin < 1, outputDirectory = fullfile(root, '.audit', 'm2.2'); end
    tests = {@horizontalAxes,@verticalAxes,@grid2x2,@manualPlacement, ...
             @overlayAxes,@mixedOwnership,@jsonCompatibility,@invalidPlacement};
    names = {'horizontal_axes','vertical_axes','grid_2x2','manual_placement', ...
             'overlay_order','mixed_ownership','json_compatibility','invalid_placement'};
    rows = cell(numel(tests), 4); failures = 0;
    for k = 1:numel(tests)
        try
            tests{k}(outputDirectory); status = 'PASS'; detail = '';
        catch err
            failures = failures + 1; status = 'FAIL'; detail = oneLine(err.message);
        end
        rows(k, :) = {names{k}, status, detail, 'renderer'};
    end
    ensureDirectory(outputDirectory);
    writeRows(fullfile(outputDirectory, 'm22-renderer-results.tsv'), rows);
    summary = struct('failures', failures, 'tests', numel(tests));
    if failures
        error('M2T2:M22RendererTestsFailed', '%d M2.2 renderer tests failed.', failures);
    end
end

function horizontalAxes(~)
    ir = figureWithPlacements([0.08 0.15 0.36 0.72; 0.56 0.15 0.36 0.72]);
    ir.layout = gridLayout(ir.axes, 1, 2);
    tex = m2t2.render.renderPgfplots(ir, true);
    assert(countText(tex, [char(92) 'begin{axis}']) == 2);
    assertContains(tex, 'at={(32pt,45pt)}');
    assertContains(tex, 'width=144pt');
    assertContains(tex, 'at={(224pt,45pt)}');
    assertContains(tex, 'scale only axis');
end

function verticalAxes(~)
    ir = figureWithPlacements([0.15 0.56 0.72 0.36; 0.15 0.08 0.72 0.36]);
    ir.layout = gridLayout(ir.axes, 2, 1);
    tex = m2t2.render.renderPgfplots(ir, true);
    assertContains(tex, 'at={(60pt,168pt)}');
    assertContains(tex, 'at={(60pt,24pt)}');
    assertContains(tex, 'height=108pt');
end

function grid2x2(~)
    placements = [0.08 0.56 0.36 0.36; 0.56 0.56 0.36 0.36; ...
                  0.08 0.08 0.36 0.36; 0.56 0.08 0.36 0.36];
    ir = figureWithPlacements(placements); ir.layout = gridLayout(ir.axes, 2, 2);
    tex = m2t2.render.renderPgfplots(ir, true);
    assert(countText(tex, [char(92) 'begin{axis}']) == 4);
    for k = 1:4, assertContains(tex, ['title={A' num2str(k) '}']); end
end

function manualPlacement(~)
    ir = figureWithPlacements([0.22 0.18 0.61 0.57]);
    tex = m2t2.render.renderPgfplots(ir, true);
    assertContains(tex, 'at={(88pt,54pt)}');
    assertContains(tex, 'width=244pt');
    assertContains(tex, 'height=171pt');
    assertContains(tex, [char(92) 'path[use as bounding box] (0pt,0pt) rectangle (400pt,300pt);']);
end

function overlayAxes(~)
    ir = figureWithPlacements([0.10 0.10 0.62 0.62; 0.28 0.28 0.62 0.62]);
    ir.axes{2}.overlayOf = 'axes-1';
    tex = m2t2.render.renderPgfplots(ir, true);
    back = strfind(tex, 'title={A1}'); front = strfind(tex, 'title={A2}');
    assert(~isempty(back) && ~isempty(front) && back(1) < front(1));
    assertContains(tex, 'at={(40pt,30pt)}');
    assertContains(tex, 'at={(112pt,84pt)}');
end

function mixedOwnership(~)
    first = baseAxes(1, [0.08 0.15 0.36 0.72]);
    first.xticks = m2t2.ir.makeTickSpec('manual', [1 2], ...
        {m2t2.ir.makeText('one'), m2t2.ir.makeText('two')});
    first.series{1}.displayName = m2t2.ir.makeText('Line');
    first.legend.visible = true;
    first.legend.location = 'north_west';
    first.legend.entries = {m2t2.ir.makeLegendEntry(first.series{1}.id, ...
                                                    first.series{1}.displayName)};
    second = m2t2.ir.makeAxes(); second.id = 'axes-2';
    second.placement = placement([0.56 0.15 0.36 0.72]);
    second.title = m2t2.ir.makeText('Mixed');
    scatter = m2t2.ir.makeScatterSeries(); scatter.id = 'axes-2-series-1';
    scatter.x = [1 2]; scatter.y = [2 1]; scatter.displayName = m2t2.ir.makeText('Samples');
    errorbar = m2t2.ir.makeErrorbarSeries(); errorbar.id = 'axes-2-series-2';
    errorbar.x = [1 2]; errorbar.y = [1 2];
    errorbar.xNegative = [0 0]; errorbar.xPositive = [0 0];
    errorbar.yNegative = [0.1 0.2]; errorbar.yPositive = [0.1 0.2];
    errorbar.displayName = m2t2.ir.makeText('Error');
    second.series = {scatter,errorbar}; second.legend.visible = true;
    second.legend.location = 'south_east';
    second.legend.entries = {m2t2.ir.makeLegendEntry(scatter.id, scatter.displayName), ...
                             m2t2.ir.makeLegendEntry(errorbar.id, errorbar.displayName)};
    ir = m2t2.ir.makeFigure({first,second}); ir.size = [400 300];
    ir.layout = gridLayout(ir.axes, 1, 2);
    tex = m2t2.render.renderPgfplots(ir, true);
    assertContains(tex, 'xtick={1,2}'); assertContains(tex, 'xticklabels={{one},{two}}');
    assertContains(tex, 'legend pos=north west'); assertContains(tex, 'legend pos=south east');
    assert(countText(tex, [char(92) 'addlegendentry']) == 3);
    assertContains(tex, 'only marks'); assertContains(tex, 'y error minus=yneg');
end

function jsonCompatibility(outputDirectory)
    ir = figureWithPlacements([0.08 0.15 0.36 0.72; 0.56 0.15 0.36 0.72]);
    ir.layout = gridLayout(ir.axes, 1, 2);
    decoded = m2t2.ir.fromJson(jsonencode(ir));
    assert(strcmp(m2t2.render.renderPgfplots(ir, true), ...
                  m2t2.render.renderPgfplots(decoded, true)));

    old = m2t2.ir.makeFigure({baseAxes(1, [0 0 1 1])});
    old = rmfield(old, {'size','layout'});
    old.axes{1} = rmfield(old.axes{1}, {'placement','overlayOf'});
    migrated = m2t2.ir.fromJson(jsonencode(old));
    assert(isempty(migrated.size)); assert(strcmp(migrated.layout.kind, 'freeform'));
    assertPlacement(migrated.axes{1}.placement, [0 0 1 1]);
    tex = m2t2.render.renderPgfplots(migrated, true);
    assert(isempty(strfind(tex, 'scale only axis'))); %#ok<STREMP>

    ensureDirectory(outputDirectory);
    path = fullfile(outputDirectory, 'layout-v2.json');
    fid = fopen(path, 'w'); cleanup = onCleanup(@() fclose(fid));
    fwrite(fid, jsonencode(ir), 'char'); clear cleanup;
end

function invalidPlacement(~)
    ir = figureWithPlacements([0 0 1 1]); ir.axes{1}.placement.width = 0;
    try
        m2t2.render.renderPgfplots(ir, true);
        error('M2T2:ExpectedFailure', 'Invalid placement was rendered.');
    catch err
        assert(strcmp(err.identifier, 'M2T2:E009:InvalidPlacement'));
    end
end

function ir = figureWithPlacements(values)
    axesItems = cell(1, size(values, 1));
    for k = 1:size(values, 1), axesItems{k} = baseAxes(k, values(k, :)); end
    ir = m2t2.ir.makeFigure(axesItems); ir.size = [400 300];
end

function node = baseAxes(index, values)
    node = m2t2.ir.makeAxes(); node.id = sprintf('axes-%d', index);
    node.placement = placement(values); node.title = m2t2.ir.makeText(sprintf('A%d', index));
    line = m2t2.ir.makeLineSeries(); line.id = sprintf('axes-%d-series-1', index);
    line.x = [1 2 3]; line.y = [index index + 1 index]; node.series = {line};
end

function node = placement(values)
    node = m2t2.ir.makePlacement(values(1), values(2), values(3), values(4));
end

function layout = gridLayout(axesItems, rows, columns)
    cells = cell(1, numel(axesItems));
    for k = 1:numel(axesItems)
        row = floor((k - 1) / columns) + 1; column = mod(k - 1, columns) + 1;
        cells{k} = m2t2.ir.makeLayoutCell(axesItems{k}.id, row, column, 1, 1);
    end
    layout = m2t2.ir.makeLayout('grid', rows, columns, cells);
end

function assertPlacement(node, expected)
    assert(max(abs([node.x node.y node.width node.height] - expected)) < 1e-12);
end

function assertContains(text, value)
    assert(~isempty(strfind(text, value))); %#ok<STREMP>
end

function count = countText(text, value)
    count = numel(strfind(text, value));
end

function ensureDirectory(path)
    if exist(path, 'dir') ~= 7, mkdir(path); end
end

function writeRows(path, rows)
    fid = fopen(path, 'w'); cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, 'case\tstatus\tdetail\tlayer\n');
    for k = 1:size(rows,1)
        fprintf(fid, '%s\t%s\t%s\t%s\n', rows{k,1}, rows{k,2}, rows{k,3}, rows{k,4});
    end
end

function value = oneLine(value)
    value = strrep(value, sprintf('\r'), ' '); value = strrep(value, sprintf('\n'), ' ');
end
