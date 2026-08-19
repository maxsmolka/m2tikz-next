function value = textValue(raw, path)
%TEXTVALUE Normalize graphics text to an IR character row vector.
    if ischar(raw)
        if isempty(raw)
            value = '';
        elseif size(raw, 1) == 1
            value = raw;
        else
            value = m2t2.util.joinCell(cellstr(raw), ' ');
        end
    elseif iscell(raw)
        parts = cell(size(raw));
        for k = 1:numel(raw)
            parts{k} = m2t2.util.textValue(raw{k}, path);
        end
        value = m2t2.util.joinCell(parts, ' ');
    elseif isnumeric(raw) && isscalar(raw)
        value = m2t2.util.formatNumber(raw);
    else
        error('M2T2:E004:NormalizationFailed', ...
              'M2T2-E004 NormalizationFailed: path=%s reason=unsupported text value', path);
    end
end
