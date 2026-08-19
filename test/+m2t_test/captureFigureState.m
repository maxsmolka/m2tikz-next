function state = captureFigureState(fig)
%CAPTUREFIGURESTATE Capture caller-owned state relevant to mutation checks.
    state=struct('visible',get(fig,'Visible'),'currentFigure',isCurrent(fig),'axes',{{}});
    axesHandles=findall(fig,'Type','axes');
    states=cell(1,numel(axesHandles));
    for k=1:numel(axesHandles)
        ax=axesHandles(k); children=get(ax,'Children');
        childStates=cell(1,numel(children));
        for c=1:numel(children)
            childStates{c}=captureProperties(children(c),{'Type','XData','YData','CData','Color','LineStyle','LineWidth','Marker','MarkerSize'});
        end
        states{k}=struct('xlim',get(ax,'XLim'),'ylim',get(ax,'YLim'), ...
            'clim',readProperty(ax,{'CLim','CLim'}),'colormap',colormap(ax), ...
            'children',{childStates});
    end
    state.axes=states;
end
function yes=isCurrent(fig),try,yes=isequal(get(0,'CurrentFigure'),fig);catch,yes=false;end,end
function output=captureProperties(handle,names)
    output=struct();for k=1:numel(names),if isprop(handle,names{k}),output.(lower(names{k}))=get(handle,names{k});end,end
end
function value=readProperty(handle,names)
    value=[];for k=1:numel(names),if isprop(handle,names{k}),value=get(handle,names{k});return;end,end
end
