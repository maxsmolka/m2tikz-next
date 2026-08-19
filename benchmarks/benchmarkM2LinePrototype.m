function rows = benchmarkM2LinePrototype(outputDirectory)
%BENCHMARKM2LINEPROTOTYPE Compare legacy and M2 line exports without reduction.
    repositoryRoot = fileparts(fileparts(mfilename('fullpath')));
    if nargin < 1
        outputDirectory = fullfile(repositoryRoot, 'benchmarks', 'output', 'm2-line');
    end
    addpath(fullfile(repositoryRoot, 'src'));
    ensureDirectory(outputDirectory);
    ensureDirectory(fullfile(outputDirectory, 'legacy'));
    ensureDirectory(fullfile(outputDirectory, 'm2'));
    counts = [100 10000 100000];
    rows = cell(numel(counts), 8);
    for k = 1:numel(counts)
        count = counts(k);
        x = linspace(0, 20, count);
        y = sin(x) + 0.05 * cos(11 * x);
        fig = figure('Visible', 'off');
        plot(x, y);
        legacyPath = fullfile(outputDirectory, 'legacy', sprintf('line-%d.tex', count));
        m2Path = fullfile(outputDirectory, 'm2', sprintf('line-%d.tex', count));

        timer = tic;
        matlab2tikz(legacyPath, 'figurehandle', fig, 'standalone', true, ...
                    'showInfo', false, 'externalData', false);
        legacySeconds = toc(timer);

        totalTimer = tic;
        timer = tic; ir = m2t2.reader.readFigure(fig); readerSeconds = toc(timer);
        timer = tic; tex = m2t2.render.renderPgfplots(ir, true); rendererSeconds = toc(timer);
        writeText(m2Path, tex);
        m2TotalSeconds = toc(totalTimer);
        close(fig);
        rows(k, :) = {count, legacySeconds, readerSeconds, rendererSeconds, ...
                      m2TotalSeconds, fileBytes(legacyPath), fileBytes(m2Path), 'no-reduction'};
    end
    writeRows(fullfile(outputDirectory, 'export-performance.tsv'), rows);
end

function writeText(path, value)
    fid = fopen(path, 'w'); cleanup = onCleanup(@() fclose(fid));
    fwrite(fid, value, 'char'); clear cleanup;
end

function bytes = fileBytes(path)
    fid = fopen(path, 'rb'); cleanup = onCleanup(@() fclose(fid));
    fseek(fid, 0, 'eof'); bytes = ftell(fid); clear cleanup;
end

function writeRows(path, rows)
    fid = fopen(path, 'w'); cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, ['points\tlegacy_export_s\tm2_reader_s\tm2_renderer_s\t' ...
                  'm2_total_s\tlegacy_tex_bytes\tm2_tex_bytes\tpolicy\n']);
    for k = 1:size(rows, 1)
        fprintf(fid, '%d\t%.9f\t%.9f\t%.9f\t%.9f\t%d\t%d\t%s\n', rows{k, :});
    end
    clear cleanup;
end

function ensureDirectory(path)
    if exist(path, 'dir') ~= 7, mkdir(path); end
end
