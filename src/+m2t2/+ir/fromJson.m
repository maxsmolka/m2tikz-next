function ir = fromJson(jsonText)
%FROMJSON Decode v1/v2 JSON and return validated current-version IR.
    try
        if isa(jsonText,'string')&&isscalar(jsonText),jsonText=char(jsonText);end
        % Bare object null is ambiguous: jsondecode turns scalar NaN into an
        % empty array. Array null is the explicit numeric gap representation.
        [tokens, ends] = regexp(char(jsonText), '"(?:[^"\\]|\\.)*"', 'match', 'end');
        for k=1:numel(tokens)
            if ~isempty(regexp(char(jsonText(ends(k)+1:end)), '^\s*:', 'once'))
                key=jsondecode(tokens{k});
                if numel(key)>63||isempty(regexp(key,'^[A-Za-z][A-Za-z0-9_]*$','once'))
                    invalidJson('JSON field names must be portable ASCII identifiers of at most 63 characters');
                end
            end
            if ~isempty(regexp(char(jsonText(ends(k)+1:end)), '^\s*:\s*null\s*[,}]', 'once'))
                invalidJson('bare null is ambiguous; use [] or a numeric array containing null');
            end
        end
        % Octave otherwise renames the valid ArrowIR field end to xEnd,
        % which formerly replaced nondefault endpoints with constructor data.
        if exist('OCTAVE_VERSION','builtin')
            decoded=jsondecode(jsonText,'makeValidName',false);
        else
            decoded=jsondecode(jsonText);
        end
        if ~(isstruct(decoded) && isscalar(decoded)), invalidJson('expected one figure object'); end
        if ~isfield(decoded,'version') || ~(isnumeric(decoded.version) && ...
                isscalar(decoded.version) && isfinite(decoded.version) && ...
                any(decoded.version==[1 2]))
            invalidVersion('missing, malformed or unsupported version');
        end
        requireSource(decoded, {'kind','axes'}, 'figure');
        if ~strcmp(decoded.kind,'m2t2.figure'), invalidJson('invalid figure kind'); end
        switch decoded.version
            case 1, ir = migrateV1(decoded);
            case 2, ir = normalizeV2(decoded);
        end
        m2t2.ir.validate(ir);
    catch err
        if strncmp(err.identifier,'M2T2:',5), rethrow(err); end
        invalidJson('malformed JSON or schema field structure');
    end
end

function ir = migrateV1(old)
    onlyFields(old,{'kind','version','axes'},'v1 figure');
    oldAxes = structArrayToCells(old.axes);
    axesItems = cell(1, numel(oldAxes));
    for a = 1:numel(oldAxes)
        source = oldAxes{a};
        names={'kind','id','xlim','ylim','xscale','yscale','xlabel','ylabel','title','xgrid','ygrid','series'};
        requireSource(source,names,'v1 axes');onlyFields(source,names,'v1 axes');
        if ~strcmp(source.kind,'m2t2.axes2d'),invalidJson('v1 supports only axes2d');end
        target = m2t2.ir.makeAxes();
        target.id = source.id;
        copyNames = {'xlim','ylim','xscale','yscale','xgrid','ygrid'};
        for k = 1:numel(copyNames), target.(copyNames{k}) = source.(copyNames{k}); end
        target.xlim = row(target.xlim); target.ylim = row(target.ylim); target.zlim = row(target.zlim);
        target.view = row(target.view); target.dataAspectRatio = row(target.dataAspectRatio);
        target.plotBoxAspectRatio = row(target.plotBoxAspectRatio);
        target.xlabel = m2t2.ir.makeText(source.xlabel, 'plain');
        target.ylabel = m2t2.ir.makeText(source.ylabel, 'plain');
        target.title = m2t2.ir.makeText(source.title, 'plain');
        % PGFPlots' previous defaults drew a boxed axis and automatic ticks.
        target.xdirection = 'normal'; target.ydirection = 'normal'; target.box = 'on';
        oldSeries = structArrayToCells(source.series);
        target.series = cell(1, numel(oldSeries));
        entries = {};
        for s = 1:numel(oldSeries)
            names={'kind','x','y','color','width','style','marker','markerSize','displayName'};
            requireSource(oldSeries{s},names,'v1 line');onlyFields(oldSeries{s},names,'v1 line');
            if ~strcmp(oldSeries{s}.kind,'m2t2.line'),invalidJson('v1 supports only line series');end
            item = m2t2.ir.makeLineSeries();
            item.id = sprintf('%s-series-%d', target.id, s);
            item.x = row(oldSeries{s}.x); item.y = row(oldSeries{s}.y);
            item.color = row(oldSeries{s}.color);
            item.width = oldSeries{s}.width; item.style = oldSeries{s}.style;
            item.marker = oldSeries{s}.marker; item.markerSize = oldSeries{s}.markerSize;
            item.displayName = m2t2.ir.makeText(oldSeries{s}.displayName, 'plain');
            item.visible = true;
            target.series{s} = item;
            if ~isempty(item.displayName.value)
                entries{end + 1} = m2t2.ir.makeLegendEntry(item.id, item.displayName); %#ok<AGROW>
            end
        end
        if ~isempty(entries)
            target.legend.visible = true;
            target.legend.entries = entries;
        end
        axesItems{a} = target;
    end
    ir = m2t2.ir.makeFigure(axesItems);
end

function ir = normalizeV2(decoded)
    axesValues = structArrayToCells(decoded.axes);
    axesItems = cell(1, numel(axesValues));
    for a = 1:numel(axesValues)
        source = axesValues{a};
        requireSource(source,{'kind','id','xlim','ylim','xscale','yscale','series'},'axes');
        target = merge(m2t2.ir.makeAxes(), source);
        target.placement = merge(m2t2.ir.makePlacement(), target.placement);
        target.colorMapping = normalizeColorMapping(target.colorMapping);
        target.xlim = row(target.xlim); target.ylim = row(target.ylim); target.zlim = row(target.zlim);
        target.view = row(target.view); target.dataAspectRatio = row(target.dataAspectRatio);
        target.plotBoxAspectRatio = row(target.plotBoxAspectRatio);
        target.xlabel = normalizeText(target.xlabel);
        target.ylabel = normalizeText(target.ylabel);
        target.title = normalizeText(target.title);
        target.xticks = normalizeTicks(target.xticks);
        target.yticks = normalizeTicks(target.yticks);
        target.zticks = normalizeTicks(target.zticks);
        target.zlabel = normalizeText(target.zlabel);
        if isfield(target,'dualY')
            target.dualY.leftColor=row(target.dualY.leftColor);
            right=target.dualY.right;
            right.limits=row(right.limits);right.color=row(right.color);
            right.ticks=normalizeTicks(right.ticks);right.label=normalizeText(right.label);
            target.dualY.right=right;
        end
        sourceSeries = structArrayToCells(target.series);
        target.series = cell(1, numel(sourceSeries));
        for s = 1:numel(sourceSeries)
            target.series{s} = normalizeSeries(sourceSeries{s}, target.id, s);
        end
        target.legend = normalizeLegend(target.legend);
        axesItems{a} = target;
    end
    ir = merge(m2t2.ir.makeFigure(axesItems), decoded);
    ir.axes = axesItems;
    ir.size = row(ir.size);
    ir.layout = normalizeLayout(ir.layout);
    ir.elements = normalizeElements(ir.elements);
    ir.annotations = normalizeAnnotations(ir.annotations);
end

function mapping = normalizeColorMapping(source)
    mapping = merge(m2t2.ir.makeColorMapping(), source);
    mapping.limits = row(mapping.limits);
end

function elements = normalizeElements(source)
    raw = structArrayToCells(source); elements = cell(1, numel(raw));
    for k = 1:numel(raw)
        item = raw{k};
        if ~isfield(item, 'kind'), invalidVersion('figure element missing kind'); end
        requireSource(item,{'owner'},'figure element');
        requireSource(item.owner,{'kind','id'},'figure element owner');
        switch item.kind
            case 'm2t2.colorbar'
                requireSource(item,{'associatedAxesIds','limits'},'colorbar');
                node = merge(m2t2.ir.makeColorbar(), item);
                node.owner = merge(m2t2.ir.makeOwner(), node.owner);
                node.placement = merge(m2t2.ir.makePlacement(), node.placement);
                node.associatedAxesIds = textList(node.associatedAxesIds);
                node.limits = row(node.limits);
                node.ticks = normalizeTicks(node.ticks);
                node.label = normalizeText(node.label);
            case 'm2t2.legend'
                requireSource(item,{'entries'},'shared legend');
                node = merge(m2t2.ir.makeSharedLegend(), item);
                node.owner = merge(m2t2.ir.makeOwner(), node.owner);
                node.placement = merge(m2t2.ir.makePlacement(), node.placement);
                entries = structArrayToCells(node.entries); node.entries = cell(1, numel(entries));
                for e = 1:numel(entries)
                    entry = entries{e}; entry.text = normalizeText(entry.text);
                    node.entries{e} = entry;
                end
            case 'm2t2.sharedlabel'
                requireSource(item,{'role','text'},'shared label');
                node = merge(m2t2.ir.makeSharedLabel(), item);
                node.owner = merge(m2t2.ir.makeOwner(), node.owner);
                node.text = normalizeText(node.text);
                if ~isempty(node.placement)
                    node.placement = merge(m2t2.ir.makePlacement(), node.placement);
                end
            otherwise
                invalidVersion(['unsupported figure element kind ' item.kind]);
        end
        elements{k} = node;
    end
end

function annotations = normalizeAnnotations(source)
    raw = structArrayToCells(source);
    annotations = cell(1, numel(raw));
    for k = 1:numel(raw)
        item = raw{k};
        if ~isfield(item, 'kind'), invalidVersion('annotation missing kind'); end
        requireSource(item,{'owner'},'annotation');
        requireSource(item.owner,{'kind','id'},'annotation owner');
        switch item.kind
            case 'm2t2.textannotation'
                requireSource(item,{'position','text','coordinateSpace'},'text annotation');
                node = merge(m2t2.ir.makeTextAnnotation(), item);
                node.owner = merge(m2t2.ir.makeOwner(), node.owner);
                node.position = row(node.position);
                node.text = normalizeText(node.text);
                node.color = row(node.color);
            case 'm2t2.arrowannotation'
                requireSource(item,{'annotationKind','start','end','coordinateSpace'},'arrow annotation');
                node = merge(m2t2.ir.makeArrowAnnotation(), item);
                node.owner = merge(m2t2.ir.makeOwner(), node.owner);
                node.start = row(node.start); node.end = row(node.end);
                node.color = row(node.color);
                node.startHead = merge(m2t2.ir.makeArrowHead(), node.startHead);
                node.endHead = merge(m2t2.ir.makeArrowHead(), node.endHead);
            otherwise
                invalidVersion(['unsupported annotation kind ' item.kind]);
        end
        annotations{k} = node;
    end
end

function layout = normalizeLayout(source)
    layout = merge(m2t2.ir.makeLayout(), source);
    rawCells = structArrayToCells(layout.cells);
    layout.cells = cell(1, numel(rawCells));
    for k = 1:numel(rawCells)
        item = rawCells{k};
        layout.cells{k} = merge(m2t2.ir.makeLayoutCell(), item);
    end
end

function node = normalizeSeries(source, axesId, index)
    if ~isfield(source, 'kind'), invalidVersion('series missing kind'); end
    switch source.kind
        case {'m2t2.line','m2t2.scatter'}, required={'x','y'};
        case {'m2t2.line3','m2t2.scatter3'}, required={'x','y','z'};
        case 'm2t2.errorbar', required={'x','y','xNegative','xPositive','yNegative','yPositive'};
        case 'm2t2.image', required={'x','y','cdata','mapping'};
        case 'm2t2.surface', required={'x','y','z','c'};
        case 'm2t2.patch3', required={'vertices'};
        case 'm2t2.bar', required={'owner','categories','values','groupId','groupIndex','groupCount'};
        case 'm2t2.boxplot', required={'owner','positions','lowerWhisker','q1','median','q3','upperWhisker','outlierPositions','outlierValues'};
        otherwise, required={};
    end
    requireSource(source,required,'series');
    switch source.kind
        case 'm2t2.line', node = merge(m2t2.ir.makeLineSeries(), source);
        case {'m2t2.scatter','m2t2.scatter3'}
            if strcmp(source.kind,'m2t2.scatter3'),base=m2t2.ir.makeScatter3Series();
            else,base=m2t2.ir.makeScatterSeries();end
            node = merge(base, source);
            if ~isfield(source, 'sizeMode')
                node.sizeMode = 'constant';
            end
            if ~isfield(source, 'edgeMode')
                node.edgeMode = 'constant';
                if ~isfield(source,'edgeColor'),node.edgeColor=row(node.color);end
            end
            if ~isfield(source, 'faceMode')
                node.faceMode = 'none';
                if ~isfield(source,'faceColor'),node.faceColor=row(node.color);end
            end
        case 'm2t2.errorbar', node = merge(m2t2.ir.makeErrorbarSeries(), source);
        case 'm2t2.image', node = merge(m2t2.ir.makeImageSeries(), source);
        case 'm2t2.bar', node = merge(m2t2.ir.makeBarSeries(), source);
        case 'm2t2.boxplot', node = merge(m2t2.ir.makeBoxplotSeries(), source);
        case 'm2t2.surface', node = merge(m2t2.ir.makeSurfaceSeries(), source);
        case 'm2t2.line3', node = merge(m2t2.ir.makeLine3Series(), source);
        case 'm2t2.patch3', node = merge(m2t2.ir.makePatch3Series(), source);
        otherwise, invalidVersion(['unsupported series kind ' source.kind]);
    end
    if ~isfield(source, 'id') || isempty(source.id)
        node.id = sprintf('%s-series-%d', axesId, index);
    end
    node.displayName = normalizeText(node.displayName);
    vectorNames = {'x','y','color','colorData','markerSize','edgeColor','faceColor', ...
                   'xNegative','xPositive','yNegative','yPositive', ...
                   'categories','values','faceColor','edgeColor','z'};
    vectorNames=[vectorNames,{'positions','lowerWhisker','q1','median','q3', ...
        'upperWhisker','outlierPositions','outlierValues','boxColor', ...
        'medianColor','whiskerColor','outlierColor'}];
    for k = 1:numel(vectorNames)
        if any(strcmp(node.kind, {'m2t2.scatter','m2t2.scatter3'})) && strcmp(vectorNames{k}, 'colorData') && ...
                strcmp(node.colorMode, 'per_point_rgb')
            continue;
        end
        if strcmp(node.kind, 'm2t2.surface') && any(strcmp(vectorNames{k}, {'x','y','z'}))
            continue;
        end
        if isfield(node, vectorNames{k}), node.(vectorNames{k}) = row(node.(vectorNames{k})); end
    end
    if strcmp(node.kind, 'm2t2.patch3') && isvector(node.vertices)
        node.vertices = reshape(node.vertices, [], 3);
    end
end

function ticks = normalizeTicks(source)
    ticks = merge(m2t2.ir.makeTickSpec(), source);
    ticks.values = row(ticks.values);
    rawLabels = structArrayToCells(ticks.labels);
    ticks.labels = cell(1, numel(rawLabels));
    for k = 1:numel(rawLabels), ticks.labels{k} = normalizeText(rawLabels{k}); end
end

function legendNode = normalizeLegend(source)
    legendNode = merge(m2t2.ir.makeLegend(), source);
    rawEntries = structArrayToCells(legendNode.entries);
    legendNode.entries = cell(1, numel(rawEntries));
    for k = 1:numel(rawEntries)
        entry = rawEntries{k}; entry.text = normalizeText(entry.text);
        legendNode.entries{k} = entry;
    end
end

function value = normalizeText(value)
    if ischar(value), value = m2t2.ir.makeText(value, 'plain'); end
end

function output = merge(defaults, source)
    output = defaults;
    names = fieldnames(source);
    for k = 1:numel(names), output.(names{k}) = source.(names{k}); end
end

function values = structArrayToCells(values)
    if ~isempty(values)&&~isvector(values)
        invalidJson('ordered node collections must be vectors');
    end
    if iscell(values),values=reshape(values,1,[]);return;end
    if isempty(values), values = {};
    elseif isstruct(values), values = arrayfun(@(item) item, values, 'UniformOutput', false);
    else, invalidJson('expected an ordered node collection'); end
end

function values = textList(values)
    if ischar(values), values = {values};
    elseif ~iscell(values), values = cellstr(values); end
    values = reshape(values, 1, []);
end

function value = row(value)
    if ~(isnumeric(value) && (isempty(value) || isvector(value)))
        invalidJson('expected numeric vector, not a matrix or another type');
    end
    value = reshape(value, 1, []);
end

function requireSource(value,names,path)
    if ~(isstruct(value)&&isscalar(value)&&(isempty(names)||all(isfield(value,names))))
        invalidJson([path ' is missing required semantic fields']);
    end
end

function onlyFields(value,names,path)
    if ~all(ismember(fieldnames(value),names))
        invalidJson([path ' contains fields outside the supported v1 migration']);
    end
end

function invalidJson(reason)
    error('M2T2:E003:InvalidIR','M2T2-E003 InvalidIR: %s',reason);
end

function invalidVersion(reason)
    error('M2T2:E008:UnsupportedIRVersion', ...
          'M2T2-E008 UnsupportedIRVersion: %s', reason);
end
