function [node, annotations] = readAxes(axesHandle, path, axesId, legendHandle)
%READAXES Normalize supported 2-D or narrow scientific 3-D Cartesian axes.
    if nargin < 3, axesId = 'axes-1'; end
    if nargin < 4, legendHandle = []; end
    try
        yRulers = get(axesHandle, 'YAxis');
        if numel(yRulers) > 1, unsupported('yyaxis', path); end
    catch err
        if strcmp(err.identifier, 'M2T2:E001:UnsupportedObject'), rethrow(err); end
    end
    viewValue = get(axesHandle, 'View');
    if numel(viewValue) ~= 2 || any(~isfinite(viewValue)), unsupported('axes', path); end
    is3d = abs(viewValue(2) - 90) > 1e-10;

    node = m2t2.ir.makeAxes();
    if is3d
        projection = lower(char(get(axesHandle, 'Projection')));
        if ~strcmp(projection, 'orthographic')
            error('M2T2:E032:Unsupported3DProjection', ...
                'M2T2-E032 Unsupported3DProjection: path=%s projection=%s', path, projection);
        end
        node.kind = 'm2t2.axes3d'; node.dimensionality = 3;
        node.zlim = reshape(double(get(axesHandle, 'ZLim')), 1, 2);
        node.zscale = lower(get(axesHandle, 'ZScale'));
        node.zdirection = lower(get(axesHandle, 'ZDir'));
        node.view = reshape(double(viewValue), 1, 2);
        node.projection = projection;
        node.dataAspectRatio = reshape(double(get(axesHandle, 'DataAspectRatio')), 1, 3);
        node.plotBoxAspectRatio = reshape(double(get(axesHandle, 'PlotBoxAspectRatio')), 1, 3);
        node.zticks = m2t2.reader.readTickSpec(axesHandle, 'Z', [path '.zticks']);
        node.zlabel = m2t2.reader.readText(get(axesHandle, 'ZLabel'), [path '.zlabel']);
        node.zgrid = strcmpi(get(axesHandle, 'ZGrid'), 'on');
    end
    node.id = axesId;
    node.placement = m2t2.reader.readNormalizedPosition(axesHandle, [path '.placement']);
    node.xlim = reshape(double(get(axesHandle, 'XLim')), 1, 2);
    node.ylim = reshape(double(get(axesHandle, 'YLim')), 1, 2);
    node.xscale = lower(get(axesHandle, 'XScale'));
    node.yscale = lower(get(axesHandle, 'YScale'));
    node.xdirection = lower(get(axesHandle, 'XDir'));
    node.ydirection = lower(get(axesHandle, 'YDir'));
    node.box = lower(char(get(axesHandle, 'Box')));
    colorScale = 'linear';
    try, colorScale = lower(get(axesHandle, 'ColorScale')); catch, end
    node.colorMapping = m2t2.ir.makeColorMapping( ...
        reshape(double(get(axesHandle, 'CLim')), 1, 2), colorScale, ...
        double(colormap(axesHandle)));
    node.xticks = m2t2.reader.readTickSpec(axesHandle, 'X', [path '.xticks']);
    node.yticks = m2t2.reader.readTickSpec(axesHandle, 'Y', [path '.yticks']);
    node.xlabel = m2t2.reader.readText(get(axesHandle, 'XLabel'), [path '.xlabel']);
    node.ylabel = m2t2.reader.readText(get(axesHandle, 'YLabel'), [path '.ylabel']);
    node.title = m2t2.reader.readText(get(axesHandle, 'Title'), [path '.title']);
    node.xgrid = strcmpi(get(axesHandle, 'XGrid'), 'on');
    node.ygrid = strcmpi(get(axesHandle, 'YGrid'), 'on');

    ignored = [get(axesHandle, 'XLabel'), get(axesHandle, 'YLabel'), get(axesHandle, 'Title')];
    try
        ignored = [ignored, get(axesHandle, 'ZLabel')];
    catch
    end
    children = flipud(allchild(axesHandle));
    barHandles = {};
    for k = 1:numel(children)
        if m2t2.reader.isBarObject(children(k), axesHandle)
            barHandles{end+1} = children(k); %#ok<AGROW>
        end
    end
    validateBarPeerGroup(barHandles, path);
    series = {};
    annotations = {};
    visibleIndex = 0;
    for k = 1:numel(children)
        if any(children(k) == ignored)
            continue;
        end
        visibleIndex = visibleIndex + 1;
        type = get(children(k), 'Type');
        childPath = sprintf('%s.children{%d}', path, visibleIndex);
        tag = '';
        try, tag = get(children(k), 'Tag'); catch, end
        if strcmp(type, 'hggroup') && isPatternRuntimeEmptyGroup(children(k), axesHandle)
            visibleIndex = visibleIndex - 1;
            continue;
        end
        if strcmp(type, 'hggroup') && isStructuredSurfaceGroup(children(k), axesHandle)
            groupChildren = flipud(allchild(children(k)));
            for g = 1:numel(groupChildren)
                groupType = get(groupChildren(g), 'Type');
                groupPath = sprintf('%s.patterngroup{%d}', childPath, g);
                if strcmp(groupType, 'text')
                    continue; % Proven compound-surface-owned axis decoration.
                elseif strcmp(groupType, 'surface')
                    item = m2t2.reader.readSurface(groupChildren(g), groupPath);
                elseif strcmp(groupType, 'line')
                    item = m2t2.reader.readLine3(groupChildren(g), groupPath);
                elseif strcmp(groupType, 'patch')
                    item = m2t2.reader.readPatch3(groupChildren(g), groupPath);
                else
                    error('M2T2:E031:Unsupported3DPrimitive', ...
                        'M2T2-E031 Unsupported3DPrimitive: type=%s path=%s', groupType, groupPath);
                end
                item.id = sprintf('%s-series-%d', axesId, numel(series) + 1);
                series{end + 1} = item; %#ok<AGROW>
            end
            continue;
        end
        if strcmp(type, 'text') && (strcmp(tag, 'colorbar') || ...
                isLegendRuntimeDecoration(children(k), axesHandle, legendHandle))
            visibleIndex = visibleIndex - 1;
            continue;
        end
        switch type
            case 'text'
                annotationId = sprintf('%s-annotation-%d', axesId, numel(annotations) + 1);
                item = m2t2.reader.readTextAnnotation(children(k), childPath, ...
                    annotationId, axesId);
                annotations{end + 1} = item; %#ok<AGROW>
                continue;
            case 'line'
                if is3d && ~isempty(get(children(k), 'ZData'))
                    item = m2t2.reader.readLine3(children(k), childPath);
                else
                    item = m2t2.reader.readLine(children(k), childPath);
                end
            case 'surface'
                if ~is3d, unsupported(type, childPath); end
                item = m2t2.reader.readSurface(children(k), childPath);
            case 'bar'
                item = m2t2.reader.readBar(children(k), axesHandle, childPath, ...
                    axesId, barIndex(barHandles, children(k)), numel(barHandles));
            case 'scatter'
                item = m2t2.reader.readScatter(children(k), childPath);
            case 'errorbar'
                item = m2t2.reader.readErrorbar(children(k), childPath);
            case 'hggroup'
                if m2t2.reader.isBoxplotObject(children(k),axesHandle)
                    item=m2t2.reader.readBoxplot(children(k),axesHandle,childPath,axesId);
                elseif m2t2.reader.isBarObject(children(k), axesHandle)
                    item = m2t2.reader.readBar(children(k), axesHandle, childPath, ...
                        axesId, barIndex(barHandles, children(k)), numel(barHandles));
                elseif isErrorbar(children(k))
                    item = m2t2.reader.readErrorbar(children(k), childPath);
                elseif isScatterGroup(children(k))
                    item = m2t2.reader.readScatter(children(k), childPath);
                else
                    unsupported(type, childPath);
                end
            case 'image'
                item = m2t2.reader.readImage(children(k), childPath);
            case 'light'
                error('M2T2:E036:UnsupportedLighting', ...
                    'M2T2-E036 UnsupportedLighting: path=%s reason=lighting and material semantics are outside M5.4', childPath);
            case 'patch'
                if is3d
                    error('M2T2:E037:Unsupported3DPatchVariant', ...
                        'M2T2-E037 Unsupported3DPatchVariant: path=%s reason=arbitrary 3-D patches are unsupported', childPath);
                end
                unsupported(type, childPath);
            otherwise
                unsupported(type, childPath);
        end
        item.id = sprintf('%s-series-%d', axesId, numel(series) + 1);
        series{end + 1} = item; %#ok<AGROW>
    end
    hasScalarScatter = any(cellfun(@(item) strcmp(item.kind, 'm2t2.scatter') && ...
        strcmp(item.colorMode, 'scalar_mapped'), series));
    if hasScalarScatter && ~strcmp(node.colorMapping.scale, 'linear')
        error('M2T2:E046:UnsupportedScatterColorMapping', ...
            'M2T2-E046 UnsupportedScatterColorMapping: path=%s reason=scalar scatter requires a linear axes ColorScale', path);
    end
    if any(cellfun(@(item) strcmp(item.kind, 'm2t2.image'), series)) && ...
            ~strcmp(node.colorMapping.scale, 'linear')
        error('M2T2:E_IMAGE_MAPPING_UNSUPPORTED', ...
              'M2T2 image mapping unsupported: path=%s scale=%s', ...
              path, node.colorMapping.scale);
    end
    node.series = series;
    node.legend = m2t2.reader.readLegend(legendHandle, series, [path '.legend']);
end

function yes = isPatternRuntimeEmptyGroup(handle, axesHandle)
    yes = false;
    try
        if ~strcmp(get(handle, 'Type'), 'hggroup') || ~isempty(allchild(handle)) || ...
           ~strcmp(get(handle, 'HandleVisibility'), 'off') || ...
           ~isempty(get(handle, 'UserData')) || ~isequal(get(handle, 'Parent'), axesHandle)
            return;
        end
        tag = char(get(handle, 'Tag'));
        if isempty(tag) || ~isfinite(str2double(tag)), return; end
        siblings = allchild(axesHandle);
        yes = any(arrayfun(@(candidate) isStructuredSurfaceGroup(candidate, axesHandle), siblings));
    catch
        yes = false;
    end
end

function yes = isStructuredSurfaceGroup(handle, axesHandle)
    yes = false;
    try
        if ~strcmp(get(handle, 'Type'), 'hggroup') || ...
           ~strcmp(get(handle, 'Tag'), 'patterngroup') || ...
           ~isequal(get(handle, 'Parent'), axesHandle)
            return;
        end
        children = allchild(handle); types = cell(1, numel(children));
        surfaceCount = 0; patchCount = 0; lineCount = 0;
        for k = 1:numel(children)
            types{k} = get(children(k), 'Type');
            if strcmp(types{k}, 'surface')
                surfaceCount = surfaceCount + strcmp(get(children(k), 'Tag'), '3D polar plot');
            elseif strcmp(types{k}, 'patch')
                faces = get(children(k), 'Faces'); vertices = get(children(k), 'Vertices');
                if ~isequal(size(faces), [1 3]) || ~isequal(size(vertices), [3 3]), return; end
                patchCount = patchCount + 1;
            elseif strcmp(types{k}, 'line')
                if isempty(get(children(k), 'ZData')), return; end
                lineCount = lineCount + 1;
            elseif ~strcmp(types{k}, 'text')
                return;
            end
        end
        yes = surfaceCount == 1 && lineCount >= 1 && patchCount >= 1;
    catch
        yes = false;
    end
end

function validateBarPeerGroup(handles, path)
    if numel(handles) < 2, return; end
    baseline = get(handles{1}, 'Baseline');
    for k = 2:numel(handles)
        if ~sameHandle(get(handles{k}, 'Baseline'), baseline)
            error('M2T2:E023:AmbiguousBarOwnership', ...
                'M2T2-E023 AmbiguousBarOwnership: path=%s reason=multiple independent bar peer groups on one axes are outside M5.2', path);
        end
    end
end

function index = barIndex(handles, target)
    index = [];
    for k=1:numel(handles),if sameHandle(handles{k},target),index=k;return;end,end
end

function yes = sameHandle(first, second)
    try,value=first==second;yes=isscalar(value)&&logical(value);
    catch,yes=isequal(first,second);end
end

function yes = isLegendRuntimeDecoration(handle, axesHandle, legendHandle)
    yes = false;
    try
        linkedLegend = get(axesHandle, '__legend_handle__');
        if isempty(legendHandle), legendHandle = linkedLegend; end
        if isempty(legendHandle) || ~ishandle(legendHandle) || ...
                ~strcmp(get(legendHandle, 'Type'), 'axes') || ...
                ~strcmp(get(legendHandle, 'Tag'), 'legend')
            return;
        end
        tag = get(handle, 'Tag');
        recognizedTag = any(strcmp(tag, {'__legend_watcher__','deletelegend'}));
        hiddenEmptyText = strcmp(get(handle, 'Type'), 'text') && ...
                          isequal(get(handle, 'Parent'), axesHandle) && ...
                          strcmp(get(handle, 'HandleVisibility'), 'off') && ...
                          strcmp(get(handle, 'Visible'), 'off') && ...
                          isempty(get(handle, 'String'));
        owners = getappdata(legendHandle, '__axes_handle__');
        ownershipProven = containsHandle(owners, axesHandle) || ...
                          containsHandle(linkedLegend, legendHandle);
        callback = get(handle, 'DeleteFcn');
        if ~(recognizedTag && hiddenEmptyText && ...
             ownershipProven && iscell(callback))
            return;
        end
        for k = 2:numel(callback)
            if containsHandle(callback{k}, legendHandle)
                yes = true;
                return;
            end
        end
    catch
        yes = false;
    end
end

function yes = containsHandle(values, target)
    yes = false;
    try
        yes = any(values(:) == target);
    catch
        try
            yes = any(arrayfun(@(value) isequal(value, target), values(:)));
        catch
            yes = false;
        end
    end
end

function yes = isErrorbar(handle)
    try
        get(handle, 'LData'); get(handle, 'UData');
        yes = true;
    catch
        yes = false;
    end
end

function yes = isScatterGroup(handle)
    yes = false;
    try
        if ~strcmp(get(handle, 'Type'), 'hggroup') || ...
                ~strcmp(getappdata(handle, '__creator__'), '__scatter__') || ...
                ~strcmp(get(get(handle, 'Parent'), 'Type'), 'axes')
            return;
        end
        x = get(handle, 'XData');
        y = get(handle, 'YData');
        get(handle, 'ZData');
        get(handle, 'SizeData');
        get(handle, 'CData');
        get(handle, 'Marker');
        get(handle, 'MarkerEdgeColor');
        get(handle, 'MarkerFaceColor');
        get(handle, 'DisplayName');
        if numel(x) ~= numel(y), return; end
        children = allchild(handle);
        if ~all(arrayfun(@(child) strcmp(get(child, 'Type'), 'patch') && ...
                        isequal(get(child, 'Parent'), handle), children))
            return;
        end
        yes = true;
    catch
        yes = false;
    end
end

function unsupported(type, path)
    error('M2T2:E001:UnsupportedObject', ...
          'M2T2-E001 UnsupportedObject: type=%s path=%s', type, path);
end
