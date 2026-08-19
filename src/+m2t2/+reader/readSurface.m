function node = readSurface(handle, path)
%READSURFACE Read the opaque, scalar-colored interpolated Surface slice.
    if ~strcmp(get(handle, 'Type'), 'surface')
        diagnostic('E031:Unsupported3DPrimitive', path, 'expected Surface');
    end
    faceAlpha = get(handle, 'FaceAlpha'); edgeAlpha = get(handle, 'EdgeAlpha');
    if ~(isnumeric(faceAlpha) && isscalar(faceAlpha) && faceAlpha == 1) || ...
       ~(isnumeric(edgeAlpha) && isscalar(edgeAlpha) && edgeAlpha == 1)
        diagnostic('E035:UnsupportedSurfaceTransparency', path, ...
            'only opaque FaceAlpha=1 and EdgeAlpha=1 are supported');
    end
    if ~strcmpi(char(get(handle, 'FaceColor')), 'interp')
        diagnostic('E034:UnsupportedSurfaceColorMode', path, ...
            'only FaceColor=interp is supported');
    end
    edgeColor = get(handle, 'EdgeColor'); lineStyle = char(get(handle, 'LineStyle'));
    edgeColorNone = ischar(edgeColor) && strcmpi(edgeColor, 'none');
    if ~(edgeColorNone || strcmpi(lineStyle, 'none'))
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
    node.x = x; node.y = y; node.z = z; node.c = c;
    node.displayName = m2t2.ir.makeText(m2t2.util.textValue( ...
        get(handle, 'DisplayName'), [path '.displayName']), 'plain');
    node.visible = strcmpi(get(handle, 'Visible'), 'on');
end

function diagnostic(code, path, reason)
    name = strrep(code, ':', ' ');
    error(['M2T2:' code], 'M2T2-%s: path=%s reason=%s', name, path, reason);
end
