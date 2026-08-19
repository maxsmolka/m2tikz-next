function summary = runPublicationProfileTests(outputDirectory)
%RUNPUBLICATIONPROFILETESTS Validate the calibrated publication profile.
    root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
    if nargin<1,outputDirectory=fullfile(root,'.audit','publication-profile');end
    resetDirectory(outputDirectory);
    cases={ ...
        'C01_normative_values',@normativeValues; ...
        'C02_profile_only',@profileOnly; ...
        'C03_single_width',@()physicalWidth('single-column',85); ...
        'C04_double_width',@()physicalWidth('double-column',170); ...
        'C05_aspect_lower',@()aspectClamp([100 20],.45); ...
        'C06_aspect_upper',@()aspectClamp([100 200],1.25); ...
        'C07_core_typography',@coreTypography; ...
        'C08_annotation_policy',@annotationPolicy; ...
        'C09_line_marker_policy',@lineMarkerPolicy; ...
        'C10_simple_line_85',@simpleLine; ...
        'C11_heatmap_colorbar_170',@heatmap; ...
        'C12_legend_85',@legendCase; ...
        'C13_dense_annotations_170',@denseAnnotations; ...
        'C14_manual_inset_170',@manualInset; ...
        'C15_grouped_bars_170',@groupedBars; ...
        'C16_boxplot_170',@boxplotCase; ...
        'C17_surface_170',@surfaceCase; ...
        'C18_json_determinism',@jsonDeterminism; ...
        'C19_manifest_determinism',@manifestDeterminism; ...
        'C20_lifecycle',@lifecycle};
    rows=cell(size(cases,1),4);failures=0;
    for k=1:size(cases,1)
        try,detail=cases{k,2}();status='PASS';
        catch err,status='FAIL';failures=failures+1;detail=[identifier(err) ': ' oneLine(err.message)];end
        rows(k,:)={cases{k,1},status,detail,'publication-profile'};
    end
    resultPath=fullfile(outputDirectory,'publication-profile-results.tsv');writeRows(resultPath,rows);
    summary=struct('tests',size(rows,1),'failures',failures,'resultPath',resultPath);
    if failures,fprintf(2,'%s',fileread(resultPath));error('M2T:PublicationProfileTestsFailed','%d publication profile tests failed.',failures);end

    function d=normativeValues()
        p=m2t.profile.publication();assert(isequal(p.figure.widthMillimeters,[85 170]));
        assert(p.text.basePt==9&&p.text.axesLabelPt==9&&p.text.titlePt==10&&p.text.tickLabelPt==8);
        assert(p.legend.textPt==8&&p.colorbar.labelPt==9&&p.colorbar.tickLabelPt==8);
        assert(p.figure.minimumAspectRatio==.45&&p.figure.maximumAspectRatio==1.25);
        assert(strcmp(p.line.widthPolicy,'preserve')&&strcmp(p.line.markerSizePolicy,'preserve'));
        d='85/170 mm; typography 9/9/10/8/8/9/8 pt; preserve styles; clamp .45-1.25';
    end
    function d=profileOnly()
        ir=lineIr();none=m2t.profile.apply(ir,m2t.profile.getProfile('none'),[]);
        calibrated=m2t.profile.apply(ir,m2t.profile.publication(),'single-column');
        assert(none.success&&calibrated.success);assert(isequaln(none.ir,ir));assertSemanticEqual(ir,calibrated.ir);
        d='default is inert; publication transform changes physical size only';
    end
    function d=physicalWidth(width,mm)
        f=figure('Visible','off');c=onCleanup(@()closeFigure(f));plot(axes('Parent',f),1:4);
        r=m2t.export(f,fullfile(outputDirectory,['width-' width]),'Profile','publication','Width',width,'Overwrite',true);
        assert(r.success);points=pdfSize(r.pdfPath);expected=mm*72/25.4;assert(abs(points(1)-expected)<=.05);
        d=sprintf('%.3f pt = %.3f mm',points(1),points(1)*25.4/72);clear c;
    end
    function d=aspectClamp(sizeValue,expected)
        ir=lineIr();ir.size=sizeValue;t=m2t.profile.apply(ir,m2t.profile.publication(),'single-column');
        assert(t.success&&abs(t.ir.size(2)/t.ir.size(1)-expected)<1e-12);
        assert(any(strcmp({t.diagnostics.code},'M2T:PROFILE_ASPECT_CLAMPED')));d=sprintf('aspect clamped to %.2f',expected);
    end
    function d=coreTypography()
        f=figure('Visible','off');c=onCleanup(@()closeFigure(f));a=axes('Parent',f);plot(a,1:3,'DisplayName','Series');xlabel(a,'x');ylabel(a,'y');title(a,'Title');legend(a,'show');
        ir=m2t2.reader.readFigure(f);t=m2t.profile.apply(ir,m2t.profile.publication(),'single-column');tex=m2t2.render.renderPgfplots(t.ir,true,t.renderConfig);
        assert(has(tex,'\fontsize{9pt}{10.8pt}')&&has(tex,'\fontsize{10pt}{12pt}')&&has(tex,'\fontsize{8pt}{9.6pt}'));
        d='core title/labels/base/ticks/legend use normalized role sizes';clear c;
    end
    function d=annotationPolicy()
        ir=lineIr();x=m2t2.ir.makeTextAnnotation();x.owner.id=ir.axes{1}.id;x.fontSize=13;x.text=m2t2.ir.makeText('intentional','plain');
        arrow=m2t2.ir.makeArrowAnnotation('doublearrow');arrow.width=1.25;arrow.startHead=m2t2.ir.makeArrowHead('vback2',7,5);arrow.endHead=m2t2.ir.makeArrowHead('vback2',8,6);ir.annotations={x,arrow};
        t=m2t.profile.apply(ir,m2t.profile.publication(),'single-column');tex=m2t2.render.renderPgfplots(t.ir,true,t.renderConfig);
        assert(has(tex,'\fontsize{13pt}{15.6pt}')&&has(tex,'line width=1.25pt')&&has(tex,'length=7pt,width=5pt'));
        d='intentional annotation text, stroke, and heads remain source-authored';
    end
    function d=lineMarkerPolicy()
        ir=lineIr();ir.axes{1}.series{1}.lineWidth=2.25;ir.axes{1}.series{1}.marker='diamond';ir.axes{1}.series{1}.markerSize=7;
        t=m2t.profile.apply(ir,m2t.profile.publication(),'single-column');s=t.ir.axes{1}.series{1};
        assert(s.lineWidth==2.25&&s.markerSize==7&&strcmp(s.marker,'diamond'));d='scientific line emphasis and marker size preserved';
    end
    function d=simpleLine()
        f=figure('Visible','off');c=onCleanup(@()closeFigure(f));a=axes('Parent',f);x=linspace(0,2*pi,200);plot(a,x,sin(x),'LineWidth',1);xlabel(a,'time');ylabel(a,'response');grid(a,'on');
        r=exportFigure(f,'simple-line-85','single-column');d=metric(r,1,1);clear c;
    end
    function d=heatmap()
        f=figure('Visible','off');c=onCleanup(@()closeFigure(f));a=axes('Parent',f);[x,y]=meshgrid(linspace(-2,2,40),linspace(-1,1,30));z=3*(1-x).^2.*exp(-(x.^2)-(y+1).^2)-10*(x/5-x.^3-y.^5).*exp(-x.^2-y.^2);imagesc(a,x(1,:),y(:,1),z);set(a,'YDir','normal');cb=colorbar(a);ylabel(cb,'intensity');
        r=exportFigure(f,'heatmap-170','double-column');d=metric(r,1,1);clear c;
    end
    function d=legendCase()
        f=figure('Visible','off');c=onCleanup(@()closeFigure(f));a=axes('Parent',f);hold(a,'on');x=1:80;for n=1:4,plot(a,x,sin(x/10+n/3),'DisplayName',sprintf('Series %d',n));end;lg=legend(a,'show');set(lg,'Location','northeast');
        r=exportFigure(f,'legend-85','single-column');d=metric(r,1,4);clear c;
    end
    function d=denseAnnotations()
        ir=lineIr();a=ir.axes{1};a.series={};a.xlim=[0 20];a.ylim=[-8 2];x=linspace(0,20,500);
        for n=1:7,s=m2t2.ir.makeLineSeries();s.id=sprintf('axes-1-series-%d',n);s.x=x;s.y=sin(x+n/5)-n;s.color=[mod(n,3)/2 mod(n+1,3)/2 mod(n+2,3)/2];a.series{end+1}=s;end
        ir.axes={a};first=m2t2.ir.makeArrowAnnotation('doublearrow');first.startHead=m2t2.ir.makeArrowHead('vback2',10,10);first.start=[.22 .45];first.end=[.22 .62];second=first;second.id='figure-annotation-2';second.start=[.32 .4];second.end=[.32 .57];ir.annotations={first,second};
        r=exportIr(ir,'dense-annotations-170','double-column');d=metric(r,1,7);
    end
    function d=manualInset()
        f=figure('Visible','off');c=onCleanup(@()closeFigure(f));main=axes('Parent',f,'Position',[.1 .1 .82 .82]);hold(main,'on');x=linspace(0,10,60);
        for n=1:8,plot(main,x,sin(x+n/10)+n/20);end;text(main,5,0,'main');
        inset=axes('Parent',f,'Position',[.52 .22 .28 .25]);hold(inset,'on');for n=1:4,plot(inset,x(20:35),sin(x(20:35)+n/10));end;text(inset,4,.5,'zoom');
        r=exportFigure(f,'manual-inset-170','double-column');ir=m2t2.reader.readFigure(f);assert(numel(ir.axes)==2&&sum(cellfun(@(a)numel(a.series),ir.axes))==12);d=metric(r,2,12);clear c;
    end
    function d=groupedBars()
        f=figure('Visible','off');c=onCleanup(@()closeFigure(f));for p=1:4,a=subplot(2,2,p,'Parent',f);bar(a,[1 2;2 3;3 2;4 3],.72,'grouped');title(a,sprintf('Panel %d',p));end
        r=exportFigure(f,'grouped-bars-170','double-column');d=metric(r,4,8);clear c;
    end
    function d=boxplotCase(),ir=boxplotIr();r=exportIr(ir,'boxplot-170','double-column');d=metric(r,4,4);end
    function d=surfaceCase()
        f=figure('Visible','off');c=onCleanup(@()closeFigure(f));a=axes('Parent',f);[x,y]=meshgrid(linspace(-1,1,31));z=sin(pi*x).*cos(pi*y);surf(a,x,y,z,z,'FaceColor','interp','EdgeColor','none');hold(a,'on');plot3(a,[-1 1],[0 0],[.8 .8],'LineWidth',1);plot3(a,[-1 1],[.5 .5],[.8 .8],'LineWidth',1);view(a,135,20);xlabel(a,'x');ylabel(a,'y');zlabel(a,'response');colorbar(a);
        r=exportFigure(f,'surface-170','double-column');d=metric(r,1,3);clear c;
    end
    function d=jsonDeterminism()
        ir=boxplotIr();replay=m2t2.ir.fromJson(jsonencode(ir));a=renderProfile(ir,'double-column');b=renderProfile(replay,'double-column');assert(strcmp(a,b));d='JSON replay produces byte-identical calibrated TeX';
    end
    function d=manifestDeterminism()
        f1=figure('Visible','off');f2=figure('Visible','off');c=onCleanup(@()closeFigures([f1 f2]));plot(axes('Parent',f1),1:4);imagesc(axes('Parent',f2),peaks(15));
        entries=struct('figure',{f1,f2},'name',{'line','image'});dirName=fullfile(outputDirectory,'set');first=m2t.exportSet(entries,dirName,'Profile','publication','Width','double-column','Overwrite',true);textA=fileread(first.manifestPath);second=m2t.exportSet(entries,dirName,'Profile','publication','Width','double-column','Overwrite',true);assert(second.success&&strcmp(textA,fileread(second.manifestPath)));d='two-entry calibrated manifest byte-identical';clear c;
    end
    function d=lifecycle()
        f=figure('Visible','off');c=onCleanup(@()closeFigure(f));a=axes('Parent',f);plot(a,1:20,sin(1:20),'-o');text(a,5,.5,'note');before=m2t2.reader.readFigure(f);r=exportFigure(f,'lifecycle','single-column');after=m2t2.reader.readFigure(f);assert(r.success&&isequaln(before,after)&&ishandle(f));d='caller figure and semantic IR unchanged';clear c;
    end
    function r=exportFigure(f,name,width)
        r=m2t.export(f,fullfile(outputDirectory,name),'Profile','publication','Width',width,'Overwrite',true);assert(r.success);assertPhysical(r.pdfPath,width);
    end
    function r=exportIr(ir,name,width)
        t=m2t.profile.apply(ir,m2t.profile.publication(),width);assert(t.success);tex=m2t2.render.renderPgfplots(t.ir,true,t.renderConfig);base=fullfile(outputDirectory,name);texPath=[base '.tex'];pdfPath=[base '.pdf'];writeText(texPath,tex);comp=m2t.internal.compileLuaLatex(texPath,pdfPath,'lualatex');assert(comp.success&&exist(pdfPath,'file')==2);assertPhysical(pdfPath,width);r=struct('texPath',texPath,'pdfPath',pdfPath,'success',true);
    end
end

function ir=lineIr(),a=m2t2.ir.makeAxes();s=m2t2.ir.makeLineSeries();s.x=0:4;s.y=[0 1 0 2 1];s.marker='circle';s.markerSize=5;a.series={s};ir=m2t2.ir.makeFigure({a});ir.size=[100 65];end
function ir=boxplotIr()
    axesNodes=cell(1,4);for p=1:4,a=m2t2.ir.makeAxes();a.id=sprintf('axes-%d',p);a.placement=m2t2.ir.makePlacement(.08+.48*mod(p-1,2),.56-.46*floor((p-1)/2),.4,.36);a.xlim=[.5 8.5];a.ylim=[0 30];s=m2t2.ir.makeBoxplotSeries();s.id=sprintf('axes-%d-series-1',p);s.owner.id=a.id;s.positions=1:8;s.lowerWhisker=4+mod(1:8,3);s.q1=s.lowerWhisker+2;s.median=s.q1+2;s.q3=s.median+2;s.upperWhisker=s.q3+2;s.outlierPositions=[3 7];s.outlierValues=[14 15]+p/4;s.boxLineWidth=.6;s.medianLineWidth=1;s.whiskerLineWidth=.6;s.outlierMarkerSize=3;a.series={s};axesNodes{p}=a;end;ir=m2t2.ir.makeFigure(axesNodes);ir.size=[100 72];
end
function ir=surfaceIr()
    a=m2t2.ir.makeAxes();a.kind='m2t2.axes3d';a.dimensionality=3;a.view=[135 20];a.zlim=[-1 1];[x,y]=meshgrid(linspace(-1,1,31));s=m2t2.ir.makeSurfaceSeries();s.x=x;s.y=y;s.z=sin(pi*x).*cos(pi*y);s.c=s.z;a.series={s};for n=1:2,l=m2t2.ir.makeLine3Series();l.id=sprintf('axes-1-series-%d',n+1);l.x=[-1 1];l.y=[0 0]+(n-1)/2;l.z=[.8 .8];a.series{end+1}=l;end;p=m2t2.ir.makePatch3Series();p.id='axes-1-series-4';p.vertices=[0 0 .8;.12 0 .8;0 .12 .8];a.series{end+1}=p;ir=m2t2.ir.makeFigure({a});ir.size=[100 80];
end
function tex=renderProfile(ir,width),t=m2t.profile.apply(ir,m2t.profile.publication(),width);assert(t.success);tex=m2t2.render.renderPgfplots(t.ir,true,t.renderConfig);end
function assertSemanticEqual(a,b),sizeValue=a.size;b.size=sizeValue;assert(isequaln(a,b));end
function assertPhysical(path,width),points=pdfSize(path);expected=85;if strcmp(width,'double-column'),expected=170;end;assert(abs(points(1)-expected*72/25.4)<=.05);end
function d=metric(r,axesCount,seriesCount),d=sprintf('%d axes, %d semantic series, TeX %d bytes, PDF %d bytes',axesCount,seriesCount,fileBytes(r.texPath),fileBytes(r.pdfPath));end
function value=pdfSize(path)
    if ispc,selector='findstr /B /C:"Page size"';else,selector='grep "^Page size"';end
    [status,out]=system(['pdfinfo -enc UTF-8 ' quote(path) ' 2>&1 | ' selector]);assert(status==0);
    token=regexp(out,'Page size:\s*([0-9.]+)\s+x\s+([0-9.]+)\s+pts','tokens','once');assert(~isempty(token));value=[str2double(token{1}) str2double(token{2})];
end
function value=fileBytes(path),f=fopen(path,'rb');assert(f>=0);c=onCleanup(@()fclose(f));assert(fseek(f,0,'eof')==0);value=ftell(f);clear c;end
function writeText(path,value),f=fopen(path,'wb');assert(f>=0);c=onCleanup(@()fclose(f));fwrite(f,value,'char');clear c;end
function writeRows(path,rows),f=fopen(path,'wb');c=onCleanup(@()fclose(f));fprintf(f,'case\tstatus\tdetail\tlayer\n');for k=1:size(rows,1),fprintf(f,'%s\t%s\t%s\t%s\n',rows{k,:});end;clear c;end
function resetDirectory(path),if exist(path,'dir')==7,rmdir(path,'s');end;mkdir(path);end
function value=quote(value),if ispc,value=strrep(value,'\','/');end;value=['"' value '"'];end
function yes=has(value,fragment),yes=~isempty(strfind(value,fragment));end
function value=identifier(err),value=err.identifier;if isempty(value),value='<none>';end,end
function value=oneLine(value),value=regexprep(value,'[\r\n\t]+',' ');end
function closeFigure(f),if ~isempty(f)&&ishandle(f),close(f);end,end
function closeFigures(figures),for k=1:numel(figures),closeFigure(figures(k));end,end
