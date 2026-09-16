function summary=runM64DualYWorkflowTests(outputDirectory)
%RUNM64DUALYWORKFLOWTESTS Native public exports with real LuaLaTeX required.
    assert(~exist('OCTAVE_VERSION','builtin'),'Native MATLAB required.');
    root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
    if nargin<1,outputDirectory=fullfile(root,'.audit','m64-dual-workflow');end
    f=figure('Visible','off','Color','w');cleanup=onCleanup(@()close(f));
    a=axes(f);yyaxis(a,'left');plot(a,1:3,[1 4 2],'DisplayName','Left');ylabel(a,'Left');
    yyaxis(a,'right');scatter(a,1:3,[10 100 1000],36,[0;.5;1],'filled','DisplayName','Right');ylabel(a,'Right');
    set(a,'YScale','log','Color','w');xlabel(a,'Time');colorbar(a);drawnow;
    for width={'single-column','double-column'}
        r=m2t.export(f,fullfile(outputDirectory,width{1}),'Profile','publication','Width',width{1},'Overwrite',true);
        assert(r.success,['Public dual-Y export failed: ' jsonencode(r.diagnostics)]);
        assert(exist(r.pdfPath,'file')==2&&strcmp(a.YAxisLocation,'right'));
    end
    entries=struct('figure',f,'name','dual');
    first=m2t.exportSet(entries,fullfile(outputDirectory,'set'),'Profile','publication','Overwrite',true);
    assert(first.success);manifest=fileread(first.manifestPath);
    second=m2t.exportSet(entries,fullfile(outputDirectory,'set'),'Profile','publication','Overwrite',true);
    assert(second.success&&strcmp(manifest,fileread(second.manifestPath)));
    summary=struct('tests',4,'failures',0,'outputDirectory',outputDirectory);
    m2t.internal.writeTextFile(fullfile(outputDirectory,'dual-workflow-results.tsv'),sprintf( ...
        'case\tstatus\nprofile_85_colorbar\tPASS\nprofile_170_colorbar\tPASS\nfigure_set\tPASS\nrepeat_manifest\tPASS\n'));
    fprintf('M64_NATIVE_WORKFLOW_PASS: 4/4\n');clear cleanup;
end
