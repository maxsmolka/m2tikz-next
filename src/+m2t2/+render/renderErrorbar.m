function lines = renderErrorbar(node, colorName)
%RENDERERRORBAR Render explicit asymmetric x/y errors as an inline table.
    options = m2t2.render.seriesOptions(node, colorName);
    hasX = any(node.xNegative ~= 0 | node.xPositive ~= 0);
    hasY = any(node.yNegative ~= 0 | node.yPositive ~= 0);
    options{end + 1} = 'error bars/.cd';
    if hasX
        options = [options, {'x dir=both','x explicit'}];
    else
        options{end + 1} = 'x dir=none';
    end
    if hasY
        options = [options, {'y dir=both','y explicit'}];
    else
        options{end + 1} = 'y dir=none';
    end
    tableOptions = {'x=x','y=y'};
    if hasX
        tableOptions = [tableOptions, {'x error minus=xneg','x error plus=xpos'}];
    end
    if hasY
        tableOptions = [tableOptions, {'y error minus=yneg','y error plus=ypos'}];
    end
    bs = char(92);
    rows = cell(1, numel(node.x) + 1);
    header = 'x y';
    if hasX, header = [header ' xneg xpos']; end
    if hasY, header = [header ' yneg ypos']; end
    rows{1} = [header ' ' bs bs];
    for k = 1:numel(node.x)
        values = {m2t2.util.formatNumber(node.x(k)), m2t2.util.formatNumber(node.y(k))};
        if hasX
            values = [values, {m2t2.util.formatNumber(node.xNegative(k)), ...
                               m2t2.util.formatNumber(node.xPositive(k))}];
        end
        if hasY
            values = [values, {m2t2.util.formatNumber(node.yNegative(k)), ...
                               m2t2.util.formatNumber(node.yPositive(k))}];
        end
        rows{k + 1} = [m2t2.util.joinCell(values, ' ') ' ' bs bs];
    end
    lines = {[bs 'addplot+[' m2t2.util.joinCell(options, ',') ']'], ...
             ['table[' m2t2.util.joinCell(tableOptions, ',') ',row sep=' bs bs '] {'], ...
             m2t2.util.joinCell(rows, sprintf('\n')), ...
             '};'};
end
