function outputPath = example_rich_scatter(outputPath)
%EXAMPLE_RICH_SCATTER Export varying marker area with scalar color metadata.
    if nargin < 1
        root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
        outputPath = fullfile(root, '.audit', 'public-preview', 'examples', ...
            '11-rich-scatter.tex');
    end
    root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    addpath(fullfile(root, 'src'));
    x = linspace(0, 2*pi, 12);
    response = sin(x) .* exp(-0.12*x);
    markerArea = linspace(24, 144, numel(x));
    scalarValue = reshape(cos(x), [], 1);
    fig = figure('Visible', 'off'); cleanup = onCleanup(@() close(fig));
    ax = axes('Parent', fig);
    scatter(ax, x, response, markerArea, scalarValue, 'filled', ...
        'MarkerEdgeColor', [0.15 0.15 0.15], ...
        'DisplayName', 'Synthetic response');
    caxis(ax, [-1 1]); colormap(ax, scientificMap(32)); colorbar(ax);
    xlabel(ax, 'Phase'); ylabel(ax, 'Response');
    title(ax, 'Rich scatter: marker area and scalar color');
    [folder, name, extension] = fileparts(outputPath);
    outputBase = outputPath;
    if strcmpi(extension, '.tex'), outputBase = fullfile(folder, name); end
    result = m2t.export(fig, outputBase, 'Overwrite', true);
    if ~result.success, error(result.diagnostics(1).code, '%s', result.diagnostics(1).message); end
    outputPath = result.texPath;
    clear cleanup;
end

function map = scientificMap(count)
    t = linspace(0, 1, count)';
    map = [0.12 + 0.78*t, 0.18 + 0.62*sin(pi*t), 0.82 - 0.70*t];
end
