function ticks = makeTickSpec(mode, values, labels)
%MAKETICKSPEC Construct an auto or manual tick specification.
    if nargin < 1, mode = 'auto'; end
    if nargin < 2, values = zeros(1, 0); end
    if nargin < 3, labels = {}; end
    ticks = struct('mode', mode, 'values', values, 'labels', {labels});
end
