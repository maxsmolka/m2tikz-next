function summary=runM65Scientific3DMatlabTests(outputDirectory)
%RUNM65SCIENTIFIC3DMATLABTESTS Native object/camera/occlusion acceptance gate.
    assert(~exist('OCTAVE_VERSION','builtin'),'Native MATLAB required.');
    root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
    if nargin<1,outputDirectory=fullfile(root,'.audit','m65-matlab');end
    if exist(outputDirectory,'dir')~=7,mkdir(outputDirectory);end
    cases={'constant',@()scatterCase('constant');'rgb_size',@()scatterCase('rgb'); ...
        'scalar_colorbar',@()scatterCase('scalar');'depth',@()depthCase('depth'); ...
        'childorder',@()depthCase('childorder');'mesh',@meshCase;'combination',@combination; ...
        'surface_combination',@surfaceCombination;'single_legend',@singleLegend; ...
        'multi_legend_rejected',@()negative('legend'); ...
        'view_positive',@()viewCase(30,25);'view_negative',@()viewCase(-60,35); ...
        'view_below',@()viewCase(120,-20);'aspect_reverse',@aspectCase; ...
        'lifecycle',@lifecycle;'perspective_rejected',@()negative('perspective'); ...
        'manual_target_rejected',@()negative('target');'roll_rejected',@()negative('roll'); ...
        'zoom_rejected',@()negative('zoom');'mixed_depth_rejected',@()negative('scene'); ...
        'mesh_default_rejected',@()negative('mesh');'mesh_mapped_rejected',@()negative('edge'); ...
        'alpha_rejected',@()negative('alpha');'lighting_rejected',@()negative('light'); ...
        'top_view_rejected',@()negative('top');'log_rejected',@()negative('log')};
    rows=cell(size(cases,1),3);failures=0;
    for caseIndex=1:size(cases,1)
        try,cases{caseIndex,2}();status='PASS';detail='assertions passed';
        catch err,status='FAIL';failures=failures+1;detail=regexprep([err.identifier ' ' err.message],'[\r\n\t]+',' ');end
        rows(caseIndex,:)={cases{caseIndex,1},status,detail};
    end
    report=sprintf('case\tstatus\tdetail\n');for reportIndex=1:size(rows,1),report=[report sprintf('%s\t%s\t%s\n',rows{reportIndex,:})];end %#ok<AGROW>
    m2t.internal.writeTextFile(fullfile(outputDirectory,'m65-matlab-results.tsv'),report);fprintf('%s',report);
    summary=struct('tests',size(rows,1),'failures',failures);assert(failures==0,'M6.5 native acceptance failed.');
    fprintf('M65_NATIVE_PASS: %d/%d\n',summary.tests,summary.tests);
    function scatterCase(mode)
        [f,a,h,c]=base();
        if strcmp(mode,'rgb'),h.CData=[1 0 0;0 1 0;0 0 1];h.SizeData=[64 256 576];
        elseif strcmp(mode,'scalar'),h.CData=[0;.5;1];clim(a,[0 1]);colorbar(a);end
        ir=m2t2.reader.readFigure(f);s=ir.axes{1}.series{1};assert(strcmp(s.kind,'m2t2.scatter3')&&isequal(s.z,reshape(h.ZData,1,[])));
        if strcmp(mode,'rgb'),assert(isequal(s.markerSize,[8 16 24])&&isequal(s.colorData,h.CData));end
        if strcmp(mode,'scalar'),assert(strcmp(s.colorMode,'scalar_mapped')&&numel(ir.elements)==1);end
        save(f,ir,mode);clear c;
    end
    function depthCase(order)
        [f,a,h,c]=base();v=[sind(30)*cosd(25),-cosd(30)*cosd(25),sind(25)];
        h.XData=[v(1) -v(1)];h.YData=[v(2) -v(2)];h.ZData=[v(3) -v(3)];h.SizeData=1600;h.CData=[1 0 0;0 0 1];a.SortMethod=order;
        ir=m2t2.reader.readFigure(f);assert(strcmp(ir.axes{1}.sceneOrder,order));save(f,ir,order);clear c;
    end
    function meshCase()
        [f,a,~,c]=base();cla(a);[x,y]=meshgrid(linspace(-1,1,6));h=mesh(a,x,y,x.*y,'FaceColor','none','EdgeColor',[.1 .4 .7]);setup(a);ir=m2t2.reader.readFigure(f);
        s=ir.axes{1}.series{1};assert(strcmp(s.faceMode,'none')&&isequal(s.edgeColor,h.EdgeColor)&&isequal(s.z,h.ZData));save(f,ir,'mesh');clear c;
    end
    function combination()
        [f,a,h,c]=base();hold(a,'on');[x,y]=meshgrid(linspace(-1,1,6));
        mesh(a,x,y,x.*y,'FaceColor','none','EdgeColor',[.1 .4 .7]);plot3(a,[-1 1],[0 0],[.7 .7],'r','LineWidth',2);
        a.SortMethod='childorder';ir=m2t2.reader.readFigure(f);assert(numel(ir.axes{1}.series)==3);save(f,ir,'combination');clear c;
    end
    function viewCase(az,el)
        [f,a,~,c]=base();view(a,az,el);ir=m2t2.reader.readFigure(f);assert(isequal(ir.axes{1}.view,[az el]));save(f,ir,sprintf('view-%d-%d',az,el));clear c;
    end
    function surfaceCombination()
        [f,a,~,c]=base();cla(a);[x,y]=meshgrid(linspace(-1,1,6));
        surf(a,x,y,.2*x.*y,'FaceColor','interp','EdgeColor','none');hold(a,'on');
        scatter3(a,[-.5 .5],[0 0],[.6 .6],[64 144],[1 0 0;0 0 1],'filled');
        plot3(a,[-1 1],[0 0],[.7 .7],'k','LineWidth',2);setup(a);a.SortMethod='childorder';
        ir=m2t2.reader.readFigure(f);assert(numel(ir.axes{1}.series)==3);save(f,ir,'surface-combination');clear c;
    end
    function singleLegend()
        [f,a,h,c]=base();h.DisplayName='Samples';legend(a,'show','Location','northeast');ir=m2t2.reader.readFigure(f);
        assert(ir.axes{1}.legend.visible&&strcmp(ir.axes{1}.legend.entries{1}.seriesId,ir.axes{1}.series{1}.id));
        save(f,ir,'single-legend');clear c;
    end
    function aspectCase()
        [f,a,~,c]=base();daspect(a,[2 3 1]);a.XDir='reverse';ir=m2t2.reader.readFigure(f);assert(isequal(ir.axes{1}.dataAspectRatio,[2 3 1])&&strcmp(ir.axes{1}.xdirection,'reverse'));save(f,ir,'aspect-reverse');clear c;
    end
    function lifecycle()
        [f,a,h,c]=base();drawnow;before=state(a,h);ir=m2t2.reader.readFigure(f);assert(isequaln(before,state(a,h)));again=m2t2.reader.readFigure(f);assert(strcmp(jsonencode(ir),jsonencode(again)));clear c;
    end
    function negative(which)
        [f,a,h,c]=base();code='M2T2:E062:Unsupported3DCamera';
        switch which
            case 'perspective',a.Projection='perspective';code='M2T2:E032:Unsupported3DProjection';
            case 'target',a.CameraTarget=[.1 0 0];
            case 'roll',camroll(a,15);
            case 'zoom',camzoom(a,2);
            case 'scene',hold(a,'on');plot3(a,[-1 1],[0 0],[0 0]);code='M2T2:E063:Unsupported3DScene';
            case 'mesh',cla(a);[x,y]=meshgrid(-1:1);mesh(a,x,y,x.*y);code='M2T2:E034:UnsupportedSurfaceColorMode';
            case 'edge',cla(a);[x,y]=meshgrid(-1:1);mesh(a,x,y,x.*y,'FaceColor','none');code='M2T2:E033:UnsupportedSurfaceEdgeMode';
            case 'alpha',h.MarkerFaceAlpha=.5;code='M2T2:E043:UnsupportedScatterTransparency';
            case 'light',light(a);code='M2T2:E036:UnsupportedLighting';
            case 'top',view(a,2);code='M2T2:E045:UnsupportedScatterDimensionality';
            case 'log',a.XLim=[.1 1];a.XScale='log';
            case 'legend',hold(a,'on');plot3(a,[-1 1],[0 0],[0 0]);a.SortMethod='childorder';legend(a,{'Scatter','Line'});code='M2T2:E063:Unsupported3DScene';
        end
        expect(@()m2t2.reader.readFigure(f),code);
        result=m2t.export(f,fullfile(outputDirectory,['rejected-' which]),'Overwrite',true);
        assert(~result.success&&exist(fullfile(outputDirectory,['rejected-' which '.tex']),'file')~=2);
        clear c;
    end
    function save(f,ir,name)
        m2t.internal.writeTextFile(fullfile(outputDirectory,[name '.tex']),m2t2.render.renderPgfplots(ir,true));
        m2t.internal.writeTextFile(fullfile(outputDirectory,[name '.json']),jsonencode(ir));
        exportgraphics(f,fullfile(outputDirectory,[name '-source.png']),'Resolution',120);
    end
end
function [f,a,h,c]=base()
    f=figure('Visible','off','Color','w','Position',[100 100 640 500]);c=onCleanup(@()close(f));a=axes(f);
    h=scatter3(a,[-.8 0 .8],[.4 -.4 .6],[-.5 .5 0],144,[.2 .4 .8],'filled');setup(a);
end
function setup(a)
    set(a,'XLim',[-1 1],'YLim',[-1 1],'ZLim',[-1 1],'Color','w','XColor','k','YColor','k','ZColor','k');
    daspect(a,[1 1 1]);view(a,30,25);xlabel(a,'X');ylabel(a,'Y');zlabel(a,'Z');drawnow;
end
function s=state(a,h)
    names={'View','CameraPosition','CameraPositionMode','CameraTarget','CameraTargetMode','CameraUpVector', ...
        'CameraUpVectorMode','CameraViewAngle','CameraViewAngleMode','DataAspectRatio','SortMethod','Children'};
    s=get(a,names);s=[s,get(h,{'XData','YData','ZData','CData','SizeData'})];
end
function expect(fn,code)
    try,fn();error('M2T:ExpectedFailure','unsupported input accepted');catch err,assert(strcmp(err.identifier,code),[err.identifier ': ' err.message]);end
end
