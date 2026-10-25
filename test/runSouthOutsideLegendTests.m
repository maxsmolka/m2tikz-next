function summary = runSouthOutsideLegendTests(out, compile)
%RUNSOUTHOUTSIDELEGENDTESTS Lower two-row legends and source/publication modes.
    root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
    if nargin<1,out=fullfile(root,'.audit','south-outside-legend');end
    if nargin<2,compile=false;end
    if exist(out,'dir')~=7,mkdir(out);end
    native=~exist('OCTAVE_VERSION','builtin');records={};checks=0;
    value=fixture(6,3);
    encoded=m2t2.ir.toJson(value);assert(strcmp(encoded,m2t2.ir.toJson(m2t2.ir.fromJson(encoded))));checks=checks+1;
    bad=value;bad.axes{1}.legend=rmfield(bad.axes{1}.legend,'layout');reject(bad);checks=checks+1;
    bad=value;bad.axes{2}=bad.axes{1};bad.axes{2}.id='axes-2';reject(bad);checks=checks+1;
    bad=m2t2.ir.fromJson(fileread(fullfile(root,'test','fixtures','ir','compatibility','scientific-3d.json')));
    bad.axes{1}.legend=fixtureLegend(numel(bad.axes{1}.series),1);
    for j=1:numel(bad.axes{1}.series)
        bad.axes{1}.legend.entries{j}=m2t2.ir.makeLegendEntry(bad.axes{1}.series{j}.id,m2t2.ir.makeText(sprintf('B%d',j),'plain'));
    end
    reject(bad);checks=checks+1;
    inert=m2t.profile.apply(value,m2t.profile.getProfile('none'),[]);
    assert(isequaln(inert.ir,value));checks=checks+1;
    hidden=value.axes{1}.legend;hidden.visible=false;
    assert(m2t.profile.legendBottomInset(hidden,m2t.profile.publication())==0);checks=checks+1;
    for k=1:9
        value=fixture(6,3);profile=m2t.profile.publication();width='single-column';
        switch k
            case 1,profile=m2t.profile.getProfile('none');width=[];
            case 3,width='double-column';
            case 4,value.axes{1}.xlabel=m2t2.ir.makeText();
            case 5,value.axes{1}.xlabel=m2t2.ir.makeText('EvaluationTimeWithUnits','plain');width='double-column';
            case 6,value=fixture(5,3);
            case 7,value.layout=m2t2.ir.makeTiledLayout(1,1,{m2t2.ir.makeLayoutCell('axes-1',1,1)});
            case 8
                value=m2t2.ir.fromJson(fileread(fullfile(root,'test','fixtures','ir','compatibility','dual-y.json')));
                value.size=[600 360];a=value.axes{1};a.xlabel=m2t2.ir.makeText('Time','plain');
                a.title=m2t2.ir.makeText('Chart','plain');a.legend=fixtureLegend(numel(a.series),ceil(numel(a.series)/2));
                for j=1:numel(a.series),a.legend.entries{j}=m2t2.ir.makeLegendEntry(a.series{j}.id,m2t2.ir.makeText(sprintf('B%d',j),'plain'));end
                value.axes{1}=a;width='double-column';
            case 9,value=fixture(2,1);value.axes{1}.legend.layout.orientation='vertical';
        end
        before=m2t2.ir.toJson(value);t=m2t.profile.apply(value,profile,width);assert(t.success);
        assert(strcmp(before,m2t2.ir.toJson(value)));
        unchanged=t.ir;unchanged.size=value.size;unchanged.layout=value.layout;
        unchanged.axes{1}.placement=value.axes{1}.placement;
        assert(isequaln(unchanged,value),'Profile changed scientific content.');
        name=sprintf('S%02d',k);tex=m2t2.render.renderPgfplots(t.ir,true,t.renderConfig);
        assert(strcmp(tex,m2t2.render.renderPgfplots(t.ir,true,t.renderConfig)));
        assert(~isempty(strfind(tex,'anchor=north'))&&~isempty(strfind(tex,'yshift=-'))); %#ok<STREMP>
        path=fullfile(out,name);m2t.internal.writeTextFile([path '.tex'],tex);
        if compile
            r=m2t.internal.compileLuaLatex([path '.tex'],[path '.pdf'],'lualatex');
            assert(r.success,['Lower legend PDF failed: ' name]);
        end
        records{end+1}=record(name,t);checks=checks+1; %#ok<AGROW>
    end
    if compile
        % No profile means no source-geometry repair. Overflow stays explicit.
        cramped=fixture(6,3);cramped.axes{1}.placement.y=.01;
        expectedOverflow(cramped,m2t.profile.getProfile('none'),[],fullfile(out,'source-too-low'));
        wide=fixture(6,3);
        for j=1:6,wide.axes{1}.legend.entries{j}.text.value=repmat('WideLabel',1,12);end
        expectedOverflow(wide,m2t.profile.publication(),'single-column',fullfile(out,'too-wide'));
        checks=checks+2;
    end
    if native
        extra=nativeWorkflows(out,compile);records=[records extra];checks=checks+1;
    end
    m2t.internal.writeTextFile(fullfile(out,'legend-manifest.json'),jsonencode(records));
    summary=struct('checks',checks,'pdfCases',numel(records),'nativeMatlab',native);
    fprintf('SOUTH_OUTSIDE_LEGEND_PASS: %d checks, %d PDF cases, compile=%d nativeMatlab=%d\n',checks,numel(records),compile,native);
end

function value=fixture(count,columns)
    a=m2t2.ir.makeAxes();a.id='axes-1';a.placement=m2t2.ir.makePlacement(.14,.32,.78,.55);
    a.xlim=[0 2];a.ylim=[0 8];a.xlabel=m2t2.ir.makeText('Time','plain');
    a.ylabel=m2t2.ir.makeText('Value','plain');a.title=m2t2.ir.makeText('Chart','plain');
    a.legend=fixtureLegend(count,columns);a.series=cell(1,count);
    for j=1:count
        s=m2t2.ir.makeLineSeries();s.id=sprintf('axes-1-series-%d',j);
        s.x=[0 1 2];s.y=[j j+1 j];s.color=[j/(count+1) .3 .6];
        s.displayName=m2t2.ir.makeText(sprintf('B%d',j),'plain');a.series{j}=s;
        a.legend.entries{j}=m2t2.ir.makeLegendEntry(s.id,s.displayName);
    end
    value=m2t2.ir.makeFigure({a});value.size=[600 360];m2t2.ir.validate(value);
end

function legend=fixtureLegend(count,columns)
    legend=m2t2.ir.makeLegend();legend.visible=true;legend.location='south_outside';legend.box='off';
    legend.layout=struct('orientation','horizontal','columns',columns);legend.entries=cell(1,count);
end

function row=record(name,t)
    a=t.ir.axes{1};border=t.renderConfig.standaloneBorderPt;
    row=struct('case',name,'pdf',[name '.pdf'], ...
        'widthMm',(t.ir.size(1)+2*border)*25.4/72.27,'heightMm',(t.ir.size(2)+2*border)*25.4/72.27, ...
        'plotTopPt',(a.placement.y+a.placement.height)*t.ir.size(2)*72/72.27, ...
        'plotBottomPt',a.placement.y*t.ir.size(2)*72/72.27,'borderPt',border*72/72.27, ...
        'columns',a.legend.layout.columns,'labels',{cellfun(@(e)e.text.value,a.legend.entries,'UniformOutput',false)}, ...
        'title',a.title.value,'xlabel',a.xlabel.value,'outside',true,'outsideSide','south');
end

function records=nativeWorkflows(out,compile)
    fig=figure('Visible','off','Color','w','Units','pixels','Position',[100 100 800 500]);
    guard=onCleanup(@()close(fig));a=axes('Parent',fig,'Color','w');hold(a,'on');h=cell(1,6);labels=cell(1,6);
    for j=1:6,h{j}=plot(a,[0 1 2],[j j+1 j]);labels{j}=sprintf('B%d',j);end
    xlabel(a,'Time');ylabel(a,'Value');title(a,'Chart');
    order=[6 2 4 1 5 3];l=legend(a,[h{order}],labels(order),'Orientation','horizontal', ...
        'NumColumns',3,'Location','southoutside','Box','off');
    set(a,'Position',[.16 .32 .76 .55],'XColor','k','YColor','k');drawnow;
    props={'Orientation','Location','Position','String','Box','NumColumns'};
    before=get(l,props);value=m2t2.reader.readFigure(fig);encoded=m2t2.ir.toJson(value);
    assert(value.axes{1}.legend.layout.columns==3&&strcmp(value.axes{1}.legend.location,'south_outside'));
    actual=cellfun(@(e)e.text.value,value.axes{1}.legend.entries,'UniformOutput',false);
    assert(isequal(actual,labels(order)));
    records={};
    for j=1:3
        profile=m2t.profile.getProfile('none');width=[];options={};
        if j>1
            profile=m2t.profile.publication();width='single-column';if j==3,width='double-column';end
            options={'Profile','publication','Width',width};
        end
        if compile
            name=sprintf('N%02d',j);r=m2t.export(fig,fullfile(out,name),options{:},'Overwrite',true);
            assert(r.success,['Native lower legend export failed: ' name]);
            t=m2t.profile.apply(value,profile,width);records{end+1}=record(name,t); %#ok<AGROW>
        end
        assert(isequaln(before,get(l,props)),'Export changed caller legend.');
        assert(strcmp(encoded,m2t2.ir.toJson(m2t2.reader.readFigure(fig))),'Export changed caller data/geometry.');
    end
    clear guard;
end

function expectedOverflow(value,profile,width,path)
    t=m2t.profile.apply(value,profile,width);assert(t.success);
    m2t.internal.writeTextFile([path '.tex'],m2t2.render.renderPgfplots(t.ir,true,t.renderConfig));
    r=m2t.internal.compileLuaLatex([path '.tex'],[path '.pdf'],'lualatex');
    assert(~r.success&&exist([path '.pdf'],'file')~=2);
    assert(strcmp(r.diagnostics(1).code,'M2T:C003:CompilationFailed'));
    assert(~isempty(strfind(regexprep(fileread(r.logPath),'\s',''),'Legendexceedsfigurebounds'))); %#ok<STREMP>
end

function reject(value)
    try,m2t2.ir.validate(value);error('M2T:ExpectedFailure','Invalid lower legend accepted');
    catch err,assert(strcmp(err.identifier,'M2T2:E003:InvalidIR'));end
end
