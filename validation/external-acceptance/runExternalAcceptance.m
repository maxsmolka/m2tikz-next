function [report, reportPath] = runExternalAcceptance(cases, sessionId, revision, texVersion, varargin)
%RUNEXTERNALACCEPTANCE Local-only acceptance utility, not a new m2t API.
% Explicit cases have exactly id ('case-001', etc.) and figure fields.
% texVersion is a manually checked short version line, or 'not available'.
% Only Profile, Width and ImageBackend options are forwarded to m2t.export.
% Review the local report manually: successful compilation is NOT a PASS.
    root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
    addpath(fullfile(root,'src'));
    sessionId=checkedText(sessionId,40);
    revision=checkedText(revision,64);
    texVersion=checkedText(texVersion,200);
    require(~isempty(regexp(sessionId,'^session-[a-z0-9][a-z0-9-]*$','once')),'Use a neutral session-ID.');
    require(~isempty(regexp(revision,'^([0-9a-fA-F]{7,40}|v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?)$','once')), ...
        'Supply the actual tested commit hash or version tag.');
    require(isstruct(cases)&&~isempty(cases)&&isvector(cases),'Supply explicit figure cases.');
    require(isequal(sort(fieldnames(cases)),sort({'id';'figure'})),'Cases require exactly id and figure.');
    ids=cell(1,numel(cases));
    for k=1:numel(cases)
        ids{k}=checkedText(cases(k).id,8);
        require(~isempty(regexp(ids{k},'^case-[0-9]{3}$','once')),'Use neutral case-001 style IDs.');
        f=cases(k).figure;
        require(isscalar(f)&&ishghandle(f)&&strcmp(get(f,'Type'),'figure'),'Supply live figure handles.');
    end
    require(numel(unique(ids))==numel(ids),'Case IDs must be unique.');
    require(mod(numel(varargin),2)==0,'Options must be name/value pairs.');
    for k=1:2:numel(varargin)
        name=checkedText(varargin{k},20);
        require(any(strcmpi(name,{'Profile','Width','ImageBackend'})), ...
            'Only Profile, Width and ImageBackend are allowed; overwrite is disabled.');
    end
    % Validate before creating any output; retain the public workflow defaults.
    options=m2t.internal.parseExportOptions(varargin{:});
    selection=m2t.profile.getSelection(options.profile,options.width);
    directory=fullfile(root,'.audit','external-acceptance',sessionId);
    require(exist(directory,'file')==0,'Session exists; choose a new neutral session ID.');
    [ok,~]=mkdir(directory);require(ok,'Could not create the local session directory.');
    reportPath=fullfile(directory,'results.json');
    if exist('OCTAVE_VERSION','builtin'),runtime='GNU Octave';else,runtime='MATLAB';end
    if ispc,os='Windows';elseif ismac,os='macOS';else,os='Unix/Linux';end
    report=struct('schemaVersion',1,'sessionId',sessionId, ...
        'runtime',runtime,'runtimeVersion',version,'os',os,'architecture',computer, ...
        'revision',revision,'texVersion',texVersion, ...
        'profile',selection.profileName,'width',selection.widthName,'imageBackend',options.imageBackend, ...
        'outcomeVocabulary',{{'PASS','PASS_WITH_VISUAL_DIFFERENCE','UNSUPPORTED_EXPECTED', ...
        'FAIL_PRODUCT','FAIL_ENVIRONMENT','NEEDS_REVIEW'}},'cases',{{}});
    writeReport(reportPath,report);
    for k=1:numel(cases)
        r=m2t.export(cases(k).figure,fullfile(directory,ids{k}),varargin{:},'Overwrite',false);
        codes=cell(1,numel(r.diagnostics));
        for j=1:numel(codes)
            code=r.diagnostics(j).code;
            if isempty(regexp(code,'^[A-Za-z0-9_:.-]+$','once')),code='UNRECOGNIZED_DIAGNOSTIC';end
            codes{j}=code;
        end
        outcome='NEEDS_REVIEW';
        if any(strcmp(codes,'M2T:C001:CompilerNotFound')),outcome='FAIL_ENVIRONMENT';end
        row=struct('id',ids{k},'exportSuccess',any(strcmp(r.status, ...
            {'success','compile_failed','validation_failed'})), ...
            'compileSuccess',any(strcmp(r.status,{'success','validation_failed'})), ...
            'workflowStatus',r.status,'outcome',outcome,'visualSemanticResult','NOT_REVIEWED', ...
            'diagnosticCodes',{codes},'timingsSeconds',r.timings,'note','');
        report.cases{end+1}=row;
        writeReport(reportPath,report);
    end
end

function value=checkedText(value,limit)
    if isa(value,'string')&&isscalar(value)&&~ismissing(value),value=char(value);end
    require(ischar(value)&&isrow(value)&&~isempty(value)&&numel(value)<=limit ...
        &&all(double(value)>=32)&&all(double(value)~=127),'Invalid short text value.');
end

function require(condition,message)
    if ~condition,error('M2T_ACCEPTANCE:InvalidInput','%s',message);end
end

function writeReport(path,report)
    % Deliberately omit figures, IR, labels, data arrays, paths and raw messages.
    m2t.internal.writeTextFile(path,[jsonencode(report) sprintf('\n')]);
end
