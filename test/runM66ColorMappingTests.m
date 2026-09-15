function summary=runM66ColorMappingTests(outputDirectory,compileTex)
%RUNM66COLORMAPPINGTESTS Discrete bins, raw values, per-point size and colorbars.
    root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
    if nargin<1,outputDirectory=fullfile(root,'.audit','m66-colors');end
    if nargin<2,compileTex=false;end
    if exist(outputDirectory,'dir')~=7,mkdir(outputDirectory);end
    values=[-1 0 .25 .5-eps(.5) .5 .5+eps(.5) .75 1 2];expected=[0 0 0 0 1 1 1 1 1];
    mapping=m2t2.ir.makeColorMapping();
    assert(isequal(m2t2.render.imageColorIndices(values,mapping),expected));
    names={'scatter','sized-scatter','scatter3','surface','three-colors','horizontal-bar'};
    for k=1:numel(names)
        a=m2t2.ir.makeAxes();a.xlim=[0 10];a.ylim=[0 2];
        s=m2t2.ir.makeScatterSeries();s.x=1:9;s.y=ones(1,9);s.markerSize=14;
        s.colorMode='scalar_mapped';s.colorData=values;s.edgeMode='none';s.faceMode='data';
        if k==2,s.sizeMode='per_point';s.markerSize=8:16;end
        if k==3||k==4
            a.kind='m2t2.axes3d';a.dimensionality=3;a.view=[30 25];a.sceneOrder='childorder';a.zlim=[0 2];
            if k==3,s.kind='m2t2.scatter3';s.z=ones(1,9);
            else,s=m2t2.ir.makeSurfaceSeries();[s.x,s.y]=meshgrid(1:3,[0 1]);s.z=ones(2,3);s.c=[0 .25 1;0 .25 1];end
        end
        if k==5,a.colorMapping.colormap=[0 0 1;0 1 0;1 0 0];end
        a.placement=m2t2.ir.makePlacement(.1,.1,.7,.8);
        if k==6,a.placement=m2t2.ir.makePlacement(.1,.3,.7,.6);end
        a.series={s};ir=m2t2.ir.makeFigure({a});ir.size=[400 250];
        cb=m2t2.ir.makeColorbar();if k==6,cb.orientation='horizontal';cb.location='southoutside';cb.placement=m2t2.ir.makePlacement(.1,.12,.7,.04);end
        ir.elements={cb};before=jsonencode(ir);tex=m2t2.render.renderPgfplots(ir,true);
        assert(strcmp(before,jsonencode(ir))&&strcmp(tex,m2t2.render.renderPgfplots(ir,true)));
        if k==4
            assert(~isempty(strfind(tex,'x y z meta'))&&~isempty(strfind(tex,'colormap access=piecewise constant')));
            assert(~isempty(strfind(tex,'2 0 1 0.25')));
        else
            indices=m2t2.render.imageColorIndices(values,a.colorMapping);
            matches=regexp(tex,'(?m)^[0-9]+ 1 (?:1 )?[^\n]+index([0-9]+)$','tokens');
            actual=cellfun(@(v)str2double(v{1}),matches);assert(isequal(actual,indices));
            assert(~isempty(strfind(tex,'value meta')));
        end
        assert(~isempty(strfind(tex,'colormap access=piecewise constant')));
        base=fullfile(outputDirectory,names{k});m2t.internal.writeTextFile([base '.tex'],tex);
        if compileTex,r=m2t.internal.compileLuaLatex([base '.tex'],[base '.pdf']);if ~r.success,disp(r.diagnostics);end;assert(r.success);end
    end
    summary=struct('tests',6,'failures',0);fprintf('M66_COLORMAPPING_PASS: 6/6 (compile=%d)\n',compileTex);
end
