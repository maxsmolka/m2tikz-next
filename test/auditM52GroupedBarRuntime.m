function evidence = auditM52GroupedBarRuntime(outputPath)
%AUDITM52GROUPEDBARRUNTIME Capture privacy-safe grouped-bar runtime evidence.
    if nargin < 1, outputPath = ''; end
    evidence = struct('runtime', runtimeInfo(), 'fixtures', {{}});
    evidence.fixtures{end+1} = inspectBasic();
    evidence.fixtures{end+1} = inspectStyled();
    evidence.fixtures{end+1} = inspectSubplots();
    if ~isempty(outputPath)
        folder = fileparts(outputPath); if exist(folder, 'dir') ~= 7, mkdir(folder); end
        fid = fopen(outputPath, 'w'); cleanup = onCleanup(@() fclose(fid));
        fwrite(fid, jsonencode(evidence, 'PrettyPrint', true), 'char'); clear cleanup;
    end
end

function fixture = inspectBasic()
    fig=figure('Visible','off');cleanup=onCleanup(@()close(fig));ax=axes('Parent',fig);
    bars=bar(ax,[1 2 3;4 5 6],'grouped');
    fixture=inspectFixture('basic_grouped',fig,ax,bars,[]);clear cleanup;
end

function fixture = inspectStyled()
    fig=figure('Visible','off');cleanup=onCleanup(@()close(fig));ax=axes('Parent',fig);
    bars=bar(ax,[2 4 7],[1 3;2 4;3 5],.65,'grouped');
    set(bars(1),'DisplayName','Measured','FaceColor',[.1 .4 .8], ...
        'EdgeColor',[.05 .1 .2],'LineWidth',1.25,'LineStyle','--','BaseValue',1);
    set(bars(2),'DisplayName','Reference','FaceColor',[.8 .3 .1], ...
        'EdgeColor','none','LineWidth',.75,'LineStyle',':','BaseValue',1);
    set(ax,'XTick',[2 4 7],'XTickLabel',{'low','mid','high'},'YGrid','on');
    legend(ax,'show');
    fixture=inspectFixture('styled_grouped',fig,ax,bars,findLegend(fig));clear cleanup;
end

function fixture = inspectSubplots()
    fig=figure('Visible','off');cleanup=onCleanup(@()close(fig));
    axesEvidence=cell(1,4);
    for k=1:4
        ax=subplot(2,2,k,'Parent',fig);bars=bar(ax,[1 2 3],[k k+1;k+2 k+3;k+4 k+5],'grouped');
        axesEvidence{k}=inspectAxes(ax,bars,[]);
    end
    fixture=struct('name','four_axes','figureChildren',{childEvidence(fig)}, ...
        'axes',{axesEvidence});clear cleanup;
end

function fixture=inspectFixture(name,fig,ax,bars,legendHandle)
    fixture=struct('name',name,'figureChildren',{childEvidence(fig)}, ...
        'axes',{{inspectAxes(ax,bars,legendHandle)}});
end

function result=inspectAxes(ax,bars,legendHandle)
    series=cell(1,numel(bars));for k=1:numel(bars),series{k}=inspectBar(bars(k));end
    result=struct('class',class(ax),'type',safeGet(ax,'Type'), ...
        'position',row(safeGet(ax,'Position')),'xlim',row(safeGet(ax,'XLim')), ...
        'ylim',row(safeGet(ax,'YLim')),'xtick',row(safeGet(ax,'XTick')), ...
        'xticklabel',{cellText(safeGet(ax,'XTickLabel'))}, ...
        'xgrid',safeGet(ax,'XGrid'),'ygrid',safeGet(ax,'YGrid'), ...
        'children',{childEvidence(ax)},'series',{series}, ...
        'legend',inspectLegend(legendHandle));
end

function result=inspectBar(handle)
    names={'Type','Parent','XData','YData','BarWidth','BaseValue','Horizontal', ...
        'BarLayout','FaceColor','FaceAlpha','EdgeColor','EdgeAlpha','LineStyle', ...
        'LineWidth','Visible','DisplayName','CData','XOffset','XEndPoints', ...
        'YEndPoints','Baseline','UserData'};
    result=struct('class',class(handle));
    for k=1:numel(names),result.(lower(names{k}))=privacyValue(safeGet(handle,names{k}));end
    result.children=childEvidence(handle);
    baseline=safeGet(handle,'Baseline');
    if ishandleValue(baseline)
        result.baselineEvidence=struct('class',class(baseline),'type',safeGet(baseline,'Type'), ...
            'parentClass',class(safeGet(baseline,'Parent')),'baseValue',privacyValue(safeGet(baseline,'BaseValue')), ...
            'visible',privacyValue(safeGet(baseline,'Visible')));
    else
        result.baselineEvidence=struct();
    end
end

function result=inspectLegend(handle)
    if isempty(handle),result=struct();return;end
    result=struct('class',class(handle),'type',safeGet(handle,'Type'), ...
        'parentClass',class(safeGet(handle,'Parent')),'string',{cellText(safeGet(handle,'String'))}, ...
        'children',{childEvidence(handle)});
end

function items=childEvidence(parent)
    try,children=flipud(allchild(parent));catch,children=[];end
    items=cell(1,numel(children));
    for k=1:numel(children)
        items{k}=struct('class',class(children(k)),'type',safeGet(children(k),'Type'), ...
            'tag',privacyValue(safeGet(children(k),'Tag')), ...
            'handleVisibility',privacyValue(safeGet(children(k),'HandleVisibility')), ...
            'visible',privacyValue(safeGet(children(k),'Visible')));
    end
end

function result=findLegend(fig)
    result=[];children=allchild(fig);
    for k=1:numel(children)
        type=safeGet(children(k),'Type');tag=safeGet(children(k),'Tag');
        if strcmp(type,'legend')||(strcmp(type,'axes')&&strcmp(tag,'legend')),result=children(k);return;end
    end
end

function value=safeGet(handle,name)
    try,value=get(handle,name);catch,value=[];end
end

function value=privacyValue(value)
    if isnumeric(value)||islogical(value),value=double(value);elseif ischar(value),value=char(value);
    elseif iscell(value),value=cellfun(@privacyValue,value,'UniformOutput',false);else,value=class(value);end
end

function yes=ishandleValue(value)
    yes=false;try,yes=isscalar(value)&&ishandle(value);catch,end
end

function value=row(value),if isnumeric(value),value=reshape(double(value),1,[]);end,end
function value=cellText(value)
    if ischar(value),value=cellstr(value);elseif isstring(value),value=cellstr(value);end
end

function info=runtimeInfo()
    if exist('OCTAVE_VERSION','builtin'),kind='octave';versionValue=OCTAVE_VERSION;release='';
    else,kind='matlab';versionValue=version;release=version('-release');end
    info=struct('kind',kind,'version',versionValue,'release',release,'computer',computer);
end
