function summary = runM63TiledIrTests(outputDirectory)
%RUNM63TILEDIRTESTS Portable explicit-layout validation without graphics APIs.
    root=fileparts(fileparts(mfilename('fullpath'))); addpath(fullfile(root,'src'));
    if nargin<1, outputDirectory=fullfile(root,'.audit','m63-tiled-ir'); end
    if exist(outputDirectory,'dir')~=7, mkdir(outputDirectory); end
    ir=fixture(); cases={'explicit_cells',@cellsCase;'span',@spanCase; ...
        'json_roundtrip',@jsonCase;'old_grid',@oldCase; ...
        'profile_85',@()profileCase('single-column');'profile_170',@()profileCase('double-column'); ...
        'overlap',@()badCase('overlap');'out_of_bounds',@()badCase('bounds'); ...
        'missing_owner',@()badCase('owner');'dynamic',@()badCase('dynamic'); ...
        'bad_spacing',@()badCase('spacing');'missing_metadata',@()badCase('missing'); ...
        'profile_figure_arrow_rejected',@arrowCase};
    rows=cell(size(cases,1),3); failures=0;
    for k=1:size(cases,1)
        try,cases{k,2}();status='PASS';detail='assertions passed';
        catch err,status='FAIL';failures=failures+1;detail=regexprep([err.identifier ': ' err.message],'[\r\n\t]+',' ');end
        rows(k,:)={cases{k,1},status,detail};
    end
    path=fullfile(outputDirectory,'tiled-ir-results.tsv');writeRows(path,rows);
    summary=struct('tests',size(rows,1),'failures',failures,'resultPath',path);
    fprintf('%s',fileread(path));assert(failures==0,'M6.3 portable tests failed.');
    function cellsCase()
        m2t2.ir.validate(ir);assert(strcmp(ir.layout.cells{2}.axesId,'axes-2'));
        a=m2t2.render.renderPgfplots(ir,true);b=m2t2.render.renderPgfplots(ir,true);assert(strcmp(a,b));
        m2t.internal.writeTextFile(fullfile(outputDirectory,'fixed-grid.tex'),a);
        m2t.internal.writeTextFile(fullfile(outputDirectory,'fixed-grid.json'),jsonencode(ir));
    end
    function spanCase()
        a=ir;a.layout.columns=3;a.layout.cells{2}.columnSpan=2;m2t2.ir.validate(a);
        assert(a.layout.cells{2}.columnSpan==2);
    end
    function jsonCase()
        a=m2t2.ir.fromJson(jsonencode(ir));assert(isequal(a.layout,ir.layout));
        assert(strcmp(m2t2.render.renderPgfplots(a,true),m2t2.render.renderPgfplots(ir,true)));
    end
    function oldCase()
        a=ir;a.layout=rmfield(a.layout,'tiled');a=m2t2.ir.fromJson(jsonencode(a));
        assert(~isfield(a.layout,'tiled'));m2t2.ir.validate(a);
    end
    function profileCase(width)
        selection=m2t.profile.getSelection('publication',width);
        a=m2t.profile.apply(ir,selection.profile,selection.width);assert(a.success&&isequal(a.ir.layout,ir.layout));
        assert(a.ir.axes{1}.placement.x*a.ir.size(1)>=24-1e-10);
        for n=1:numel(ir.axes),assert(isequal(a.ir.axes{n}.series,ir.axes{n}.series));end
        m2t.internal.writeTextFile(fullfile(outputDirectory,[width '.tex']),m2t2.render.renderPgfplots(a.ir,true,a.renderConfig));
    end
    function arrowCase()
        a=ir;a.annotations={m2t2.ir.makeArrowAnnotation()};
        selection=m2t.profile.getSelection('publication','single-column');
        caught=false;try,m2t.profile.apply(a,selection.profile,selection.width);
        catch err,caught=strcmp(err.identifier,'M2T:PROFILE_GEOMETRY_INVALID');end;assert(caught);
    end
    function badCase(kind)
        a=ir;
        switch kind
            case 'overlap',a.layout.cells{2}.column=1;
            case 'bounds',a.layout.cells{2}.columnSpan=2;
            case 'owner',a.layout.cells(2)=[];
            case 'dynamic',a.layout.tiled.arrangement='flow';
            case 'spacing',a.layout.tiled.spacing='unrecognized';
            case 'missing',a.layout.tiled=rmfield(a.layout.tiled,'indexing');
        end
        caught=false;try,m2t2.ir.validate(a);catch,caught=true;end;assert(caught);
    end
end
function ir=fixture()
    axesItems=cell(1,2);cells=cell(1,2);
    for k=1:2
        a=m2t2.ir.makeAxes();a.id=sprintf('axes-%d',k);
        a.placement=m2t2.ir.makePlacement(.12+(k-1)*.47,.2,.32,.6);
        s=m2t2.ir.makeLineSeries();s.x=[0 .5 1];s.y=[0 .25 1];a.series={s};axesItems{k}=a;
        cells{k}=m2t2.ir.makeLayoutCell(a.id,1,k);
    end
    ir=m2t2.ir.makeFigure(axesItems);ir.size=[480 280];
    ir.layout=m2t2.ir.makeTiledLayout(1,2,cells,'rowmajor','compact','compact');
    label=m2t2.ir.makeSharedLabel('title',m2t2.ir.makeText('Fixed grid'));
    label.owner=m2t2.ir.makeOwner('layout','layout');ir.elements={label};
end
function writeRows(path,rows)
    fid=fopen(path,'wb');assert(fid>=0);c=onCleanup(@()fclose(fid));fprintf(fid,'case\tstatus\tdetail\n');
    for k=1:size(rows,1),fprintf(fid,'%s\t%s\t%s\n',rows{k,:});end;clear c;
end
