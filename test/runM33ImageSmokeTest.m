function result = runM33ImageSmokeTest(outputDirectory)
%RUNM33IMAGESMOKETEST Compile one compact hosted-CI image fixture.
    repositoryRoot = fileparts(fileparts(mfilename('fullpath')));
    if nargin < 1
        outputDirectory = fullfile(repositoryRoot, '.audit', 'm33-image-smoke');
    end
    addpath(fullfile(repositoryRoot, 'src'));
    if exist(outputDirectory, 'dir') == 7, rmdir(outputDirectory, 's'); end
    mkdir(outputDirectory);
    fig = figure('Visible', 'off'); cleanup = onCleanup(@() closeFigure(fig));
    ax = axes('Parent', fig);
    values = peaks(20); imagesc(ax, linspace(-2, 2, 20), linspace(-1, 1, 20), values);
    set(ax, 'YDir', 'normal'); colormap(ax, [0 0.15 0.5; 1 1 1; 0.65 0 0]);
    colorbar(ax);
    result = m2t.export(fig, fullfile(outputDirectory, 'heatmap'), ...
                        'Profile', 'publication');
    if ~(result.success && strcmp(result.status, 'success') && ...
            exist(result.pdfPath, 'file') == 2)
        error('M2T:M33ImageSmokeFailed', 'Hosted M3.3 image smoke export failed.');
    end
    clear cleanup;
end

function closeFigure(fig), if ishandle(fig), close(fig); end, end
