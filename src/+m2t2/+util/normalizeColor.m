function rgb = normalizeColor(value, path)
%NORMALIZECOLOR Convert supported graphics colors to canonical RGB.
    if isnumeric(value) && numel(value) == 3
        rgb = reshape(double(value), 1, 3);
    elseif ischar(value)
        names = {'y','m','c','r','g','b','w','k','yellow','magenta','cyan', ...
                 'red','green','blue','white','black'};
        colors = [1 1 0;1 0 1;0 1 1;1 0 0;0 1 0;0 0 1;1 1 1;0 0 0; ...
                  1 1 0;1 0 1;0 1 1;1 0 0;0 1 0;0 0 1;1 1 1;0 0 0];
        index = find(strcmpi(value, names), 1);
        if isempty(index)
            failed(path, ['unsupported color ' value]);
        end
        rgb = colors(index, :);
    else
        failed(path, 'expected RGB or a named basic color');
    end
    if any(~isfinite(rgb)) || any(rgb < 0) || any(rgb > 1)
        failed(path, 'RGB values must be finite and in [0,1]');
    end
end

function failed(path, reason)
    error('M2T2:E004:NormalizationFailed', ...
          'M2T2-E004 NormalizationFailed: path=%s reason=%s', path, reason);
end
