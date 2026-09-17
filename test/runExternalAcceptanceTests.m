function summary=runExternalAcceptanceTests(outputDirectory,compile)
%RUNEXTERNALACCEPTANCETESTS Synthetic-only tests of the optional local utility.
    root=fileparts(fileparts(mfilename('fullpath')));
    addpath(fullfile(root,'src'));addpath(fullfile(root,'validation','external-acceptance'));
    if nargin<1,outputDirectory=fullfile(root,'.audit','external-package-tests');end
    if nargin<2,compile=false;end
    if exist(outputDirectory,'dir')~=7,mkdir(outputDirectory);end
    [~,token]=fileparts(tempname);token=lower(regexprep(token,'[^a-zA-Z0-9]',''));
    token=token(max(1,end-15):end);
    session=['session-test-' token];revision=repmat('a',1,40);
    f=figure('Visible','off','Color','w');cleanup=onCleanup(@()close(f)); %#ok<NASGU>
    a=axes('Parent',f,'Color','w','XColor','k','YColor','k');
    line('Parent',a,'XData',[0 1 2],'YData',[1 0 1],'Color','k', ...
        'DisplayName','SYNTHETIC_SOURCE_LABEL_NOT_IN_REPORT');
    title(a,'Acceptance','Interpreter','none','Color','k');
    entry=struct('id','case-001','figure',f);
    expect(@()runExternalAcceptance(entry,'../escape',revision,'synthetic'));
    expect(@()runExternalAcceptance(entry,session,'ACTUAL_COMMIT_HASH','synthetic'));
    expect(@()runExternalAcceptance([entry entry],session,revision,'synthetic'));
    bad=entry;bad.id='../other';expect(@()runExternalAcceptance(bad,session,revision,'synthetic'));
    bad=entry;bad.sourceData=42;expect(@()runExternalAcceptance(bad,session,revision,'synthetic'));
    expect(@()runExternalAcceptance(entry,session,revision,'synthetic','Overwrite',true));
    expect(@()runExternalAcceptance(entry,session,revision,'synthetic','ImageBackend','bad'));
    expect(@()runExternalAcceptance(entry,session,revision,'synthetic','Profile',struct('sourceData',42)));
    expect(@()runExternalAcceptance(entry,session,revision,'synthetic','Width',[1 2 3]));
    assert(exist(fullfile(root,'.audit','external-acceptance',session),'file')==0);
    % Documented unsupported source remains NEEDS_REVIEW until a human checks it.
    set(a,'Color',[.8 .8 .8]);before=get(a,'Color');
    [r,p]=runExternalAcceptance(entry,session,revision,'not available');
    row=r.cases{1};assert(strcmp(row.outcome,'NEEDS_REVIEW'));
    assert(~row.exportSuccess&&~row.compileSuccess&&strcmp(row.workflowStatus,'unsupported'));
    assert(strcmp(row.visualSemanticResult,'NOT_REVIEWED')&&~isempty(row.diagnosticCodes));
    assert(ishghandle(f)&&isequal(get(a,'Color'),before));
    raw=fileread(p);assert(isempty(strfind(raw,'SYNTHETIC_SOURCE_LABEL'))); %#ok<STREMP>
    assert(isempty(strfind(raw,'Acceptance'))); %#ok<STREMP>
    assert(isempty(strfind(raw,root))&&isempty(strfind(raw,'texPath'))); %#ok<STREMP>
    decoded=jsondecode(raw);assert(decoded.schemaVersion==1&&strcmp(decoded.revision,revision));
    assert(numel(decoded.outcomeVocabulary)==6&&strcmp(decoded.runtimeVersion,version));
    expect(@()runExternalAcceptance(entry,session,revision,'not available'));
    assert(strcmp(raw,fileread(p)),'Existing evidence was overwritten.');
    set(a,'Color','w');
    missing=withoutCompiler(entry,[session '-missing'],revision,outputDirectory);
    assert(missing.cases{1}.exportSuccess&&~missing.cases{1}.compileSuccess);
    assert(strcmp(missing.cases{1}.outcome,'FAIL_ENVIRONMENT'));
    assert(any(strcmp(missing.cases{1}.diagnosticCodes,'M2T:C001:CompilerNotFound')));
    tests=12;
    if compile
        [r,p]=runExternalAcceptance(entry,[session '-compiled'],revision,'synthetic test compiler', ...
            'Profile','publication','Width','single-column','ImageBackend','auto');
        row=r.cases{1};assert(row.exportSuccess&&row.compileSuccess&&strcmp(row.workflowStatus,'success'));
        assert(strcmp(row.outcome,'NEEDS_REVIEW')&&strcmp(row.visualSemanticResult,'NOT_REVIEWED'));
        assert(strcmp(r.profile,'publication')&&strcmp(r.imageBackend,'auto'));
        validation=m2t.internal.validatePdf(fullfile(fileparts(p),'case-001.pdf'));assert(validation.success);
        assert(ishghandle(f)&&isequal(get(a,'Color'),[1 1 1]));
        assert(row.timingsSeconds.compile>0&&row.timingsSeconds.export>0);tests=13;
        m2t.internal.writeTextFile(fullfile(outputDirectory,'compiled-session.txt'),fileparts(p));
    end
    summary=struct('tests',tests,'failures',0);
    m2t.internal.writeTextFile(fullfile(outputDirectory,'summary.json'),jsonencode(summary));
    fprintf('EXTERNAL_ACCEPTANCE_PACKAGE_PASS: %d/%d compile=%d\n',tests,tests,compile);
end

function r=withoutCompiler(entry,session,revision,directory)
    previous=getenv('PATH');cleanup=onCleanup(@()setenv('PATH',previous)); %#ok<NASGU>
    setenv('PATH',directory);
    r=runExternalAcceptance(entry,session,revision,'not available');
end

function expect(action)
    failed=false;try,action();catch,failed=true;end
    assert(failed,'Expected input rejection.');
end
