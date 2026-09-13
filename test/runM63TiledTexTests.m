function summary=runM63TiledTexTests(outputDirectory)
%RUNM63TILEDTEXTESTS Compile portable fixed-grid and 85/170 mm profile fixtures.
    root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
    if nargin<1,outputDirectory=fullfile(root,'.audit','m63-tiled-tex');end
    paths=m2t.internal.normalizeOutputBase(fullfile(outputDirectory,'fixture'));
    outputDirectory=paths.directory;
    runM63TiledIrTests(outputDirectory);
    names={'fixed-grid','single-column','double-column'};
    for k=1:numel(names)
        base=fullfile(outputDirectory,names{k});
        r=m2t.internal.compileLuaLatex([base '.tex'],[base '.pdf']);assert(r.success);
    end
    summary=struct('tests',3,'failures',0,'outputDirectory',outputDirectory);
    m2t.internal.writeTextFile(fullfile(outputDirectory,'tiled-tex-results.tsv'),sprintf( ...
        'case\tstatus\nfixed_grid\tPASS\nprofile_85\tPASS\nprofile_170\tPASS\n'));
end
