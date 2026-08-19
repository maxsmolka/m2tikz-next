function lines = renderFigureElement(node, figureNode, elementIndex, config)
%RENDERFIGUREELEMENT Render a normalized figure-level node without handles.
    if nargin < 4, config = m2t2.render.defaultConfig(); end
    switch node.kind
        case 'm2t2.colorbar'
            lines = renderColorbar(node, figureNode, elementIndex, config);
        case 'm2t2.legend'
            lines = renderSharedLegend(node, figureNode, config);
        case 'm2t2.sharedlabel'
            lines = renderSharedLabel(node, figureNode.size, config);
        otherwise
            error('M2T2:E003:InvalidIR', 'Unsupported figure element kind %s.', node.kind);
    end
end

function lines = renderColorbar(node, figureNode, elementIndex, config)
    bs = char(92); mapping = mappingFor(node, figureNode);
    mapName = sprintf('m2t2colormap%d', elementIndex);
    stops = cell(1, size(mapping.colormap, 1));
    for k = 1:numel(stops)
        color = mapping.colormap(k, :);
        stops{k} = ['rgb(' m2t2.util.formatNumber(k - 1) 'pt)=(' ...
            m2t2.util.formatNumber(color(1)) ',' ...
            m2t2.util.formatNumber(color(2)) ',' ...
            m2t2.util.formatNumber(color(3)) ')'];
    end
    lines = { [bs 'pgfplotsset{colormap={' mapName '}{' ...
        m2t2.util.joinCell(stops, ';') '}}'] };
    options = {'hide axis','scale only axis','at={(0pt,0pt)}','anchor=south west', ...
               'width=1pt','height=1pt', ...
               ['point meta min=' m2t2.util.formatNumber(node.limits(1))], ...
               ['point meta max=' m2t2.util.formatNumber(node.limits(2))], ...
               ['colormap name=' mapName]};
    if strcmp(node.orientation, 'horizontal')
        options{end + 1} = 'colorbar horizontal'; axisName = 'x';
    else
        options{end + 1} = 'colorbar'; axisName = 'y';
    end
    style = placementStyle(node.placement, figureNode.size);
    style{end + 1} = [axisName ' dir=' node.direction];
    if strcmp(node.scale, 'log'), style{end + 1} = [axisName 'mode=log']; end
    switch node.location
        case 'westoutside', style{end + 1} = 'yticklabel pos=left';
        case 'eastoutside', style{end + 1} = 'yticklabel pos=right';
        case 'northoutside', style{end + 1} = 'xticklabel pos=upper';
        case 'southoutside', style{end + 1} = 'xticklabel pos=lower';
    end
    style = [style, tickStyle(node.ticks, axisName)];
    style = addFontStyle(style, 'tick label style', ...
                         config.typography.colorbarTickLabelPt);
    style = addFontStyle(style, 'label style', ...
                         config.typography.colorbarLabelPt);
    if ~isempty(node.label.value)
        style{end + 1} = [axisName 'label={' m2t2.render.renderText(node.label) '}'];
    end
    options{end + 1} = ['colorbar style={' m2t2.util.joinCell(style, ',') '}'];
    lines{end + 1} = [bs 'begin{axis}['];
    lines = [lines, optionLines(options)];
    lines{end + 1} = ']';
    lines{end + 1} = [bs 'addplot[draw=none] coordinates {(0,0) (1,1)};'];
    lines{end + 1} = [bs 'end{axis}'];
end

function mapping = mappingFor(node, figureNode)
    index = find(cellfun(@(item) strcmp(item.id, node.associatedAxesIds{1}), ...
                        figureNode.axes), 1);
    mapping = figureNode.axes{index}.colorMapping;
end

function lines = renderSharedLegend(node, figureNode, config)
    bs = char(92); p = node.placement; sizeValue = figureNode.size;
    x = p.x * sizeValue(1); y = p.y * sizeValue(2);
    style = ['at={(' m2t2.util.formatNumber(x) 'pt,' ...
        m2t2.util.formatNumber(y) 'pt)},anchor=south west,draw=none'];
    command = m2t2.render.fontCommand(config.typography.legendPt);
    if ~isempty(command), style = [style ',font={' command '}']; end
    options = {'hide axis','scale only axis', ...
               ['at={(' m2t2.util.formatNumber(x) 'pt,' m2t2.util.formatNumber(y) 'pt)}'], ...
               'anchor=south west','width=1pt','height=1pt', ...
               ['legend style={' style '}'],'legend columns=-1'};
    lines = {[bs 'begin{axis}[']}; lines = [lines, optionLines(options)]; lines{end + 1} = ']';
    for k = 1:numel(node.entries)
        entry = node.entries{k}; series = referencedSeries(entry, figureNode);
        color = series.color; colorName = sprintf('m2t2sharedcolor%d', k);
        lines{end + 1} = [bs 'definecolor{' colorName '}{rgb}{' ...
            m2t2.util.formatNumber(color(1)) ',' m2t2.util.formatNumber(color(2)) ',' ...
            m2t2.util.formatNumber(color(3)) '}']; %#ok<AGROW>
        seriesOptions = m2t2.render.seriesOptions(series, colorName);
        seriesOptions(strcmp(seriesOptions, 'forget plot')) = [];
        lines{end + 1} = [bs 'addlegendimage{' m2t2.util.joinCell(seriesOptions, ',') '}']; %#ok<AGROW>
        lines{end + 1} = [bs 'addlegendentry{' m2t2.render.renderText(entry.text) '}']; %#ok<AGROW>
    end
    lines{end + 1} = [bs 'end{axis}'];
end

function series = referencedSeries(entry, figureNode)
    axesIndex = find(cellfun(@(item) strcmp(item.id, entry.axesId), figureNode.axes), 1);
    axesNode = figureNode.axes{axesIndex};
    seriesIndex = find(cellfun(@(item) strcmp(item.id, entry.seriesId), axesNode.series), 1);
    series = axesNode.series{seriesIndex};
end

function lines = renderSharedLabel(node, figureSize, config)
    bs = char(92);
    if isempty(node.placement)
        switch node.role
            case 'title', x = 0.5; y = 0.97; rotation = '';
            case 'xlabel', x = 0.5; y = 0.02; rotation = '';
            otherwise, x = 0.02; y = 0.5; rotation = ',rotate=90';
        end
    else
        x = node.placement.x + node.placement.width / 2;
        y = node.placement.y + node.placement.height / 2;
        if strcmp(node.role, 'ylabel'), rotation = ',rotate=90'; else, rotation = ''; end
    end
    if strcmp(node.role, 'title')
        points = config.typography.titlePt;
    else
        points = config.typography.axesLabelPt;
    end
    command = m2t2.render.fontCommand(points);
    if isempty(command), font = ''; else, font = ['font={' command '},']; end
    lines = {[bs 'node[' font 'anchor=center' rotation '] at (' ...
        m2t2.util.formatNumber(x * figureSize(1)) 'pt,' ...
        m2t2.util.formatNumber(y * figureSize(2)) 'pt) {' ...
        m2t2.render.renderText(node.text) '};']};
end

function style = addFontStyle(style, key, points)
    command = m2t2.render.fontCommand(points);
    if ~isempty(command), style{end + 1} = [key '={font={' command '}}']; end
end

function style = placementStyle(node, figureSize)
    style = {['at={(' m2t2.util.formatNumber(node.x * figureSize(1)) 'pt,' ...
                    m2t2.util.formatNumber(node.y * figureSize(2)) 'pt)}'], ...
             'anchor=south west', ...
             ['width=' m2t2.util.formatNumber(node.width * figureSize(1)) 'pt'], ...
             ['height=' m2t2.util.formatNumber(node.height * figureSize(2)) 'pt']};
end

function options = tickStyle(node, axisName)
    options = {};
    if strcmp(node.mode, 'auto'), return; end
    values = cell(1, numel(node.values)); labels = cell(1, numel(node.labels));
    for k = 1:numel(values)
        values{k} = m2t2.util.formatNumber(node.values(k));
        labels{k} = ['{' m2t2.render.renderText(node.labels{k}) '}'];
    end
    options = {[[axisName 'tick={'] m2t2.util.joinCell(values, ',') '}'], ...
               [[axisName 'ticklabels={'] m2t2.util.joinCell(labels, ',') '}']};
end

function lines = optionLines(options)
    lines = cell(1, numel(options));
    for k = 1:numel(options)
        separator = ','; if k == numel(options), separator = ''; end
        lines{k} = ['  ' options{k} separator];
    end
end
