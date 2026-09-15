function summary=runM65Scientific3DIrTests(outputDirectory)
%RUNM65SCIENTIFIC3DIRTESTS Portable explicit depth, data, mesh and JSON checks.
    root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
    if nargin<1,outputDirectory=fullfile(root,'.audit','m65-ir');end
    if exist(outputDirectory,'dir')~=7,mkdir(outputDirectory);end
    cases={'constant',@constant;'rgb_size',@rgbSize;'scalar',@scalar; ...
        'depth_order',@depthOrder;'child_order',@childOrder;'ties',@ties; ...
        'reverse_aspect',@reverseAspect;'mesh',@meshCase;'combination',@combination; ...
        'json',@jsonCase;'determinism',@determinism;'bad_z',@badZ; ...
        'missing_order',@missingOrder;'bad_order',@badOrder;'mixed_depth',@mixedDepth; ...
        'bad_mesh',@badMesh;'perspective',@perspective;'old_surface',@oldSurface; ...
        'profile_gutters',@profileGutters};
    results=cell(size(cases,1),3);failures=0;
    for caseIndex=1:size(cases,1)
        try,fn=cases{caseIndex,2};fn();status='PASS';detail='';
        catch err,status='FAIL';detail=[err.identifier ' ' regexprep(err.message,'[\r\n]+',' ')];failures=failures+1;end
        results(caseIndex,:)={cases{caseIndex,1},status,detail};
    end
    f=fopen(fullfile(outputDirectory,'m65-ir-results.tsv'),'w');guard=onCleanup(@()fclose(f));
    fprintf(f,'case\tstatus\tdetail\n');for reportIndex=1:size(results,1),fprintf(f,'%s\t%s\t%s\n',results{reportIndex,:});end;clear guard;
    summary=struct('tests',size(cases,1),'failures',failures);
    if failures,disp(results);error('M2T:M65IrFailed','%d portable cases failed.',failures);end
    fprintf('M65_PORTABLE_IR_PASS: %d/%d\n',summary.tests,summary.tests);
    function constant(),ir=fixture();write(ir,'constant');end
    function rgbSize(),ir=fixture();s=ir.axes{1}.series{1};s.colorMode='per_point_rgb';s.colorData=[1 0 0;0 1 0;0 0 1];s.sizeMode='per_point';s.markerSize=[8 16 24];s.faceMode='data';s.edgeMode='none';ir.axes{1}.series{1}=s;tex=write(ir,'rgb-size');for n=1:3,assert(~isempty(strfind(tex,sprintf('run%dp1',n))));end;end
    function scalar(),ir=fixture();s=ir.axes{1}.series{1};s.colorMode='scalar_mapped';s.colorData=[0 .5 1];s.faceMode='data';s.edgeMode='none';ir.axes{1}.series{1}=s;write(ir,'scalar');end
    function depthOrder(),ir=depthFixture();s=m2t2.render.orderScatter3(ir.axes{1}.series{1},ir.axes{1});assert(isequal(s.colorData,[0 0 1;1 0 0]));write(ir,'depth');end
    function childOrder(),ir=depthFixture();ir.axes{1}.sceneOrder='childorder';s=m2t2.render.orderScatter3(ir.axes{1}.series{1},ir.axes{1});assert(isequal(s.colorData,[1 0 0;0 0 1]));write(ir,'childorder');end
    function ties(),ir=depthFixture();s=ir.axes{1}.series{1};s.x=[0 0];s.y=[0 0];s.z=[0 0];assert(isequal(m2t2.render.orderScatter3(s,ir.axes{1}),s));end
    function reverseAspect(),ir=depthFixture();a=ir.axes{1};a.xdirection='reverse';a.ydirection='reverse';a.zdirection='reverse';a.dataAspectRatio=[2 3 4];s=m2t2.render.orderScatter3(a.series{1},a);assert(isequal(s.colorData,[1 0 0;0 0 1]));end
    function meshCase(),ir=meshFixture();tex=write(ir,'mesh');assert(numel(strfind(tex,'\addplot3['))==7);assert(isempty(strfind(tex,'shader=interp')));end
    function combination(),ir=meshFixture();ir.axes{1}.sceneOrder='childorder';s=m2t2.ir.makeLine3Series();s.id='line';s.x=[-1 1];s.y=[0 0];s.z=[.7 .7];ir.axes{1}.series{2}=s;ir.axes{1}.series{3}=fixture().axes{1}.series{1};write(ir,'combination');end
    function jsonCase(),ir=meshFixture();assert(strcmp(m2t2.render.renderPgfplots(ir,true),m2t2.render.renderPgfplots(m2t2.ir.fromJson(jsonencode(ir)),true)));ir=depthFixture();assert(strcmp(m2t2.render.renderPgfplots(ir,true),m2t2.render.renderPgfplots(m2t2.ir.fromJson(jsonencode(ir)),true)));end
    function determinism(),ir=depthFixture();before=jsonencode(ir);assert(strcmp(m2t2.render.renderPgfplots(ir,true),m2t2.render.renderPgfplots(ir,true)));assert(strcmp(before,jsonencode(ir)));end
    function badZ(),ir=fixture();ir.axes{1}.series{1}.z=[1 2];reject(ir);end
    function missingOrder(),ir=fixture();ir.axes{1}=rmfield(ir.axes{1},'sceneOrder');reject(ir);end
    function badOrder(),ir=fixture();ir.axes{1}.sceneOrder='guessed';reject(ir);end
    function mixedDepth(),ir=meshFixture();s=m2t2.ir.makeLine3Series();s.id='line';ir.axes{1}.series{2}=s;reject(ir);end
    function badMesh(),ir=meshFixture();ir.axes{1}.series{1}.edgeMode='flat';reject(ir);end
    function perspective(),ir=fixture();ir.axes{1}.projection='perspective';reject(ir);end
    function oldSurface(),runM54SurfaceIrTests(fullfile(outputDirectory,'old-surface'));end
    function profileGutters(),ir=fixture();ir.size=[400 250];a=ir.axes{1};a.xlabel=m2t2.ir.makeText('X');a.ylabel=m2t2.ir.makeText('Y');a.zlabel=m2t2.ir.makeText('Z');ir.axes{1}=a;before=jsonencode(ir);p=m2t.profile.apply(ir,m2t.profile.getProfile('publication'),'single-column');assert(p.success&&p.ir.axes{1}.placement.y*p.ir.size(2)>=32);assert(strcmp(before,jsonencode(ir))&&isequal(p.ir.axes{1}.series,a.series));end
    function tex=write(ir,name),tex=m2t2.render.renderPgfplots(ir,true);f=fopen(fullfile(outputDirectory,[name '.tex']),'w');c=onCleanup(@()fclose(f));fprintf(f,'%s',tex);clear c;end
end
function ir=fixture()
    a=m2t2.ir.makeAxes();a.kind='m2t2.axes3d';a.dimensionality=3;a.view=[30 25];a.sceneOrder='depth';
    a.xlim=[-1 1];a.ylim=[-1 1];a.zlim=[-1 1];
    s=m2t2.ir.makeScatter3Series();s.id='scatter';s.x=[-.8 0 .8];s.y=[.4 -.4 .6];s.z=[-.5 .5 0];
    a.series={s};ir=m2t2.ir.makeFigure({a});
end
function ir=depthFixture()
    ir=fixture();a=ir.axes{1};v=[sind(30)*cosd(25),-cosd(30)*cosd(25),sind(25)];
    s=a.series{1};s.x=[v(1) -v(1)];s.y=[v(2) -v(2)];s.z=[v(3) -v(3)];
    s.markerSize=40;s.colorMode='per_point_rgb';s.colorData=[1 0 0;0 0 1];s.faceMode='data';s.edgeMode='none';a.series={s};ir.axes{1}=a;
end
function ir=meshFixture()
    ir=fixture();[x,y]=meshgrid(linspace(-1,1,4),linspace(-1,1,3));s=m2t2.ir.makeSurfaceSeries();s.id='mesh';s.x=x;s.y=y;s.z=x.*y;s.c=s.z;
    s.faceMode='none';s.edgeMode='constant';s.edgeColor=[.1 .4 .7];s.lineWidth=1;s.lineStyle='solid';ir.axes{1}.series={s};
end
function reject(ir)
    try,m2t2.ir.validate(ir);error('M2T:ExpectedFailure','invalid IR accepted');
    catch err,assert(strcmp(err.identifier,'M2T2:E003:InvalidIR'));end
end
