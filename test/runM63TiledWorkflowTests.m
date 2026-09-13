function summary=runM63TiledWorkflowTests(outputDirectory)
%RUNM63TILEDWORKFLOWTESTS Native figure and figure-set integration with real TeX.
    assert(~exist('OCTAVE_VERSION','builtin'),'Native MATLAB tiled layout is required.');
    root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
    if nargin<1,outputDirectory=fullfile(root,'.audit','m63-tiled-workflow');end
    if exist(outputDirectory,'dir')~=7,mkdir(outputDirectory);end
    f1=figure('Visible','off','Color','w');f2=figure('Visible','off','Color','w');
    cleanup=onCleanup(@()close([f1 f2]));
    t=tiledlayout(f1,1,2,'TileSpacing','compact','Padding','compact');
    plot(nexttile(t),1:3,'DisplayName','wave');title(t,'Shared title');
    imagesc(nexttile(t),[1 2;3 4]);
    t2=tiledlayout(f2,2,2);plot(nexttile(t2,1,[2 1]),1:3);plot(nexttile(t2,2),3:-1:1);
    one=m2t.export(f1,fullfile(outputDirectory,'single'),'Profile','publication','Overwrite',true);
    assert(one.success&&exist(one.pdfPath,'file')==2);
    entries=struct('figure',{f1,f2},'name',{'fixed','span'});
    setResult=m2t.exportSet(entries,fullfile(outputDirectory,'set'),'Profile','publication', ...
        'Width','double-column','Overwrite',true);
    assert(setResult.success&&exist(setResult.manifestPath,'file')==2);
    first=fileread(setResult.manifestPath);
    repeat=m2t.exportSet(entries,fullfile(outputDirectory,'set'),'Profile','publication', ...
        'Width','double-column','Overwrite',true);
    assert(repeat.success&&strcmp(first,fileread(repeat.manifestPath)));
    summary=struct('tests',3,'failures',0,'outputDirectory',outputDirectory);
    m2t.internal.writeTextFile(fullfile(outputDirectory,'workflow-results.tsv'),sprintf( ...
        'case\tstatus\nsingle_export\tPASS\nfigure_set\tPASS\nrepeated_manifest\tPASS\n'));
    fprintf('M63_NATIVE_WORKFLOW_PASS: 3/3\n');clear cleanup;
end
