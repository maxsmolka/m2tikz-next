function node = readScatter(handle, path)
%READSCATTER Normalize a constant-style 2-D scatter series.
    try
        z = get(handle, 'ZData');
        if ~isempty(z), unsupportedProperty(path, 'ZData', '3-D scatter'); end
    catch err
        if strcmp(err.identifier, 'M2T2:E007:UnsupportedProperty'), rethrow(err); end
    end
    [x, y] = m2t2.util.normalizeXY(get(handle, 'XData'), get(handle, 'YData'), path);
    sizes = reshape(double(get(handle, 'SizeData')), 1, []);
    if isempty(sizes), sizes = 36; end
    if any(~isfinite(sizes)) || any(sizes < 0) || any(abs(sizes - sizes(1)) > 1e-12)
        unsupportedProperty(path, 'SizeData', 'per-point or invalid sizes');
    end
    cdata = double(get(handle, 'CData'));
    if size(cdata, 2) ~= 3 || isempty(cdata)
        unsupportedProperty(path, 'CData', 'mapped or missing per-point color');
    end
    if size(cdata, 1) > 1 && any(any(abs(cdata - repmat(cdata(1, :), size(cdata, 1), 1)) > 1e-12))
        unsupportedProperty(path, 'CData', 'per-point colors');
    end
    face = get(handle, 'MarkerFaceColor');
    if ~(ischar(face) && strcmpi(face, 'none'))
        unsupportedProperty(path, 'MarkerFaceColor', 'filled scatter');
    end
    edge = get(handle, 'MarkerEdgeColor');
    if isnumeric(edge), color = m2t2.util.normalizeColor(edge, [path '.color']);
    else, color = m2t2.util.normalizeColor(cdata(1, :), [path '.color']); end

    node = m2t2.ir.makeScatterSeries();
    node.x = x; node.y = y; node.color = color;
    node.marker = m2t2.util.normalizeMarker(get(handle, 'Marker'), [path '.marker']);
    node.markerSize = sqrt(sizes(1));
    node.displayName = m2t2.ir.makeText( ...
        m2t2.util.textValue(get(handle, 'DisplayName'), [path '.displayName']), 'plain');
    node.visible = strcmpi(get(handle, 'Visible'), 'on');
end

function unsupportedProperty(path, property, value)
    error('M2T2:E007:UnsupportedProperty', ...
          'M2T2-E007 UnsupportedProperty: type=scatter path=%s property=%s value=%s', ...
          path, property, value);
end
