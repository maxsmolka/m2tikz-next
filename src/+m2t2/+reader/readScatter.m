function node = readScatter(handle, path)
%READSCATTER Normalize the explicit, reproducible rich 2-D scatter slice.
    z = property(handle, 'ZData', []);
    if ~isempty(z)
        diagnostic('E045:UnsupportedScatterDimensionality', path, ...
            'ZData must be empty for 2-D scatter');
    end
    rawX = property(handle, 'XData', []); rawY = property(handle, 'YData', []);
    if ~(isnumeric(rawX) && isvector(rawX) && isnumeric(rawY) && isvector(rawY) && ...
            numel(rawX) == numel(rawY) && ~isempty(rawX) && ...
            all(isfinite(rawX(:))) && all(isfinite(rawY(:))))
        diagnostic('E040:MalformedScatterData', path, ...
            'XData and YData must be equal-length nonempty finite numeric vectors');
    end
    x = reshape(double(rawX), 1, []); y = reshape(double(rawY), 1, []);
    count = numel(x);

    sizeData = property(handle, 'SizeData', 36);
    if ~(isnumeric(sizeData) && isvector(sizeData) && ~isempty(sizeData))
        diagnostic('E041:UnsupportedScatterSize', path, ...
            'SizeData must be one value or one value per point');
    end
    sizeData = reshape(double(sizeData), 1, []);
    if ~(numel(sizeData) == 1 || numel(sizeData) == count) || ...
            any(~isfinite(sizeData)) || any(sizeData < 0)
        diagnostic('E041:UnsupportedScatterSize', path, ...
            'SizeData must contain finite nonnegative marker areas for every point');
    end

    checkAlpha(handle, 'MarkerEdgeAlpha', path);
    checkAlpha(handle, 'MarkerFaceAlpha', path);
    edge = colorRole(property(handle, 'MarkerEdgeColor', 'flat'), ...
                     'MarkerEdgeColor', path);
    face = colorRole(property(handle, 'MarkerFaceColor', 'none'), ...
                     'MarkerFaceColor', path);

    cdata = property(handle, 'CData', []);
    needsData = strcmp(edge.mode, 'data') || strcmp(face.mode, 'data');
    [colorMode, color, colorData] = normalizeColorData(cdata, count, needsData, path);

    node = m2t2.ir.makeScatterSeries();
    node.x = x; node.y = y; node.colorMode = colorMode;
    node.color = color; node.colorData = colorData;
    node.marker = m2t2.util.normalizeMarker(get(handle, 'Marker'), [path '.marker']);
    if strcmp(node.marker, 'none')
        diagnostic('E044:UnsupportedScatterMarkerStyle', path, ...
            'Marker=none is outside the visible scatter slice');
    end
    if ~strcmp(face.mode, 'none') && any(strcmp(node.marker, ...
            {'plus','asterisk','point','x'}))
        diagnostic('E044:UnsupportedScatterMarkerStyle', path, ...
            'the selected marker has no faithful filled face representation');
    end
    node.markerSize = sqrt(sizeData);
    if numel(sizeData) == 1, node.sizeMode = 'constant'; else, node.sizeMode = 'per_point'; end
    node.edgeMode = edge.mode; node.edgeColor = edge.color;
    node.faceMode = face.mode; node.faceColor = face.color;
    if strcmp(colorMode, 'constant_rgb')
        if strcmp(edge.mode, 'data'), node.edgeColor = color; end
        if strcmp(face.mode, 'data'), node.faceColor = color; end
    end
    node.displayName = m2t2.ir.makeText( ...
        m2t2.util.textValue(get(handle, 'DisplayName'), [path '.displayName']), 'plain');
    node.visible = strcmpi(get(handle, 'Visible'), 'on');
end

function checkAlpha(handle, name, path)
    value = property(handle, name, 1);
    if ~(isnumeric(value) && isscalar(value) && isfinite(value) && value == 1)
        diagnostic('E043:UnsupportedScatterTransparency', path, ...
            [name ' must be the opaque scalar value 1']);
    end
end

function role = colorRole(value, name, path)
    role = struct('mode', '', 'color', [0 0 0]);
    if isnumeric(value)
        try, role.color = m2t2.util.normalizeColor(value, [path '.' name]);
        catch, diagnostic('E044:UnsupportedScatterMarkerStyle', path, ...
                [name ' must be none, flat, or one constant RGB value']); end
        role.mode = 'constant'; return;
    end
    if ~(ischar(value) || (isstring(value) && isscalar(value)))
        diagnostic('E044:UnsupportedScatterMarkerStyle', path, ...
            [name ' must be none, flat, or one constant RGB value']);
    end
    value = lower(char(value));
    if strcmp(value, 'none'), role.mode = 'none';
    elseif strcmp(value, 'flat'), role.mode = 'data';
    else
        diagnostic('E044:UnsupportedScatterMarkerStyle', path, ...
            [name '=' value ' is not an evidence-backed edge/face mode']);
    end
end

function [mode, color, data] = normalizeColorData(value, count, required, path)
    color = [0 0 1]; data = zeros(0, 3); mode = 'constant_rgb';
    if ~required, return; end
    if ~(isnumeric(value) && isreal(value) && ~isempty(value) && all(isfinite(value(:))))
        diagnostic('E042:UnsupportedScatterColor', path, ...
            'CData must be finite constant RGB, N-by-3 RGB, or N scalar values');
    end
    value = double(value);
    if isequal(size(value), [1 3]) && all(value >= 0) && all(value <= 1)
        color = value; return;
    end
    if ismatrix(value) && size(value, 1) == count && size(value, 2) == 3
        if any(value(:) < 0) || any(value(:) > 1)
            diagnostic('E042:UnsupportedScatterColor', path, ...
                'per-point RGB CData must lie in [0,1]');
        end
        mode = 'per_point_rgb'; data = value; color = value(1, :); return;
    end
    if isvector(value) && numel(value) == count
        mode = 'scalar_mapped'; data = reshape(value, 1, []); return;
    end
    diagnostic('E042:UnsupportedScatterColor', path, ...
        'CData shape must be 1-by-3 RGB, N-by-3 RGB, or an N-value scalar vector');
end

function value = property(handle, name, default)
    try, value = get(handle, name); catch, value = default; end
end

function diagnostic(code, path, reason)
    identifier = ['M2T2:' code]; label = strrep(code, ':', ' ');
    error(identifier, 'M2T2-%s: path=%s reason=%s', label, path, reason);
end
