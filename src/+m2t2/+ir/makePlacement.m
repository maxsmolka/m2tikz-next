function placement = makePlacement(x, y, width, height)
%MAKEPLACEMENT Construct normalized axes plot-rectangle geometry.
    if nargin < 1, x = 0; end
    if nargin < 2, y = 0; end
    if nargin < 3, width = 1; end
    if nargin < 4, height = 1; end
    placement = struct('x', x, 'y', y, 'width', width, 'height', height);
end
