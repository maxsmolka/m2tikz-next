function result = runM32FigureSetSmokeTest(outputDirectory)
%RUNM32FIGURESETSMOKETEST Compile a compact hosted-CI publication set.
    repositoryRoot = fileparts(fileparts(mfilename('fullpath')));
    if nargin < 1
        outputDirectory = fullfile(repositoryRoot, '.audit', 'm32-set-smoke');
    end
    addpath(fullfile(repositoryRoot, 'src'));
    if exist(outputDirectory, 'dir') == 7, rmdir(outputDirectory, 's'); end

    first = figure('Visible', 'off'); plot(1:4, [1 3 2 4]);
    second = figure('Visible', 'off'); scatter(1:4, [2 1 4 3], 36, [0.2 0.4 0.8]);
    third = figure('Visible', 'off'); errorbar(1:4, [2 3 2 4], [0.2 0.1 0.3 0.2]);
    figures = [first second third]; cleanup = onCleanup(@() closeFigures(figures));
    entries = struct('figure', {first, second, third}, ...
                     'name', {'detection','measurements','error-analysis'}, ...
                     'width', {[], 'double-column', []});
    result = m2t.exportSet(entries, outputDirectory, ...
        'Profile', 'publication', 'Width', 'single-column', 'Overwrite', true);
    assert(result.success && strcmp(result.status, 'success'));
    assert(result.summary.total == 3 && result.summary.succeeded == 3);
    assert(strcmp(result.entries(2).effective.width, 'double-column'));
    assert(exist(result.manifestPath, 'file') == 2);
    manifest = jsondecode(fileread(result.manifestPath));
    assert(manifest.schemaVersion == 1 && numel(manifest.figures) == 3);
    for k = 1:3, assert(exist(result.entries(k).result.pdfPath, 'file') == 2); end
    clear cleanup;
end

function closeFigures(figures)
    for k = 1:numel(figures), if ishandle(figures(k)), close(figures(k)); end, end
end
