function summary=runM71FigureIrTexTests(outputDirectory)
%RUNM71FIGUREIRTEXTESTS Compile the nine stored compatibility classes.
    root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
    if nargin<1,outputDirectory=fullfile(root,'.audit','m71-tex');end
    runM71FigureIrContractTests(outputDirectory);
    files=dir(fullfile(outputDirectory,'*.json'));
    for k=1:numel(files)
        ir=m2t2.ir.fromJson(fileread(fullfile(outputDirectory,files(k).name)));
        [~,name]=fileparts(files(k).name);assetName=[name '-assets'];
        plan=m2t2.render.makePgfplotsPlan(ir,true,m2t2.render.defaultConfig(),'hybrid',assetName);
        folder=fullfile(outputDirectory,assetName);if exist(folder,'dir')~=7,mkdir(folder);end
        for j=1:numel(plan.assets),m2t2.render.writePngAsset(plan.assets(j),fullfile(folder,plan.assets(j).filename));end
        tex=fullfile(outputDirectory,[name '.tex']);pdf=fullfile(outputDirectory,[name '.pdf']);
        m2t.internal.writeTextFile(tex,plan.tex);r=m2t.internal.compileLuaLatex(tex,pdf,'lualatex');
        assert(r.success,['M7.1 compile failed: ' name]);r=m2t.internal.validatePdf(pdf);assert(r.success);
    end
    assert(numel(files)==9);summary=struct('tests',numel(files),'failures',0);fprintf('M71_IR_TEX_PASS: 9/9\n');
end
