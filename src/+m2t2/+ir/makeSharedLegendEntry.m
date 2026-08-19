function entry = makeSharedLegendEntry(axesId, seriesId, text)
%MAKESHAREDLEGENDENTRY Reference a series through stable axes/series IDs.
    if nargin < 1, axesId = ''; end
    if nargin < 2, seriesId = ''; end
    if nargin < 3, text = m2t2.ir.makeText(); end
    entry = struct('axesId', axesId, 'seriesId', seriesId, 'text', text);
end
