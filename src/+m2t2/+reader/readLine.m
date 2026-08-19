function node = readLine(lineHandle, path)
%READLINE Normalize a 2-D line. Non-finite points become paired NaN gaps.
    z = get(lineHandle, 'ZData');
    if ~isempty(z)
        unsupported('line3d', path);
    end

    [x, y] = m2t2.util.normalizeXY(get(lineHandle, 'XData'), get(lineHandle, 'YData'), path);

    node = m2t2.ir.makeLineSeries();
    node.x = x;
    node.y = y;
    node.color = m2t2.util.normalizeColor(get(lineHandle, 'Color'), [path '.color']);
    node.width = double(get(lineHandle, 'LineWidth'));
    node.style = m2t2.util.normalizeLineStyle(get(lineHandle, 'LineStyle'), [path '.style']);
    node.marker = m2t2.util.normalizeMarker(get(lineHandle, 'Marker'), [path '.marker']);
    node.markerSize = double(get(lineHandle, 'MarkerSize'));
    node.displayName = m2t2.ir.makeText( ...
        m2t2.util.textValue(get(lineHandle, 'DisplayName'), [path '.displayName']), 'plain');
    node.visible = strcmpi(get(lineHandle, 'Visible'), 'on');
end

function unsupported(type, path)
    error('M2T2:E001:UnsupportedObject', ...
          'M2T2-E001 UnsupportedObject: type=%s path=%s', type, path);
end
