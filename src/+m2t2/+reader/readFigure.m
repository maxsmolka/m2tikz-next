function ir = readFigure(figureHandle)
%READFIGURE Normalize supported figure geometry and axes in back-to-front order.
    if ~(isscalar(figureHandle) && ishandle(figureHandle) && ...
         strcmp(get(figureHandle, 'Type'), 'figure'))
        error('M2T2:E002:InvalidArgument', ...
              'M2T2-E002 InvalidArgument: expected a scalar figure handle.');
    end

    children = flipud(allchild(figureHandle));
    axesHandles = {};
    legendHandles = {};
    colorbarHandles = {};
    annotationPanes = {};
    for k = 1:numel(children)
        type = get(children(k), 'Type');
        tag = property(children(k), 'Tag', '');
        if strcmp(type, 'legend') || (strcmp(type, 'axes') && strcmp(tag, 'legend'))
            legendHandles{end + 1} = children(k); %#ok<AGROW>
        elseif strcmp(type, 'colorbar') || (strcmp(type, 'axes') && strcmp(tag, 'colorbar'))
            colorbarHandles{end + 1} = children(k); %#ok<AGROW>
        elseif strcmp(type, 'axes')
            axesHandles{end + 1} = children(k); %#ok<AGROW>
        elseif isAnnotationPane(children(k), figureHandle)
            annotationPanes{end + 1} = children(k); %#ok<AGROW>
        elseif ~any(strcmp(type, {'uimenu','uitoolbar','uicontextmenu'}))
            unsupported(type, sprintf('figure.children{%d}', k));
        end
    end

    axesItems = cell(1, numel(axesHandles));
    annotations = {};
    usedLegends = false(1, numel(legendHandles));
    for k = 1:numel(axesHandles)
        axesId = sprintf('axes-%d', k);
        legendIndex = legendForAxes(legendHandles, axesHandles{k}, numel(axesHandles));
        if numel(legendIndex) > 1
            unsupportedSharedLegend(sprintf('figure.axes{%d}.legend', k), ...
                                    'multiple legends resolve to one axes');
        end
        legendHandle = [];
        if ~isempty(legendIndex)
            legendHandle = legendHandles{legendIndex};
            usedLegends(legendIndex) = true;
        end
        path = sprintf('figure.axes{%d}', k);
        [axesItems{k}, axesAnnotations] = m2t2.reader.readAxes( ...
            axesHandles{k}, path, axesId, legendHandle);
        annotations = [annotations, axesAnnotations]; %#ok<AGROW>
        for prior = 1:k-1
            if placementsOverlap(axesItems{prior}.placement, axesItems{k}.placement)
                axesItems{k}.overlayOf = axesItems{prior}.id;
                break;
            end
        end
    end
    if any(~usedLegends)
        unsupportedSharedLegend('figure.layout', ...
            'legend could not be assigned to exactly one axes');
    end

    ir = m2t2.ir.makeFigure(axesItems);
    ir.size = m2t2.reader.readFigureSize(figureHandle, 'figure.size');
    ir.layout = m2t2.reader.inferLayout(axesItems);
    ir.elements = cell(1, numel(colorbarHandles));
    for k = 1:numel(colorbarHandles)
        ownerIndex = colorbarOwner(colorbarHandles{k}, axesHandles);
        if isempty(ownerIndex)
            unsupportedColorbarOwnership(sprintf('figure.elements{%d}', k), ...
                'runtime colorbar does not resolve to exactly one axes');
        end
        path = sprintf('figure.elements{%d}', k);
        ir.elements{k} = m2t2.reader.readColorbar(colorbarHandles{k}, ...
            axesItems{ownerIndex}, path, sprintf('colorbar-%d', k));
    end
    figureAnnotationIndex = 0;
    for p = 1:numel(annotationPanes)
        paneChildren = flipud(allchild(annotationPanes{p}));
        for k = 1:numel(paneChildren)
            figureAnnotationIndex = figureAnnotationIndex + 1;
            path = sprintf('figure.annotations{%d}', ...
                numel(annotations) + 1);
            id = sprintf('figure-annotation-%d', figureAnnotationIndex);
            type = char(get(paneChildren(k), 'Type'));
            if ~any(strcmp(type, {'arrowshape','doubleendarrowshape'}))
                unsupportedAnnotation(type, path);
            end
            annotations{end + 1} = m2t2.reader.readArrowAnnotation( ...
                paneChildren(k), annotationPanes{p}, path, id); %#ok<AGROW>
        end
    end
    ir.annotations = annotations;
    m2t2.ir.validate(ir);
end

function yes = isAnnotationPane(handle, figureHandle)
    yes = false;
    try
        yes = strcmp(get(handle, 'Type'), 'annotationpane') && ...
              strcmp(get(handle, 'Tag'), 'scribeOverlay') && ...
              strcmp(get(handle, 'HandleVisibility'), 'off') && ...
              sameGraphicsHandle(get(handle, 'Parent'), figureHandle);
    catch
        yes = false;
    end
end

function unsupportedAnnotation(type, path)
    error('M2T2:E013:UnsupportedAnnotationType', ...
          'M2T2-E013 UnsupportedAnnotationType: path=%s type=%s', path, type);
end

function yes = sameGraphicsHandle(first, second)
    yes = false;
    try
        comparison = first == second;
        yes = isscalar(comparison) && logical(comparison);
    catch
        yes = isequal(first, second);
    end
end

function index = colorbarOwner(colorbarHandle, axesHandles)
    owner = property(colorbarHandle, '__axes_handle__', []);
    if isempty(owner), owner = property(colorbarHandle, 'Axes', []); end
    index = [];
    for k = 1:numel(axesHandles)
        if numel(owner) == 1 && isequal(owner, axesHandles{k}), index = k; return; end
        linked = property(axesHandles{k}, '__colorbar_handle__', []);
        if numel(linked) == 1 && isequal(linked, colorbarHandle), index = k; return; end
    end
end

function indices = legendForAxes(legends, axesHandle, axesCount)
    indices = [];
    for k = 1:numel(legends)
        owner = [];
        try, owner = getappdata(legends{k}, '__axes_handle__'); catch, end
        if isempty(owner), owner = property(legends{k}, 'Axes', []); end
        if numel(owner) > 1
            unsupportedSharedLegend('figure.layout', 'legend references multiple axes');
        end
        if ~isempty(owner) && isequal(owner, axesHandle)
            indices(end + 1) = k; %#ok<AGROW>
        end
    end
    if isempty(indices) && axesCount == 1 && numel(legends) == 1
        indices = 1;
    end
end

function yes = placementsOverlap(first, second)
    overlapX = min(first.x + first.width, second.x + second.width) - max(first.x, second.x);
    overlapY = min(first.y + first.height, second.y + second.height) - max(first.y, second.y);
    yes = overlapX > 1e-10 && overlapY > 1e-10;
end

function value = property(handle, name, default)
    try, value = get(handle, name); catch, value = default; end
end

function unsupported(type, path)
    error('M2T2:E001:UnsupportedObject', ...
          'M2T2-E001 UnsupportedObject: type=%s path=%s', type, path);
end

function unsupportedSharedLegend(path, reason)
    error('M2T2:E010:UnsupportedSharedLegend', ...
          'M2T2-E010 UnsupportedSharedLegend: path=%s reason=%s', path, reason);
end

function unsupportedColorbarOwnership(path, reason)
    error('M2T2:E011:UnsupportedColorbarOwnership', ...
          'M2T2-E011 UnsupportedColorbarOwnership: path=%s reason=%s', path, reason);
end
