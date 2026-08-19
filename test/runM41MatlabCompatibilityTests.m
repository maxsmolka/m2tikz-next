function summary = runM41MatlabCompatibilityTests(outputDirectory)
%RUNM41MATLABCOMPATIBILITYTESTS Regress evidence-backed MATLAB HG behavior.
    repositoryRoot=fileparts(fileparts(mfilename('fullpath')));
    if nargin<1,outputDirectory=fullfile(repositoryRoot,'build','matlab-validation','m41-regression');end
    addpath(fullfile(repositoryRoot,'src'));if exist(outputDirectory,'dir')~=7,mkdir(outputDirectory);end
    rows=cell(5,4);failures=0;
    [rows(1,:),failures]=runCase('F01_MATLAB_READER_001_scribe_overlay',@defaultOverlay,failures,'MATLAB-READER-001');
    [rows(2,:),failures]=runCase('F01_user_annotation_still_unsupported',@userAnnotation,failures,'MATLAB-READER-001');
    [rows(3,:),failures]=runCase('F25_MATLAB_RENDER_001_png_time_metadata',@pngDeterminism,failures,'MATLAB-RENDER-001');
    [rows(4,:),failures]=runCase('F01_MATLAB_READER_001_text_interpreters',@textInterpreters,failures,'MATLAB-READER-001');
    [rows(5,:),failures]=runCase('F24_MATLAB_READER_002_numeric_figure_handle',@numericFigureHandle,failures,'MATLAB-READER-002');
    resultPath=fullfile(outputDirectory,'m41-results.tsv');writeRows(resultPath,rows);
    summary=struct('failures',failures,'tests',5,'resultPath',resultPath);
    if failures>0,fprintf(2,'M4.1 diagnostics from %s:\n%s',resultPath,fileread(resultPath));error('M2T:M41CompatibilityFailed','%d M4.1 tests failed.',failures);end
end
function detail=numericFigureHandle()
    fig=figure('Visible','off');cleanup=onCleanup(@()close(fig));ax=axes('Parent',fig);plot(ax,1:3,[1 3 2]);
    numericHandle=zeros(1,1);numericHandle(1)=fig;
    ir=m2t2.reader.readFigure(numericHandle);assert(numel(ir.axes)==1&&numel(ir.axes{1}.series)==1);
    detail='numeric legacy figure handle matches its HG2 parent by graphics identity';clear cleanup;
end
function detail=textInterpreters()
    fig=figure('Visible','off');cleanup=onCleanup(@()close(fig));ax=axes('Parent',fig);plot(ax,1:3,[1 3 2]);
    xlabel(ax,'plain_x','Interpreter','none');ylabel(ax,'tex_{y}','Interpreter','tex');title(ax,'$latex_z$','Interpreter','latex');
    ir=m2t2.reader.readFigure(fig);axesNode=ir.axes{1};
    assert(strcmp(axesNode.xlabel.value,'plain_x')&&strcmp(axesNode.xlabel.interpreter,'plain'));
    assert(strcmp(axesNode.ylabel.value,'tex_{y}')&&strcmp(axesNode.ylabel.interpreter,'tex'));
    assert(strcmp(axesNode.title.value,'$latex_z$')&&strcmp(axesNode.title.interpreter,'latex'));
    detail='plain, tex, and latex label/title strings and interpreter semantics preserved';clear cleanup;
end
function detail=pngDeterminism()
    root=tempname;mkdir(root);cleanupDirectory=onCleanup(@()rmdir(root,'s'));
    fig=figure('Visible','off');cleanupFigure=onCleanup(@()close(fig));ax=axes('Parent',fig);imagesc(ax,peaks(12));
    ir=m2t2.reader.readFigure(fig);plan=m2t2.render.makePgfplotsPlan(ir,true,m2t2.render.defaultConfig(),'hybrid','assets');
    first=fullfile(root,'first.png');second=fullfile(root,'second.png');
    m2t2.render.writePngAsset(plan.assets(1),first);pause(1.1);m2t2.render.writePngAsset(plan.assets(1),second);
    assert(isequal(readBytes(first),readBytes(second)));
    bytes=readBytes(first);assert(isempty(strfind(char(bytes(:)'),'tIME'))); %#ok<STREMP>
    detail='optional encoder tIME metadata removed; repeated PNG bytes identical';clear cleanupFigure cleanupDirectory;
end
function detail=defaultOverlay()
    fig=figure('Visible','off');cleanup=onCleanup(@()close(fig));plot(1:3,[1 3 2]);
    pane=findall(fig,'Type','annotationpane','Tag','scribeOverlay');
    assert(numel(pane)==1&&strcmp(get(pane,'HandleVisibility'),'off')&&isempty(allchild(pane)));
    ir=m2t2.reader.readFigure(fig);assert(numel(ir.axes)==1&&numel(ir.axes{1}.series)==1);
    detail='MATLAB-owned empty scribe overlay ignored; line semantics preserved';clear cleanup;
end
function detail=userAnnotation()
    fig=figure('Visible','off');cleanup=onCleanup(@()close(fig));plot(1:3,[1 3 2]);annotation(fig,'textbox',[.2 .2 .2 .1],'String','User note');
    caught=false;try,m2t2.reader.readFigure(fig);catch err,caught=strcmp(err.identifier,'M2T2:E013:UnsupportedAnnotationType')&&contains(err.message,'textboxshape');end
    assert(caught);detail='unsupported nonempty annotation pane remains precisely rejected';clear cleanup;
end
function [row,failures]=runCase(name,callback,failures,layer)
    try,detail=callback();status='PASS';catch err,status='FAIL';failures=failures+1;detail=sprintf('%s: %s',err.identifier,regexprep(err.message,'[\r\n\t]+',' '));end
    row={name,status,detail,layer};
end
function bytes=readBytes(path),fid=fopen(path,'rb');assert(fid>=0);cleanup=onCleanup(@()fclose(fid));bytes=fread(fid,Inf,'*uint8');clear cleanup;end
function writeRows(path,rows),fid=fopen(path,'wb');assert(fid>=0);cleanup=onCleanup(@()fclose(fid));fprintf(fid,'case\tstatus\tdetail\tlayer\n');for k=1:size(rows,1),fprintf(fid,'%s\t%s\t%s\t%s\n',rows{k,:});end;clear cleanup;end
