function options = legendOptions(node, axesIndex, config)
%LEGENDOPTIONS Preserve explicit horizontal columns and axes-owned placement.
    legend=node.legend;style={};
    if strcmp(legend.location,'north_outside')
        points=config.typography.titlePt;if isempty(points),points=10;end
        hasTitle=~isempty(node.title.value);
        if isfield(config,'outsideLegendHasTitle'),hasTitle=config.outsideLegendHasTitle;end
        gap=6+hasTitle*(points+8);
        options={};
        style={'at={(0.5,1)}','anchor=south',['yshift=' m2t2.util.formatNumber(gap) 'pt']};
    else
        options={['legend pos=' strrep(legend.location,'_',' ')]};
    end
    if isfield(legend,'layout')
        options{end+1}=['legend columns=' m2t2.util.formatNumber(legend.layout.columns)];
        style{end+1}=sprintf('name=m2tlegend%d',axesIndex);
    end
    if isfield(legend,'box')&&strcmp(legend.box,'off'),style=[style {'draw=none','fill=none'}];end
    if ~isempty(style),options{end+1}=['legend style={' m2t2.util.joinCell(style,',') '}'];end
end
