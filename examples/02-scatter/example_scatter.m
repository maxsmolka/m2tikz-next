function outputPath = example_scatter(outputPath)
%EXAMPLE_SCATTER Export constant-style sample observations.
    if nargin < 1, outputPath = ''; end
    [root, outputPath] = paths(mfilename('fullpath'), outputPath, '02-scatter.tex');
    addpath(fullfile(root, 'src')); ensureParent(outputPath);
    fig = figure('Visible', 'off'); cleanup = onCleanup(@() close(fig));
    scatter(1:6, [2 1 4 3 5 4], 49, [0.8 0.1 0.2], 'o', 'DisplayName', 'Samples');
    xlabel('sample'); ylabel('value'); title('Scatter observations'); legend('show');
    m2t2.export(fig, outputPath, true); clear cleanup;
end

function [root, outputPath] = paths(source, outputPath, name)
    root=fileparts(fileparts(fileparts(source)));
    if nargin<2||isempty(outputPath),outputPath=fullfile(root,'.audit','public-preview','examples',name);end
end
function ensureParent(path),folder=fileparts(path);if exist(folder,'dir')~=7,mkdir(folder);end,end
