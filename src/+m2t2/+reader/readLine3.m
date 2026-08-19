function node = readLine3(handle, path)
%READLINE3 Normalize a semantic Plot3 line without runtime state.
    x = reshape(double(get(handle, 'XData')), 1, []);
    y = reshape(double(get(handle, 'YData')), 1, []);
    z = reshape(double(get(handle, 'ZData')), 1, []);
    if isempty(z) || numel(x) ~= numel(y) || numel(x) ~= numel(z) || ...
       any(isinf(x)) || any(isinf(y)) || any(isinf(z)) || ...
       any(xor(isnan(x), isnan(y))) || any(xor(isnan(x), isnan(z)))
        error('M2T2:E038:Malformed3DData', ...
            'M2T2-E038 Malformed3DData: path=%s reason=Plot3 coordinates must be equal-length finite triples or shared NaN gaps', path);
    end
    node = m2t2.ir.makeLine3Series();
    node.x = x; node.y = y; node.z = z;
    node.color = m2t2.util.normalizeColor(get(handle, 'Color'), [path '.color']);
    node.width = double(get(handle, 'LineWidth'));
    node.style = m2t2.util.normalizeLineStyle(get(handle, 'LineStyle'), [path '.style']);
    node.marker = m2t2.util.normalizeMarker(get(handle, 'Marker'), [path '.marker']);
    node.markerSize = double(get(handle, 'MarkerSize'));
    node.displayName = m2t2.ir.makeText(m2t2.util.textValue( ...
        get(handle, 'DisplayName'), [path '.displayName']), 'plain');
    node.visible = strcmpi(get(handle, 'Visible'), 'on');
end
