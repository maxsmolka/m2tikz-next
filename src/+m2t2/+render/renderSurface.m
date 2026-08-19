function lines = renderSurface(node, colormapName)
%RENDERSURFACE Render deterministic matrix-oriented scalar surface data.
    bs = char(92); rows = size(node.z, 1); columns = size(node.z, 2);
    data = cell(1, rows * columns + columns + 1); index = 1;
    data{index} = 'x y z meta'; index = index + 1;
    for column = 1:columns
        for row = 1:rows
            data{index} = [m2t2.util.formatNumber(node.x(row, column)) ' ' ...
                m2t2.util.formatNumber(node.y(row, column)) ' ' ...
                m2t2.util.formatNumber(node.z(row, column)) ' ' ...
                m2t2.util.formatNumber(node.c(row, column))];
            index = index + 1;
        end
        data{index} = ''; index = index + 1;
    end
    options = {'surf','shader=interp','draw=none', ...
        ['mesh/rows=' m2t2.util.formatNumber(rows)], ...
        'point meta=explicit', ['colormap name=' colormapName], 'forget plot'};
    lines = {[bs 'addplot3[' m2t2.util.joinCell(options, ',') '] table[meta=meta] {'], ...
        m2t2.util.joinCell(data, sprintf('\n')), '};'};
end
