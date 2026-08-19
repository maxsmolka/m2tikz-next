function node = makeArrowHead(style, length, width)
%MAKEARROWHEAD Construct supported semantic arrow-head geometry.
    if nargin < 1, style = 'none'; end
    if nargin < 2, length = 0; end
    if nargin < 3, width = 0; end
    node = struct('style', style, 'length', length, 'width', width);
end
