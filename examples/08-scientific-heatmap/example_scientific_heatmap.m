function result = example_scientific_heatmap(outputDirectory)
%EXAMPLE_SCIENTIFIC_HEATMAP Export a scalar Gaussian-residual field.
    repositoryRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    if nargin < 1 || isempty(outputDirectory)
        outputDirectory = fullfile(repositoryRoot, '.audit', ...
                                   'public-preview', 'examples', ...
                                   '08-scientific-heatmap');
    end
    addpath(fullfile(repositoryRoot, 'src'));
    if exist(outputDirectory, 'dir') ~= 7, mkdir(outputDirectory); end

    x = linspace(-2.5, 2.5, 31);
    y = linspace(-1.5, 1.5, 25);
    [X, Y] = meshgrid(x, y);
    field = exp(-(X .^ 2 + 1.8 * Y .^ 2)) - ...
            0.35 * exp(-((X - 1.2) .^ 2 + 3 * (Y + 0.25) .^ 2));

    fig = figure('Visible', 'off'); cleanup = onCleanup(@() close(fig));
    ax = axes('Parent', fig);
    imagesc(ax, x, y, field); set(ax, 'YDir', 'normal');
    set(ax, 'CLim', [-0.3 1]);
    colormap(ax, [0.08 0.20 0.48; 0.22 0.62 0.72; 0.96 0.94 0.72; 0.65 0.12 0.12]);
    xlabel(ax, 'Position x'); ylabel(ax, 'Position y'); title(ax, 'Residual field');
    cb = colorbar(ax); ylabel(cb, 'Normalized residual');

    result = m2t.export(fig, fullfile(outputDirectory, 'scientific-heatmap'), ...
                        'Profile', 'publication', ...
                        'Width', 'single-column', 'Overwrite', true);
    if ~result.success
        error('M2T:ExampleFailed', 'Scientific heatmap export failed: %s', ...
              result.diagnostics(1).message);
    end
    clear cleanup;
end
