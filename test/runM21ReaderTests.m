function summary = runM21ReaderTests(outputDirectory)
%RUNM21READERTESTS Assert concrete axes and mixed-series IR semantics.
    root = fileparts(fileparts(mfilename('fullpath'))); addpath(fullfile(root, 'src'));
    if nargin < 1, outputDirectory = fullfile(root, '.audit', 'm2.1'); end
    names = fixtureNames(); rows = cell(numel(names), 4); failures = 0;
    for k = 1:numel(names)
        fig = [];
        try
            fig = createM21Fixture(names{k}); ir = m2t2.reader.readFigure(fig);
            assert(ir.version == 2 && numel(ir.axes) == 1);
            verify(names{k}, ir.axes{1}); status = 'PASS'; detail = '';
        catch err
            failures = failures + 1; status = 'FAIL'; detail = oneLine(err.message);
        end
        if ~isempty(fig) && ishandle(fig), close(fig); end
        rows(k, :) = {names{k}, status, detail, 'reader'};
    end
    [status, detail] = unsupportedHggroup();
    if ~strcmp(status, 'PASS'), failures = failures + 1; end
    rows(end + 1, :) = {'unsupported_arbitrary_hggroup', status, detail, 'reader'}; %#ok<AGROW>
    unsupportedNames = {'3d'};
    for u = 1:numel(unsupportedNames)
        [status, detail] = unsupportedScatter(unsupportedNames{u});
        if ~strcmp(status, 'PASS'), failures = failures + 1; end
        rows(end + 1, :) = {['scatter_unsupported_' unsupportedNames{u}], status, detail, 'reader'}; %#ok<AGROW>
    end
    ensureDirectory(outputDirectory); writeRows(fullfile(outputDirectory, 'm21-reader-results.tsv'), rows);
    summary = struct('failures', failures, 'tests', size(rows, 1));
    if failures, error('M2T2:M21ReaderTestsFailed', '%d M2.1 reader tests failed.', failures); end
end

function verify(name, ax)
    switch name
        case 'manual_x_ticks'
            assert(strcmp(ax.xticks.mode, 'manual'));
            assert(isequal(ax.xticks.values, [0 1 2]));
            assert(strcmp(ax.xticks.labels{2}.value, 'one'));
        case 'manual_y_ticks'
            assert(strcmp(ax.yticks.mode, 'manual'));
            assert(isequal(ax.yticks.values, [0 2 4]));
            assert(strcmp(ax.yticks.labels{3}.value, 'high'));
        case 'reverse_x', assert(strcmp(ax.xdirection, 'reverse'));
        case 'reverse_y', assert(strcmp(ax.ydirection, 'reverse'));
        case 'box_on', assert(strcmp(ax.box, 'on'));
        case 'box_off', assert(strcmp(ax.box, 'off'));
        case 'plain_text'
            assert(strcmp(ax.xlabel.value, 'plain_a_b') && strcmp(ax.xlabel.interpreter, 'plain'));
        case 'tex_text'
            assert(strcmp(ax.ylabel.value, 'x_{1}') && strcmp(ax.ylabel.interpreter, 'tex'));
        case 'latex_text'
            assert(strcmp(ax.title.value, '$x^2$') && strcmp(ax.title.interpreter, 'latex'));
        case 'legend_on'
            assert(ax.legend.visible && strcmp(ax.legend.location, 'south_west'));
            assert(numel(ax.legend.entries) == 2 && strcmp(ax.legend.entries{1}.text.value, 'First'));
        case 'legend_off'
            assert(~ax.legend.visible && isempty(ax.legend.entries));
            assert(strcmp(ax.series{1}.displayName.value, 'Named but hidden'));
        case 'scatter'
            assert(strcmp(ax.series{1}.kind, 'm2t2.scatter'));
            assert(ax.series{1}.markerSize == 7 && numel(ax.series{1}.x) == 4);
        case 'errorbar_symmetric'
            item = ax.series{1}; assert(strcmp(item.kind, 'm2t2.errorbar'));
            assert(isequal(item.yNegative, item.yPositive));
        case 'errorbar_asymmetric'
            item = ax.series{1}; assert(strcmp(item.kind, 'm2t2.errorbar'));
            assert(~isequal(item.yNegative, item.yPositive));
            assert(abs(item.yNegative(1) - 0.1) < 1e-12 && abs(item.yPositive(4) - 0.5) < 1e-12);
        case 'mixed_line_scatter'
            assertKinds(ax, {'m2t2.line','m2t2.scatter'});
            assert(numel(ax.legend.entries) == 2);
        case 'mixed_line_errorbar'
            assertKinds(ax, {'m2t2.line','m2t2.errorbar'});
            assert(numel(ax.legend.entries) == 2);
    end
end

function assertKinds(ax, expected)
    assert(numel(ax.series) == numel(expected));
    for k = 1:numel(expected), assert(strcmp(ax.series{k}.kind, expected{k})); end
end

function [status, detail] = unsupportedScatter(kind)
    fig = figure('Visible', 'off');
    try
        expectedIdentifier = 'M2T2:E045:UnsupportedScatterDimensionality';
        switch kind
            case '3d'
                scatter3(1:3, 1:3, 1:3, 36, [1 0 0]);
                expected = 'ZData';
        end
        try
            m2t2.reader.readFigure(fig); status = 'FAIL'; detail = ['unsupported scatter ' kind ' was accepted'];
        catch err
            valid = strcmp(err.identifier, expectedIdentifier) && ...
                    ~isempty(strfind(err.message, expected)); %#ok<STREMP>
            if valid, status = 'PASS'; detail = err.message; else, status = 'FAIL'; detail = err.message; end
        end
    catch err, status = 'FAIL'; detail = err.message;
    end
    close(fig); detail = oneLine(detail);
end

function [status, detail] = unsupportedHggroup()
    fig = figure('Visible', 'off');
    try
        ax = axes('Parent', fig);
        group = hggroup('Parent', ax);
        line('Parent', group, 'XData', 1:3, 'YData', 1:3);
        try
            m2t2.reader.readFigure(fig);
            status = 'FAIL'; detail = 'arbitrary hggroup was accepted';
        catch err
            valid = strcmp(err.identifier, 'M2T2:E001:UnsupportedObject') && ...
                    ~isempty(strfind(err.message, 'type=hggroup')); %#ok<STREMP>
            if valid, status = 'PASS'; detail = err.message;
            else, status = 'FAIL'; detail = err.message; end
        end
    catch err, status = 'FAIL'; detail = err.message;
    end
    close(fig); detail = oneLine(detail);
end

function names = fixtureNames()
    names = {'manual_x_ticks','manual_y_ticks','reverse_x','reverse_y','box_on','box_off', ...
             'plain_text','tex_text','latex_text','legend_on','legend_off','scatter', ...
             'errorbar_symmetric','errorbar_asymmetric','mixed_line_scatter','mixed_line_errorbar'};
end

function ensureDirectory(path), if exist(path, 'dir') ~= 7, mkdir(path); end, end
function writeRows(path, rows)
    fid=fopen(path,'w'); cleanup=onCleanup(@() fclose(fid)); fprintf(fid,'case\tstatus\tdetail\tlayer\n');
    for k=1:size(rows,1), fprintf(fid,'%s\t%s\t%s\t%s\n',rows{k,:}); end; clear cleanup;
end
function value=oneLine(value), value=strrep(strrep(value,sprintf('\r'),' '),sprintf('\n'),' '); end
