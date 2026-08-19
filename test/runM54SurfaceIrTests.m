function summary = runM54SurfaceIrTests(outputDirectory)
%RUNM54SURFACEIRTESTS Runtime-neutral M5.4 IR and renderer coverage.
    root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
    if nargin<1,outputDirectory=fullfile(root,'.audit','m54-surface-ir');end;if exist(outputDirectory,'dir')~=7,mkdir(outputDirectory);end
    cases={'ZI01_surface',@surfaceCase;'ZI02_line3',@lineCase;'ZI03_patch3',@patchCase; ...
        'ZI04_json',@jsonCase;'ZI05_deterministic',@deterministicCase; ...
        'ZI06_bad_geometry',@badGeometry;'ZI07_bad_surface_mode',@badMode; ...
        'ZI08_bad_line',@badLine;'ZI09_bad_patch',@badPatch;'ZI10_old_v2',@oldV2};
    rows=cell(size(cases,1),4);failures=0;
    for k=1:size(cases,1),try,fn=cases{k,2};d=fn();s='PASS';catch err,s='FAIL';failures=failures+1;d=[err.identifier ': ' regexprep(err.message,'[\r\n]+',' ')];end;rows(k,:)={cases{k,1},s,d,'M5.4-IR'};end
    path=fullfile(outputDirectory,'m54-ir-results.tsv');f=fopen(path,'w');guard=onCleanup(@()fclose(f));fprintf(f,'case\tstatus\tdetail\tlayer\n');for k=1:size(rows,1),fprintf(f,'%s\t%s\t%s\t%s\n',rows{k,:});end;clear guard;
    summary=struct('tests',size(rows,1),'failures',failures,'resultPath',path);if failures,fprintf(2,'%s',fileread(path));error('M2T:M54IrFailed','%d M5.4 IR tests failed.',failures);end
end
function d=surfaceCase(),ir=fixture();tex=m2t2.render.renderPgfplots(ir,true);assert(~isempty(strfind(tex,'\addplot3[surf'))&&~isempty(strfind(tex,'shader=interp')));d='surface renders as native addplot3 surf';end
function d=lineCase(),ir=fixture();tex=m2t2.render.renderPgfplots(ir,true);assert(~isempty(strfind(tex,'coordinates {')));d='Line3IR renders explicit triples';end
function d=patchCase(),ir=fixture();tex=m2t2.render.renderPgfplots(ir,true);assert(~isempty(strfind(tex,'patch type=triangle'))&&~isempty(strfind(tex,'usepgfplotslibrary{patchplots}')));d='narrow triangle Patch3IR rendered';end
function d=jsonCase(),ir=fixture();replay=m2t2.ir.fromJson(jsonencode(ir));assert(strcmp(m2t2.render.renderPgfplots(ir,true),m2t2.render.renderPgfplots(replay,true)));d='v2 JSON replay identical';end
function d=deterministicCase(),ir=fixture();assert(strcmp(m2t2.render.renderPgfplots(ir,true),m2t2.render.renderPgfplots(ir,true)));d='renderer deterministic';end
function d=badGeometry(),ir=fixture();ir.axes{1}.series{1}.x=zeros(2,3);expect(@()m2t2.ir.validate(ir));d='malformed surface rejected';end
function d=badMode(),ir=fixture();ir.axes{1}.series{1}.faceMode='flat';expect(@()m2t2.ir.validate(ir));d='unsupported face mode rejected';end
function d=badLine(),ir=fixture();ir.axes{1}.series{2}.z=[1 2 3];expect(@()m2t2.ir.validate(ir));d='malformed Line3 rejected';end
function d=badPatch(),ir=fixture();ir.axes{1}.series{3}.vertices=zeros(4,3);expect(@()m2t2.ir.validate(ir));d='arbitrary patch rejected';end
function d=oldV2(),a=m2t2.ir.makeAxes();a.series={m2t2.ir.makeLineSeries()};ir=m2t2.ir.makeFigure({a});replay=m2t2.ir.fromJson(jsonencode(ir));assert(strcmp(replay.axes{1}.kind,'m2t2.axes2d'));d='existing v2 axes default to 2-D';end
function ir=fixture(),a=m2t2.ir.makeAxes();a.kind='m2t2.axes3d';a.dimensionality=3;a.view=[35 25];a.zlim=[-1 1];[x,y]=meshgrid([-1 0 1]);s=m2t2.ir.makeSurfaceSeries();s.id='surface';s.x=x;s.y=y;s.z=x.*y;s.c=s.z;l=m2t2.ir.makeLine3Series();l.id='line';l.x=[-1 1];l.y=[0 0];l.z=[1 1];p=m2t2.ir.makePatch3Series();p.id='patch';p.vertices=[0 0 0;.2 0 0;0 .2 0];a.series={s,l,p};ir=m2t2.ir.makeFigure({a});end
function expect(fn),try,fn();error('M2T:ExpectedFailure','invalid IR accepted');catch err,assert(strcmp(err.identifier,'M2T2:E003:InvalidIR'));end,end
