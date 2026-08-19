function outputPath = example_colorbar(outputPath)
%EXAMPLE_COLORBAR Export an axes-owned colorbar foundation example.
    if nargin < 1, outputPath = ''; end
    [root, outputPath] = paths(mfilename('fullpath'), outputPath, '05-colorbar.tex');
    addpath(fullfile(root, 'src')); ensureParent(outputPath);
    fig=figure('Visible','off','PaperUnits','points','PaperPosition',[0 0 432 324]);cleanup=onCleanup(@()close(fig));
    ax=axes('Parent',fig);imagesc(ax,[1 2;3 4]);cb=colorbar(ax,'eastoutside');ylabel(cb,'Intensity');
    title(ax,'Color mapping');m2t2.export(fig,outputPath,true);clear cleanup;
end

function [root, outputPath] = paths(source, outputPath, name)
    root=fileparts(fileparts(fileparts(source)));
    if nargin<2||isempty(outputPath),outputPath=fullfile(root,'.audit','public-preview','examples',name);end
end
function ensureParent(path),folder=fileparts(path);if exist(folder,'dir')~=7,mkdir(folder);end,end
