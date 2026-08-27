function lines = renderAxes(node, axesIndex, figureSize, config, annotations)
%RENDERAXES Render normalized axes semantics and discriminated series.
    if nargin < 3, figureSize = zeros(1, 0); end
    if nargin < 4, config = m2t2.render.defaultConfig(); end
    if nargin < 5, annotations = {}; end
    lines = {};
    bs = char(92);
    for s = 1:numel(node.series)
        if strcmp(node.series{s}.kind, 'm2t2.image'), continue; end
        if strcmp(node.series{s}.kind, 'm2t2.surface'), continue; end
        if strcmp(node.series{s}.kind,'m2t2.bar')
            color=node.series{s}.faceColor;
        elseif strcmp(node.series{s}.kind,'m2t2.boxplot')
            color=node.series{s}.boxColor;
        elseif strcmp(node.series{s}.kind,'m2t2.patch3')
            color=node.series{s}.faceColor;
        else
            color = node.series{s}.color;
        end
        name = colorName(axesIndex, s);
        lines{end + 1} = [bs 'definecolor{' name '}{rgb}{' ...
            m2t2.util.formatNumber(color(1)) ',' ...
            m2t2.util.formatNumber(color(2)) ',' ...
            m2t2.util.formatNumber(color(3)) '}']; %#ok<AGROW>
        if strcmp(node.series{s}.kind,'m2t2.scatter')
            lines{end+1}=rgbDefinition([name 'edge'],node.series{s}.edgeColor); %#ok<AGROW>
            lines{end+1}=rgbDefinition([name 'face'],node.series{s}.faceColor); %#ok<AGROW>
        elseif strcmp(node.series{s}.kind,'m2t2.bar')
            edge=node.series{s}.edgeColor;
            lines{end+1}=[bs 'definecolor{' name 'edge}{rgb}{' ...
                m2t2.util.formatNumber(edge(1)) ',' m2t2.util.formatNumber(edge(2)) ',' ...
                m2t2.util.formatNumber(edge(3)) '}']; %#ok<AGROW>
        elseif strcmp(node.series{s}.kind,'m2t2.boxplot')
            roleNames={'box','median','whisker','outlier'};fields={'boxColor','medianColor','whiskerColor','outlierColor'};
            for roleIndex=1:numel(roleNames),roleColor=node.series{s}.(fields{roleIndex});lines{end+1}=[bs 'definecolor{' name roleNames{roleIndex} '}{rgb}{' m2t2.util.formatNumber(roleColor(1)) ',' m2t2.util.formatNumber(roleColor(2)) ',' m2t2.util.formatNumber(roleColor(3)) '}'];end %#ok<AGROW>
        elseif strcmp(node.series{s}.kind,'m2t2.patch3')
            edge=node.series{s}.edgeColor;
            lines{end+1}=[bs 'definecolor{' name 'edge}{rgb}{' ...
                m2t2.util.formatNumber(edge(1)) ',' m2t2.util.formatNumber(edge(2)) ',' ...
                m2t2.util.formatNumber(edge(3)) '}']; %#ok<AGROW>
        end
    end
    hasScalarColor = any(cellfun(@(item) strcmp(item.kind,'m2t2.surface') || ...
        (strcmp(item.kind,'m2t2.image') && strcmp(item.colorMode,'scalar')) || ...
        (strcmp(item.kind,'m2t2.scatter') && strcmp(item.colorMode,'scalar_mapped')), ...
        node.series));
    if hasScalarColor
        lines{end + 1} = colormapDefinition(node.colorMapping.colormap, ...
                                            colormapName(axesIndex));
    end

    options = { ...
        ['xmin=' m2t2.util.formatNumber(node.xlim(1))], ...
        ['xmax=' m2t2.util.formatNumber(node.xlim(2))], ...
        ['ymin=' m2t2.util.formatNumber(node.ylim(1))], ...
        ['ymax=' m2t2.util.formatNumber(node.ylim(2))], ...
        ['xmode=' node.xscale], ['ymode=' node.yscale], ...
        ['x dir=' node.xdirection], ['y dir=' node.ydirection], ...
        boxOption(node.box), ...
        ['xlabel={' m2t2.render.renderText(node.xlabel) '}'], ...
        ['ylabel={' m2t2.render.renderText(node.ylabel) '}'], ...
        ['title={' m2t2.render.renderText(node.title) '}'], ...
        ['xmajorgrids=' booleanText(node.xgrid)], ...
        ['ymajorgrids=' booleanText(node.ygrid)], ...
        'unbounded coords=jump'};
    if hasScalarColor
        options{end + 1} = ['point meta min=' ...
            m2t2.util.formatNumber(node.colorMapping.limits(1))];
        options{end + 1} = ['point meta max=' ...
            m2t2.util.formatNumber(node.colorMapping.limits(2))];
        options{end + 1} = ['colormap name=' colormapName(axesIndex)];
    end
    if node.dimensionality == 3
        ratios = 1 ./ node.dataAspectRatio;
        ratios = ratios / min(ratios);
        options = [options, { ...
            ['zmin=' m2t2.util.formatNumber(node.zlim(1))], ...
            ['zmax=' m2t2.util.formatNumber(node.zlim(2))], ...
            ['zmode=' node.zscale], ['z dir=' node.zdirection], ...
            ['zlabel={' m2t2.render.renderText(node.zlabel) '}'], ...
            ['zmajorgrids=' booleanText(node.zgrid)], ...
            ['view={' m2t2.util.formatNumber(node.view(1)) '}{' ...
                m2t2.util.formatNumber(node.view(2)) '}'], ...
            ['unit vector ratio*={' m2t2.util.formatNumber(ratios(1)) ' ' ...
                m2t2.util.formatNumber(ratios(2)) ' ' ...
                m2t2.util.formatNumber(ratios(3)) '}']}];
    end
    if isfield(config, 'imageBackend') && strcmp(config.imageBackend, 'hybrid')
        options{end + 1} = 'axis on top';
    end
    options = [options, typographyOptions(config.typography)];
    if ~isempty(figureSize)
        placement = placementOptions(node.placement, figureSize);
        options = [placement, options];
    end
    options = [options, tickOptions(node.xticks, 'x'), tickOptions(node.yticks, 'y')];
    if node.dimensionality == 3, options = [options, tickOptions(node.zticks, 'z')]; end
    if node.legend.visible
        options{end + 1} = ['legend pos=' legendPosition(node.legend.location)];
    end
    lines{end + 1} = [bs 'begin{axis}['];
    for k = 1:numel(options)
        separator = ','; if k == numel(options), separator = ''; end
        lines{end + 1} = ['  ' options{k} separator]; %#ok<AGROW>
    end
    lines{end + 1} = ']';
    for s = 1:numel(node.series)
        if ~node.series{s}.visible, continue; end
        if strcmp(node.series{s}.kind, 'm2t2.image') && ...
                isfield(config, 'imageBackend') && ...
                strcmp(config.imageBackend, 'hybrid')
            asset = config.imageReferences{axesIndex}{s};
            seriesLines = m2t2.render.renderHybridImage( ...
                asset.reference, asset.xExtent, asset.yExtent);
        else
            seriesLines = m2t2.render.renderSeries( ...
                node.series{s}, colorName(axesIndex, s), colormapName(axesIndex), ...
                node.colorMapping);
        end
        lines = [lines, seriesLines]; %#ok<AGROW>
    end
    if node.legend.visible
        legendLines = renderLegend(node, axesIndex);
        lines = [lines, legendLines]; %#ok<AGROW>
    end
    for k = 1:numel(annotations)
        if ~annotations{k}.visible, continue; end
        annotationLines = m2t2.render.renderTextAnnotation(annotations{k}, ...
            axesIndex * 1000 + k);
        lines = [lines, annotationLines]; %#ok<AGROW>
    end
    lines{end + 1} = [bs 'end{axis}'];
end

function line = rgbDefinition(name, color)
    bs=char(92);
    line=[bs 'definecolor{' name '}{rgb}{' ...
        m2t2.util.formatNumber(color(1)) ',' ...
        m2t2.util.formatNumber(color(2)) ',' ...
        m2t2.util.formatNumber(color(3)) '}'];
end

function line = colormapDefinition(map, name)
    bs = char(92); stops = cell(1, size(map, 1));
    for k = 1:numel(stops)
        stops{k} = ['rgb(' m2t2.util.formatNumber(k - 1) 'pt)=(' ...
            m2t2.util.formatNumber(map(k, 1)) ',' ...
            m2t2.util.formatNumber(map(k, 2)) ',' ...
            m2t2.util.formatNumber(map(k, 3)) ')'];
    end
    line = [bs 'pgfplotsset{colormap={' name '}{' ...
            m2t2.util.joinCell(stops, ';') '}}'];
end

function name = colormapName(axesIndex)
    name = sprintf('m2t2axescolormap%d', axesIndex);
end

function options = typographyOptions(typography)
    options = {};
    options = addFontOption(options, 'font', typography.basePt, false);
    options = addFontOption(options, 'label style', typography.axesLabelPt, true);
    options = addFontOption(options, 'title style', typography.titlePt, true);
    options = addFontOption(options, 'tick label style', typography.tickLabelPt, true);
    options = addFontOption(options, 'legend style', typography.legendPt, true);
end

function options = addFontOption(options, key, points, style)
    command = m2t2.render.fontCommand(points);
    if isempty(command), return; end
    if style
        options{end + 1} = [key '={font={' command '}}'];
    else
        options{end + 1} = [key '={' command '}'];
    end
end

function options = placementOptions(node, figureSize)
    x = node.x * figureSize(1);
    y = node.y * figureSize(2);
    width = node.width * figureSize(1);
    height = node.height * figureSize(2);
    options = {['at={(' m2t2.util.formatNumber(x) 'pt,' ...
                     m2t2.util.formatNumber(y) 'pt)}'], ...
               'anchor=south west', ...
               ['width=' m2t2.util.formatNumber(width) 'pt'], ...
               ['height=' m2t2.util.formatNumber(height) 'pt'], ...
               'scale only axis'};
end

function options = tickOptions(node, axisName)
    options = {};
    if strcmp(node.mode, 'auto'), return; end
    values = cell(1, numel(node.values));
    labels = cell(1, numel(node.labels));
    for k = 1:numel(values)
        values{k} = m2t2.util.formatNumber(node.values(k));
        labels{k} = ['{' m2t2.render.renderText(node.labels{k}) '}'];
    end
    options = {[[axisName 'tick={'] m2t2.util.joinCell(values, ',') '}'], ...
               [[axisName 'ticklabels={'] m2t2.util.joinCell(labels, ',') '}']};
end

function lines = renderLegend(node, axesIndex)
    bs = char(92); lines = {};
    for k = 1:numel(node.legend.entries)
        entry = node.legend.entries{k};
        index = find(cellfun(@(item) strcmp(item.id, entry.seriesId), node.series), 1);
        options = m2t2.render.seriesOptions(node.series{index}, colorName(axesIndex, index));
        options(strcmp(options, 'forget plot')) = [];
        lines{end + 1} = [bs 'addlegendimage{' m2t2.util.joinCell(options, ',') '}']; %#ok<AGROW>
        lines{end + 1} = [bs 'addlegendentry{' m2t2.render.renderText(entry.text) '}']; %#ok<AGROW>
    end
end

function value = boxOption(box)
    if strcmp(box, 'on'), value = 'axis lines=box'; else, value = 'axis lines=left'; end
end

function value = booleanText(input)
    if input, value = 'true'; else, value = 'false'; end
end

function value = legendPosition(location)
    value = strrep(location, '_', ' ');
end

function name = colorName(axesIndex, seriesIndex)
    name = sprintf('m2t2color%d_%d', axesIndex, seriesIndex);
end
