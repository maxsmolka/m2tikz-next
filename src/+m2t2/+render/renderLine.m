function lines = renderLine(node, colorName)
%RENDERLINE Render one normalized line using buffered coordinates.
    options = m2t2.render.seriesOptions(node, colorName);
    bs = char(92);
    lines = {[bs 'addplot+[' m2t2.util.joinCell(options, ',') '] coordinates {'], ...
             m2t2.render.formatCoordinates(node.x, node.y), ...
             '};'};
end
