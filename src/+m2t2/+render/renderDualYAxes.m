function lines = renderDualYAxes(node, axesIndex, figureSize, config)
%RENDERDUALYAXES Shared physical box; independent coordinate systems per side.
%   Decorate once, then emit data in original order, then the linked legend.
    right=node.dualY.right; leftColor=node.dualY.leftColor;
    node=rmfield(node,'dualY'); left=node; other=node;
    other.ylim=right.limits;other.yscale=right.scale;other.ydirection=right.direction;
    other.yticks=right.ticks;other.ylabel=right.label;
    other.xlabel=m2t2.ir.makeText();other.title=m2t2.ir.makeText();
    other.xgrid=false;other.ygrid=false;
    left.legend.visible=false;other.legend.visible=false;
    config.seriesIndices=[];
    xLine='axis x line*=bottom';if strcmp(node.box,'on'),xLine='axis x line*=box';end
    config.axesOptions=[{'axis y line*=left',xLine,'axis line style={-}'},colorOptions(leftColor)];
    lines=m2t2.render.renderAxes(left,axesIndex,figureSize,config);
    config.axesOptions=[{'axis y line*=right','axis x line=none','axis line style={-}', ...
        'axis background/.style={fill=none}'},colorOptions(right.color)];
    lines=[lines,m2t2.render.renderAxes(other,axesIndex,figureSize,config)];
    config.axesOptions={'hide axis','axis background/.style={fill=none}'};
    for k=1:numel(node.series)
        if ~node.series{k}.visible,continue;end
        if strcmp(node.series{k}.yAxis,'left'),data=left;else,data=other;end
        data.xlabel=m2t2.ir.makeText();data.ylabel=m2t2.ir.makeText();data.title=m2t2.ir.makeText();
        data.xgrid=false;data.ygrid=false;config.seriesIndices=k;
        lines=[lines,m2t2.render.renderAxes(data,axesIndex,figureSize,config)]; %#ok<AGROW>
    end
    if node.legend.visible
        node.xlabel=m2t2.ir.makeText();node.ylabel=m2t2.ir.makeText();node.title=m2t2.ir.makeText();
        node.xgrid=false;node.ygrid=false;config.seriesIndices=[];
        lines=[lines,m2t2.render.renderAxes(node,axesIndex,figureSize,config)];
    end
end

function options=colorOptions(rgb)
    values=arrayfun(@m2t2.util.formatNumber,rgb,'UniformOutput',false);
    color=['{rgb,1:red,' values{1} ';green,' values{2} ';blue,' values{3} '}'];
    options={['y axis line style={draw=' color '}'], ...
        ['y tick style={draw=' color '}'],['yticklabel style={text=' color '}'], ...
        ['ylabel style={text=' color '}']};
end
