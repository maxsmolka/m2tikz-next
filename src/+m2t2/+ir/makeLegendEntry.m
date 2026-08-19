function entry = makeLegendEntry(seriesId, text)
%MAKELEGENDENTRY Construct an explicit series-to-legend mapping.
    if nargin < 1, seriesId = ''; end
    if nargin < 2, text = m2t2.ir.makeText(); end
    entry = struct('seriesId', seriesId, 'text', text);
end
