function node = readBar(handle, axesHandle, path, axesId, groupIndex, groupCount)
%READBAR Normalize one positively identified vertical grouped-bar series.
    if ~m2t2.reader.isBarObject(handle, axesHandle)
        ownership(path, 'object does not satisfy the semantic bar ownership signature');
    end
    mode = lower(char(get(handle, 'BarLayout')));
    if ~strcmp(mode, 'grouped'), unsupportedMode(path, mode); end
    horizontal = get(handle, 'Horizontal');
    if (ischar(horizontal) && ~strcmpi(horizontal, 'off')) || ...
            (~ischar(horizontal) && logical(horizontal))
        unsupportedOrientation(path, horizontal);
    end
    categories = reshape(double(get(handle, 'XData')), 1, []);
    values = reshape(double(get(handle, 'YData')), 1, []);
    if isempty(categories) || numel(categories) ~= numel(values) || ...
            any(~isfinite(categories)) || any(~isfinite(values))
        malformed(path, 'XData and YData must be equal-length finite nonempty vectors');
    end
    if numel(categories) > 1 && any(diff(categories) <= 0)
        unsupportedCategory(path, 'numeric categories must be strictly increasing');
    end
    barWidth = double(get(handle, 'BarWidth'));
    baseline = double(get(handle, 'BaseValue'));
    lineWidth = double(get(handle, 'LineWidth'));
    if ~(isscalar(barWidth) && isfinite(barWidth) && barWidth > 0 && barWidth <= 1)
        malformed(path, 'BarWidth must be a scalar in (0,1]');
    end
    if ~(isscalar(baseline) && isfinite(baseline))
        malformed(path, 'BaseValue must be a finite scalar');
    end
    if ~(isscalar(lineWidth) && isfinite(lineWidth) && lineWidth >= 0)
        malformed(path, 'LineWidth must be a nonnegative finite scalar');
    end
    requireOpaqueAlpha(handle, 'FaceAlpha', path);
    requireOpaqueAlpha(handle, 'EdgeAlpha', path);
    [faceVisible, faceColor] = color(get(handle, 'FaceColor'), [path '.FaceColor']);
    [edgeVisible, edgeColor] = color(get(handle, 'EdgeColor'), [path '.EdgeColor']);
    lineStyle = m2t2.util.normalizeLineStyle(char(get(handle, 'LineStyle')), ...
        [path '.LineStyle']);
    if strcmp(lineStyle, 'none'), edgeVisible = false; end

    node = m2t2.ir.makeBarSeries();
    node.owner = m2t2.ir.makeOwner('axes', axesId);
    node.groupId = [axesId '-bar-group-1'];
    node.groupIndex = groupIndex; node.groupCount = groupCount;
    node.categories = categories; node.values = values;
    node.barWidth = barWidth; node.baseline = baseline;
    node.faceVisible = faceVisible; node.faceColor = faceColor;
    node.edgeVisible = edgeVisible; node.edgeColor = edgeColor;
    node.lineWidth = lineWidth; node.lineStyle = lineStyle;
    node.displayName = m2t2.ir.makeText(m2t2.util.textValue( ...
        get(handle, 'DisplayName'), [path '.DisplayName']), 'plain');
    node.visible = strcmpi(char(get(handle, 'Visible')), 'on');
end

function requireOpaqueAlpha(handle, property, path)
    try, value = double(get(handle, property)); catch, value = 1; end
    if ~(isscalar(value) && isfinite(value) && value == 1)
        unsupportedColor(path, property, value);
    end
end

function [visible, rgb] = color(value, path)
    if ischar(value)
        if strcmpi(value, 'none'), visible = false; rgb = [0 0 0]; return; end
        unsupportedColor(path, 'color mode', value);
    end
    try, rgb = m2t2.util.normalizeColor(value, path);
    catch, unsupportedColor(path, 'color mode', value); end
    visible = true;
end

function unsupportedMode(path, value)
    error('M2T2:E018:UnsupportedBarMode', ...
        'M2T2-E018 UnsupportedBarMode: path=%s value=%s', path, text(value));
end
function unsupportedOrientation(path, value)
    error('M2T2:E019:UnsupportedBarOrientation', ...
        'M2T2-E019 UnsupportedBarOrientation: path=%s value=%s', path, text(value));
end
function unsupportedCategory(path, reason)
    error('M2T2:E020:UnsupportedBarCategory', ...
        'M2T2-E020 UnsupportedBarCategory: path=%s reason=%s', path, reason);
end
function unsupportedColor(path, property, value)
    error('M2T2:E021:UnsupportedBarColorMode', ...
        'M2T2-E021 UnsupportedBarColorMode: path=%s property=%s value=%s', ...
        path, property, text(value));
end
function malformed(path, reason)
    error('M2T2:E022:MalformedBarData', ...
        'M2T2-E022 MalformedBarData: path=%s reason=%s', path, reason);
end
function ownership(path, reason)
    error('M2T2:E023:AmbiguousBarOwnership', ...
        'M2T2-E023 AmbiguousBarOwnership: path=%s reason=%s', path, reason);
end
function value = text(value)
    if ischar(value), return; elseif isnumeric(value) || islogical(value), value=num2str(value);
    else, value=class(value); end
end
