function summary=runM53BoxplotTests(outputDirectory)
%RUNM53BOXPLOTTESTS Validate boxplots with synthetic MATLAB figures.
    root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
    if nargin<1,outputDirectory=fullfile(root,'.audit','m53-boxplots');end;ensure(outputDirectory);
    cases={'X01_single_box',@x01;'X02_multiple_groups',@x02;'X03_positions',@x03; ...
        'X04_statistics',@x04;'X05_whiskers',@x05;'X06_outliers',@x06; ...
        'X07_filled_style',@x07;'X08_median_style',@x08;'X09_whisker_style',@x09; ...
        'X10_outlier_style',@x10;'X11_legend',@x11;'X12_mean_line',@x12; ...
        'X13_multiple_axes',@x13;'X14_four_axes',@x14;'X15_profile_single',@x15; ...
        'X16_profile_double',@x16;'X17_json',@x17;'X18_deterministic',@x18; ...
        'X19_lifecycle',@x19;'X20_horizontal',@x20;'X21_notch_variant',@x21; ...
        'X22_arbitrary_compound',@x22;'X23_grouped_bar',@x23;'X24_figure_set',@x24; ...
        'X25_synthetic_four_panel',@syntheticFourPanel;'XNC4_rectangle',@xnc4; ...
        'XNC7_outline_style',@xnc7;'XNC8_outliers_not_dropped',@xnc8; ...
        'XNC10_no_fallback',@xnc10};
    rows=cell(size(cases,1),4);failures=0;
    for caseIndex=1:size(cases,1),try,detail=cases{caseIndex,2}();status='PASS';catch err,status='FAIL';failures=failures+1;detail=[err.identifier ': ' one(err.message)];end;rows(caseIndex,:)={cases{caseIndex,1},status,detail,'M5.3'};end
    path=fullfile(outputDirectory,'m53-results.tsv');writeRows(path,rows);summary=struct('tests',size(rows,1),'failures',failures,'resultPath',path);
    if failures,fprintf(2,'M5.3 diagnostics from %s:\n%s',path,fileread(path));error('M2T:M53Failed','%d M5.3 tests failed.',failures);end
    function d=x01(),[f,~,c]=boxFigure(1);s=read(f).axes{1}.series{1};assertBox(s,1);r=compile(f,'X01');d=sprintf('single resolved box compiled in %.3fs',r.timings.total);clear c;end
    function d=x02(),[f,~,c]=boxFigure(4);s=read(f).axes{1}.series{1};assertBox(s,4);r=compile(f,'X02');d=sprintf('four groups compiled in %.3fs',r.timings.total);clear c;end
    function d=x03(),[f,~,c]=boxFigure(3,[2 4 7]);s=read(f).axes{1}.series{1};assert(isequal(s.positions,[2 4 7]));d='explicit positions preserved';clear c;end
    function d=x04(),[f,~,c]=boxFigure(2);s=read(f).axes{1}.series{1};assert(all(s.q1<s.median&s.median<s.q3));d='resolved quartiles and medians preserved';clear c;end
    function d=x05(),[f,~,c]=boxFigure(2);s=read(f).axes{1}.series{1};assert(all(s.lowerWhisker<s.q1&s.q3<s.upperWhisker));d='resolved whisker endpoints preserved';clear c;end
    function d=x06(),[f,~,c]=boxFigure(3);s=read(f).axes{1}.series{1};assert(numel(s.outlierValues)==3);compile(f,'X06');d='one visible outlier per group preserved';clear c;end
    function d=x07(),[f,~,c]=boxFigure(2,[],[.2 .4 .8]);s=read(f).axes{1}.series{1};assert(max(abs(s.boxColor-[.2 .4 .8]))<1e-12&&s.boxLineWidth==4);compile(f,'X07');d='filled body color/stroke preserved';clear c;end
    function d=x08(),[f,a,c]=boxFigure(2);set(findobj(a,'Tag','Median'),'Color',[0 0 0],'LineWidth',1.25,'LineStyle','--');s=read(f).axes{1}.series{1};assert(s.medianLineWidth==1.25&&strcmp(s.medianLineStyle,'dashed'));compile(f,'X08');d='median style preserved';clear c;end
    function d=x09(),[f,a,c]=boxFigure(2);set(findobj(a,'Tag','Whisker'),'Color',[.3 .3 .3],'LineWidth',1,'LineStyle',':');s=read(f).axes{1}.series{1};assert(strcmp(s.whiskerLineStyle,'dotted'));d='whisker style preserved';clear c;end
    function d=x10(),[f,a,c]=boxFigure(2);set(findobj(a,'Tag','Outliers'),'MarkerSize',4,'Color',[0 0 0]);s=read(f).axes{1}.series{1};assert(s.outlierMarkerSize==4&&strcmp(s.outlierMarker,'x'));d='outlier marker style preserved';clear c;end
    function d=x11(),[f,a,c]=boxFigure(2);boxes=flipud(findobj(a,'Tag','Box'));legend(a,boxes(1),{'Distribution'});ir=read(f);assert(ir.axes{1}.legend.visible&&numel(ir.axes{1}.legend.entries)==1);compile(f,'X11');d='one explicit compound legend entry preserved';clear c;end
    function d=x12(),[f,a,c]=boxFigure(3);hold(a,'on');plot(a,[1 2 3],[12 22 32],'-.d','DisplayName','Mean');ir=read(f);kinds=cellfun(@(s)s.kind,ir.axes{1}.series,'UniformOutput',false);assert(any(strcmp(kinds,'m2t2.boxplot'))&&any(strcmp(kinds,'m2t2.line')));compile(f,'X12');d='mean overlay remains independent LineIR';clear c;end
    function d=x13(),f=figure('Visible','off');c=onCleanup(@()close(f));for p=1:2,a=subplot(2,1,p,'Parent',f);makeBox(a,3);end;ir=read(f);assert(numel(ir.axes)==2&&all(cellfun(@(a)strcmp(a.series{1}.kind,'m2t2.boxplot'),ir.axes)));d='two axes retain box ownership';clear c;end
    function d=x14(),[f,c]=fourPanel(6);ir=read(f);assert(numel(ir.axes)==4&&all(cellfun(@(a)strcmp(a.series{1}.kind,'m2t2.boxplot'),ir.axes)));compile(f,'X14');d='four-axis layout compiled';clear c;end
    function d=x15(),[f,~,c]=boxFigure(4);r=compile(f,'X15','Profile','publication','Width','single-column');assert(strcmp(r.profile.width,'single-column'));d='85 mm profile compiled';clear c;end
    function d=x16(),[f,c]=fourPanel(6);r=compile(f,'X16','Profile','publication','Width','double-column');assert(strcmp(r.profile.width,'double-column'));d='170 mm profile compiled';clear c;end
    function d=x17(),[f,~,c]=boxFigure(3);ir=read(f);replay=m2t2.ir.fromJson(jsonencode(ir));assert(strcmp(m2t2.render.renderPgfplots(ir,true),m2t2.render.renderPgfplots(replay,true)));d='JSON replay identical';clear c;end
    function d=x18(),[f,~,c]=boxFigure(3);a=read(f);b=read(f);assert(strcmp(jsonencode(a),jsonencode(b))&&strcmp(m2t2.render.renderPgfplots(a,true),m2t2.render.renderPgfplots(b,true)));d='IR and TeX deterministic';clear c;end
    function d=x19(),[f,a,c]=boxFigure(3);h=allchild(a);before={f.Visible,a.Position,a.XLim,a.YLim,get(h,'Visible'),getappdata(h,'gpos'),getappdata(h,'boxvalplot')};read(f);after={f.Visible,a.Position,a.XLim,a.YLim,get(h,'Visible'),getappdata(h,'gpos'),getappdata(h,'boxvalplot')};assert(isgraphics(f)&&isequaln(before,after));d='caller figure and compound unchanged';clear c;end
    function d=x20(),f=figure('Visible','off');c=onCleanup(@()close(f));boxplot(axes('Parent',f),data(2),'Orientation','horizontal');expect(@()read(f),'M2T2:E024:UnsupportedBoxplotOrientation');d='horizontal precisely rejected';clear c;end
    function d=x21(),f=figure('Visible','off');c=onCleanup(@()close(f));boxplot(axes('Parent',f),data(2),'Notch','on');expect(@()read(f),'M2T2:E029:UnsupportedBoxplotNotch');d='notch precisely rejected';clear c;end
    function d=x22(),f=figure('Visible','off');c=onCleanup(@()close(f));a=axes('Parent',f);g=hggroup('Parent',a);set(g,'Tag','boxplot');line('Parent',g,'XData',[1 1],'YData',[1 2],'Tag','Box');expect(@()read(f),'M2T2:E001:UnsupportedObject');d='lookalike compound rejected';clear c;end
    function d=x23(),f=figure('Visible','off');c=onCleanup(@()close(f));bar(axes('Parent',f),[1 2;3 4],'grouped');assert(strcmp(read(f).axes{1}.series{1}.kind,'m2t2.bar'));d='grouped bar remains bar';clear c;end
    function d=x24(),[b,~,cb]=boxFigure(2);l=figure('Visible','off');cl=onCleanup(@()close(l));al=axes('Parent',l);plot(al,1:3,[1 3 2]);text(al,2,2,'note');br=figure('Visible','off');cbr=onCleanup(@()close(br));bar(axes('Parent',br),[1 2;3 4]);entries=struct('figure',{b,l,br},'name',{'box','annotation','bar'});dir=fullfile(outputDirectory,'X24-set');r=m2t.exportSet(entries,dir,'Overwrite',true);first=fileread(r.manifestPath);r=m2t.exportSet(entries,dir,'Overwrite',true);assert(r.success&&strcmp(first,fileread(r.manifestPath)));d='mixed set and manifest deterministic';clear cb cl cbr;end
    function d=syntheticFourPanel(),[f,c]=fourPanel(8);compile(f,'synthetic-four-panel','Profile','publication','Width','double-column');ir=read(f);assert(numel(ir.axes)==4&&all(cellfun(@(a)numel(a.series{1}.positions)==8,ir.axes)));d='four axes x 8 semantic boxes compiled';clear c;end
    function d=xnc4(),f=figure('Visible','off');c=onCleanup(@()close(f));patch(axes('Parent',f),[0 1 1 0],[0 0 1 1],[1 0 0]);expect(@()read(f),'M2T2:E001:UnsupportedObject');d='rectangle remains unsupported';clear c;end
    function d=xnc7(),f=figure('Visible','off');c=onCleanup(@()close(f));boxplot(axes('Parent',f),data(2),'BoxStyle','outline');expect(@()read(f),'M2T2:E025:UnsupportedBoxplotVariant');d='outline variant not silently flattened';clear c;end
    function d=xnc8(),[f,~,c]=boxFigure(2);s=read(f).axes{1}.series{1};assert(numel(s.outlierValues)==2&&all(s.outlierValues>50));d='resolved outliers mandatory in IR';clear c;end
    function d=xnc10(),f=figure('Visible','off');c=onCleanup(@()close(f));boxplot(axes('Parent',f),data(2),'Notch','on');r=m2t.export(f,fullfile(outputDirectory,'XNC10'),'Overwrite',true);assert(~r.success&&strcmp(r.status,'unsupported')&&exist(r.texPath,'file')~=2);d='unsupported variant has no fallback';clear c;end
    function r=compile(f,name,varargin),dir=fullfile(outputDirectory,name);ensure(dir);r=m2t.export(f,fullfile(dir,'figure'),'Overwrite',true,varargin{:});assert(r.success&&exist(r.pdfPath,'file')==2);end
end
function [f,a,c]=boxFigure(groups,positions,color),if nargin<2,positions=[];end;if nargin<3,color=[.2 .4 .8];end;f=figure('Visible','off');c=onCleanup(@()close(f));a=axes('Parent',f);makeBox(a,groups,positions,color);end
function makeBox(a,groups,positions,color),if nargin<3||isempty(positions),positions=1:groups;end;if nargin<4,color=[.2 .4 .8];end;boxplot(a,data(groups),'Positions',positions,'Color',color,'PlotStyle','traditional','BoxStyle','filled','MedianStyle','line','Symbol','xk','OutlierSize',2);end
function values=data(groups),values=zeros(21,groups);for k=1:groups,values(:,k)=[(1:20)'+10*(k-1);70+10*k];end,end
function [f,c]=fourPanel(groups),f=figure('Visible','off');c=onCleanup(@()close(f));colors={[1 0 0],[0 0 1],[.5 .1 .6],[.9 .6 .1]};for p=1:4,a=subplot(4,1,p,'Parent',f);makeBox(a,groups,0:groups-1,colors{p});set(findobj(a,'Tag','Median'),'Color',[0 0 0]);hold(a,'on');plot(a,0:groups-1,12+(0:groups-1)*10,'-.d','Color',colors{p});set(a,'YGrid','on');end,end
function ir=read(f),ir=m2t2.reader.readFigure(f);end
function assertBox(s,count),assert(strcmp(s.kind,'m2t2.boxplot')&&numel(s.positions)==count&&numel(s.q1)==count&&numel(s.median)==count&&numel(s.q3)==count);end
function expect(fn,id),try,fn();error('M2T:ExpectedFailure','accepted unsupported fixture');catch err,assert(strcmp(err.identifier,id));end,end
function ensure(path),if exist(path,'dir')~=7,mkdir(path);end,end
function value=one(value),value=regexprep(value,'[\r\n]+',' ');end
function writeRows(path,rows),f=fopen(path,'w');c=onCleanup(@()fclose(f));fprintf(f,'case\tstatus\tdetail\tlayer\n');for k=1:size(rows,1),fprintf(f,'%s\t%s\t%s\t%s\n',rows{k,:});end;clear c;end
