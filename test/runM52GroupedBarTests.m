function summary=runM52GroupedBarTests(outputDirectory)
%RUNM52GROUPEDBARTESTS Validate grouped bars with synthetic figures.
    root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
    if nargin<1,outputDirectory=fullfile(root,'.audit','m52-grouped-bars');end
    ensureDirectory(outputDirectory);
    cases={ ...
        'B01_single_grouped_bar',@b01; 'B02_two_series',@b02; ...
        'B03_three_series',@b03; 'B04_explicit_categories',@b04; ...
        'B05_custom_ticks',@b05; 'B06_legend_order',@b06; ...
        'B07_face_color',@b07; 'B08_edge_color',@b08; ...
        'B09_line_style',@b09; 'B10_bar_width',@b10; ...
        'B11_baseline',@b11; 'B12_mixed_sign',@b12; ...
        'B13_multi_axes',@b13; 'B14_four_axes_layout',@b14; ...
        'B15_profile_single',@b15; ...
        'B16_profile_double',@b16; ...
        'B17_json_replay',@b17; 'B18_deterministic_repeat',@b18; ...
        'B19_figure_lifecycle',@b19; 'B20_stacked_rejected',@b20; ...
        'B21_horizontal_rejected',@b21; 'B22_arbitrary_hggroup',@b22; ...
        'B23_boxplot_compound',@b23; 'B24_figure_set',@b24; ...
        'B25_synthetic_overview',@syntheticOverview; 'B26_synthetic_four_panel',@syntheticFourPanel; ...
        'BNC3_rectangle_patch',@bnc3; 'BNC7_flat_color',@bnc7; ...
        'BNC8_modern_no_fallback',@bnc8; 'BNC10_existing_semantics',@bnc10};
    rows=cell(size(cases,1),4);failures=0;
    for k=1:size(cases,1)
        try,caseDetail=cases{k,2}();status='PASS';
        catch err,status='FAIL';failures=failures+1;caseDetail=sprintf('%s: %s',err.identifier,oneLine(err.message));end
        rows(k,:)={cases{k,1},status,caseDetail,'M5.2'};
    end
    resultPath=fullfile(outputDirectory,'m52-results.tsv');writeRows(resultPath,rows);
    summary=struct('failures',failures,'tests',size(rows,1),'resultPath',resultPath);
    if failures,fprintf(2,'M5.2 diagnostics from %s:\n%s',resultPath,fileread(resultPath));error('M2T:M52GroupedBarTestsFailed','%d M5.2 tests failed.',failures);end

    function detail=b01()
        [f,a,c]=barFigure(1);ir=read(f);s=ir.axes{1}.series{1};assertBar(s,1,1);r=compile(f,'B01');detail=sprintf('single vertical grouped series compiled in %.3fs',r.timings.total);clear c;
    end
    function detail=basic(count,name)
        [f,~,c]=barFigure(count);ir=read(f);assert(numel(ir.axes{1}.series)==count);for i=1:count,assertBar(ir.axes{1}.series{i},i,count);end;compile(f,name);detail=sprintf('%d semantic series compiled',count);clear c;
    end
    function detail=b02(),detail=basic(2,'B02');end
    function detail=b03(),detail=basic(3,'B03');end
    function detail=b04()
        [f,a,c]=barFigure(2,[2 4 7]);ir=read(f);assert(isequal(ir.axes{1}.series{1}.categories,[2 4 7]));compile(f,'B04');detail='numeric categories preserved';clear c;
    end
    function detail=b05()
        [f,a,c]=barFigure(2,[2 4 7]);set(a,'XTick',[2 4 7],'XTickLabel',{'low','mid','high'});ir=read(f);assert(isequal(ir.axes{1}.xticks.values,[2 4 7]));compile(f,'B05');detail='tick positions and labels preserved';clear c;
    end
    function detail=b06()
        [f,a,c,b]=barFigure(2);set(b(1),'DisplayName','Measured');set(b(2),'DisplayName','Reference');legend(a,'show');ir=read(f);assert(strcmp(ir.axes{1}.legend.entries{1}.text.value,'Measured'));assert(strcmp(ir.axes{1}.legend.entries{2}.text.value,'Reference'));r=compile(f,'B06');tex=fileread(r.texPath);assert(contains(tex,'area legend'));detail='ordered entries use filled-area legend samples';clear c;
    end
    function detail=b07()
        [f,~,c,b]=barFigure(2);set(b(1),'FaceColor',[.1 .4 .8]);s=read(f).axes{1}.series{1};assert(max(abs(s.faceColor-[.1 .4 .8]))<1e-12);compile(f,'B07');detail='constant RGB face preserved';clear c;
    end
    function detail=b08()
        [f,~,c,b]=barFigure(2);set(b(1),'EdgeColor',[.2 .3 .4]);set(b(2),'EdgeColor','none');ir=read(f);assert(ir.axes{1}.series{1}.edgeVisible&&~ir.axes{1}.series{2}.edgeVisible);compile(f,'B08');detail='constant and none edge modes preserved';clear c;
    end
    function detail=b09()
        [f,~,c,b]=barFigure(2);set(b(1),'LineWidth',1.25,'LineStyle','--');s=read(f).axes{1}.series{1};assert(s.lineWidth==1.25&&strcmp(s.lineStyle,'dashed'));compile(f,'B09');detail='edge width/style preserved';clear c;
    end
    function detail=b10()
        [f,~,c]=barFigure(3,[],.5);ir=read(f);assert(all(cellfun(@(s)s.barWidth==.5,ir.axes{1}.series)));compile(f,'B10');detail='bar width and grouped offsets preserved';clear c;
    end
    function detail=b11()
        [f,~,c,b]=barFigure(2);for i=1:numel(b),set(b(i),'BaseValue',1);end;ir=read(f);assert(all(cellfun(@(s)s.baseline==1,ir.axes{1}.series)));compile(f,'B11');detail='custom baseline preserved';clear c;
    end
    function detail=b12()
        f=figure('Visible','off');c=onCleanup(@()close(f));a=axes('Parent',f);bar(a,[-2 3;1 -1],'grouped');ir=read(f);assert(any(ir.axes{1}.series{1}.values<0));compile(f,'B12');detail='mixed-sign bars preserve zero crossing';clear c;
    end
    function result13=b13()
        f=figure('Visible','off');c=onCleanup(@()close(f));for panelIndex=1:2,a=subplot(1,2,panelIndex,'Parent',f);bar(a,[1 2;3 4],'grouped');end;ir=read(f);assert(numel(ir.axes)==2&&all(cellfun(@(a)numel(a.series)==2,ir.axes)));compile(f,'B13');result13='two axes retain independent bar groups';clear c;
    end
    function detail=b14()
        [f,c]=fourPanel();ir=read(f);assert(numel(ir.axes)==4&&all(cellfun(@(a)numel(a.series)==4,ir.axes)));compile(f,'B14');detail='four axes x four semantic series compiled';clear c;
    end
    function detail=profile(width,name)
        [f,~,c]=barFigure(4);r=compile(f,name,'Profile','publication','Width',width);assert(strcmp(r.profile.width,width));detail=[width ' profile compiled'];clear c;
    end
    function detail=b15(),detail=profile('single-column','B15');end
    function detail=b16(),detail=profile('double-column','B16');end
    function detail=b17()
        [f,~,c]=barFigure(3);ir=read(f);decoded=m2t2.ir.fromJson(jsonencode(ir));assert(strcmp(m2t2.render.renderPgfplots(ir,true),m2t2.render.renderPgfplots(decoded,true)));detail='JSON replay produces identical TeX';clear c;
    end
    function detail=b18()
        [f,~,c]=barFigure(3);a=read(f);b=read(f);assert(strcmp(jsonencode(a),jsonencode(b)));assert(strcmp(m2t2.render.renderPgfplots(a,true),m2t2.render.renderPgfplots(b,true)));detail='IR and TeX byte-identical in process';clear c;
    end
    function detail=b19()
        [f,a,c,b]=barFigure(2);before={f.Visible,a.Position,a.XLim,a.YLim,b(1).XData,b(1).YData,b(1).BarWidth,b(1).BaseValue,b(1).FaceColor,b(1).EdgeColor};read(f);after={f.Visible,a.Position,a.XLim,a.YLim,b(1).XData,b(1).YData,b(1).BarWidth,b(1).BaseValue,b(1).FaceColor,b(1).EdgeColor};assert(isgraphics(f)&&isequal(before,after));detail='caller figure, axes, values, and styles unchanged';clear c;
    end
    function detail=b20()
        f=figure('Visible','off');c=onCleanup(@()close(f));bar(axes('Parent',f),[1 2;3 4],'stacked');expect(@()read(f),'M2T2:E018:UnsupportedBarMode','stacked');detail='stacked mode precisely rejected';clear c;
    end
    function detail=b21()
        f=figure('Visible','off');c=onCleanup(@()close(f));barh(axes('Parent',f),[1 2;3 4],'grouped');expect(@()read(f),'M2T2:E019:UnsupportedBarOrientation','');detail='horizontal mode precisely rejected';clear c;
    end
    function detail=b22()
        [f,a,c]=lineFigure();g=hggroup('Parent',a);patch('Parent',g,'XData',[0 1 1 0],'YData',[0 0 1 1]);expect(@()read(f),'M2T2:E001:UnsupportedObject','hggroup');detail='patch-owning arbitrary hggroup remains unsupported';clear c;
    end
    function detail=b23()
        [f,a,c]=lineFigure();g=hggroup('Parent',a);patch('Parent',g,'XData',[.8 1.2 1.2 .8],'YData',[1 1 3 3]);line('Parent',g,'XData',[.8 1.2],'YData',[2 2]);expect(@()read(f),'M2T2:E001:UnsupportedObject','hggroup');detail='box-like patch/line compound is not a bar';clear c;
    end
    function detail=b24()
        [b,~,cb]=barFigure(2);[l,al,cl]=lineFigure();text(al,2,4,'note');[p,cp]=fourPanel();entries=struct('figure',{b,l,p},'name',{'bar','annotation','four-panel'});dir=fullfile(outputDirectory,'B24-set');r=m2t.exportSet(entries,dir,'Overwrite',true,'ContinueOnError',true);assert(r.success&&r.summary.succeeded==3);first=fileread(r.manifestPath);r=m2t.exportSet(entries,dir,'Overwrite',true,'ContinueOnError',true);assert(r.success&&strcmp(first,fileread(r.manifestPath)));detail='mixed line/annotation/bar set and manifest deterministic';clear cb cl cp;
    end
    function detail=syntheticOverview()
        f=figure('Visible','off');c=onCleanup(@()close(f));a=axes('Parent',f);x=1:5;y=[1 2 3 4;2 3 4 5;3 4 5 4;4 5 4 3;5 4 3 2];b=bar(a,x,y,.5,'grouped');names={'Series A','Series B','Series C','Series D'};for i=1:4,set(b(i),'DisplayName',names{i});end;set(a,'XTick',x,'XTickLabel',arrayfun(@num2str,x,'UniformOutput',false),'YGrid','on');legend(a,'show');compile(f,'synthetic-overview');ir=read(f);assert(numel(ir.axes{1}.series)==4&&isequal(ir.axes{1}.series{4}.values,y(:,4)'));detail='4 semantic series x 5 categories compiled';clear c;
    end
    function detail=syntheticFourPanel()
        [f,c]=fourPanel();compile(f,'synthetic-four-panel','Profile','publication','Width','double-column');ir=read(f);assert(numel(ir.axes)==4&&all(cellfun(@(a)numel(a.series)==4,ir.axes)));detail='four panels x 4 semantic series compiled';clear c;
    end
    function detail=bnc3()
        [f,a,c]=lineFigure();patch(a,[1 2 2 1],[1 1 2 2],[.5 .5 .5]);expect(@()read(f),'M2T2:E001:UnsupportedObject','patch');detail='rectangle patch remains unsupported';clear c;
    end
    function detail=bnc7()
        [f,~,c,b]=barFigure(2);set(b(1),'FaceColor','flat');expect(@()read(f),'M2T2:E021:UnsupportedBarColorMode','FaceColor');detail='per-category flat color not flattened';clear c;
    end
    function detail=bnc8()
        f=figure('Visible','off');c=onCleanup(@()close(f));bar(axes('Parent',f),[1 2;3 4],'stacked');r=m2t.export(f,fullfile(outputDirectory,'BNC8'),'Overwrite',true);assert(~r.success&&strcmp(r.status,'unsupported')&&contains(r.diagnostics(1).code,'E018'));assert(exist(r.texPath,'file')~=2);detail='unsupported mode neither legacy- nor screenshot-falls back';clear c;
    end
    function detail=bnc10()
        [f,a,c]=lineFigure();text(a,2,4,'annotation');ir=read(f);assert(strcmp(ir.axes{1}.series{1}.kind,'m2t2.line')&&strcmp(ir.annotations{1}.kind,'m2t2.textannotation'));detail='line and annotation semantics unchanged';clear c;
    end
    function r=compile(f,name,varargin)
        dir=fullfile(outputDirectory,name);ensureDirectory(dir);r=m2t.export(f,fullfile(dir,'figure'),'Overwrite',true,varargin{:});if ~r.success,error('M2T:M52ExportFailed','%s',diagnostic(r));end;info=dirInfo(r.pdfPath);assert(exist(r.pdfPath,'file')==2&&info.bytes>0);
    end
end

function [f,a,c,b]=barFigure(count,categories,width)
    if nargin<2||isempty(categories),categories=1:4;end;if nargin<3,width=.8;end
    f=figure('Visible','off');c=onCleanup(@()close(f));a=axes('Parent',f);values=reshape(1:(numel(categories)*count),numel(categories),count);b=bar(a,categories,values,width,'grouped');
end
function [f,c]=fourPanel()
    f=figure('Visible','off');c=onCleanup(@()close(f));x=0:5;
    for k=1:4,a=subplot(4,1,k,'Parent',f);y=reshape(1:24,6,4)+k;bars=bar(a,x,y,.5,'grouped');set(a,'XTick',x,'YGrid','on');if k==1,for s=1:4,set(bars(s),'DisplayName',sprintf('series-%d',s));end;legend(a,'show');end,end
end
function [f,a,c]=lineFigure(),f=figure('Visible','off');c=onCleanup(@()close(f));a=axes('Parent',f);plot(a,1:3,[1 4 9]);end
function ir=read(f),ir=m2t2.reader.readFigure(f);end
function assertBar(s,index,count),assert(strcmp(s.kind,'m2t2.bar')&&strcmp(s.mode,'grouped')&&strcmp(s.orientation,'vertical')&&s.groupIndex==index&&s.groupCount==count&&strcmp(s.owner.kind,'axes'));end
function expect(action,id,fragment),try,action();catch err,assert(strcmp(err.identifier,id));assert(isempty(fragment)||contains(err.message,fragment));return;end;error('M2T2:ExpectedFailureMissing','Expected %s.',id);end
function value=diagnostic(r),if isempty(r.diagnostics),value=r.status;else,value=r.diagnostics(1).message;end,end
function info=dirInfo(path),info=dir(path);end
function ensureDirectory(path),if exist(path,'dir')~=7,mkdir(path);end,end
function writeRows(path,rows),fid=fopen(path,'w');c=onCleanup(@()fclose(fid));fprintf(fid,'case\tstatus\tdetail\tlayer\n');for k=1:size(rows,1),fprintf(fid,'%s\t%s\t%s\t%s\n',rows{k,:});end;clear c;end
function value=oneLine(value),value=strrep(strrep(value,sprintf('\r'),' '),sprintf('\n'),' ');end
