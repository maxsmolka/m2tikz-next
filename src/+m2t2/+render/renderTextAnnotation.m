function lines = renderTextAnnotation(node, annotationIndex)
%RENDERTEXTANNOTATION Render axes-data user text inside its owning axis.
    bs = char(92);
    colorName = sprintf('m2t2annotationtext%d', annotationIndex);
    lines = {[bs 'definecolor{' colorName '}{rgb}{' ...
        m2t2.util.formatNumber(node.color(1)) ',' ...
        m2t2.util.formatNumber(node.color(2)) ',' ...
        m2t2.util.formatNumber(node.color(3)) '}']};
    options = {['text=' colorName], ['anchor=' anchor(node)], ...
        ['align=' node.horizontalAlignment]};
    if abs(node.rotation) > 1e-12
        options{end + 1} = ['rotate=' m2t2.util.formatNumber(node.rotation)];
    end
    font = m2t2.render.fontCommand(node.fontSize);
    if strcmp(node.fontWeight, 'bold'), font = [font bs 'bfseries']; end
    if strcmp(node.fontAngle, 'italic'), font = [font bs 'itshape']; end
    options{end + 1} = ['font={' font '}'];
    lines{end + 1} = [bs 'node[' m2t2.util.joinCell(options, ',') ...
        '] at (axis cs:' m2t2.util.formatNumber(node.position(1)) ',' ...
        m2t2.util.formatNumber(node.position(2)) ') {' ...
        m2t2.render.renderText(node.text) '};'];
end

function value = anchor(node)
    horizontal = struct('left','west','center','','right','east');
    switch node.verticalAlignment
        case {'top','cap'}
            vertical = 'north';
        case 'middle'
            vertical = '';
        case 'baseline'
            vertical = 'base';
        otherwise
            vertical = 'south';
    end
    h = horizontal.(node.horizontalAlignment);
    if isempty(vertical)
        if isempty(h), value = 'center'; else, value = h; end
    elseif isempty(h)
        value = vertical;
    else
        value = [vertical ' ' h];
    end
end
