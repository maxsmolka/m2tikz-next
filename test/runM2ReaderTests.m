function summary = runM2ReaderTests(outputDirectory)
%RUNM2READERTESTS Exercise handle-to-IR normalization independently.
    repositoryRoot = fileparts(fileparts(mfilename('fullpath')));
    if nargin < 1
        outputDirectory = fullfile(repositoryRoot, '.audit', 'm2');
    end
    addpath(fullfile(repositoryRoot, 'src'));
    names = fixtureNames();
    rows = cell(numel(names), 4);
    failures = 0;
    for k = 1:numel(names)
        fig = [];
        expectedResult = 'fixture creation did not complete';
        actualResult = 'reader did not return an axes IR';
        try
            [fig, expected] = createM2LineFixture(names{k});
            expectedResult = summarizeExpected(names{k}, expected);
            ir = m2t2.reader.readFigure(fig);
            try
                actualResult = summarizeActual(names{k}, ir.axes{1});
            catch summaryError
                actualResult = ['axes IR summary failed: ' oneLine(summaryError.message)];
            end
            assert(strcmp(ir.kind, 'm2t2.figure'));
            assert(ir.version == 2 && numel(ir.axes) == 1);
            ax = ir.axes{1};
            assert(numel(ax.series) == expected.seriesCount);
            assert(strcmp(ax.xscale, expected.xscale));
            assert(strcmp(ax.yscale, expected.yscale));
            assert(strcmp(ax.xlabel.value, expected.xlabel));
            assert(strcmp(ax.ylabel.value, expected.ylabel));
            assert(strcmp(ax.title.value, expected.title));
            verifySpecialCase(names{k}, ax);
            status = 'PASS'; detail = '';
        catch err
            status = 'FAIL';
            detail = failureDetail(expectedResult, actualResult, err.identifier, err.message);
            failures = failures + 1;
        end
        if ~isempty(fig) && ishandle(fig), close(fig); end
        rows(k, :) = {names{k}, status, detail, 'reader'};
    end

    [decorationStatus, decorationDetail] = verifyLegendDecoration();
    if ~strcmp(decorationStatus, 'PASS'), failures = failures + 1; end
    rows(end + 1, :) = {'legend_runtime_decoration', decorationStatus, ...
                        decorationDetail, 'reader'};
    [textStatus, textDetail] = verifySupportedUserText();
    if ~strcmp(textStatus, 'PASS'), failures = failures + 1; end
    rows(end + 1, :) = {'semantic_user_text', textStatus, textDetail, 'reader'};
    [barStatus, barDetail] = verifyGroupedBar();
    if ~strcmp(barStatus, 'PASS'), failures = failures + 1; end
    rows(end + 1, :) = {'semantic_grouped_bar', barStatus, barDetail, 'reader'};
    ensureDirectory(outputDirectory);
    resultPath = fullfile(outputDirectory, 'reader-results.tsv');
    writeRows(resultPath, rows);
    summary = struct('failures', failures, 'tests', size(rows, 1));
    if failures > 0
        fprintf(2, 'M2 reader fixture diagnostics from %s:\n', resultPath);
        fprintf(2, '%s', fileread(resultPath));
        error('M2T2:ReaderTestsFailed', '%d M2 reader tests failed.', failures);
    end
end

function verifySpecialCase(name, ax)
    switch name
        case 'styled'
            s = ax.series{1};
            assert(strcmp(s.style, 'dashed') && strcmp(s.marker, 'circle'));
            assert(abs(s.width - 2) < eps && abs(s.markerSize - 8) < eps);
            assert(max(abs(s.color - [1 0 0])) < eps);
        case 'display_name'
            assert(strcmp(ax.series{1}.displayName.value, 'Measured'));
            assert(strcmp(ax.series{2}.displayName.value, 'Reference'));
            assert(ax.legend.visible && numel(ax.legend.entries) == 2);
        case 'nan_gap'
            assert(isnan(ax.series{1}.x(3)) && isnan(ax.series{1}.y(3)));
        case 'inf_gap'
            assert(isnan(ax.series{1}.x(3)) && isnan(ax.series{1}.y(3)));
            assert(~any(isinf(ax.series{1}.x)) && ~any(isinf(ax.series{1}.y)));
        case 'empty'
            assert(isempty(ax.series{1}.x) && isempty(ax.series{1}.y));
    end
end

function [status, detail] = verifyLegendDecoration()
    fig = figure('Visible', 'off');
    try
        ax = axes('Parent', fig);
        plot(ax, 1:3, [1 3 2], 'DisplayName', 'Measured');
        legendHandle = legend(ax, 'show');
        decoration = findall(ax, 'Type', 'text', 'Tag', 'deletelegend');
        synthesized = false;
        if isempty(decoration) && supportsSyntheticLegendDecoration(ax, legendHandle)
            decoration = text(ax, 0, 0, '', 'Tag', 'deletelegend', ...
                              'Visible', 'off', 'HandleVisibility', 'off');
            set(decoration, 'DeleteFcn', ...
                {@noopLegendDecoration, ax, legendHandle});
            synthesized = true;
        end
        ir = m2t2.reader.readFigure(fig);
        valid = numel(ir.axes) == 1 && numel(ir.axes{1}.series) == 1 && ...
                ir.axes{1}.legend.visible && ...
                numel(ir.axes{1}.legend.entries) == 1 && ...
                strcmp(ir.axes{1}.legend.entries{1}.text.value, 'Measured');
        if valid
            if ~isempty(decoration) || synthesized
                detail = 'owned legend runtime decoration ignored';
            else
                detail = 'runtime exposes no owned axes-text decoration; native legend semantics preserved';
            end
            status = 'PASS';
        else
            status = 'FAIL';
            detail = 'legend semantics changed after ignoring owned runtime decoration';
        end
    catch err
        status = 'FAIL';
        detail = failureDetail('owned legend runtime decoration is ignored', ...
                               'reader raised an exception', ...
                               err.identifier, err.message);
    end
    close(fig);
end

function yes = supportsSyntheticLegendDecoration(ax, legendHandle)
    yes = false;
    try
        linkedLegend = get(ax, '__legend_handle__');
        yes = ishandle(legendHandle) && strcmp(get(legendHandle, 'Type'), 'axes') && ...
              strcmp(get(legendHandle, 'Tag'), 'legend') && ...
              any(linkedLegend == legendHandle);
    catch
        yes = false;
    end
end

function noopLegendDecoration(~, ~, ~, ~)
end

function [status, detail] = verifySupportedUserText()
    fig = figure('Visible', 'off');
    try
        ax = axes('Parent', fig);
        plot(ax, 1:3, [1 2 3]);
        text(ax, 2, 2, 'User annotation', 'Rotation', 15, ...
             'HorizontalAlignment', 'center', 'Color', [0.2 0.3 0.4]);
        ir = m2t2.reader.readFigure(fig);
        valid = numel(ir.annotations) == 1 && ...
            strcmp(ir.annotations{1}.kind, 'm2t2.textannotation') && ...
            strcmp(ir.annotations{1}.owner.id, 'axes-1') && ...
            strcmp(ir.annotations{1}.coordinateSpace, 'axes_data') && ...
            isequal(ir.annotations{1}.position, [2 2]) && ...
            strcmp(ir.annotations{1}.text.value, 'User annotation') && ...
            ir.annotations{1}.rotation == 15;
        assert(valid);
        status = 'PASS'; detail = 'axes text normalized as explicit semantic annotation';
    catch err
        status = 'FAIL';
        detail = failureDetail('semantic axes-owned text annotation', ...
                               'reader failed or changed semantics', err.identifier, err.message);
    end
    close(fig);
end

function [status, detail] = verifyGroupedBar()
    fig = figure('Visible', 'off');
    expectedResult = 'one explicit vertical grouped BarSeriesIR';
    try
        bar(1:3, 1:3);
        try
            ir = m2t2.reader.readFigure(fig); item = ir.axes{1}.series{1};
            valid = numel(ir.axes{1}.series) == 1 && ...
                    strcmp(item.kind, 'm2t2.bar') && ...
                    strcmp(item.mode, 'grouped') && ...
                    strcmp(item.orientation, 'vertical') && ...
                    isequal(item.categories, [1 2 3]) && ...
                    isequal(item.values, [1 2 3]);
            assert(valid); status = 'PASS';
            detail = 'grouped bar normalized as explicit semantic series';
        catch err
            status = 'FAIL';
            actualResult = ['identifier=' identifierText(err.identifier) ...
                            ', message=' oneLine(err.message)];
            detail = failureDetail(expectedResult, actualResult, ...
                                   err.identifier, err.message);
        end
    catch err
        status = 'FAIL';
        detail = failureDetail(expectedResult, 'grouped-bar fixture creation failed', ...
                               err.identifier, err.message);
    end
    close(fig);
end

function value = summarizeExpected(name, expected)
    value = sprintf(['seriesCount=%d, xscale=%s, yscale=%s, xlabel="%s", ' ...
                     'ylabel="%s", title="%s"'], ...
                    expected.seriesCount, expected.xscale, expected.yscale, ...
                    expected.xlabel, expected.ylabel, expected.title);
    switch name
        case 'styled'
            value = [value ', style=dashed, marker=circle, width=2, ' ...
                     'markerSize=8, color=[1 0 0]'];
        case 'display_name'
            value = [value ', displayNames=[Measured,Reference], ' ...
                     'legendVisible=true, legendEntries=2'];
        case 'nan_gap'
            value = [value ', x(3)=NaN, y(3)=NaN'];
        case 'inf_gap'
            value = [value ', x(3)=NaN, y(3)=NaN, containsInf=false'];
        case 'empty'
            value = [value ', xCount=0, yCount=0'];
    end
end

function value = summarizeActual(name, ax)
    value = sprintf(['seriesCount=%d, xscale=%s, yscale=%s, xlabel="%s", ' ...
                     'ylabel="%s", title="%s"'], ...
                    numel(ax.series), ax.xscale, ax.yscale, ax.xlabel.value, ...
                    ax.ylabel.value, ax.title.value);
    switch name
        case 'styled'
            s = ax.series{1};
            value = sprintf(['%s, style=%s, marker=%s, width=%g, ' ...
                             'markerSize=%g, color=%s'], value, s.style, ...
                            s.marker, s.width, s.markerSize, mat2str(s.color));
        case 'display_name'
            names = cellfun(@(s) s.displayName.value, ax.series, ...
                            'UniformOutput', false);
            value = sprintf('%s, displayNames=[%s], legendVisible=%s, legendEntries=%d', ...
                            value, strjoin(names, ','), ...
                            logicalText(ax.legend.visible), numel(ax.legend.entries));
        case {'nan_gap','inf_gap'}
            s = ax.series{1};
            value = sprintf('%s, x(3)=%g, y(3)=%g, containsInf=%s', ...
                            value, s.x(3), s.y(3), ...
                            logicalText(any(isinf(s.x)) || any(isinf(s.y))));
        case 'empty'
            s = ax.series{1};
            value = sprintf('%s, xCount=%d, yCount=%d', ...
                            value, numel(s.x), numel(s.y));
    end
end

function value = failureDetail(expectedResult, actualResult, identifier, message)
    value = sprintf('expected={%s}; actual={%s}; error={%s: %s}', ...
                    oneLine(expectedResult), oneLine(actualResult), ...
                    identifierText(identifier), oneLine(message));
end

function value = identifierText(value)
    if isempty(value), value = '<none>'; end
end

function value = logicalText(value)
    if value, value = 'true'; else, value = 'false'; end
end

function names = fixtureNames()
    names = {'minimal','multiple','styled','labels','display_name', ...
             'log_x','log_y','nan_gap','inf_gap','empty'};
end

function ensureDirectory(path)
    if exist(path, 'dir') ~= 7, mkdir(path); end
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
    value = strrep(strrep(strrep(value, sprintf('\r'), ' '), ...
                         sprintf('\n'), ' '), sprintf('\t'), ' ');
end
