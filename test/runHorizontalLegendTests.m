function summary = runHorizontalLegendTests(out, compile)
%RUNHORIZONTALLEGENDTESTS Synthetic regression for explicit upper legend layout.
    root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
    if nargin<1,out=fullfile(root,'.audit','horizontal-legend');end
    if nargin<2,compile=false;end
    if exist(out,'dir')~=7,mkdir(out);end
    native=~exist('OCTAVE_VERSION','builtin');tests=0;records={};
    ir=fixture(6,6);encoded=m2t2.ir.toJson(ir);
    assert(strcmp(encoded,m2t2.ir.toJson(m2t2.ir.fromJson(encoded))));tests=tests+1;
    bad=ir;bad.axes{1}.legend=rmfield(bad.axes{1}.legend,'layout');reject(bad);tests=tests+1;
    for c={0,-1,NaN,Inf,1.5,[1 2],true,'6',1i}
        bad=ir;bad.axes{1}.legend.layout.columns=c{1};reject(bad);tests=tests+1;
    end
    bad=ir;bad.axes{1}.legend.layout.orientation='diagonal';reject(bad);tests=tests+1;
    bad=ir;bad.axes{1}.legend.layout.orientation='vertical';reject(bad);tests=tests+1;
    bad=ir;bad.axes{1}.legend.box='invalid';reject(bad);tests=tests+1;
    bad=ir;bad.axes{2}=bad.axes{1};bad.axes{2}.id='axes-2';reject(bad);tests=tests+1;
    % Old v2 files gain no invented layout fields or changed canonical bytes.
    old=m2t2.ir.fromJson(fileread(fullfile(root,'test','fixtures','ir','compatibility','rich-scatter.json')));
    assert(~isfield(old.axes{1}.legend,'layout'));
    assert(strcmp(m2t2.ir.toJson(old),strtrim(fileread(fullfile(root,'test','fixtures','ir','compatibility','rich-scatter.canonical.json')))));
    tests=tests+1;
    inert=m2t.profile.apply(ir,m2t.profile.getProfile('none'),[]);assert(isequaln(ir,inert.ir));tests=tests+1;
    tex=m2t2.render.renderPgfplots(ir,true);assert(strcmp(tex,m2t2.render.renderPgfplots(ir,true)));
    labels=regexp(tex,'\\addlegendentry\{(L\d+)\}','tokens');
    assert(isequal(cellfun(@(x)x{1},labels,'UniformOutput',false),{'L1','L2','L3','L4','L5','L6'}));
    assert(~isempty(strfind(tex,'legend columns=6'))&&~isempty(strfind(tex,'anchor=south')));tests=tests+1; %#ok<STREMP>
    nativeReader(native);tests=tests+1;
    empty=ir;empty.axes{1}.legend.entries={};
    assert(isempty(m2t2.render.legendBoundsCheck(empty.axes{1},1,empty.size)));tests=tests+1;
    for k=1:10
        value=fixture(6,6);width='single-column';profile=m2t.profile.publication();
        switch k
            case 2,width='double-column';
            case 3,profile=m2t.profile.getProfile('none');width=[];
            case 4,value.axes{1}.legend.layout.columns=3;
            case 5,width='double-column';value.axes{1}.title=m2t2.ir.makeText('Chart','plain');
            case 6,value=fixture(1,1);
            case 7
                value.axes{1}.title=m2t2.ir.makeText('Chart','plain');width='double-column';
                value.layout=m2t2.ir.makeTiledLayout(1,1,{m2t2.ir.makeLayoutCell('axes-1',1,1)});
            case 8
                value=m2t2.ir.fromJson(fileread(fullfile(root,'test','fixtures','ir','compatibility','dual-y.json')));
                value.size=[600 315];a=value.axes{1};a.title=m2t2.ir.makeText('Chart','plain');
                a.legend=m2t2.ir.makeLegend();a.legend.visible=true;a.legend.location='north_outside';
                a.legend.layout=struct('orientation','horizontal','columns',2);
                a.legend.entries=cell(1,numel(a.series));
                for j=1:numel(a.series),a.legend.entries{j}=m2t2.ir.makeLegendEntry(a.series{j}.id,m2t2.ir.makeText(sprintf('L%d',j),'plain'));end
                value.axes{1}=a;width='double-column';
            case 9,value.axes{1}.legend.location='north_east';width='double-column';
            case 10,value=fixture(5,3);
        end
        original=m2t2.ir.toJson(value);t=m2t.profile.apply(value,profile,width);assert(t.success);
        unchanged=t.ir;unchanged.size=value.size;unchanged.layout=value.layout;
        unchanged.axes{1}.placement=value.axes{1}.placement;
        assert(isequaln(unchanged,value),'Legend profile changed scientific content.');
        assert(strcmp(original,m2t2.ir.toJson(value)));
        name=sprintf('H%02d',k);plan=m2t2.render.makePgfplotsPlan(t.ir,true,t.renderConfig,'vector',[name '-assets']);
        m2t.internal.writeTextFile(fullfile(out,[name '.tex']),plan.tex);
        if compile
            r=m2t.internal.compileLuaLatex(fullfile(out,[name '.tex']),fullfile(out,[name '.pdf']),'lualatex');
            assert(r.success,['Legend PDF failed: ' name]);
        end
        a=t.ir.axes{1};border=t.renderConfig.standaloneBorderPt;
        records{end+1}=struct('case',name,'pdf',[name '.pdf'], ...
            'widthMm',(t.ir.size(1)+2*border)*25.4/72.27, ...
            'heightMm',(t.ir.size(2)+2*border)*25.4/72.27, ...
            'plotTopPt',(a.placement.y+a.placement.height)*t.ir.size(2)*72/72.27, ...
            'borderPt',border*72/72.27,'columns',a.legend.layout.columns, ...
            'labels',{cellfun(@(e)e.text.value,a.legend.entries,'UniformOutput',false)}, ...
            'title',a.title.value,'outside',strcmp(a.legend.location,'north_outside')); %#ok<AGROW>
        tests=tests+1;
    end
    % Actual interpreted TeX text decides fit; never silently crop or restyle.
    if compile
        value=fixture(6,6);
        for j=1:6,value.axes{1}.legend.entries{j}.text.value=repmat('WideLabel',1,12);end
        t=m2t.profile.apply(value,m2t.profile.publication(),'single-column');
        path=fullfile(out,'oversized');m2t.internal.writeTextFile([path '.tex'],m2t2.render.renderPgfplots(t.ir,true,t.renderConfig));
        r=m2t.internal.compileLuaLatex([path '.tex'],[path '.pdf'],'lualatex');
        assert(~r.success&&exist([path '.pdf'],'file')~=2);
        % Compiler/bridge logs can wrap even within a word; assert the message
        % independently of that incidental line wrapping.
        logText=regexprep(fileread(r.logPath),'\s','');
        assert(~isempty(strfind(logText,'Legendexceedsfigurebounds'))); %#ok<STREMP>
        tests=tests+1;
    end
    m2t.internal.writeTextFile(fullfile(out,'legend-manifest.json'),jsonencode(records));
    summary=struct('tests',tests,'pdfCases',10,'failures',0,'nativeReader',native);
    fprintf('HORIZONTAL_LEGEND_PASS: %d/%d compile=%d nativeMatlab=%d\n',tests,tests,compile,native);
end

function ir=fixture(count,columns)
    a=m2t2.ir.makeAxes();a.id='axes-1';a.placement=m2t2.ir.makePlacement(.13,.15,.775,.7);
    a.xlim=[0 2];a.ylim=[0 8];a.xlabel=m2t2.ir.makeText('Time','plain');a.ylabel=m2t2.ir.makeText('Value','plain');
    a.legend.visible=true;a.legend.location='north_outside';a.legend.box='off';
    a.legend.layout=struct('orientation','horizontal','columns',columns);
    a.series=cell(1,count);a.legend.entries=cell(1,count);
    for j=1:count
        s=m2t2.ir.makeLineSeries();s.id=sprintf('axes-1-series-%d',j);s.x=[0 1 2];s.y=[j j+1 j];
        s.color=[mod(j,3)/3 mod(j+1,3)/3 mod(j+2,3)/3];s.marker='circle';s.displayName=m2t2.ir.makeText(sprintf('L%d',j),'plain');
        a.series{j}=s;a.legend.entries{j}=m2t2.ir.makeLegendEntry(s.id,s.displayName);
    end
    ir=m2t2.ir.makeFigure({a});ir.size=[600 315];m2t2.ir.validate(ir);
end
function nativeReader(native)
    f=figure('Visible','off','Color','w');guard=onCleanup(@()close(f));
    a=axes('Parent',f,'Color','w');hold(a,'on');h=cell(1,6);labels=cell(1,6);
    for j=1:6,h{j}=plot(a,[0 1 2],[j j+1 j]);labels{j}=sprintf('L%d',j);end
    order=[6 2 4 1 5 3];l=legend(a,[h{order}],labels(order),'Orientation','horizontal','Location','northoutside');
    if native,set(l,'NumColumns',6);end
    set(l,'Box','off');drawnow;
    properties={'Orientation','Location','Position','String','Box'};if native,properties{end+1}='NumColumns';end
    before=get(l,properties);ir=m2t2.reader.readFigure(f);after=get(l,properties);
    assert(isequaln(before,after),'Reader changed caller legend.');
    assert(strcmp(ir.axes{1}.legend.location,'north_outside')&&ir.axes{1}.legend.layout.columns==6);
    actual=cellfun(@(e)e.seriesId,ir.axes{1}.legend.entries,'UniformOutput',false);
    expected=arrayfun(@(j)sprintf('axes-1-series-%d',j),order,'UniformOutput',false);assert(isequal(actual,expected));
    assert(strcmp(ir.axes{1}.legend.box,'off'));
    set(l,'Location','southoutside');
    lower=m2t2.reader.readFigure(f);assert(strcmp(lower.axes{1}.legend.location,'south_outside'));
    set(l,'Location','eastoutside');
    try,m2t2.reader.readFigure(f);error('M2T:ExpectedFailure','eastoutside accepted');
    catch err,assert(strcmp(err.identifier,'M2T2:E007:UnsupportedProperty'));end
    clear guard;
end
function reject(ir)
    try,m2t2.ir.validate(ir);error('M2T:ExpectedFailure','Invalid legend accepted');
    catch err,assert(strcmp(err.identifier,'M2T2:E003:InvalidIR'));end
end
