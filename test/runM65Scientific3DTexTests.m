function summary=runM65Scientific3DTexTests(outputDirectory)
%RUNM65SCIENTIFIC3DTEXTESTS Compile portable 3-D projections without handles.
    root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
    if nargin<1,outputDirectory=fullfile(root,'.audit','m65-tex');end
    paths=m2t.internal.normalizeOutputBase(fullfile(outputDirectory,'fixture'));outputDirectory=paths.directory;
    runM65Scientific3DIrTests(outputDirectory);
    names={'constant','rgb-size','scalar','depth','childorder','mesh','combination'};
    for k=1:numel(names)
        base=fullfile(outputDirectory,names{k});r=m2t.internal.compileLuaLatex([base '.tex'],[base '.pdf']);assert(r.success,['Compilation failed: ' names{k}]);
    end
    summary=struct('tests',numel(names),'failures',0);fprintf('M65_PORTABLE_TEX_PASS: %d/%d\n',numel(names),numel(names));
end
