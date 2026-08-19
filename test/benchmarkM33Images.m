function rows = benchmarkM33Images(outputDirectory)
%BENCHMARKM33IMAGES Measure pure-PGFPlots image cost at milestone sizes.
    repositoryRoot = fileparts(fileparts(mfilename('fullpath')));
    if nargin < 1
        outputDirectory = fullfile(repositoryRoot, '.audit', 'm33-image-benchmark');
    end
    addpath(fullfile(repositoryRoot, 'src'));
    if exist(outputDirectory, 'dir') == 7, rmdir(outputDirectory, 's'); end
    mkdir(outputDirectory);
    sizes = [25 100 250];
    rows = zeros(numel(sizes), 6);
    for k = 1:numel(sizes)
        count = sizes(k); fig = figure('Visible', 'off');
        cleanup = onCleanup(@() closeFigure(fig));
        data = reshape(sin((1:(count * count)) / 31), count, count);
        imagesc(data);
        started = tic; ir = m2t2.reader.readFigure(fig); readerTime = toc(started);
        started = tic; tex = m2t2.render.renderPgfplots(ir, true); renderTime = toc(started);
        base = fullfile(outputDirectory, sprintf('image-%d', count));
        texPath = [base '.tex']; writeText(texPath, tex);
        started = tic; compiled = m2t.internal.compileLuaLatex(texPath, [base '.pdf'], 'lualatex');
        compileTime = toc(started);
        if ~compiled.success
            error('M2T:M33BenchmarkCompileFailed', ...
                  '%dx%d compilation failed: %s', count, count, compiled.diagnostics(1).message);
        end
        texBytes = numel(unicode2native(tex, 'UTF-8'));
        rows(k, :) = [count count readerTime renderTime texBytes compileTime];
        fprintf('%dx%d reader=%.6fs renderer=%.6fs tex=%d bytes compile=%.6fs\n', ...
                count, count, readerTime, renderTime, texBytes, compileTime);
        clear cleanup;
    end
    path = fullfile(outputDirectory, 'benchmark.tsv');
    fid = fopen(path, 'wb'); assert(fid >= 0); cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, 'rows\tcolumns\treader_seconds\trenderer_seconds\ttex_bytes\tcompile_seconds\n');
    for k = 1:size(rows, 1)
        fprintf(fid, '%d\t%d\t%.9g\t%.9g\t%d\t%.9g\n', ...
                sizes(k), sizes(k), rows(k, 3), rows(k, 4), ...
                round(rows(k, 5)), rows(k, 6));
    end
    clear cleanup;
end

function writeText(path, text)
    fid = fopen(path, 'wb'); assert(fid >= 0); cleanup = onCleanup(@() fclose(fid));
    written = fwrite(fid, text, 'char'); assert(written == numel(text)); clear cleanup;
end

function closeFigure(fig), if ishandle(fig), close(fig); end, end
