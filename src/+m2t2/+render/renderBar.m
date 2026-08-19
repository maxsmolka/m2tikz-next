function lines = renderBar(node, colorName)
%RENDERBAR Render semantic grouped bars as axis-coordinate vector rectangles.
    bs = char(92); edgeName = [colorName 'edge']; lines = {};
    spacing=1;if numel(node.categories)>1,spacing=min(diff(node.categories));end
    [offset, width] = groupedGeometry(node.groupIndex, node.groupCount, node.barWidth,spacing);
    options = {};
    if node.faceVisible, options{end+1}=['fill=' colorName]; else, options{end+1}='fill=none'; end
    if node.edgeVisible
        options{end+1}=['draw=' edgeName];
        options{end+1}=['line width=' m2t2.util.formatNumber(node.lineWidth) 'pt'];
        options{end+1}=m2t2.render.lineStyleName(node.lineStyle);
    else
        options{end+1}='draw=none';
    end
    for k=1:numel(node.categories)
        center=node.categories(k)+offset;
        left=center-width/2; right=center+width/2;
        lines{end+1}=[bs 'path[' m2t2.util.joinCell(options, ',') '] (axis cs:' ...
            m2t2.util.formatNumber(left) ',' m2t2.util.formatNumber(node.baseline) ...
            ') rectangle (axis cs:' m2t2.util.formatNumber(right) ',' ...
            m2t2.util.formatNumber(node.values(k)) ');']; %#ok<AGROW>
    end
end

function [offset,width]=groupedGeometry(index,count,barWidth,spacing)
    if count==1,groupWidth=1;offset=0;
    else,groupWidth=min(0.8,count/(count+1.5));offset=groupWidth*(2*index-count-1)/(2*count);end
    offset=offset*spacing;width=barWidth*groupWidth*spacing/count;
end
