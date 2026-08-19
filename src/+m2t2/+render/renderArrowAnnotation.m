function lines = renderArrowAnnotation(node, figureSize, annotationIndex)
%RENDERARROWANNOTATION Render a figure-normalized vector arrow.
    bs = char(92);
    colorName = sprintf('m2t2annotationarrow%d', annotationIndex);
    lines = {[bs 'definecolor{' colorName '}{rgb}{' ...
        m2t2.util.formatNumber(node.color(1)) ',' ...
        m2t2.util.formatNumber(node.color(2)) ',' ...
        m2t2.util.formatNumber(node.color(3)) '}']};
    options = {['draw=' colorName], styleName(node.style), ...
        ['line width=' m2t2.util.formatNumber(node.width) 'pt'], ...
        arrowHeads(node)};
    start = node.start .* figureSize;
    finish = node.end .* figureSize;
    lines{end + 1} = [bs 'draw[' m2t2.util.joinCell(options, ',') '] (' ...
        m2t2.util.formatNumber(start(1)) 'pt,' ...
        m2t2.util.formatNumber(start(2)) 'pt) -- (' ...
        m2t2.util.formatNumber(finish(1)) 'pt,' ...
        m2t2.util.formatNumber(finish(2)) 'pt);'];
end

function value = styleName(style)
    source = {'solid','dashed','dotted','dashdot'};
    target = {'solid','dashed','dotted','dash dot'};
    value = target{find(strcmp(style, source), 1)};
end

function value = arrowHeads(node)
    start = arrowHead(node.startHead);
    finish = arrowHead(node.endHead);
    if isempty(start), value = ['-' finish];
    elseif isempty(finish), value = [start '-'];
    else, value = [start '-' finish];
    end
end

function value = arrowHead(node)
    if strcmp(node.style, 'none'), value = ''; return; end
    value = ['{Latex[length=' m2t2.util.formatNumber(node.length) ...
        'pt,width=' m2t2.util.formatNumber(node.width) 'pt]}'];
end
