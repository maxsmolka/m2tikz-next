function summary=runM53BoxplotIrTests(outputDirectory)
%RUNM53BOXPLOTIRTESTS Runtime-neutral BoxplotSeriesIR validation.
    root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
    if nargin<1,outputDirectory=fullfile(root,'.audit','m53-boxplot-ir');end;if exist(outputDirectory,'dir')~=7,mkdir(outputDirectory);end
    cases={'XI01_valid',@valid;'XI02_render',@renderCase;'XI03_json',@jsonCase;'XI04_outliers',@outliers; ...
        'XI05_old_v2',@oldv2;'XI06_horizontal',@horizontal;'XI07_order',@order; ...
        'XI08_outlier_pair',@outlierPair;'XI09_marker',@marker;'XI10_handle_free',@handleFree};
    rows=cell(size(cases,1),4);failures=0;
    for k=1:size(cases,1),try,detail=cases{k,2}();status='PASS';catch err,status='FAIL';failures=failures+1;detail=[err.identifier ': ' regexprep(err.message,'[\r\n]+',' ')];end;rows(k,:)={cases{k,1},status,detail,'M5.3 IR'};end
    path=fullfile(outputDirectory,'m53-boxplot-ir-results.tsv');writeRows(path,rows);summary=struct('tests',size(rows,1),'failures',failures,'resultPath',path);
    if failures,fprintf(2,'%s',fileread(path));error('M2T:M53IrFailed','%d M5.3 IR tests failed.',failures);end
    function d=valid(),m2t2.ir.validate(fixture());d='explicit vertical statistics valid';end
    function d=renderCase(),t=m2t2.render.renderPgfplots(fixture(),true);assert(~isempty(strfind(t,'axis cs:1,2'))&&~isempty(strfind(t,'mark=x')));d='boxes, medians, whiskers, and outliers rendered';end %#ok<STREMP>
    function d=jsonCase(),ir=fixture();r=m2t2.ir.fromJson(jsonencode(ir));assert(strcmp(m2t2.render.renderPgfplots(ir,true),m2t2.render.renderPgfplots(r,true)));d='JSON replay deterministic';end
    function d=outliers(),ir=fixture();ir.axes{1}.series{1}.outlierValues=[];ir.axes{1}.series{1}.outlierPositions=[];m2t2.ir.validate(ir);d='empty outlier set explicit';end
    function d=oldv2(),ir=m2t2.ir.fromJson(jsonencode(m2t2.ir.makeFigure()));m2t2.ir.validate(ir);d='old empty v2 remains readable';end
    function d=horizontal(),ir=fixture();ir.axes{1}.series{1}.orientation='horizontal';expect(ir,'orientation');d='horizontal rejected';end
    function d=order(),ir=fixture();ir.axes{1}.series{1}.q1(1)=12;expect(ir,'ordered');d='unordered statistics rejected';end
    function d=outlierPair(),ir=fixture();ir.axes{1}.series{1}.outlierPositions=[];expect(ir,'paired');d='outlier loss/mismatch rejected';end
    function d=marker(),ir=fixture();ir.axes{1}.series{1}.outlierMarker='none';expect(ir,'visible');d='invisible outlier marker rejected';end
    function d=handleFree(),t=m2t2.render.renderPgfplots(fixture(),true);assert(isempty(regexp(t,'handle|gnuplot|MATLAB|Octave','once')));d='renderer output runtime-neutral';end
end
function ir=fixture()
    ir=m2t2.ir.makeFigure();a=m2t2.ir.makeAxes();s=m2t2.ir.makeBoxplotSeries();
    s.positions=[1 2];s.lowerWhisker=[1 11];s.q1=[5 15];s.median=[10 20];s.q3=[15 25];s.upperWhisker=[20 30];s.outlierPositions=[1 2];s.outlierValues=[30 40];a.series={s};ir.axes={a};
end
function expect(ir,fragment)
    try,m2t2.ir.validate(ir);error('M2T:ExpectedFailure','accepted invalid IR');catch err,assert(strcmp(err.identifier,'M2T2:E003:InvalidIR')&&~isempty(strfind(err.message,fragment)));end %#ok<STREMP>
end
function writeRows(path,rows)
    f=fopen(path,'w');c=onCleanup(@()fclose(f));fprintf(f,'case\tstatus\tdetail\tlayer\n');for k=1:size(rows,1),fprintf(f,'%s\t%s\t%s\t%s\n',rows{k,:});end;clear c;
end
