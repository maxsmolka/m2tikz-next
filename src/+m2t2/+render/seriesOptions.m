function options = seriesOptions(node, colorName)
%SERIESOPTIONS Produce deterministic base style options for a series node.
    switch node.kind
        case {'m2t2.line','m2t2.line3'}
            options = lineOptions(node, colorName);
        case 'm2t2.patch3'
            options = {['fill=' colorName], 'area legend', 'forget plot'};
        case 'm2t2.scatter'
            options = {['color=' colorName], 'only marks', ...
                       ['mark=' m2t2.render.markerName(node.marker)], ...
                       ['mark size=' m2t2.util.formatNumber(node.markerSize / 2) 'pt'], ...
                       'mark options={solid}','forget plot'};
        case 'm2t2.errorbar'
            options = lineOptions(node, colorName);
        case 'm2t2.bar'
            options = barOptions(node, colorName);
        case 'm2t2.boxplot'
            options={['color=' colorName 'box'],['line width=' m2t2.util.formatNumber(node.boxLineWidth) 'pt'],'forget plot'};
        otherwise
            error('M2T2:E003:InvalidIR', 'M2T2-E003 InvalidIR: unknown series kind %s', node.kind);
    end
end

function options = barOptions(node,colorName)
    if node.faceVisible,fill=['fill=' colorName];else,fill='fill=none';end
    if node.edgeVisible,draw=['draw=' colorName 'edge'];else,draw='draw=none';end
    options={fill,draw,'area legend',['line width=' m2t2.util.formatNumber(node.lineWidth) 'pt']};
    if node.edgeVisible,options{end+1}=m2t2.render.lineStyleName(node.lineStyle);end
    options{end+1}='forget plot';
end

function options = lineOptions(node, colorName)
    options = {['color=' colorName], ...
               ['line width=' m2t2.util.formatNumber(node.width) 'pt'], ...
               m2t2.render.lineStyleName(node.style), ...
               ['mark=' m2t2.render.markerName(node.marker)], ...
               ['mark size=' m2t2.util.formatNumber(node.markerSize / 2) 'pt'], ...
               'mark options={solid}','forget plot'};
end
