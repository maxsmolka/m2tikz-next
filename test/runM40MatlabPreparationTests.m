function summary = runM40MatlabPreparationTests(outputDirectory)
%RUNM40MATLABPREPARATIONTESTS Validate M4.0 infrastructure without MATLAB.
    repositoryRoot=fileparts(fileparts(mfilename('fullpath')));
    if nargin<1,outputDirectory=fullfile(repositoryRoot,'.audit','m40-preparation');end
    addpath(fullfile(repositoryRoot,'test'));resetDirectory(outputDirectory);
    cases={ ...
      'MP1_runtime_metadata_sanitizer',@()sanitizerTest(); ...
      'MP2_fixture_registry_completeness',@()registryComplete(); ...
      'MP3_unique_fixture_ids',@()uniqueIds(); ...
      'MP4_validation_layers',@()layersPresent(); ...
      'MP5_comparator_exact',@()exactComparison(); ...
      'MP6_numeric_tolerances',@()toleranceComparison(); ...
      'MP7_expected_difference',@()expectedDifference(); ...
      'MP8_path_sanitization',@()pathSanitization(); ...
      'MP9_report_json_schema',@()reportJson(outputDirectory); ...
      'MP10_report_markdown',@()reportMarkdown(outputDirectory); ...
      'MP11_matlab_claim_release_scoped',@()releaseScopedTruth(repositoryRoot); ...
      'MP12_architecture_invariant',@()architecture(repositoryRoot)};
    rows=cell(size(cases,1),4);failures=0;
    for k=1:size(cases,1)
        try,detail=cases{k,2}();status='PASS';catch err,status='FAIL';failures=failures+1;detail=sprintf('%s: %s',identifierText(err.identifier),oneLine(err.message));end
        rows(k,:)={cases{k,1},status,detail,'matlab-preparation'};
    end
    resultPath=fullfile(outputDirectory,'preparation-results.tsv');writeRows(resultPath,rows);
    summary=struct('failures',failures,'tests',size(rows,1),'resultPath',resultPath);
    if failures>0,fprintf(2,'M4.0 preparation diagnostics from %s:\n%s',resultPath,fileread(resultPath));error('M2T:M40PreparationFailed','%d M4.0 tests failed.',failures);end
end

function detail=sanitizerTest()
    info=m2t_test.runtimeInfo();assert(any(strcmp(info.kind,{'matlab','octave'})));assert(~isfield(info,'license')&&~isfield(info,'hostname')&&~isfield(info,'username'));
    sanitized=m2t_test.sanitizeEvidence(struct('path',fullfile(pwd,'private','file')),{pwd});assert(~isempty(strfind(sanitized.path,'<machine-path>')));detail='runtime schema excludes identity/license data and sanitizes roots';
end
function detail=registryComplete()
    fixtures=m2t_test.fixtureRegistry();assert(numel(fixtures)==26);assert(strcmp(fixtures(1).id,'F01')&&strcmp(fixtures(end).id,'F26'));
    for k=1:numel(fixtures),fixture=m2t_test.buildFixture(fixtures(k).id);closeFigures(fixture.figures);end
    detail='F01-F26 registry entries construct without proprietary data';
end
function detail=uniqueIds(),fixtures=m2t_test.fixtureRegistry();ids={fixtures.id};assert(numel(unique(ids))==26);detail='26 unique fixture IDs';end
function detail=layersPresent(),layers=m2t_test.validationLayers();assert(isequal({layers.id},arrayfun(@(k)sprintf('L%d',k),0:11,'UniformOutput',false)));detail='L0-L11 and failure categories present';end
function detail=exactComparison(),result=m2t_test.compareSemantic(struct('x',[1 2],'text','a'),struct('x',[1 2],'text','a'));assert(result.equal&&strcmp(result.classification,'exact'));detail='exact values classify exact';end
function detail=toleranceComparison()
    closeResult=m2t_test.compareSemantic(struct('placement',1),struct('placement',1+5e-9));farResult=m2t_test.compareSemantic(struct('placement',1),struct('placement',1+2e-8));
    dataResult=m2t_test.compareSemantic(struct('xdata',1),struct('xdata',1+2e-12));assert(closeResult.equal&&~farResult.equal&&~dataResult.equal);detail='geometry 1e-8 and scientific-data 1e-12 tolerances are distinct';
end
function detail=expectedDifference(),result=m2t_test.compareSemantic(struct('runtimeClass','A'),struct('runtimeClass','B'),{'runtimeClass'});assert(result.equal&&strcmp(result.classification,'expected_runtime_difference'));detail='declared runtime representation difference is distinct from mismatch';end
function detail=pathSanitization(),value=m2t_test.sanitizeEvidence({fullfile(pwd,'x'),fullfile(tempdir,'y')},{pwd,tempdir});assert(all(cellfun(@(x)isempty(strfind(x,pwd)),value)));detail='workspace and temporary roots removed recursively';end
function detail=reportJson(root),paths=m2t_test.writeValidationReports(sampleReport(),fullfile(root,'report'));decoded=jsondecode(fileread(paths.json));assert(decoded.schemaVersion==1&&isfield(decoded,'runtime')&&isfield(decoded,'fixtures')&&isfield(decoded,'summary'));detail='schema-1 JSON contains runtime, environment, fixtures, layers, and summary';end
function detail=reportMarkdown(root),paths=m2t_test.writeValidationReports(sampleReport(),fullfile(root,'report-md'));text=fileread(paths.markdown);assertContains(text,'# MATLAB Validation');assertContains(text,'## Validation layers');assertContains(text,'## Fixtures');detail='human-readable report generated deterministically';end
function detail=releaseScopedTruth(root)
    text=fileread(fullfile(root,'docs','MATLAB_VALIDATION_MATRIX.md'));
    assertContains(text,'MATLAB R2026a Update 4 on Windows');
    assertContains(text,'does not validate older or newer MATLAB');
    assert(isempty(strfind(lower(text),'supports all matlab versions')));
    detail='MATLAB validation claim is exact-release and OS scoped';
end
function detail=architecture(root)
    package=fullfile(root,'test','+m2t_test');files=dir(fullfile(package,'*.m'));for k=1:numel(files),source=fileread(fullfile(package,files(k).name));assert(isempty(regexp(source,'(?i)license\s*\(|getenv\s*\(\s*''(username|computername)','once')));end
    readerFiles=dir(fullfile(root,'src','+m2t2','+reader','*.m'));for k=1:numel(readerFiles),assert(isempty(strfind(fileread(fullfile(readerFiles(k).folder,readerFiles(k).name)),'m2t_test')));end
    detail='test-only harness; no license/identity calls or product coupling';
end
function report=sampleReport()
    runtime=struct('kind','matlab','version','pending','release','','os','windows','architecture','win64','graphicsToolkit','','products',{{}});
    environment=struct('writableOutput',true,'writableTemp',true,'luaLatexAvailable',true,'pdfInfoAvailable',true,'pngAvailable',true,'pgfplotsValidatedByCompile',false,'failures',{{}});
    layers=m2t_test.validationLayers();for k=1:numel(layers),layers(k).status='pending';end
    fixture=struct('id','F01','name','line-basic','status','pending','failureCategory','','failureId','','message','','readerSuccess',false,'irDeterministic',false,'rendererDeterministic',false,'workflowSuccess',false,'compileSuccess',false,'repeatDeterministic',false,'pdfGeometryValid',false,'figureUnchanged',false,'irEvidence','F01/ir.json','workflowEvidence','','evidence','F01/');
    legacy=struct('status','pending','message','','evidence','legacy/');summary=struct('totalFixtures',1,'passed',0,'failed',0,'environmentFailures',0,'semanticMismatches',0);
    report=struct('schemaVersion',1,'runtime',runtime,'environment',environment,'fixtures',fixture,'layers',layers,'legacy',legacy,'summary',summary,'success',false);
end
function assertContains(text,pattern),assert(~isempty(strfind(text,pattern)));end %#ok<STREMP>
function closeFigures(figures),for k=1:numel(figures),if ishandle(figures(k)),close(figures(k));end,end,end
function resetDirectory(path),if exist(path,'dir')==7,rmdir(path,'s');end,mkdir(path);end
function value=oneLine(value),value=regexprep(value,'[\r\n\t]+',' ');end
function value=identifierText(value),if isempty(value),value='<none>';end,end
function writeRows(path,rows),fid=fopen(path,'wb');assert(fid>=0);cleanup=onCleanup(@()fclose(fid));fprintf(fid,'case\tstatus\tdetail\tlayer\n');for k=1:size(rows,1),fprintf(fid,'%s\t%s\t%s\t%s\n',rows{k,:});end;clear cleanup;end
