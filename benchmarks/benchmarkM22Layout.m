function rows = benchmarkM22Layout(outputDirectory, pointsPerAxes)
%BENCHMARKM22LAYOUT Measure linear 1/2/4-axes reader and renderer scaling.
    root = fileparts(fileparts(mfilename('fullpath'))); addpath(fullfile(root, 'src'));
    if nargin < 1, outputDirectory = fullfile(root, 'benchmarks', 'output', 'm2.2-layout'); end
    if nargin < 2, pointsPerAxes = 1000; end
    if exist(outputDirectory, 'dir') ~= 7, mkdir(outputDirectory); end
    texDirectory = fullfile(outputDirectory, 'tex');
    if exist(texDirectory, 'dir') ~= 7, mkdir(texDirectory); end
    counts = [1 2 4]; rows = cell(numel(counts), 7);
    for k = 1:numel(counts)
        fig = makeFigure(counts(k), pointsPerAxes);
        timer = tic; ir = m2t2.reader.readFigure(fig); readerSeconds = toc(timer);
        timer = tic; text = m2t2.render.renderPgfplots(ir, true); rendererSeconds = toc(timer);
        path = fullfile(texDirectory, sprintf('axes-%d.tex', counts(k)));
        fid = fopen(path, 'w'); cleanup = onCleanup(@() fclose(fid));
        fwrite(fid, text, 'char'); clear cleanup; close(fig);
        rows(k, :) = {counts(k), counts(k) * pointsPerAxes, readerSeconds, ...
                      rendererSeconds, readerSeconds + rendererSeconds, numel(text), path};
    end
    path = fullfile(outputDirectory, 'layout-performance-raw.tsv');
    fid = fopen(path, 'w'); cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, 'axes\ttotal_points\treader_s\trenderer_s\ttotal_s\ttex_bytes\ttex_path\n');
    for k = 1:size(rows,1)
        fprintf(fid, '%d\t%d\t%.9f\t%.9f\t%.9f\t%d\t%s\n', rows{k,:});
    end
end

function fig = makeFigure(axesCount, pointsPerAxes)
    fig = figure('Visible', 'off');
    set(fig, 'PaperUnits', 'points', 'PaperPosition', [0 0 432 324]);
    x = linspace(0, 2 * pi, pointsPerAxes);
    if axesCount == 1
        axesHandle = axes('Parent', fig);
        plot(axesHandle, x, sin(x)); title(axesHandle, 'A1');
    else
        rows = axesCount / 2; columns = 2;
        for k = 1:axesCount
            axesHandle = subplot(rows, columns, k, 'Parent', fig);
            plot(axesHandle, x, sin(x + k / 10)); title(axesHandle, sprintf('A%d', k));
        end
    end
end
