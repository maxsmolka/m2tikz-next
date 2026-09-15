function summary=runM65Scientific3DWorkflowTests(outputDirectory)
%RUNM65SCIENTIFIC3DWORKFLOWTESTS Native profiles/set with real TeX compiler.
    assert(~exist('OCTAVE_VERSION','builtin'),'Native MATLAB required.');
    root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
    if nargin<1,outputDirectory=fullfile(root,'.audit','m65-workflow');end
    f=figure('Visible','off','Color','w');cleanup=onCleanup(@()close(f));a=axes(f);
    scatter3(a,[-.8 0 .8],[.4 -.4 .6],[-.5 .5 0],[64 144 256],[0;.5;1],'filled');
    view(a,30,25);daspect(a,[1 1 1]);xlabel(a,'X');ylabel(a,'Y');zlabel(a,'Z');colorbar(a);drawnow;
    for width={'single-column','double-column'}
        r=m2t.export(f,fullfile(outputDirectory,width{1}),'Profile','publication','Width',width{1},'Overwrite',true);
        assert(r.success,['Public 3-D export failed: ' jsonencode(r.diagnostics)]);
    end
    entries=struct('figure',f,'name','scientific-3d');
    first=m2t.exportSet(entries,fullfile(outputDirectory,'set'),'Profile','publication','Overwrite',true);assert(first.success);
    manifest=fileread(first.manifestPath);
    second=m2t.exportSet(entries,fullfile(outputDirectory,'set'),'Profile','publication','Overwrite',true);
    assert(second.success&&strcmp(manifest,fileread(second.manifestPath)));
    summary=struct('tests',4,'failures',0);fprintf('M65_NATIVE_WORKFLOW_PASS: 4/4\n');clear cleanup;
end
