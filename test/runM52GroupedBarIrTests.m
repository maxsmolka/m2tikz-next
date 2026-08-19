function summary=runM52GroupedBarIrTests(outputDirectory)
%RUNM52GROUPEDBARIRTESTS Validate portable bar recognition, IR, and rendering.
    root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
    if nargin<1,outputDirectory=fullfile(root,'.audit','m52-bar-ir');end;ensureDirectory(outputDirectory);
    cases={@nativeGrouped,@syntheticGeometry,@mixedSign,@jsonReplay,@oldV2, ...
        @stacked,@horizontal,@arbitraryGroup,@invalidGroup,@invalidColor};
    names={'native_grouped','synthetic_geometry','mixed_sign','json_replay','old_v2', ...
        'stacked_rejected','horizontal_rejected','arbitrary_group','invalid_group','invalid_color'};
    rows=cell(1,numel(cases));results=cell(numel(cases),4);failures=0;
    for k=1:numel(cases),try,cases{k}();status='PASS';detail='';catch err,status='FAIL';failures=failures+1;detail=[err.identifier ': ' oneLine(err.message)];end;results(k,:)={names{k},status,detail,'bar-ir'};end %#ok<NASGU>
    path=fullfile(outputDirectory,'m52-bar-ir-results.tsv');writeRows(path,results);summary=struct('failures',failures,'tests',numel(cases),'resultPath',path);
    if failures,fprintf(2,'M5.2 bar IR diagnostics from %s:\n%s',path,fileread(path));error('M2T2:M52BarIrTestsFailed','%d bar IR tests failed.',failures);end
end
function nativeGrouped()
    f=figure('Visible','off');c=onCleanup(@()close(f));a=axes('Parent',f);b=bar(a,[2 4 7],[1 3;2 4;3 5],.65,'grouped');set(b(1),'DisplayName','A');set(b(2),'DisplayName','B');legend(a,'show');ir=m2t2.reader.readFigure(f);assert(numel(ir.axes{1}.series)==2);assert(strcmp(ir.axes{1}.series{1}.kind,'m2t2.bar'));assert(isequal(ir.axes{1}.series{2}.values,[3 4 5]));assert(ir.axes{1}.series{1}.groupIndex==1&&ir.axes{1}.series{2}.groupIndex==2);clear c;
end
function syntheticGeometry()
    ir=barIR();tex=m2t2.render.renderPgfplots(ir,true);assertContains(tex,'(axis cs:0.742857142857143,0) rectangle (axis cs:0.971428571428572,2)');assertContains(tex,'(axis cs:1.02857142857143,0) rectangle (axis cs:1.25714285714286,4)');
end
function mixedSign(),ir=barIR();ir.axes{1}.series{1}.values=[-2 3];m2t2.ir.validate(ir);tex=m2t2.render.renderPgfplots(ir,true);assertContains(tex,'-2)');end
function jsonReplay(),ir=barIR();loaded=m2t2.ir.fromJson(jsonencode(ir));assert(strcmp(m2t2.render.renderPgfplots(ir,true),m2t2.render.renderPgfplots(loaded,true)));end
function oldV2(),ir=barIR();ir.axes{1}.series={};loaded=m2t2.ir.fromJson(jsonencode(ir));assert(isempty(loaded.axes{1}.series));end
function stacked(),f=figure('Visible','off');c=onCleanup(@()close(f));bar(axes('Parent',f),[1 2;3 4],'stacked');expect(@()m2t2.reader.readFigure(f),'M2T2:E018:UnsupportedBarMode');clear c;end
function horizontal(),f=figure('Visible','off');c=onCleanup(@()close(f));barh(axes('Parent',f),[1 2;3 4],'grouped');expect(@()m2t2.reader.readFigure(f),'M2T2:E019:UnsupportedBarOrientation');clear c;end
function arbitraryGroup(),f=figure('Visible','off');c=onCleanup(@()close(f));a=axes('Parent',f);g=hggroup('Parent',a);patch('Parent',g,'XData',[0 1 1 0],'YData',[0 0 1 1]);expect(@()m2t2.reader.readFigure(f),'M2T2:E001:UnsupportedObject');clear c;end
function invalidGroup(),ir=barIR();ir.axes{1}.series{2}.groupIndex=1;expect(@()m2t2.ir.validate(ir),'M2T2:E003:InvalidIR');end
function invalidColor(),ir=barIR();ir.axes{1}.series{1}.faceColor=[2 0 0];expect(@()m2t2.ir.validate(ir),'M2T2:E003:InvalidIR');end
function ir=barIR()
    a=m2t2.ir.makeAxes();a.xlim=[0 3];a.ylim=[-3 6];a.series=cell(1,2);
    for k=1:2,s=m2t2.ir.makeBarSeries();s.id=sprintf('axes-1-series-%d',k);s.groupIndex=k;s.groupCount=2;s.categories=[1 2];s.values=[2 3]+2*(k-1);s.faceColor=[k==2 0 k==1];a.series{k}=s;end
    ir=m2t2.ir.makeFigure({a});ir.size=[12 8];
end
function expect(action,id),try,action();catch err,assert(strcmp(err.identifier,id));return;end;error('M2T2:ExpectedFailureMissing','Expected %s.',id);end
function assertContains(text,value),assert(~isempty(strfind(text,value)));end %#ok<STREMP>
function ensureDirectory(path),if exist(path,'dir')~=7,mkdir(path);end,end
function writeRows(path,rows),fid=fopen(path,'w');c=onCleanup(@()fclose(fid));fprintf(fid,'case\tstatus\tdetail\tlayer\n');for k=1:size(rows,1),fprintf(fid,'%s\t%s\t%s\t%s\n',rows{k,:});end;clear c;end
function value=oneLine(value),value=strrep(strrep(value,sprintf('\r'),' '),sprintf('\n'),' ');end
