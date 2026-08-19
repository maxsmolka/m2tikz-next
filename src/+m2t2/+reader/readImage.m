function node = readImage(handle, path)
%READIMAGE Normalize a scalar 2-D runtime image without resampling.
    cdata = get(handle, 'CData');
    if ~(isnumeric(cdata) && ismatrix(cdata) && ~isempty(cdata))
        if isnumeric(cdata) && ndims(cdata) == 3 && size(cdata, 3) == 3
            error('M2T2:E_IMAGE_RGB_UNSUPPORTED', ...
                  'M2T2 image RGB unsupported: path=%s size=%s', ...
                  path, sizeText(size(cdata)));
        end
        error('M2T2:E_IMAGE_DIMENSIONS_INVALID', ...
              'M2T2 image dimensions invalid: path=%s size=%s', ...
              path, sizeText(size(cdata)));
    end
    if any(isinf(cdata(:)))
        error('M2T2:E_IMAGE_NONFINITE_UNSUPPORTED', ...
              'M2T2 image Inf unsupported: path=%s', path);
    end
    mapping = lower(get(handle, 'CDataMapping'));
    if ~strcmp(mapping, 'scaled')
        error('M2T2:E_IMAGE_MAPPING_UNSUPPORTED', ...
              'M2T2 image mapping unsupported: path=%s mapping=%s', path, mapping);
    end
    alpha = get(handle, 'AlphaData');
    alphaMapping = lower(get(handle, 'AlphaDataMapping'));
    if ~(isnumeric(alpha) && ~isempty(alpha) && all(isfinite(alpha(:))) && ...
            all(alpha(:) == 1) && strcmp(alphaMapping, 'none'))
        error('M2T2:E_IMAGE_ALPHA_UNSUPPORTED', ...
              'M2T2 image alpha unsupported: path=%s', path);
    end

    rows = size(cdata, 1); columns = size(cdata, 2);
    x = coordinateCenters(get(handle, 'XData'), columns, [path '.x']);
    y = coordinateCenters(get(handle, 'YData'), rows, [path '.y']);
    node = m2t2.ir.makeImageSeries();
    node.x = x; node.y = y; node.cdata = double(cdata);
    node.mapping = mapping;
    node.visible = strcmpi(get(handle, 'Visible'), 'on');
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
    error('M2T2:E_IMAGE_COORDINATES_UNSUPPORTED', ...
          'M2T2 image coordinates unsupported: path=%s reason=%s', path, reason);
end

function value = sizeText(dimensions)
    values = arrayfun(@num2str, dimensions, 'UniformOutput', false);
    value = m2t2.util.joinCell(values, 'x');
end
