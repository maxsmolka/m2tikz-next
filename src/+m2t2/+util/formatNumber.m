function output = formatNumber(value)
%FORMATNUMBER Locale-independent deterministic numeric representation.
    if isnan(value)
        output = 'nan';
        return;
    end
    if isinf(value)
        error('M2T2:E003:InvalidIR', ...
              'M2T2-E003 InvalidIR: renderer received an infinite number');
    end
    if value == 0
        value = 0; % Canonicalize negative zero.
    end
    output = sprintf('%.15g', value);
    output = strrep(output, ',', '.');
end
