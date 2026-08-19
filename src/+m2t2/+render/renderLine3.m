function lines = renderLine3(node, colorName)
%RENDERLINE3 Render one semantic Plot3 line.
    options = m2t2.render.seriesOptions(node, colorName); bs = char(92);
    points = cell(1, numel(node.x));
    for k = 1:numel(points)
        if isnan(node.x(k)), points{k} = '(nan,nan,nan)';
        else
            points{k} = ['(' m2t2.util.formatNumber(node.x(k)) ',' ...
                m2t2.util.formatNumber(node.y(k)) ',' ...
                m2t2.util.formatNumber(node.z(k)) ')'];
        end
    end
    lines = {[bs 'addplot3+[' m2t2.util.joinCell(options, ',') '] coordinates {'], ...
        m2t2.util.joinCell(points, ' '), '};'};
end
