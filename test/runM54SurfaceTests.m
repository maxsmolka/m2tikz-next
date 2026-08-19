function summary = runM54SurfaceTests(outputDirectory)
%RUNM54SURFACETESTS Validate the public synthetic M5.4 3-D surface slice.
    root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
    if nargin<1,outputDirectory=fullfile(root,'.audit','m54-surface');end;ensure(outputDirectory);
    cases={'Z01_simple_surface',@z01;'Z02_explicit_matrices',@z02;'Z03_scalar_cdata',@z03; ...
        'Z04_clim_colormap',@z04;'Z05_interpolated_face',@z05;'Z06_hidden_edges',@z06; ...
        'Z07_camera_view',@z07;'Z08_labels_ticks',@z08;'Z09_colorbar',@z09; ...
        'Z10_plot3',@z10;'Z11_surface_plot3',@z11; ...
        'Z13_colorbar_ownership',@z13;'Z14_profile_85mm',@z14;'Z15_profile_170mm',@z15; ...
        'Z16_json_replay',@z16;'Z17_deterministic',@z17;'Z18_lifecycle',@z18; ...
        'Z19_transparency',@z19;'Z20_lighting',@z20;'Z21_mesh',@z21; ...
        'Z22_scatter3',@z22;'Z23_arbitrary_patch',@z23;'Z24_figure_set',@z24};
    rows=cell(size(cases,1),4);failures=0;
    for caseIndex=1:size(cases,1),caseName=cases{caseIndex,1};try,fn=cases{caseIndex,2};d=fn();s='PASS';catch err,s='FAIL';failures=failures+1;d=[err.identifier ': ' one(err.message)];end;rows(caseIndex,:)={caseName,s,d,'M5.4'};end
    path=fullfile(outputDirectory,'m54-results.tsv');writeRows(path,rows);
    summary=struct('tests',size(rows,1),'failures',failures,'resultPath',path);
    if failures,fprintf(2,'M5.4 diagnostics from %s:\n%s',path,fileread(path));error('M2T:M54Failed','%d M5.4 tests failed.',failures);end
    function d=z01(),[f,~,c]=surfaceFigure(9);ir=read(f);assert(strcmp(ir.axes{1}.series{1}.kind,'m2t2.surface'));d='scalar SurfaceIR recognized';clear c;end
    function d=z02(),[f,~,c,x,y,z]=surfaceFigure(7);s=read(f).axes{1}.series{1};assert(isequal(s.x,x)&&isequal(s.y,y)&&isequal(s.z,z));d='explicit matrix geometry and orientation preserved';clear c;end
    function d=z03(),[f,~,c,~,~,z]=surfaceFigure(7);s=read(f).axes{1}.series{1};assert(isequal(s.c,z));d='scalar CData matrix preserved';clear c;end
    function d=z04(),[f,a,c]=surfaceFigure(7);caxis(a,[-2 3]);colormap(a,parula(17));ir=read(f);assert(isequal(ir.axes{1}.colorMapping.limits,[-2 3])&&size(ir.axes{1}.colorMapping.colormap,1)==17);d='CLim and colormap preserve axes ownership';clear c;end
    function d=z05(),[f,~,c]=surfaceFigure(7);assert(strcmp(read(f).axes{1}.series{1}.faceMode,'interpolated'));d='FaceColor interp is explicit';clear c;end
    function d=z06(),[f,~,c]=surfaceFigure(7);assert(strcmp(read(f).axes{1}.series{1}.edgeMode,'none'));d='hidden edges do not broaden mesh support';clear c;end
    function d=z07(),[f,a,c]=surfaceFigure(7);view(a,135,20);ir=read(f);assert(max(abs(ir.axes{1}.view-[135 20]))<1e-12&&strcmp(ir.axes{1}.projection,'orthographic'));d='azimuth elevation and projection preserved';clear c;end
    function d=z08(),[f,a,c]=surfaceFigure(7);xlabel(a,'x');ylabel(a,'y');zlabel(a,'z');title(a,'field');set(a,'ZTick',[-1 0 1],'ZTickLabel',{'-1','0','1'});ir=read(f);assert(strcmp(ir.axes{1}.zlabel.value,'z')&&strcmp(ir.axes{1}.title.value,'field'));d='3-D labels title and ticks preserved';clear c;end
    function d=z09(),[f,a,c]=surfaceFigure(7);cb=colorbar(a);ylabel(cb,'value');ir=read(f);assert(numel(ir.elements)==1&&strcmp(ir.elements{1}.kind,'m2t2.colorbar'));compile(f,'Z09');d='existing semantic ColorbarIR path compiled';clear c;end
    function d=z10(),f=figure('Visible','off');c=onCleanup(@()close(f));a=axes('Parent',f);plot3(a,0:2,0:2,[0 1 0]);view(a,30,20);s=read(f).axes{1}.series{1};assert(strcmp(s.kind,'m2t2.line3'));d='Plot3 normalized as Line3IR';clear c;end
    function d=z11(),[f,a,c]=surfaceFigure(7);hold(a,'on');plot3(a,[-1 1],[0 0],[1 1],'k-');kinds=cellfun(@(s)s.kind,read(f).axes{1}.series,'UniformOutput',false);assert(any(strcmp(kinds,'m2t2.surface'))&&any(strcmp(kinds,'m2t2.line3')));compile(f,'Z11');d='surface plus independent Plot3 compiled';clear c;end
    function d=z13(),[f,a,c]=surfaceFigure(7);colorbar(a);ir=read(f);assert(strcmp(ir.elements{1}.owner.kind,'axes')&&strcmp(ir.elements{1}.owner.id,ir.axes{1}.id));d='one scientific axes plus owned display colorbar';clear c;end
    function d=z14(),[f,~,c]=surfaceFigure(9);r=compile(f,'Z14','Profile','publication','Width','single-column');assert(strcmp(r.profile.width,'single-column'));d='85 mm publication profile compiled';clear c;end
    function d=z15(),[f,~,c]=surfaceFigure(19);r=compile(f,'Z15','Profile','publication','Width','double-column');assert(strcmp(r.profile.width,'double-column'));d='170 mm synthetic surface compiled';clear c;end
    function d=z16(),[f,~,c]=surfaceFigure(7);ir=read(f);replay=m2t2.ir.fromJson(jsonencode(ir));assert(strcmp(m2t2.render.renderPgfplots(ir,true),m2t2.render.renderPgfplots(replay,true)));d='JSON replay is runtime-free and identical';clear c;end
    function d=z17(),[f,~,c]=surfaceFigure(7);a=read(f);b=read(f);assert(strcmp(jsonencode(a),jsonencode(b))&&strcmp(m2t2.render.renderPgfplots(a,true),m2t2.render.renderPgfplots(b,true)));d='IR JSON and TeX repeat deterministically';clear c;end
    function d=z18(),[f,a,c,~,~,z]=surfaceFigure(7);h=findobj(a,'Type','surface');before={f.Visible,a.Position,a.XLim,a.YLim,a.ZLim,a.View,a.Projection,a.DataAspectRatio,get(h,'ZData')};read(f);after={f.Visible,a.Position,a.XLim,a.YLim,a.ZLim,a.View,a.Projection,a.DataAspectRatio,get(h,'ZData')};assert(isgraphics(f)&&isequaln(before,after)&&isequal(z,get(h,'ZData')));d='caller figure camera axes and surface unchanged';clear c;end
    function d=z19(),[f,a,c]=surfaceFigure(7);set(findobj(a,'Type','surface'),'FaceAlpha',.5);expect(@()read(f),'M2T2:E035:UnsupportedSurfaceTransparency');d='transparent surface fails precisely';clear c;end
    function d=z20(),[f,a,c]=surfaceFigure(7);light(a);expect(@()read(f),'M2T2:E036:UnsupportedLighting');d='lighting dependency fails precisely';clear c;end
    function d=z21(),f=figure('Visible','off');c=onCleanup(@()close(f));a=axes('Parent',f);mesh(a,peaks(7));view(a,30,20);expectAny(@()read(f),{'M2T2:E033:UnsupportedSurfaceColorMode','M2T2:E033:UnsupportedSurfaceEdgeMode','M2T2:E034:UnsupportedSurfaceColorMode'});d='mesh remains unsupported';clear c;end
    function d=z22(),f=figure('Visible','off');c=onCleanup(@()close(f));a=axes('Parent',f);scatter3(a,1:3,1:3,1:3);view(a,30,20);expectAny(@()read(f),{'M2T2:E001:UnsupportedObject','M2T2:E007:UnsupportedProperty'});d='scatter3 remains unsupported';clear c;end
    function d=z23(),f=figure('Visible','off');c=onCleanup(@()close(f));a=axes('Parent',f);fill3(a,[0 1 0],[0 0 1],[0 0 0],'r');view(a,30,20);expect(@()read(f),'M2T2:E037:Unsupported3DPatchVariant');d='arbitrary axes patch is not accepted as pattern Fill3';clear c;end
    function d=z24(),[s,~,cs]=surfaceFigure(7);l=figure('Visible','off');cl=onCleanup(@()close(l));plot(axes('Parent',l),1:3);entries=struct('figure',{s,l},'name',{'surface','line'});dir=fullfile(outputDirectory,'Z24-set');r=m2t.exportSet(entries,dir,'Overwrite',true);assert(r.success);d='mixed 3-D and 2-D figure set compiled';clear cs cl;end
    function r=compile(f,name,varargin),dirPath=fullfile(outputDirectory,name);ensure(dirPath);r=m2t.export(f,fullfile(dirPath,'figure'),'Overwrite',true,varargin{:});assert(r.success&&exist(r.pdfPath,'file')==2);end
end

function [f,a,c,x,y,z]=surfaceFigure(n),f=figure('Visible','off');c=onCleanup(@()close(f));a=axes('Parent',f);[x,y]=meshgrid(linspace(-1,1,n));z=sin(pi*x).*cos(pi*y);surf(a,x,y,z,z,'FaceColor','interp','EdgeColor','none');view(a,35,25);axis(a,'equal');end
function ir=read(f),ir=m2t2.reader.readFigure(f);end
function expect(fn,id),try,fn();error('M2T:ExpectedFailure','accepted unsupported fixture');catch err,assert(strcmp(err.identifier,id));end,end
function expectAny(fn,ids),try,fn();error('M2T:ExpectedFailure','accepted unsupported fixture');catch err,assert(any(strcmp(err.identifier,ids)));end,end
function ensure(path),if exist(path,'dir')~=7,mkdir(path);end,end
function value=one(value),value=regexprep(value,'[\r\n]+',' ');end
function writeRows(path,rows),f=fopen(path,'w');c=onCleanup(@()fclose(f));fprintf(f,'case\tstatus\tdetail\tlayer\n');for k=1:size(rows,1),fprintf(f,'%s\t%s\t%s\t%s\n',rows{k,:});end;clear c;end
