function summary=runM68DeterminismWorkflowTests(outputDirectory)
%RUNM68DETERMINISMWORKFLOWTESTS Real repeated and cross-root public products.
    root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
    if nargin<1,outputDirectory=fullfile(root,'.audit','m68-workflow');end
    if exist(outputDirectory,'dir')~=7,mkdir(outputDirectory);end
    figures={};cleanup=onCleanup(@()closeOwned(figures)); %#ok<NASGU>
    f=figure('Visible','off','Color','w');figures{end+1}=f;a=axes('Parent',f);
    rgb=cat(3,[0 1;1 0],[1 0;0 1],[0 .5;.5 0]);h=image('Parent',a,'CData',rgb);set(h,'AlphaData',[1 .5;.25 0]);set(a,'Color','w');
    entries=struct('figure',f,'name','image');
    f=figure('Visible','off','Color','w');figures{end+1}=f;a=axes('Parent',f);plot(a,[0 0 1 2],[1 1 2 0]);set(a,'Color','w');entries(end+1)=struct('figure',f,'name','line');
    if ~exist('OCTAVE_VERSION','builtin')
        f=figure('Visible','off','Color','w');figures{end+1}=f;t=tiledlayout(f,1,2);
        a=nexttile(t,1);plot(a,1:3,[1 3 2]);set(a,'Color','w');a=nexttile(t,2);scatter(a,1:3,[2 1 3],[16 25 36],[1 0 0;0 1 0;0 0 1],'filled');set(a,'Color','w');title(t,'Fixed cells');entries(end+1)=struct('figure',f,'name','tiled');
        f=figure('Visible','off','Color','w');figures{end+1}=f;a=axes('Parent',f);yyaxis(a,'left');plot(a,1:3,[1 3 2]);yyaxis(a,'right');plot(a,1:3,[100 200 150]);set(a,'Color','w');entries(end+1)=struct('figure',f,'name','dual');
        f=figure('Visible','off','Color','w');figures{end+1}=f;a=axes('Parent',f);scatter3(a,[0 0 1],[0 0 1],[0 0 .5],36,[1 0 0;0 1 0;0 0 1],'filled');view(a,30,25);set(a,'Color','w');entries(end+1)=struct('figure',f,'name','three-d');
    end
    % Capture cleanup only after the owned list is complete (anonymous closures
    % capture values, not subsequent cell-array assignments).
    clear cleanup;cleanup=onCleanup(@()closeOwned(figures)); %#ok<NASGU>
    before=cellfun(@(f)jsonencode(m2t2.reader.readFigure(f)),figures,'UniformOutput',false);
    roots={fullfile(outputDirectory,'first-root'),fullfile(outputDirectory,'second-root')};
    first=m2t.exportSet(entries,roots{1},'ImageBackend','auto','Overwrite',true);assert(first.success);products=snapshot(first);
    second=m2t.exportSet(entries,roots{1},'ImageBackend','auto','Overwrite',true);assert(second.success);assert(isequal(products,snapshot(second)));
    third=m2t.exportSet(entries,roots{2},'ImageBackend','auto','Overwrite',true);assert(third.success);assert(isequal(products,snapshot(third)));
    manifest=fileread(third.manifestPath);parsed=jsondecode(manifest);
    assert(isequal(reshape({parsed.figures.name},1,[]),reshape({entries.name},1,[])));
    for k=1:numel(roots),assert(isempty(strfind(manifest,roots{k})));end
    assert(isempty(regexp(manifest,'"(?:timestamp|timings|uuid|outputDirectory|message)"','once')));
    for k=1:numel(figures),assert(strcmp(before{k},jsonencode(m2t2.reader.readFigure(figures{k}))));end
    % Failed/skipped manifest records also contain only stable relative metadata.
    bad=figure('Visible','off','Color','w');badCleanup=onCleanup(@()close(bad));a=axes('Parent',bad,'Color','w');hggroup('Parent',a);
    failures=[struct('figure',bad,'name','unsupported'),entries(1)];
    r1=m2t.exportSet(failures,fullfile(outputDirectory,'failed-first'),'ContinueOnError',false,'Overwrite',true);
    r2=m2t.exportSet(failures,fullfile(outputDirectory,'failed-second'),'ContinueOnError',false,'Overwrite',true);
    assert(~r1.success&&~r2.success&&r1.summary.unsupported==1&&r1.summary.skipped==1);
    assert(strcmp(fileread(r1.manifestPath),fileread(r2.manifestPath)));
    assert(isequal(r1.entries(1).result.diagnostics,r2.entries(1).result.diagnostics));clear badCleanup;
    summary=struct('tests',5,'failures',0,'figures',numel(entries));
    m2t.internal.writeTextFile(fullfile(outputDirectory,'m68-workflow-results.tsv'),sprintf( ...
        'case\tstatus\nsame_root\tPASS\ncross_root\tPASS\nmanifest_order\tPASS\nsource_unchanged\tPASS\nfailed_manifest\tPASS\n'));
    fprintf('M68_REAL_DETERMINISM_PASS: 5/5 figures=%d\n',numel(entries));
end
function products=snapshot(result)
    products={bytes(result.manifestPath)};
    for k=1:numel(result.entries)
        r=result.entries(k).result;assert(r.success&&exist(r.pdfPath,'file')==2);products{end+1}=bytes(r.texPath); %#ok<AGROW>
        for j=1:numel(r.render.assets),products{end+1}=bytes(r.render.assets{j});end %#ok<AGROW>
    end
end
function value=bytes(path),f=fopen(path,'rb');assert(f>=0);c=onCleanup(@()fclose(f));value=fread(f,Inf,'*uint8').';clear c;end
function closeOwned(figures),for k=1:numel(figures),if ishandle(figures{k}),close(figures{k});end,end,end
