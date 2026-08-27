function indices = imageColorIndices(cdata, colorMapping, mapping, directIndexBase)
%IMAGECOLORINDICES Map scalar CData to zero-based discrete colormap rows.
    if nargin < 3, mapping = 'scaled'; end
    if nargin < 4, directIndexBase = 1; end
    count = size(colorMapping.colormap, 1);
    if strcmp(mapping, 'direct')
        indices = min(max(cdata - directIndexBase, 0), count - 1);
    else
        normalized = (cdata - colorMapping.limits(1)) ./ ...
                     (colorMapping.limits(2) - colorMapping.limits(1));
        indices = min(max(floor(normalized * count), 0), count - 1);
    end
    indices(isnan(cdata)) = NaN;
end
