function node = readImage(handle, path)
%READIMAGE Normalize a bounded scalar/truecolor image without resampling.
    cdata = get(handle, 'CData');
    if ~(isnumeric(cdata) && ~isempty(cdata))
        fail('M2T2:E047:MalformedImageCData', path, 'CData must be nonempty numeric data');
    end
    scalarImage = ismatrix(cdata);
    rgbImage = ndims(cdata) == 3 && size(cdata, 3) == 3;
    if ~(scalarImage || rgbImage)
        fail('M2T2:E048:UnsupportedImageDimensionality', path, ...
             ['CData size=' sizeText(size(cdata))]);
    end
    mapping = lower(get(handle, 'CDataMapping'));
    directIndexBase = 1;
    if scalarImage
        if any(isinf(cdata(:)))
            fail('M2T2:E047:MalformedImageCData', path, 'scalar CData contains Inf');
        end
        if ~any(strcmp(mapping, {'scaled','direct'}))
            fail('M2T2:E052:UnsupportedImageColorMapping', path, ['mapping=' mapping]);
        end
        if strcmp(mapping, 'direct')
            if isa(cdata, 'uint8') || isa(cdata, 'uint16'), directIndexBase = 0; end
            if any(~isfinite(double(cdata(:)))) || any(double(cdata(:)) ~= fix(double(cdata(:))))
                fail('M2T2:E052:UnsupportedImageColorMapping', path, ...
                     'direct CData must contain finite integer indices');
            end
        end
        normalized = double(cdata); colorMode = 'scalar';
    else
        if ~strcmp(mapping, 'direct')
            fail('M2T2:E052:UnsupportedImageColorMapping', path, ...
                 'truecolor CData requires runtime direct mapping');
        end
        normalized = normalizeRgb(cdata, path); colorMode = 'rgb'; mapping = 'none';
    end

    alpha = get(handle, 'AlphaData');
    alphaMapping = lower(get(handle, 'AlphaDataMapping'));
    if ~strcmp(alphaMapping, 'none')
        fail('M2T2:E051:UnsupportedImageAlphaMapping', path, ...
             ['AlphaDataMapping=' alphaMapping]);
    end
    [alphaMode, alphaData] = normalizeAlpha(alpha, size(normalized, 1), ...
                                            size(normalized, 2), path);

    rows = size(normalized, 1); columns = size(normalized, 2);
    x = coordinateCenters(get(handle, 'XData'), columns, [path '.x']);
    y = coordinateCenters(get(handle, 'YData'), rows, [path '.y']);
    node = m2t2.ir.makeImageSeries();
    node.x = x; node.y = y; node.cdata = normalized;
    node.colorMode = colorMode; node.mapping = mapping;
    node.directIndexBase = directIndexBase;
    node.alphaMode = alphaMode; node.alphaData = alphaData;
    node.visible = strcmpi(get(handle, 'Visible'), 'on');
end

function rgb = normalizeRgb(value, path)
    if isa(value, 'uint8')
        rgb = double(value) / 255;
    elseif isa(value, 'uint16')
        rgb = double(value) / 65535;
    elseif isa(value, 'single') || isa(value, 'double')
        rgb = double(value);
    else
        fail('M2T2:E049:UnsupportedImageRGB', path, ['class=' class(value)]);
    end
    if any(~isfinite(rgb(:))) || any(rgb(:) < 0) || any(rgb(:) > 1)
        fail('M2T2:E049:UnsupportedImageRGB', path, ...
             'RGB channels must be finite and normalized after class conversion');
    end
end

function [mode, value] = normalizeAlpha(alpha, rows, columns, path)
    if ~(isnumeric(alpha) && ~isempty(alpha))
        fail('M2T2:E050:MalformedImageAlphaData', path, ...
             'AlphaData must be a numeric scalar or image-sized matrix');
    end
    if isa(alpha, 'uint8')
        value = double(alpha) / 255;
    elseif isa(alpha, 'uint16')
        value = double(alpha) / 65535;
    elseif isa(alpha, 'single') || isa(alpha, 'double')
        value = double(alpha);
    else
        fail('M2T2:E050:MalformedImageAlphaData', path, ['class=' class(alpha)]);
    end
    if any(~isfinite(value(:))) || any(value(:) < 0) || any(value(:) > 1)
        fail('M2T2:E050:MalformedImageAlphaData', path, 'alpha must be finite in [0,1]');
    end
    if isscalar(value)
        if value == 1, mode = 'opaque'; else, mode = 'constant'; end
    elseif isequal(size(value), [rows columns])
        mode = 'per_pixel';
    else
        fail('M2T2:E050:MalformedImageAlphaData', path, ...
             ['AlphaData size=' sizeText(size(value))]);
    end
end

function values = coordinateCenters(runtimeValue, count, path)
    value = reshape(double(runtimeValue), 1, []);
    if count == 1
        if isempty(value) || ~isfinite(value(1))
            unsupported(path, 'single-cell coordinate must be finite');
        end
        values = value(1);
        return
    end
    if numel(value) == count
        values = value;
    elseif numel(value) == 2
        values = linspace(value(1), value(2), count);
    else
        unsupported(path, 'expected endpoint pair or one coordinate per cell');
    end
    if any(~isfinite(values)) || any(diff(values) == 0) || ...
       ~(all(diff(values) > 0) || all(diff(values) < 0))
        unsupported(path, 'coordinates must be finite and strictly monotonic');
    end
end

function unsupported(path, reason)
    fail('M2T2:E054:UnsupportedImageCoordinates', path, reason);
end

function fail(identifier, path, reason)
    error(identifier, '%s: path=%s reason=%s', identifier, path, reason);
end

function value = sizeText(dimensions)
    values = arrayfun(@num2str, dimensions, 'UniformOutput', false);
    value = m2t2.util.joinCell(values, 'x');
end
