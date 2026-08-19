function snapshots = auditGraphicsObjects(outputDirectory)
%AUDITGRAPHICSOBJECTS Record normalized HG evidence for curated fixtures.
    if exist(outputDirectory,'dir')~=7,mkdir(outputDirectory);end
    ids={'F01','F03','F04','F08','F09','F11','F12','F13','F15','F16','F18','F19','F20','F21','F22'};
    snapshots=repmat(struct('fixtureId','','runtime',struct(),'objects',{{}}),1,numel(ids));
    for k=1:numel(ids)
        fixture=m2t_test.buildFixture(ids{k});cleanup=onCleanup(@()closeFigures(fixture.figures));
        handles=relevantHandles(fixture.primary);objects=cell(1,numel(handles));
        for h=1:numel(handles),objects{h}=captureObject(handles(h));end
        snapshot=struct('fixtureId',ids{k},'runtime',m2t_test.runtimeInfo(),'objects',{objects});
        snapshot=m2t_test.sanitizeEvidence(snapshot);snapshots(k)=snapshot;
        writeText(fullfile(outputDirectory,[ids{k} '.json']),[jsonencode(snapshot) sprintf('\n')]);
        clear cleanup;
    end
end

function handles=relevantHandles(fig)
    allHandles=findall(fig);keep=false(size(allHandles));
    relevant={'figure','axes','legend','colorbar','line','scatter','errorbar','image','text','hggroup','annotationpane'};
    for k=1:numel(allHandles)
        try,keep(k)=any(strcmp(get(allHandles(k),'Type'),relevant));catch,keep(k)=false;end
    end
    handles=allHandles(keep);
end

function object=captureObject(handle)
    names={'Type','Tag','HandleVisibility','Visible','DisplayName','XData','YData','ZData', ...
        'CData','CDataMapping','AlphaData','Color','LineStyle','LineWidth','Marker','MarkerSize', ...
        'XLim','YLim','CLim','XTick','YTick','XTickLabel','YTickLabel','XDir','YDir','Position','Location','String'};
    object=struct('class',class(handle),'parentClass','','childClasses',{{}},'properties',struct());
    try,parent=get(handle,'Parent');if ~isempty(parent),object.parentClass=class(parent);end;catch,end
    try,children=get(handle,'Children');object.childClasses=arrayfun(@class,children,'UniformOutput',false);catch,end
    for k=1:numel(names)
        if isprop(handle,names{k})
            try,object.properties.(names{k})=normalize(get(handle,names{k}));catch,end
        end
    end
end
function value=normalize(value)
    if isobject(value),value=class(value);elseif iscell(value),for k=1:numel(value),value{k}=normalize(value{k});end;end
end
function writeText(path,text),fid=fopen(path,'wb');assert(fid>=0);cleanup=onCleanup(@()fclose(fid));fwrite(fid,text,'char');clear cleanup;end
function closeFigures(figures),for k=1:numel(figures),if ishandle(figures(k)),close(figures(k));end,end,end
