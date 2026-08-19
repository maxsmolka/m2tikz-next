function output = formatCoordinates(x, y)
%FORMATCOORDINATES Buffered locale-safe coordinate serialization.
    if isempty(x), output = ''; return; end
    x = reshape(x, 1, []); y = reshape(y, 1, []);
    x(x == 0) = 0; y(y == 0) = 0;
    % Semicolon is a temporary structural delimiter. Decimal commas can then
    % be normalized without corrupting the final coordinate comma.
    output = sprintf('  (%.15g;%.15g)\n', [x; y]);
    output = strrep(output, ',', '.');
    output = strrep(output, ';', ',');
    output = strrep(output, 'NaN', 'nan');
end
