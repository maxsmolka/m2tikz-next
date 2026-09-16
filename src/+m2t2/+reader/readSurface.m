function node = readSurface(handle, path)
%READSURFACE Read the opaque, scalar-colored interpolated Surface slice.
    m2t2.reader.assertSupportedProperties(handle,path,'primitive');
    if ~strcmp(get(handle,'Marker'),'none')
        error('M2T2:E007:UnsupportedProperty','Surface markers are not represented: %s',path);
    end
    if ~strcmp(get(handle, 'Type'), 'surface')
        diagnostic('E031:Unsupported3DPrimitive', path, 'expected Surface');
    end
    faceAlpha = get(handle, 'FaceAlpha'); edgeAlpha = get(handle, 'EdgeAlpha');
    if ~(isnumeric(faceAlpha) && isscalar(faceAlpha) && faceAlpha == 1) || ...
       ~(isnumeric(edgeAlpha) && isscalar(edgeAlpha) && edgeAlpha == 1)
        diagnostic('E035:UnsupportedSurfaceTransparency', path, ...
            'only opaque FaceAlpha=1 and EdgeAlpha=1 are supported');
    end
    faceColor=get(handle,'FaceColor');
    wire=ischar(faceColor)&&strcmpi(faceColor,'none');
    if ~wire && ~(ischar(faceColor)&&strcmpi(faceColor,'interp'))
        diagnostic('E034:UnsupportedSurfaceColorMode', path, ...
            'only FaceColor=interp is supported');
    end
    edgeColor = get(handle, 'EdgeColor'); lineStyle = char(get(handle, 'LineStyle'));
    edgeColorNone = ischar(edgeColor) && strcmpi(edgeColor, 'none');
    if wire
        if ~(isnumeric(edgeColor)&&numel(edgeColor)==3&&all(isfinite(edgeColor))&& ...
                all(edgeColor>=0)&&all(edgeColor<=1)) || strcmpi(lineStyle,'none') || ...
                ~strcmpi(get(handle,'MeshStyle'),'both')
            diagnostic('E033:UnsupportedSurfaceEdgeMode',path, ...
                'wire mesh requires constant RGB edges, visible lines, and MeshStyle=both');
        end
    elseif ~(edgeColorNone || strcmpi(lineStyle, 'none'))
        diagnostic('E033:UnsupportedSurfaceEdgeMode', path, ...
            'only invisible edges (EdgeColor=none or LineStyle=none) are supported; mesh is outside M5.4');
    end
    if ~strcmpi(char(get(handle, 'CDataMapping')), 'scaled')
        diagnostic('E034:UnsupportedSurfaceColorMode', path, ...
            'only scaled scalar CData is supported');
    end
    x = double(get(handle, 'XData')); y = double(get(handle, 'YData'));
    z = double(get(handle, 'ZData')); c = double(get(handle, 'CData'));
    expected = size(z);
    if ~(ismatrix(z) && numel(expected) == 2 && all(expected >= 2) && ...
         isequal(size(x), expected) && isequal(size(y), expected) && ...
         isequal(size(c), expected))
        diagnostic('E033:UnsupportedSurfaceGeometry', path, ...
            'XData/YData/ZData/CData must be equal matrices of at least 2-by-2');
    end
    if any(~isfinite(x(:))) || any(~isfinite(y(:))) || ...
       any(~isfinite(z(:))) || any(~isfinite(c(:)))
        diagnostic('E038:Malformed3DData', path, ...
            'surface coordinates and scalar colors must be finite');
    end
    node = m2t2.ir.makeSurfaceSeries();
    if wire
        node.faceMode='none';node.edgeMode='constant';node.edgeColor=reshape(double(edgeColor),1,3);
        node.lineWidth=double(get(handle,'LineWidth'));
        node.lineStyle=m2t2.util.normalizeLineStyle(lineStyle,[path '.lineStyle']);
    end
    node.x = x; node.y = y; node.z = z; node.c = c;
    node.displayName = m2t2.ir.makeText(m2t2.util.textValue( ...
        get(handle, 'DisplayName'), [path '.displayName']), 'plain');
    node.visible = strcmpi(get(handle, 'Visible'), 'on');
end

function diagnostic(code, path, reason)
    name = strrep(code, ':', ' ');
    error(['M2T2:' code], 'M2T2-%s: path=%s reason=%s', name, path, reason);
end
