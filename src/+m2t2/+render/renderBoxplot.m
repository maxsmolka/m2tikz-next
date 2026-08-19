function lines=renderBoxplot(node,colorName)
%RENDERBOXPLOT Render resolved vertical statistics without runtime handles.
    bs=char(92);lines={};box=[colorName 'box'];med=[colorName 'median'];whisk=[colorName 'whisker'];out=[colorName 'outlier'];
    for k=1:numel(node.positions)
        x=m2t2.util.formatNumber(node.positions(k));half=m2t2.util.formatNumber(node.boxWidth/2);
        lines{end+1}=pathLine(bs,whisk,node.whiskerLineWidth,node.whiskerLineStyle, ...
            ['(axis cs:' x ',' n(node.lowerWhisker(k)) ') -- (axis cs:' x ',' n(node.upperWhisker(k)) ')']); %#ok<AGROW>
        lines{end+1}=pathLine(bs,box,node.boxLineWidth,'solid', ...
            ['(axis cs:' x ',' n(node.q1(k)) ') -- (axis cs:' x ',' n(node.q3(k)) ')']); %#ok<AGROW>
        lines{end+1}=pathLine(bs,med,node.medianLineWidth,node.medianLineStyle, ...
            ['(axis cs:{' x '-' half '},' n(node.median(k)) ') -- (axis cs:{' x '+' half '},' n(node.median(k)) ')']); %#ok<AGROW>
    end
    if ~isempty(node.outlierValues)
        coords=cell(1,numel(node.outlierValues));for k=1:numel(coords),coords{k}=['(' n(node.outlierPositions(k)) ',' n(node.outlierValues(k)) ')'];end
        lines{end+1}=[bs 'addplot[only marks,color=' out ',mark=' m2t2.render.markerName(node.outlierMarker) ...
            ',mark size=' n(node.outlierMarkerSize/2) 'pt,forget plot] coordinates {' m2t2.util.joinCell(coords,' ') '};'];
    end
end
function value=pathLine(bs,color,width,style,geometry)
    value=[bs 'path[draw=' color ',line width=' n(width) 'pt,' m2t2.render.lineStyleName(style) '] ' geometry ';'];
end
function value=n(input),value=m2t2.util.formatNumber(input);end
