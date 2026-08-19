function benchmarkLargeData(pointCounts, compileTex)
%BENCHMARKLARGEDATA Reproduce the M0 inline/external-data performance matrix.
% This benchmark is intentionally not part of the unit-test entry point.

    if nargin < 1 || isempty(pointCounts)
        pointCounts = [100, 10000, 100000, 1000000];
    end
    if nargin < 2
        compileTex = true;
    end

    benchmarkDir = fileparts(mfilename('fullpath'));
    [pathExists, pathInfo] = fileattrib(benchmarkDir);
    if pathExists, benchmarkDir = pathInfo.Name; end
    repoDir = fileparts(benchmarkDir);
    outputDir = fullfile(benchmarkDir, 'output');
    dataDir = fullfile(outputDir, 'data');
    if ~exist(outputDir, 'dir'), mkdir(outputDir); end
    if ~exist(dataDir, 'dir'), mkdir(dataDir); end
    addpath(fullfile(repoDir, 'src'));

    resultPath = fullfile(outputDir, 'large-data-results.tsv');
    fid = fopen(resultPath, 'w');
    if fid < 0, error('m2t:benchmark:ResultFile', 'Cannot open %s.', resultPath); end
    cleanupResult = onCleanup(@() fclose(fid));
    fprintf(fid, ['points\tmode\texport_seconds\ttex_bytes\texternal_files\t', ...
                  'external_bytes\tcompile_seconds\tcompile_status\tpeak_note\n']);

    for n = pointCounts
        fig = figure('visible', 'off');
        x = linspace(0, 100, n);
        plot(x, sin(x));
        for modeCell = {'inline', 'external'}
            mode = modeCell{1};
            stem = sprintf('line-%d-%s', n, mode);
            target = fullfile(outputDir, [stem '.tex']);
            if strcmp(mode, 'external')
                removePriorDataFiles(dataDir, stem);
            end
            started = tic;
            if strcmp(mode, 'external')
                matlab2tikz(target, 'figurehandle', fig, 'standalone', true, ...
                    'showInfo', false, 'externalData', true, ...
                    'dataPath', dataDir, 'relativeDataPath', 'data');
            else
                matlab2tikz(target, 'figurehandle', fig, 'standalone', true, ...
                    'showInfo', false);
            end
            exportSeconds = toc(started);
            texBytes = fileSize(target);
            externalInfo = matchingDataFiles(dataDir, stem);
            compileSeconds = NaN;
            compileStatus = 'NOT RUN';
            if compileTex
                compileStarted = tic;
                command = sprintf(['latexmk -lualatex -interaction=nonstopmode ', ...
                    '-halt-on-error -outdir="%s" "%s"'], outputDir, target);
                [compileExit, ~] = system(command);
                compileSeconds = toc(compileStarted);
                if compileExit == 0, compileStatus = 'PASS'; else, compileStatus = 'FAIL'; end
            end
            fprintf(fid, '%d\t%s\t%.6f\t%d\t%d\t%d\t%.6f\t%s\t%s\n', ...
                n, mode, exportSeconds, texBytes, numel(externalInfo), ...
                sum([externalInfo.bytes]), compileSeconds, compileStatus, ...
                'portable peak RSS unavailable; observe OS process externally');
            fprintf('M2T_BENCH|%d|%s|export=%.3fs|tex=%d|files=%d|compile=%s\n', ...
                n, mode, exportSeconds, texBytes, numel(externalInfo), compileStatus);
        end
        close(fig);
    end
    fprintf('Results: %s\n', resultPath);
end

function bytes = fileSize(path)
    fid = fopen(path, 'rb');
    if fid < 0, error('m2t:benchmark:OutputMissing', 'Cannot open %s.', path); end
    cleanupFile = onCleanup(@() fclose(fid));
    fseek(fid, 0, 'eof');
    bytes = ftell(fid);
end

function entries = matchingDataFiles(dataDir, stem)
    previousDir = pwd;
    cd(dataDir);
    restoreDir = onCleanup(@() cd(previousDir));
    entries = dir();
    entries = entries(~[entries.isdir]);
    prefix = [stem '-'];
    keep = arrayfun(@(entry) strncmp(entry.name, prefix, length(prefix)) && ...
        length(entry.name) >= 4 && strcmp(entry.name(end-3:end), '.tsv'), entries);
    entries = entries(keep);
end

function removePriorDataFiles(dataDir, stem)
    entries = matchingDataFiles(dataDir, stem);
    previousDir = pwd;
    cd(dataDir);
    restoreDir = onCleanup(@() cd(previousDir));
    for k = 1:numel(entries)
        delete(entries(k).name);
    end
end
