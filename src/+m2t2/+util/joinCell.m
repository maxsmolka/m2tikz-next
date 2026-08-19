function output = joinCell(parts, delimiter)
%JOINCELL Compatibility-safe join for character cell arrays.
    if isempty(parts)
        output = '';
        return;
    end
    joined = cell(2, numel(parts));
    joined(1, :) = reshape(parts, 1, []);
    joined(2, 1:end-1) = {delimiter};
    joined{2, end} = '';
    output = [joined{:}];
end
