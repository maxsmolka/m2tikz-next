function outputPath = example_multiple_axes(outputPath)
%EXAMPLE_MULTIPLE_AXES Export a two-panel layout.
    if nargin < 1, outputPath = ''; end
    [root, outputPath] = paths(mfilename('fullpath'), outputPath, '04-multiple-axes.tex');
    addpath(fullfile(root, 'src')); ensureParent(outputPath);
    fig=figure('Visible','off','PaperUnits','points','PaperPosition',[0 0 432 324]);cleanup=onCleanup(@()close(fig));
    first=subplot(1,2,1,'Parent',fig);plot(first,0:3,[0 1 4 9]);title(first,'Quadratic');
    second=subplot(1,2,2,'Parent',fig);semilogy(second,1:3,[1 10 100]);title(second,'Log scale');
    m2t2.export(fig, outputPath, true); clear cleanup;
end

function [root, outputPath] = paths(source, outputPath, name)
    root=fileparts(fileparts(fileparts(source)));
    if nargin<2||isempty(outputPath),outputPath=fullfile(root,'.audit','public-preview','examples',name);end
end
function ensureParent(path),folder=fileparts(path);if exist(folder,'dir')~=7,mkdir(folder);end,end
