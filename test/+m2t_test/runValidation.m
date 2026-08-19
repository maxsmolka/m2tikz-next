function report = runValidation(expectedRuntime, outputDirectory)
%RUNVALIDATION Execute the layered modern compatibility evidence program.
    repositoryRoot=fileparts(fileparts(fileparts(mfilename('fullpath'))));
    if nargin<1,expectedRuntime='matlab';end
    if nargin<2,outputDirectory=fullfile(repositoryRoot,'build','matlab-validation');end
    addpath(fullfile(repositoryRoot,'src'));
    if exist(outputDirectory,'dir')==7,rmdir(outputDirectory,'s');end;mkdir(outputDirectory);
    runtime=m2t_test.runtimeInfo();environment=m2t_test.environmentCheck(outputDirectory);
    layers=m2t_test.validationLayers();for k=1:numel(layers),layers(k).status='pending';end
    layers(1).status=ternary(strcmp(runtime.kind,expectedRuntime)&&isempty(environment.failures),'pass','environment_failure');
    fixtures=m2t_test.fixtureRegistry();results=repmat(resultTemplate(),1,numel(fixtures));

    auditDirectory=fullfile(outputDirectory,'hg-audit');
    try,m2t_test.auditGraphicsObjects(auditDirectory);layers(2).status='pass';catch err,layers(2).status='fail';environment.failures{end+1}=['HG audit: ' err.message];end
    for k=1:numel(fixtures)
        results(k)=runFixture(fixtures(k),outputDirectory);
    end
    modernPassed=all(strcmp({results.status},'pass'));
    for k=3:11,layers(k).status=ternary(modernPassed,'pass','fail');end
    legacy=runLegacy(outputDirectory);layers(12).status=legacy.status;
    environment.pgfplotsValidatedByCompile=modernPassed;
    summary=struct('totalFixtures',numel(results),'passed',sum(strcmp({results.status},'pass')), ...
        'failed',sum(strcmp({results.status},'fail')),'environmentFailures',numel(environment.failures), ...
        'semanticMismatches',sum(strcmp({results.failureCategory},'IR')));
    report=struct('schemaVersion',1,'runtime',runtime,'environment',environment, ...
        'fixtures',results,'layers',layers,'legacy',legacy,'summary',summary,'success',false);
    report.success=strcmp(runtime.kind,expectedRuntime)&&isempty(environment.failures)&&modernPassed;
    report.paths=m2t_test.writeValidationReports(report,outputDirectory);
end

function result=runFixture(definition,outputDirectory)
    result=resultTemplate();result.id=definition.id;result.name=definition.name;
    fixtureDirectory=fullfile(outputDirectory,'fixtures',definition.id);mkdir(fixtureDirectory);
    fixture=[];
    try
        fixture=m2t_test.buildFixture(definition.id);cleanup=onCleanup(@()closeFigures(fixture.figures));
        before=m2t_test.captureFigureState(fixture.primary);
        analysis=m2t.internal.analyzeFigure(fixture.primary);result.readerSuccess=strcmp(analysis.classification,'supported');
        if ~result.readerSuccess,error('M2T_TEST:READER','%s',diagnosticText(analysis.diagnostics));end
        irJson=jsonencode(analysis.ir);assert(strcmp(irJson,jsonencode(analysis.ir)));result.irDeterministic=true;
        writeText(fullfile(fixtureDirectory,'ir.json'),[irJson sprintf('\n')]);result.irEvidence='ir.json';
        tex1=m2t2.render.renderPgfplots(analysis.ir,true);tex2=m2t2.render.renderPgfplots(analysis.ir,true);
        result.rendererDeterministic=strcmp(tex1,tex2);if ~result.rendererDeterministic,error('M2T_TEST:RENDER','Repeated renderer output differs.');end
        if strcmp(fixture.mode,'set')
            entries=struct('figure',{fixture.figures(1),fixture.figures(2)},'name',{'first','second'});
            workflow=m2t.exportSet(entries,fullfile(fixtureDirectory,'set'),'Overwrite',true);
            result.workflowSuccess=workflow.success;result.compileSuccess=workflow.success;
            result.workflowEvidence='set/m2t-manifest.json';
        else
            args=[fixture.exportOptions {'Overwrite',true}];
            workflow=m2t.export(fixture.primary,fullfile(fixtureDirectory,'figure'),args{:});
            result.workflowSuccess=workflow.success;result.compileSuccess=workflow.success;
            result.workflowEvidence='figure.tex';
        end
        if ~result.workflowSuccess,error(failureIdentifier(definition,workflow),'Workflow failed.');end
        if strcmp(definition.id,'F23')
            expectedPdfPoints=workflow.profile.widthMillimeters*72/25.4;
            [result.pdfGeometryValid,actualWidth]=validatePdfWidth(workflow.pdfPath,expectedPdfPoints);
            if ~result.pdfGeometryValid,error('M2T_TEST:PROFILE','Publication PDF width %.6g differs from requested %.6g PDF pt.',actualWidth,expectedPdfPoints);end
        end
        result.repeatDeterministic=validateRepeat(definition,fixture,fixtureDirectory,workflow);
        if ~result.repeatDeterministic,error('M2T_TEST:RENDER','Repeated workflow evidence differs.');end
        after=m2t_test.captureFigureState(fixture.primary);mutation=m2t_test.compareSemantic(after,before,{});
        result.figureUnchanged=mutation.equal;if ~result.figureUnchanged,error('M2T_TEST:WORKFLOW','Caller figure state changed.');end
        result.status='pass';result.failureCategory='';result.evidence=[definition.id '/ir.json'];
        clear cleanup;
    catch err
        result.status='fail';result.failureCategory=category(err.identifier);result.failureId=['MATLAB-' result.failureCategory '-001'];result.message=oneLine(err.message);result.evidence=[definition.id '/'];
        if ~isempty(fixture),closeFigures(fixture.figures);end
    end
end

function legacy=runLegacy(outputDirectory)
    legacy=struct('status','fail','message','','evidence','legacy/legacy-smoke.tex');
    directory=fullfile(outputDirectory,'legacy');mkdir(directory);fig=figure('Visible','off');cleanup=onCleanup(@()closeFigures(fig));
    try,plot(1:3,[1 3 2]);matlab2tikz(fullfile(directory,'legacy-smoke.tex'),'figurehandle',fig,'standalone',true,'showInfo',false,'externalData',false);legacy.status='pass';catch err,legacy.message=oneLine(err.message);end
    clear cleanup;
end
function value=resultTemplate(),value=struct('id','','name','','status','pending','failureCategory','', ...
    'failureId','','message','','readerSuccess',false,'irDeterministic',false, ...
    'rendererDeterministic',false,'workflowSuccess',false,'compileSuccess',false, ...
    'repeatDeterministic',false,'pdfGeometryValid',false,'figureUnchanged',false, ...
    'irEvidence','','workflowEvidence','','evidence','');end
function value=category(identifier)
    categories={'ENV','HG','READER','IR','RENDER','TEX','WORKFLOW','PROFILE','SET','IMAGE','HYBRID','PLANNER','LEGACY'};value='IR';
    for k=1:numel(categories),if ~isempty(strfind(identifier,categories{k})),value=categories{k};return;end,end %#ok<STREMP>
end
function identifier=failureIdentifier(definition,workflow)
    if isfield(workflow,'status')&&strcmp(workflow.status,'compile_failed'),identifier='M2T_TEST:TEX';return;end
    capability=definition.capabilities{1};
    switch capability
        case 'profile',identifier='M2T_TEST:PROFILE';case 'set',identifier='M2T_TEST:SET';
        case 'image',identifier='M2T_TEST:IMAGE';case 'hybrid',identifier='M2T_TEST:HYBRID';
        case 'planner',identifier='M2T_TEST:PLANNER';otherwise,identifier='M2T_TEST:WORKFLOW';
    end
end
function equal=validateRepeat(definition,fixture,directory,first)
    equal=true;
    if strcmp(definition.id,'F24')
        firstText=fileread(first.manifestPath);entries=struct('figure',{fixture.figures(1),fixture.figures(2)},'name',{'first','second'});
        second=m2t.exportSet(entries,fullfile(directory,'set'),'Overwrite',true);equal=second.success&&strcmp(firstText,fileread(second.manifestPath));
    elseif any(strcmp(definition.id,{'F25','F26'}))
        firstTex=fileread(first.texPath);firstDecision=first.render.imageBackend;
        firstAssets=readAssets(first.render.assets);args=[fixture.exportOptions {'Overwrite',true}];
        second=m2t.export(fixture.primary,fullfile(directory,'figure'),args{:});
        equal=second.success&&strcmp(firstTex,fileread(second.texPath))&&isequal(firstDecision,second.render.imageBackend)&&isequal(firstAssets,readAssets(second.render.assets));
    end
end
function values=readAssets(paths),values=cell(1,numel(paths));for k=1:numel(paths),fid=fopen(paths{k},'rb');cleanup=onCleanup(@()fclose(fid));values{k}=fread(fid,Inf,'*uint8');clear cleanup;end,end
function [valid,width]=validatePdfWidth(path,expected)
    if ispc,path=strrep(path,'\','/');selector='findstr /B /C:"Page size"';else,selector='grep "^Page size"';end
    quoted=['"' path '"'];[status,text]=system(['pdfinfo -enc UTF-8 ' quoted ' 2>&1 | ' selector]);
    token=regexp(text,'Page size:\s+([0-9.]+)\s+x\s+([0-9.]+)\s+pts','tokens','once');
    if isempty(token),width=NaN;else,width=str2double(token{1});end
    valid=status==0&&isfinite(width)&&abs(width-expected)<=0.05;
end
function value=diagnosticText(items),if isempty(items),value='Reader failed without diagnostic.';else,value=items(1).message;end,end
function value=ternary(condition,a,b),if condition,value=a;else,value=b;end,end
function value=oneLine(value),value=regexprep(value,'[\r\n\t]+',' ');end
function writeText(path,text),fid=fopen(path,'wb');assert(fid>=0);cleanup=onCleanup(@()fclose(fid));fwrite(fid,text,'char');clear cleanup;end
function closeFigures(figures),for k=1:numel(figures),if ishandle(figures(k)),close(figures(k));end,end,end
