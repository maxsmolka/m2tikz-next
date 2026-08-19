function outputPath = example_line(outputPath)
%EXAMPLE_LINE Export a deterministic standalone line plot.
    if nargin < 1, outputPath = ''; end
    [root, outputPath] = paths(mfilename('fullpath'), outputPath, '01-line.tex');
    addpath(fullfile(root, 'src')); ensureParent(outputPath);
    fig = figure('Visible', 'off'); cleanup = onCleanup(@() close(fig));
    x = linspace(0, 2*pi, 200); plot(x, sin(x), 'LineWidth', 1.2);
    xlabel('x'); ylabel('sin(x)'); title('Sine wave'); grid on;
    m2t2.export(fig, outputPath, true); clear cleanup;
end

function [root, outputPath] = paths(source, outputPath, name)
    root = fileparts(fileparts(fileparts(source)));
    if nargin < 2 || isempty(outputPath), outputPath = fullfile(root, '.audit', 'public-preview', 'examples', name); end
end
function ensureParent(path), folder=fileparts(path);if exist(folder,'dir')~=7,mkdir(folder);end,end
