function [x, y, gaps] = normalizeXY(xValue, yValue, path)
%NORMALIZEXY Normalize vectors and retain non-finite records as paired gaps.
    x = reshape(double(xValue), 1, []);
    y = reshape(double(yValue), 1, []);
    if numel(x) ~= numel(y)
        error('M2T2:E004:NormalizationFailed', ...
              'M2T2-E004 NormalizationFailed: path=%s reason=XData/YData length mismatch', path);
    end
    gaps = ~isfinite(x) | ~isfinite(y);
    x(gaps) = NaN; y(gaps) = NaN;
end
