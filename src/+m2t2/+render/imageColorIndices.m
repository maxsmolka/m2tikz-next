function indices = imageColorIndices(cdata, colorMapping)
%IMAGECOLORINDICES Map scalar CData to zero-based discrete colormap rows.
    count = size(colorMapping.colormap, 1);
    normalized = (cdata - colorMapping.limits(1)) ./ ...
                 (colorMapping.limits(2) - colorMapping.limits(1));
    indices = min(max(floor(normalized * count), 0), count - 1);
    indices(isnan(cdata)) = NaN;
end
