function mapping = makeColorMapping(limits, scale, colormap)
%MAKECOLORMAPPING Describe the data-axes-owned scalar-to-color mapping.
    if nargin < 1, limits = [0 1]; end
    if nargin < 2, scale = 'linear'; end
    if nargin < 3, colormap = [0 0 1; 1 0 0]; end
    mapping = struct('limits', limits, 'scale', scale, 'colormap', colormap);
end
