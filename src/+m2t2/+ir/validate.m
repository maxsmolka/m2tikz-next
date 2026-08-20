function validate(ir)
%VALIDATE Reject malformed or non-normalized current-version M2 IR.
    requireStruct(ir, 'figure');
    requireFields(ir, {'kind','version','size','layout','axes','elements','annotations'}, 'figure');
    if ~strcmp(ir.kind, 'm2t2.figure') || ~isequal(ir.version, 2)
        invalid('figure', 'expected kind=m2t2.figure and version=2');
    end
    validateFigureSize(ir.size, 'figure.size');
    if isempty(ir.size) && (~isempty(ir.elements) || ~isempty(ir.annotations))
        invalid('figure.size', 'figure-level elements and annotations require an explicit physical figure size');
    end
    if ~iscell(ir.axes), invalid('figure.axes', 'expected a cell array'); end
    axesIds = cell(1, numel(ir.axes));
    for a = 1:numel(ir.axes)
        axesIds{a} = validateAxes(ir.axes{a}, sprintf('figure.axes{%d}', a));
    end
    if numel(unique(axesIds)) ~= numel(axesIds)
        invalid('figure.axes', 'axes ids must be unique');
    end
    for a = 1:numel(ir.axes)
        relation = ir.axes{a}.overlayOf;
        if isempty(relation), continue; end
        target = find(strcmp(relation, axesIds), 1);
        if isempty(target)
            invalid(sprintf('figure.axes{%d}.overlayOf', a), ...
                    'overlay relation references an unknown axes');
        end
        if target >= a
            invalid(sprintf('figure.axes{%d}.overlayOf', a), ...
                    'overlay relation must reference an earlier axes in render order');
        end
        if ~placementsOverlap(ir.axes{target}.placement, ir.axes{a}.placement)
            invalid(sprintf('figure.axes{%d}.overlayOf', a), ...
                    'overlay relation requires overlapping physical placement');
        end
    end
    validateLayout(ir.layout, axesIds, 'figure.layout');
    validateElements(ir.elements, ir.axes, axesIds, ir.layout, 'figure.elements');
    validateAnnotations(ir.annotations, ir.axes, axesIds, ir.layout, 'figure.annotations');
end

function id = validateAxes(node, path)
    requireStruct(node, path);
    names = {'kind','dimensionality','id','placement','overlayOf','xlim','ylim','zlim','xscale','yscale','zscale','xdirection','ydirection','zdirection', ...
             'view','projection','dataAspectRatio','plotBoxAspectRatio','box','colorMapping','xticks','yticks','zticks','xlabel','ylabel','zlabel','title','xgrid','ygrid','zgrid', ...
             'legend','series'};
    requireFields(node, names, path);
    enum(node.kind, {'m2t2.axes2d','m2t2.axes3d'}, [path '.kind']);
    if ~(isequal(node.dimensionality, 2) || isequal(node.dimensionality, 3)) || ...
       (strcmp(node.kind, 'm2t2.axes2d') ~= isequal(node.dimensionality, 2))
        invalid(path, 'axes kind and dimensionality must agree');
    end
    nonemptyText(node.id, [path '.id']); id = node.id;
    validatePlacement(node.placement, [path '.placement']);
    textScalar(node.overlayOf, [path '.overlayOf']);
    finitePair(node.xlim, [path '.xlim']); finitePair(node.ylim, [path '.ylim']);
    finitePair(node.zlim, [path '.zlim']);
    enum(node.xscale, {'linear','log'}, [path '.xscale']);
    enum(node.yscale, {'linear','log'}, [path '.yscale']);
    enum(node.zscale, {'linear','log'}, [path '.zscale']);
    enum(node.xdirection, {'normal','reverse'}, [path '.xdirection']);
    enum(node.ydirection, {'normal','reverse'}, [path '.ydirection']);
    enum(node.zdirection, {'normal','reverse'}, [path '.zdirection']);
    finitePair(node.view, [path '.view']);
    enum(node.projection, {'orthographic'}, [path '.projection']);
    positiveTriple(node.dataAspectRatio, [path '.dataAspectRatio']);
    positiveTriple(node.plotBoxAspectRatio, [path '.plotBoxAspectRatio']);
    enum(node.box, {'on','off'}, [path '.box']);
    validateColorMapping(node.colorMapping, [path '.colorMapping']);
    validateTicks(node.xticks, [path '.xticks']);
    validateTicks(node.yticks, [path '.yticks']);
    validateTicks(node.zticks, [path '.zticks']);
    validateText(node.xlabel, [path '.xlabel']);
    validateText(node.ylabel, [path '.ylabel']);
    validateText(node.zlabel, [path '.zlabel']);
    validateText(node.title, [path '.title']);
    logicalScalar(node.xgrid, [path '.xgrid']);
    logicalScalar(node.ygrid, [path '.ygrid']);
    logicalScalar(node.zgrid, [path '.zgrid']);
    if ~iscell(node.series), invalid([path '.series'], 'expected a cell array'); end
    seriesIds = cell(1, numel(node.series));
    for s = 1:numel(node.series)
        seriesPath = sprintf('%s.series{%d}', path, s);
        seriesIds{s} = validateSeries(node.series{s}, seriesPath, node.id, node.xscale, node.yscale, node.dimensionality);
    end
    if numel(unique(seriesIds)) ~= numel(seriesIds)
        invalid([path '.series'], 'series ids must be unique');
    end
    validateBarGroups(node.series, path);
    validateLegend(node.legend, seriesIds, [path '.legend']);
end

function validateColorMapping(node, path)
    requireStruct(node, path);
    requireFields(node, {'limits','scale','colormap'}, path);
    finiteIncreasingPair(node.limits, [path '.limits']);
    enum(node.scale, {'linear','log'}, [path '.scale']);
    if ~(isnumeric(node.colormap) && ismatrix(node.colormap) && ...
         size(node.colormap, 2) == 3 && size(node.colormap, 1) >= 2 && ...
         all(isfinite(node.colormap(:))) && all(node.colormap(:) >= 0) && ...
         all(node.colormap(:) <= 1))
        invalid([path '.colormap'], 'expected an N-by-3 RGB matrix in [0,1] with N >= 2');
    end
end

function validateElements(elements, axesItems, axesIds, layout, path)
    if ~iscell(elements), invalid(path, 'expected a cell array'); end
    ids = cell(1, numel(elements));
    for k = 1:numel(elements)
        itemPath = sprintf('%s{%d}', path, k);
        item = elements{k}; requireStruct(item, itemPath);
        requireFields(item, {'kind','id','owner'}, itemPath);
        nonemptyText(item.id, [itemPath '.id']); ids{k} = item.id;
        validateOwner(item.owner, axesIds, layout, [itemPath '.owner']);
        switch item.kind
            case 'm2t2.colorbar'
                validateColorbar(item, axesItems, axesIds, itemPath);
            case 'm2t2.legend'
                validateSharedLegend(item, axesItems, axesIds, itemPath);
            case 'm2t2.sharedlabel'
                validateSharedLabel(item, itemPath);
            otherwise
                invalid([itemPath '.kind'], ['unsupported figure element kind ' item.kind]);
        end
    end
    if numel(unique(ids)) ~= numel(ids), invalid(path, 'element ids must be unique'); end
end

function validateOwner(owner, axesIds, layout, path)
    requireStruct(owner, path); requireFields(owner, {'kind','id'}, path);
    enum(owner.kind, {'axes','layout','figure'}, [path '.kind']);
    nonemptyText(owner.id, [path '.id']);
    valid = (strcmp(owner.kind, 'figure') && strcmp(owner.id, 'figure')) || ...
            (strcmp(owner.kind, 'layout') && strcmp(owner.id, 'layout') && ...
             strcmp(layout.kind, 'grid')) || ...
            (strcmp(owner.kind, 'axes') && any(strcmp(owner.id, axesIds)));
    if ~valid, invalidReference(path, 'owner does not resolve in this figure'); end
end

function validateColorbar(node, axesItems, axesIds, path)
    names = {'associatedAxesIds','orientation','placement','location','direction', ...
             'scale','limits','ticks','label'};
    requireFields(node, names, path);
    if ~iscell(node.associatedAxesIds) || isempty(node.associatedAxesIds)
        invalid([path '.associatedAxesIds'], 'expected a non-empty cell array');
    end
    for k = 1:numel(node.associatedAxesIds)
        id = node.associatedAxesIds{k}; nonemptyText(id, [path '.associatedAxesIds']);
        if ~any(strcmp(id, axesIds)), invalidReference([path '.associatedAxesIds'], 'unknown axes reference'); end
    end
    if numel(unique(node.associatedAxesIds)) ~= numel(node.associatedAxesIds)
        invalid([path '.associatedAxesIds'], 'axes references must be unique');
    end
    if strcmp(node.owner.kind, 'axes') && ~any(strcmp(node.owner.id, node.associatedAxesIds))
        invalidColorbarOwnership([path '.owner'], 'axes owner must be an associated axes');
    end
    enum(node.orientation, {'vertical','horizontal'}, [path '.orientation']);
    validatePlacement(node.placement, [path '.placement']);
    enum(node.location, {'eastoutside','westoutside','northoutside','southoutside','manual'}, [path '.location']);
    enum(node.direction, {'normal','reverse'}, [path '.direction']);
    enum(node.scale, {'linear','log'}, [path '.scale']);
    finiteIncreasingPair(node.limits, [path '.limits']);
    validateTicks(node.ticks, [path '.ticks']); validateText(node.label, [path '.label']);
    for k = 1:numel(node.associatedAxesIds)
        index = find(strcmp(node.associatedAxesIds{k}, axesIds), 1);
        mapping = axesItems{index}.colorMapping;
        sourceIndex = find(strcmp(node.associatedAxesIds{1}, axesIds), 1);
        sourceMap = axesItems{sourceIndex}.colorMapping.colormap;
        sameColormap = isequal(size(mapping.colormap), size(sourceMap)) && ...
            max(abs(mapping.colormap(:) - sourceMap(:))) <= 1e-10;
        if ~strcmp(mapping.scale, node.scale) || max(abs(mapping.limits - node.limits)) > 1e-10 || ~sameColormap
            invalidColorbarOwnership(path, 'display scale must match every associated axes color mapping');
        end
    end
end

function validateSharedLegend(node, axesItems, axesIds, path)
    requireFields(node, {'entries','placement','location'}, path);
    if strcmp(node.owner.kind, 'axes')
        invalid([path '.owner'], 'figure-level legend must be layout- or figure-owned');
    end
    validatePlacement(node.placement, [path '.placement']);
    enum(node.location, {'north','south','east','west','manual'}, [path '.location']);
    if ~iscell(node.entries), invalid([path '.entries'], 'expected a cell array'); end
    used = {};
    for k = 1:numel(node.entries)
        entryPath = sprintf('%s.entries{%d}', path, k); entry = node.entries{k};
        requireStruct(entry, entryPath); requireFields(entry, {'axesId','seriesId','text'}, entryPath);
        nonemptyText(entry.axesId, [entryPath '.axesId']);
        nonemptyText(entry.seriesId, [entryPath '.seriesId']);
        a = find(strcmp(entry.axesId, axesIds), 1);
        if isempty(a), invalidReference(entryPath, 'unknown axes reference'); end
        seriesIds = cellfun(@(item) item.id, axesItems{a}.series, 'UniformOutput', false);
        if ~any(strcmp(entry.seriesId, seriesIds)), invalidReference(entryPath, 'unknown series reference'); end
        key = [entry.axesId '/' entry.seriesId];
        if any(strcmp(key, used)), invalid(entryPath, 'series may occur only once in a shared legend'); end
        used{end + 1} = key; %#ok<AGROW>
        validateText(entry.text, [entryPath '.text']);
    end
end

function validateSharedLabel(node, path)
    requireFields(node, {'role','text','placement'}, path);
    if strcmp(node.owner.kind, 'axes')
        invalid([path '.owner'], 'shared label must be layout- or figure-owned');
    end
    enum(node.role, {'xlabel','ylabel','title'}, [path '.role']);
    validateText(node.text, [path '.text']);
    if ~isempty(node.placement), validatePlacement(node.placement, [path '.placement']); end
end

function validateAnnotations(annotations, axesItems, axesIds, layout, path)
    if ~iscell(annotations), invalid(path, 'expected a cell array'); end
    ids = cell(1, numel(annotations));
    for k = 1:numel(annotations)
        itemPath = sprintf('%s{%d}', path, k);
        node = annotations{k}; requireStruct(node, itemPath);
        requireFields(node, {'kind','id','owner','coordinateSpace','visible'}, itemPath);
        nonemptyText(node.id, [itemPath '.id']); ids{k} = node.id;
        validateOwner(node.owner, axesIds, layout, [itemPath '.owner']);
        logicalScalar(node.visible, [itemPath '.visible']);
        switch node.kind
            case 'm2t2.textannotation'
                validateTextAnnotation(node, axesItems, axesIds, itemPath);
            case 'm2t2.arrowannotation'
                validateArrowAnnotation(node, itemPath);
            otherwise
                invalid([itemPath '.kind'], ['unsupported annotation kind ' node.kind]);
        end
    end
    if numel(unique(ids)) ~= numel(ids), invalid(path, 'annotation ids must be unique'); end
end

function validateTextAnnotation(node, axesItems, axesIds, path)
    names = {'position','text','horizontalAlignment','verticalAlignment', ...
             'rotation','fontSize','fontWeight','fontAngle','color'};
    requireFields(node, names, path);
    if ~strcmp(node.owner.kind, 'axes')
        invalid([path '.owner'], 'text annotations must be axes-owned');
    end
    enum(node.coordinateSpace, {'axes_data'}, [path '.coordinateSpace']);
    finitePoint(node.position, [path '.position']);
    validateText(node.text, [path '.text']);
    enum(node.horizontalAlignment, {'left','center','right'}, ...
         [path '.horizontalAlignment']);
    enum(node.verticalAlignment, {'top','cap','middle','baseline','bottom'}, ...
         [path '.verticalAlignment']);
    finiteScalar(node.rotation, [path '.rotation']);
    positiveScalar(node.fontSize, [path '.fontSize']);
    enum(node.fontWeight, {'normal','bold'}, [path '.fontWeight']);
    enum(node.fontAngle, {'normal','italic'}, [path '.fontAngle']);
    validateColor(node.color, [path '.color']);
    index = find(strcmp(node.owner.id, axesIds), 1);
    axesNode = axesItems{index};
    if (strcmp(axesNode.xscale, 'log') && node.position(1) <= 0) || ...
       (strcmp(axesNode.yscale, 'log') && node.position(2) <= 0)
        invalid([path '.position'], 'log-axis text coordinates must be positive');
    end
end

function validateArrowAnnotation(node, path)
    names = {'annotationKind','start','end','style','width','color', ...
             'startHead','endHead'};
    requireFields(node, names, path);
    if ~strcmp(node.owner.kind, 'figure') || ~strcmp(node.owner.id, 'figure')
        invalid([path '.owner'], 'arrow annotations must be figure-owned');
    end
    enum(node.annotationKind, {'arrow','doublearrow'}, [path '.annotationKind']);
    enum(node.coordinateSpace, {'figure_normalized'}, [path '.coordinateSpace']);
    normalizedPoint(node.start, [path '.start']);
    normalizedPoint(node.end, [path '.end']);
    enum(node.style, {'solid','dashed','dotted','dashdot'}, [path '.style']);
    nonnegativeScalar(node.width, [path '.width']);
    validateColor(node.color, [path '.color']);
    validateArrowHead(node.startHead, [path '.startHead']);
    validateArrowHead(node.endHead, [path '.endHead']);
    if strcmp(node.annotationKind, 'arrow') && ~strcmp(node.startHead.style, 'none')
        invalid([path '.startHead'], 'single arrow may only have an end head');
    end
    if strcmp(node.annotationKind, 'doublearrow') && ...
            (strcmp(node.startHead.style, 'none') || strcmp(node.endHead.style, 'none'))
        invalid(path, 'double arrow requires both semantic arrow heads');
    end
end

function validateArrowHead(node, path)
    requireStruct(node, path); requireFields(node, {'style','length','width'}, path);
    enum(node.style, {'none','vback2'}, [path '.style']);
    if strcmp(node.style, 'none')
        if ~isequal(node.length, 0) || ~isequal(node.width, 0)
            invalid(path, 'head style none requires zero length and width');
        end
    else
        positiveScalar(node.length, [path '.length']);
        positiveScalar(node.width, [path '.width']);
    end
end

function validateFigureSize(value, path)
    if isempty(value), return; end
    if ~(isnumeric(value) && isequal(size(value), [1 2]) && ...
         all(isfinite(value)) && all(value > 0))
        invalid(path, 'expected empty auto-size or a positive finite 1-by-2 point size');
    end
end

function validatePlacement(node, path)
    if ~(isstruct(node) && isscalar(node))
        invalidPlacement(path, 'expected a scalar placement struct');
    end
    names = {'x','y','width','height'};
    for k = 1:numel(names)
        if ~isfield(node, names{k})
            invalidPlacement(path, ['missing field ' names{k}]);
        end
        value = node.(names{k});
        if ~(isnumeric(value) && isscalar(value) && isfinite(value))
            invalidPlacement([path '.' names{k}], 'expected a finite scalar');
        end
    end
    tolerance = 1e-10;
    if node.x < -tolerance || node.y < -tolerance || ...
       node.width <= 0 || node.height <= 0 || ...
       node.x + node.width > 1 + tolerance || ...
       node.y + node.height > 1 + tolerance
        invalidPlacement(path, ...
            'normalized x/y/width/height must define a positive rectangle inside [0,1]');
    end
end

function validateLayout(node, axesIds, path)
    requireStruct(node, path);
    requireFields(node, {'kind','rows','columns','cells'}, path);
    enum(node.kind, {'freeform','grid'}, [path '.kind']);
    if ~iscell(node.cells), invalid([path '.cells'], 'expected a cell array'); end
    if strcmp(node.kind, 'freeform')
        if ~isequal(node.rows, 0) || ~isequal(node.columns, 0) || ~isempty(node.cells)
            invalid(path, 'freeform layout must have zero rows/columns and no cells');
        end
        return;
    end
    positiveInteger(node.rows, [path '.rows']);
    positiveInteger(node.columns, [path '.columns']);
    used = {};
    occupied = false(node.rows, node.columns);
    for k = 1:numel(node.cells)
        cellPath = sprintf('%s.cells{%d}', path, k);
        item = node.cells{k}; requireStruct(item, cellPath);
        requireFields(item, {'axesId','row','column','rowSpan','columnSpan'}, cellPath);
        nonemptyText(item.axesId, [cellPath '.axesId']);
        if ~any(strcmp(item.axesId, axesIds))
            invalid([cellPath '.axesId'], 'layout cell references an unknown axes');
        end
        if any(strcmp(item.axesId, used))
            invalid([cellPath '.axesId'], 'axes may occur only once in logical layout');
        end
        positiveInteger(item.row, [cellPath '.row']);
        positiveInteger(item.column, [cellPath '.column']);
        positiveInteger(item.rowSpan, [cellPath '.rowSpan']);
        positiveInteger(item.columnSpan, [cellPath '.columnSpan']);
        lastRow = item.row + item.rowSpan - 1;
        lastColumn = item.column + item.columnSpan - 1;
        if lastRow > node.rows || lastColumn > node.columns
            invalid(cellPath, 'layout cell exceeds grid bounds');
        end
        if any(any(occupied(item.row:lastRow, item.column:lastColumn)))
            invalid(cellPath, 'logical grid cells may not overlap');
        end
        occupied(item.row:lastRow, item.column:lastColumn) = true;
        used{end + 1} = item.axesId; %#ok<AGROW>
    end
end

function yes = placementsOverlap(first, second)
    overlapX = min(first.x + first.width, second.x + second.width) - max(first.x, second.x);
    overlapY = min(first.y + first.height, second.y + second.height) - max(first.y, second.y);
    yes = overlapX > 1e-10 && overlapY > 1e-10;
end

function validateTicks(node, path)
    requireStruct(node, path);
    requireFields(node, {'mode','values','labels'}, path);
    enum(node.mode, {'auto','manual'}, [path '.mode']);
    numericVector(node.values, [path '.values']);
    if any(~isfinite(node.values(:))), invalid([path '.values'], 'ticks must be finite'); end
    if ~iscell(node.labels), invalid([path '.labels'], 'expected a cell array'); end
    for k = 1:numel(node.labels)
        validateText(node.labels{k}, sprintf('%s.labels{%d}', path, k));
    end
    if strcmp(node.mode, 'auto') && (~isempty(node.values) || ~isempty(node.labels))
        invalid(path, 'auto ticks must not materialize runtime values or labels');
    end
    if strcmp(node.mode, 'manual') && numel(node.values) ~= numel(node.labels)
        invalid(path, 'manual tick values and labels must have equal lengths');
    end
end

function validateText(node, path)
    requireStruct(node, path);
    requireFields(node, {'value','interpreter'}, path);
    textScalar(node.value, [path '.value']);
    enum(node.interpreter, {'plain','tex','latex'}, [path '.interpreter']);
end

function validateLegend(node, seriesIds, path)
    requireStruct(node, path);
    requireFields(node, {'visible','mode','entries','location'}, path);
    logicalScalar(node.visible, [path '.visible']);
    enum(node.mode, {'automatic','manual'}, [path '.mode']);
    enum(node.location, {'north_east','north_west','south_east','south_west', ...
         'north','south','east','west'}, [path '.location']);
    if ~iscell(node.entries), invalid([path '.entries'], 'expected a cell array'); end
    used = {};
    for k = 1:numel(node.entries)
        entryPath = sprintf('%s.entries{%d}', path, k);
        entry = node.entries{k}; requireStruct(entry, entryPath);
        requireFields(entry, {'seriesId','text'}, entryPath);
        nonemptyText(entry.seriesId, [entryPath '.seriesId']);
        if ~any(strcmp(entry.seriesId, seriesIds))
            invalid([entryPath '.seriesId'], 'legend entry references an unknown series');
        end
        if any(strcmp(entry.seriesId, used))
            invalid([entryPath '.seriesId'], 'series may occur only once in a legend');
        end
        used{end + 1} = entry.seriesId; %#ok<AGROW>
        validateText(entry.text, [entryPath '.text']);
    end
    if ~node.visible && ~isempty(node.entries)
        invalid(path, 'an invisible legend must not contain entries');
    end
end

function id = validateSeries(node, path, axesId, xscale, yscale, dimensionality)
    requireStruct(node, path);
    requireFields(node, {'kind','id','displayName','visible'}, path);
    nonemptyText(node.id, [path '.id']); id = node.id;
    validateText(node.displayName, [path '.displayName']);
    logicalScalar(node.visible, [path '.visible']);
    switch node.kind
        case 'm2t2.line'
            validateLine(node, path);
        case 'm2t2.scatter'
            validateScatter(node, path);
        case 'm2t2.errorbar'
            validateErrorbar(node, path);
        case 'm2t2.image'
            validateImage(node, path);
        case 'm2t2.bar'
            validateBar(node, path, axesId, xscale, yscale);
        case 'm2t2.boxplot'
            validateBoxplot(node,path,axesId,xscale,yscale);
        case 'm2t2.surface'
            if dimensionality ~= 3, invalid(path, 'surface requires axes3d'); end
            validateSurface(node, path);
        case 'm2t2.line3'
            if dimensionality ~= 3, invalid(path, 'line3 requires axes3d'); end
            validateLine3(node, path);
        case 'm2t2.patch3'
            if dimensionality ~= 3, invalid(path, 'patch3 requires axes3d'); end
            validatePatch3(node, path);
        otherwise
            invalid([path '.kind'], ['unsupported series kind ' node.kind]);
    end
end

function validateSurface(node, path)
    requireFields(node, {'x','y','z','c','mapping','faceMode','edgeMode'}, path);
    if ~(isnumeric(node.z) && ismatrix(node.z) && all(size(node.z) >= 2) && ...
         isequal(size(node.x), size(node.z)) && isequal(size(node.y), size(node.z)) && ...
         isequal(size(node.c), size(node.z)))
        invalid(path, 'surface X/Y/Z/C must be equal matrices of at least 2-by-2');
    end
    if any(~isfinite(node.x(:))) || any(~isfinite(node.y(:))) || ...
       any(~isfinite(node.z(:))) || any(~isfinite(node.c(:)))
        invalid(path, 'surface geometry and scalar colors must be finite');
    end
    enum(node.mapping, {'scaled'}, [path '.mapping']);
    enum(node.faceMode, {'interpolated'}, [path '.faceMode']);
    enum(node.edgeMode, {'none'}, [path '.edgeMode']);
end

function validateLine3(node, path)
    requireFields(node, {'x','y','z','color','width','style','marker','markerSize'}, path);
    numericVector(node.x, [path '.x']); numericVector(node.y, [path '.y']); numericVector(node.z, [path '.z']);
    if numel(node.x) ~= numel(node.y) || numel(node.x) ~= numel(node.z) || ...
       any(isinf(node.x(:))) || any(isinf(node.y(:))) || any(isinf(node.z(:))) || ...
       any(xor(isnan(node.x(:)), isnan(node.y(:)))) || any(xor(isnan(node.x(:)), isnan(node.z(:))))
        invalid(path, 'line3 coordinates must be equal-length finite triples or shared NaN gaps');
    end
    validateColor(node.color, [path '.color']); nonnegativeScalar(node.width, [path '.width']);
    validateStyle(node.style, [path '.style']); validateMarker(node.marker, [path '.marker']);
    nonnegativeScalar(node.markerSize, [path '.markerSize']);
end

function validatePatch3(node, path)
    requireFields(node, {'vertices','faceColor','edgeColor','edgeVisible','lineWidth','lineStyle'}, path);
    if ~(isnumeric(node.vertices) && isequal(size(node.vertices), [3 3]) && all(isfinite(node.vertices(:))))
        invalid([path '.vertices'], 'patch3 is restricted to one finite triangle');
    end
    validateColor(node.faceColor, [path '.faceColor']); validateColor(node.edgeColor, [path '.edgeColor']);
    logicalScalar(node.edgeVisible, [path '.edgeVisible']); nonnegativeScalar(node.lineWidth, [path '.lineWidth']);
    validateStyle(node.lineStyle, [path '.lineStyle']);
end

function validateBoxplot(node,path,axesId,xscale,yscale)
    names={'owner','orientation','positions','lowerWhisker','q1','median','q3', ...
        'upperWhisker','outlierPositions','outlierValues','boxWidth','boxColor', ...
        'boxLineWidth','medianColor','medianLineWidth','medianLineStyle', ...
        'whiskerColor','whiskerLineWidth','whiskerLineStyle','outlierMarker', ...
        'outlierMarkerSize','outlierColor'};
    requireFields(node,names,path);validateOwner(node.owner,{axesId},m2t2.ir.makeLayout(),[path '.owner']);
    if ~strcmp(node.owner.kind,'axes')||~strcmp(node.owner.id,axesId),invalid([path '.owner'],'boxplot must be owned by its containing axes');end
    enum(node.orientation,{'vertical'},[path '.orientation']);
    if ~strcmp(xscale,'linear')||~strcmp(yscale,'linear'),invalid(path,'boxplots require linear axes');end
    vectors={'positions','lowerWhisker','q1','median','q3','upperWhisker'};count=numel(node.positions);
    for k=1:numel(vectors),v=node.(vectors{k});numericVector(v,[path '.' vectors{k}]);if numel(v)~=count||any(~isfinite(v)),invalid([path '.' vectors{k}],'must match positions and be finite');end,end
    if count<1||any(diff(node.positions)<=0),invalid([path '.positions'],'must be nonempty and strictly increasing');end
    if any(node.lowerWhisker>node.q1|node.q1>node.median|node.median>node.q3|node.q3>node.upperWhisker),invalid(path,'box statistics must be ordered');end
    numericVector(node.outlierPositions,[path '.outlierPositions']);numericVector(node.outlierValues,[path '.outlierValues']);
    if numel(node.outlierPositions)~=numel(node.outlierValues)||any(~isfinite(node.outlierPositions))||any(~isfinite(node.outlierValues)),invalid(path,'outlier coordinates must be paired and finite');end
    positiveScalar(node.boxWidth,[path '.boxWidth']);positiveScalar(node.boxLineWidth,[path '.boxLineWidth']);
    validateColor(node.boxColor,[path '.boxColor']);validateColor(node.medianColor,[path '.medianColor']);validateColor(node.whiskerColor,[path '.whiskerColor']);validateColor(node.outlierColor,[path '.outlierColor']);
    nonnegativeScalar(node.medianLineWidth,[path '.medianLineWidth']);validateStyle(node.medianLineStyle,[path '.medianLineStyle']);
    nonnegativeScalar(node.whiskerLineWidth,[path '.whiskerLineWidth']);validateStyle(node.whiskerLineStyle,[path '.whiskerLineStyle']);
    validateMarker(node.outlierMarker,[path '.outlierMarker']);if strcmp(node.outlierMarker,'none'),invalid([path '.outlierMarker'],'must remain visible');end
    positiveScalar(node.outlierMarkerSize,[path '.outlierMarkerSize']);
end

function validateBar(node, path, axesId, xscale, yscale)
    names={'owner','orientation','mode','groupId','groupIndex','groupCount', ...
        'categories','values','barWidth','baseline','faceVisible','faceColor', ...
        'edgeVisible','edgeColor','lineWidth','lineStyle'};
    requireFields(node,names,path);
    validateOwner(node.owner,{axesId},m2t2.ir.makeLayout(),[path '.owner']);
    if ~strcmp(node.owner.kind,'axes')||~strcmp(node.owner.id,axesId)
        invalid([path '.owner'],'bar series must be owned by its containing axes');
    end
    enum(node.orientation,{'vertical'},[path '.orientation']);
    enum(node.mode,{'grouped'},[path '.mode']);nonemptyText(node.groupId,[path '.groupId']);
    positiveInteger(node.groupIndex,[path '.groupIndex']);positiveInteger(node.groupCount,[path '.groupCount']);
    if node.groupIndex>node.groupCount,invalid([path '.groupIndex'],'must not exceed groupCount');end
    numericVector(node.categories,[path '.categories']);numericVector(node.values,[path '.values']);
    if isempty(node.categories)||numel(node.categories)~=numel(node.values)|| ...
            any(~isfinite(node.categories))||any(~isfinite(node.values))
        invalid(path,'bar categories and values must be equal-length finite nonempty vectors');
    end
    if numel(node.categories)>1&&any(diff(node.categories)<=0)
        invalid([path '.categories'],'numeric categories must be strictly increasing');
    end
    if ~strcmp(xscale,'linear')||~strcmp(yscale,'linear')
        invalid(path,'grouped bars require linear axes');
    end
    positiveScalar(node.barWidth,[path '.barWidth']);
    if node.barWidth>1,invalid([path '.barWidth'],'must not exceed 1');end
    finiteScalar(node.baseline,[path '.baseline']);logicalScalar(node.faceVisible,[path '.faceVisible']);
    validateColor(node.faceColor,[path '.faceColor']);logicalScalar(node.edgeVisible,[path '.edgeVisible']);
    validateColor(node.edgeColor,[path '.edgeColor']);nonnegativeScalar(node.lineWidth,[path '.lineWidth']);
    validateStyle(node.lineStyle,[path '.lineStyle']);
end

function validateBarGroups(series,path)
    bars=series(cellfun(@(n)strcmp(n.kind,'m2t2.bar'),series));
    if isempty(bars),return;end
    groups=unique(cellfun(@(n)n.groupId,bars,'UniformOutput',false));
    for g=1:numel(groups)
        peers=bars(cellfun(@(n)strcmp(n.groupId,groups{g}),bars));first=peers{1};
        if numel(peers)~=first.groupCount,invalid([path '.series'],'bar groupCount does not match peer count');end
        indices=sort(cellfun(@(n)n.groupIndex,peers));
        if ~isequal(indices,1:first.groupCount),invalid([path '.series'],'bar group indices must be contiguous and unique');end
        for k=2:numel(peers)
            item=peers{k};
            if item.groupCount~=first.groupCount||~isequal(item.categories,first.categories)|| ...
                    item.barWidth~=first.barWidth||item.baseline~=first.baseline
                invalid([path '.series'],'bar peers must share categories, width, baseline, and count');
            end
        end
    end
end

function validateImage(node, path)
    requireFields(node, {'x','y','cdata','mapping','interpolation'}, path);
    numericVector(node.x, [path '.x']); numericVector(node.y, [path '.y']);
    if isempty(node.x) || isempty(node.y) || any(~isfinite(node.x(:))) || ...
       any(~isfinite(node.y(:)))
        invalid(path, 'image coordinates must be nonempty and finite');
    end
    if numel(node.x) > 1 && ~(all(diff(node.x) > 0) || all(diff(node.x) < 0))
        invalid([path '.x'], 'image x coordinates must be strictly monotonic');
    end
    if numel(node.y) > 1 && ~(all(diff(node.y) > 0) || all(diff(node.y) < 0))
        invalid([path '.y'], 'image y coordinates must be strictly monotonic');
    end
    if ~(isnumeric(node.cdata) && ismatrix(node.cdata) && ...
         isequal(size(node.cdata), [numel(node.y) numel(node.x)]))
        invalid([path '.cdata'], 'expected rows(y)-by-columns(x) scalar matrix');
    end
    if any(isinf(node.cdata(:)))
        invalid([path '.cdata'], 'Inf is unsupported; NaN represents a missing cell');
    end
    enum(node.mapping, {'scaled'}, [path '.mapping']);
    enum(node.interpolation, {'nearest'}, [path '.interpolation']);
end

function validateLine(node, path)
    requireFields(node, {'x','y','color','width','style','marker','markerSize'}, path);
    validateXY(node.x, node.y, path); validateColor(node.color, [path '.color']);
    nonnegativeScalar(node.width, [path '.width']);
    validateStyle(node.style, [path '.style']);
    validateMarker(node.marker, [path '.marker']);
    nonnegativeScalar(node.markerSize, [path '.markerSize']);
end

function validateScatter(node, path)
    requireFields(node, {'x','y','color','colorMode','colorData','marker', ...
        'sizeMode','markerSize','edgeMode','edgeColor','faceMode','faceColor'}, path);
    validateXY(node.x, node.y, path); validateColor(node.color, [path '.color']);
    if isempty(node.x) || any(~isfinite(node.x(:))) || any(~isfinite(node.y(:)))
        invalid(path, 'scatter coordinates must be nonempty and finite');
    end
    validateMarker(node.marker, [path '.marker']);
    if strcmp(node.marker, 'none'), invalid([path '.marker'], 'scatter marker may not be none'); end
    enum(node.sizeMode, {'constant','per_point'}, [path '.sizeMode']);
    numericVector(node.markerSize, [path '.markerSize']);
    if any(~isfinite(node.markerSize(:))) || any(node.markerSize(:) < 0)
        invalid([path '.markerSize'], 'marker diameters must be finite and nonnegative');
    end
    if strcmp(node.sizeMode, 'constant') && numel(node.markerSize) ~= 1
        invalid([path '.markerSize'], 'constant size mode requires one marker diameter');
    elseif strcmp(node.sizeMode, 'per_point') && numel(node.markerSize) ~= numel(node.x)
        invalid([path '.markerSize'], 'per-point size mode requires one marker diameter per point');
    end
    enum(node.colorMode, {'constant_rgb','per_point_rgb','scalar_mapped'}, [path '.colorMode']);
    if strcmp(node.colorMode, 'constant_rgb')
        if ~isempty(node.colorData), invalid([path '.colorData'], 'constant RGB mode has no point color data'); end
    elseif strcmp(node.colorMode, 'per_point_rgb')
        if ~(isnumeric(node.colorData) && isequal(size(node.colorData), [numel(node.x) 3]) && ...
                all(isfinite(node.colorData(:))) && all(node.colorData(:) >= 0) && ...
                all(node.colorData(:) <= 1))
            invalid([path '.colorData'], 'per-point RGB mode requires an N-by-3 matrix in [0,1]');
        end
    else
        numericVector(node.colorData, [path '.colorData']);
        if numel(node.colorData) ~= numel(node.x) || any(~isfinite(node.colorData(:)))
            invalid([path '.colorData'], 'scalar mapped mode requires one finite value per point');
        end
    end
    enum(node.edgeMode, {'none','constant','data'}, [path '.edgeMode']);
    enum(node.faceMode, {'none','constant','data'}, [path '.faceMode']);
    validateColor(node.edgeColor, [path '.edgeColor']);
    validateColor(node.faceColor, [path '.faceColor']);
end

function validateErrorbar(node, path)
    names = {'x','y','xNegative','xPositive','yNegative','yPositive','color', ...
             'width','style','marker','markerSize'};
    requireFields(node, names, path);
    validateXY(node.x, node.y, path);
    count = numel(node.x);
    errors = {'xNegative','xPositive','yNegative','yPositive'};
    for k = 1:numel(errors)
        value = node.(errors{k}); numericVector(value, [path '.' errors{k}]);
        if numel(value) ~= count, invalid([path '.' errors{k}], 'error vector length must match x/y'); end
        finitePoints = isfinite(node.x) & isfinite(node.y);
        if any(~isfinite(value(finitePoints))) || any(value(finitePoints) < 0)
            invalid([path '.' errors{k}], 'errors for finite points must be finite and non-negative');
        end
        if any(~isnan(value(~finitePoints)))
            invalid([path '.' errors{k}], 'gap errors must be NaN');
        end
    end
    validateColor(node.color, [path '.color']);
    nonnegativeScalar(node.width, [path '.width']);
    validateStyle(node.style, [path '.style']);
    validateMarker(node.marker, [path '.marker']);
    nonnegativeScalar(node.markerSize, [path '.markerSize']);
end

function validateXY(x, y, path)
    numericVector(x, [path '.x']); numericVector(y, [path '.y']);
    if numel(x) ~= numel(y), invalid(path, 'x and y must contain the same number of values'); end
    if any(isinf(x(:))) || any(isinf(y(:)))
        invalid(path, 'Inf is not normalized; use paired NaN gap coordinates');
    end
    if any(xor(isnan(x(:)), isnan(y(:))))
        invalid(path, 'non-finite coordinates must be represented as paired NaN gaps');
    end
end

function validateColor(value, path)
    if ~(isnumeric(value) && isequal(size(value), [1 3]) && ...
         all(isfinite(value)) && all(value >= 0) && all(value <= 1))
        invalid(path, 'expected finite RGB values in [0,1]');
    end
end

function validateStyle(value, path)
    enum(value, {'solid','dashed','dotted','dashdot','none'}, path);
end

function validateMarker(value, path)
    enum(value, {'none','circle','plus','asterisk','point','x','square', ...
         'diamond','triangle_up','triangle_down','triangle_right','triangle_left', ...
         'pentagram','hexagram'}, path);
end

function requireStruct(value, path)
    if ~(isstruct(value) && isscalar(value)), invalid(path, 'expected a scalar struct'); end
end

function requireFields(value, names, path)
    for k = 1:numel(names)
        if ~isfield(value, names{k}), invalid(path, ['missing field ' names{k}]); end
    end
end

function finitePair(value, path)
    if ~(isnumeric(value) && isequal(size(value), [1 2]) && all(isfinite(value)))
        invalid(path, 'expected a finite 1-by-2 numeric vector');
    end
end

function finitePoint(value, path)
    if ~(isnumeric(value) && isequal(size(value), [1 2]) && all(isfinite(value)))
        invalid(path, 'expected a finite 1-by-2 point');
    end
end

function positiveTriple(value, path)
    if ~(isnumeric(value) && isequal(size(value), [1 3]) && all(isfinite(value)) && all(value > 0))
        invalid(path, 'expected a positive finite 1-by-3 numeric vector');
    end
end

function normalizedPoint(value, path)
    finitePoint(value, path);
    if any(value < 0) || any(value > 1)
        invalid(path, 'expected normalized coordinates in [0,1]');
    end
end

function finiteScalar(value, path)
    if ~(isnumeric(value) && isscalar(value) && isfinite(value))
        invalid(path, 'expected a finite scalar');
    end
end

function positiveScalar(value, path)
    if ~(isnumeric(value) && isscalar(value) && isfinite(value) && value > 0)
        invalid(path, 'expected a positive finite scalar');
    end
end

function finiteIncreasingPair(value, path)
    finitePair(value, path);
    if value(1) >= value(2), invalid(path, 'expected strictly increasing limits'); end
end

function numericVector(value, path)
    if ~(isnumeric(value) && (isempty(value) || isvector(value)))
        invalid(path, 'expected a numeric vector');
    end
end

function nonnegativeScalar(value, path)
    if ~(isnumeric(value) && isscalar(value) && isfinite(value) && value >= 0)
        invalid(path, 'expected a finite non-negative scalar');
    end
end

function positiveInteger(value, path)
    if ~(isnumeric(value) && isscalar(value) && isfinite(value) && ...
         value >= 1 && value == fix(value))
        invalid(path, 'expected a positive integer');
    end
end

function logicalScalar(value, path)
    if ~(islogical(value) && isscalar(value)), invalid(path, 'expected a logical scalar'); end
end

function nonemptyText(value, path)
    textScalar(value, path); if isempty(value), invalid(path, 'expected non-empty text'); end
end

function textScalar(value, path)
    if ~(ischar(value) && (isempty(value) || isrow(value)))
        invalid(path, 'expected a character row vector');
    end
end

function enum(value, values, path)
    textScalar(value, path);
    if ~any(strcmp(value, values)), invalid(path, ['unsupported value ' value]); end
end

function invalid(path, reason)
    error('M2T2:E003:InvalidIR', 'M2T2-E003 InvalidIR: path=%s reason=%s', path, reason);
end

function invalidPlacement(path, reason)
    error('M2T2:E009:InvalidPlacement', ...
          'M2T2-E009 InvalidPlacement: path=%s reason=%s', path, reason);
end

function invalidColorbarOwnership(path, reason)
    error('M2T2:E011:UnsupportedColorbarOwnership', ...
          'M2T2-E011 UnsupportedColorbarOwnership: path=%s reason=%s', path, reason);
end

function invalidReference(path, reason)
    error('M2T2:E012:InvalidFigureElementReference', ...
          'M2T2-E012 InvalidFigureElementReference: path=%s reason=%s', path, reason);
end
