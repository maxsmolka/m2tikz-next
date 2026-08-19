function node = readErrorbar(handle, path)
%READERRORBAR Normalize Octave hggroup or MATLAB ErrorBar public properties.
    [x, y, gaps] = m2t2.util.normalizeXY(property(handle, {'XData'}, []), ...
                                          property(handle, {'YData'}, []), path);
    count = numel(x);
    xNegative = errorVector(property(handle, {'XNegativeDelta','LData','XLData'}, []), count, path, 'xNegative');
    xPositive = errorVector(property(handle, {'XPositiveDelta','UData','XUData'}, []), count, path, 'xPositive');
    yNegative = errorVector(property(handle, {'YNegativeDelta','LData'}, []), count, path, 'yNegative');
    yPositive = errorVector(property(handle, {'YPositiveDelta','UData'}, []), count, path, 'yPositive');

    % Octave exposes LData/UData for y and XLData/XUData for x. Avoid using
    % LData/UData as x errors when the dedicated x properties are absent.
    if hasProperty(handle, 'XLData')
        xNegative = errorVector(get(handle, 'XLData'), count, path, 'xNegative');
        xPositive = errorVector(get(handle, 'XUData'), count, path, 'xPositive');
    elseif ~hasProperty(handle, 'XNegativeDelta')
        xNegative = zeros(1, count); xPositive = zeros(1, count);
    end
    errorNames = {'xNegative','xPositive','yNegative','yPositive'};
    values = {xNegative,xPositive,yNegative,yPositive};
    for k = 1:numel(values)
        value = values{k};
        if any(~isfinite(value(~gaps))) || any(value(~gaps) < 0)
            error('M2T2:E004:NormalizationFailed', ...
                  'M2T2-E004 NormalizationFailed: path=%s.%s reason=errors must be finite and non-negative', ...
                  path, errorNames{k});
        end
        value(gaps) = NaN; values{k} = value;
    end

    node = m2t2.ir.makeErrorbarSeries();
    node.x = x; node.y = y;
    node.xNegative = values{1}; node.xPositive = values{2};
    node.yNegative = values{3}; node.yPositive = values{4};
    node.color = m2t2.util.normalizeColor(get(handle, 'Color'), [path '.color']);
    node.width = double(get(handle, 'LineWidth'));
    node.style = m2t2.util.normalizeLineStyle(get(handle, 'LineStyle'), [path '.style']);
    node.marker = m2t2.util.normalizeMarker(get(handle, 'Marker'), [path '.marker']);
    node.markerSize = double(get(handle, 'MarkerSize'));
    node.displayName = m2t2.ir.makeText( ...
        m2t2.util.textValue(get(handle, 'DisplayName'), [path '.displayName']), 'plain');
    node.visible = strcmpi(get(handle, 'Visible'), 'on');
end

function value = errorVector(value, count, path, name)
    value = reshape(double(value), 1, []);
    if isempty(value), value = zeros(1, count); end
    if isscalar(value) && count ~= 1, value = repmat(value, 1, count); end
    if numel(value) ~= count
        error('M2T2:E004:NormalizationFailed', ...
              'M2T2-E004 NormalizationFailed: path=%s.%s reason=error length mismatch', path, name);
    end
end

function value = property(handle, names, default)
    for k = 1:numel(names)
        try
            value = get(handle, names{k}); return;
        catch
        end
    end
    value = default;
end

function yes = hasProperty(handle, name)
    try, get(handle, name); yes = true; catch, yes = false; end
end
