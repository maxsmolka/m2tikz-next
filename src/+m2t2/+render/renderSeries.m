function lines = renderSeries(node, colorName, colormapName, colorMapping)
%RENDERSERIES Dispatch a discriminated series node without runtime access.
    if nargin < 3, colormapName = ''; end
    if nargin < 4, colorMapping = []; end
    switch node.kind
        case 'm2t2.line'
            lines = m2t2.render.renderLine(node, colorName);
        case 'm2t2.scatter'
            lines = m2t2.render.renderScatter(node, colorName);
        case 'm2t2.errorbar'
            lines = m2t2.render.renderErrorbar(node, colorName);
        case 'm2t2.image'
            lines = m2t2.render.renderImage(node, colormapName, colorMapping);
        case 'm2t2.bar'
            lines = m2t2.render.renderBar(node, colorName);
        case 'm2t2.boxplot'
            lines=m2t2.render.renderBoxplot(node,colorName);
        case 'm2t2.surface'
            lines = m2t2.render.renderSurface(node, colormapName);
        case 'm2t2.line3'
            lines = m2t2.render.renderLine3(node, colorName);
        case 'm2t2.patch3'
            lines = m2t2.render.renderPatch3(node, colorName);
        otherwise
            error('M2T2:E003:InvalidIR', 'M2T2-E003 InvalidIR: unknown series kind %s', node.kind);
    end
end
