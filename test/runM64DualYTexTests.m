function summary=runM64DualYTexTests(outputDirectory)
%RUNM64DUALYTEXTESTS Real compilation of independent-coordinate fixtures.
    root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
    if nargin<1,outputDirectory=fullfile(root,'.audit','m64-dual-tex');end
    paths=m2t.internal.normalizeOutputBase(fullfile(outputDirectory,'fixture'));outputDirectory=paths.directory;
    runM64DualYIrTests(outputDirectory);
    names={'dual','single-column','double-column','right-log','both-log','scatter-roles'};
    for k=1:numel(names)
        base=fullfile(outputDirectory,names{k});r=m2t.internal.compileLuaLatex([base '.tex'],[base '.pdf']);
        assert(r.success,['Compilation failed: ' names{k}]);
    end
    summary=struct('tests',numel(names),'failures',0,'outputDirectory',outputDirectory);
    fprintf('M64_PORTABLE_TEX_PASS: %d/%d\n',numel(names),numel(names));
end
