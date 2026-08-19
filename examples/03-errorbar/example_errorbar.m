function outputPath = example_errorbar(outputPath)
%EXAMPLE_ERRORBAR Export asymmetric measurement uncertainty.
    if nargin < 1, outputPath = ''; end
    [root, outputPath] = paths(mfilename('fullpath'), outputPath, '03-errorbar.tex');
    addpath(fullfile(root, 'src')); ensureParent(outputPath);
    fig = figure('Visible', 'off'); cleanup = onCleanup(@() close(fig));
    item=errorbar(1:5,[2 3 2.5 4 3.5],[0.1 0.2 0.15 0.25 0.2],[0.3 0.2 0.25 0.2 0.3]);
    set(item,'DisplayName','Measurement');xlabel('sample');ylabel('value');legend('show');grid on;
    m2t2.export(fig, outputPath, true); clear cleanup;
end

function [root, outputPath] = paths(source, outputPath, name)
    root=fileparts(fileparts(fileparts(source)));
    if nargin<2||isempty(outputPath),outputPath=fullfile(root,'.audit','public-preview','examples',name);end
end
function ensureParent(path),folder=fileparts(path);if exist(folder,'dir')~=7,mkdir(folder);end,end
