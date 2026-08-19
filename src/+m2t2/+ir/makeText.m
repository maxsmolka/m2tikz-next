function text = makeText(value, interpreter)
%MAKETEXT Construct a normalized text node.
    if nargin < 1, value = ''; end
    if nargin < 2, interpreter = 'plain'; end
    text = struct('value', value, 'interpreter', interpreter);
end
