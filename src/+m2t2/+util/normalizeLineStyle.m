function style = normalizeLineStyle(value, path)
%NORMALIZELINESTYLE Map runtime line-style vocabulary to the M2 IR.
    source = {'-','--',':','-.','none'};
    target = {'solid','dashed','dotted','dashdot','none'};
    index = find(strcmp(value, source), 1);
    if isempty(index)
        error('M2T2:E004:NormalizationFailed', ...
              'M2T2-E004 NormalizationFailed: path=%s reason=unsupported line style %s', ...
              path, value);
    end
    style = target{index};
end
