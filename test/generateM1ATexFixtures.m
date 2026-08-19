function generateM1ATexFixtures(outputDirectory)
%GENERATEM1ATEXFIXTURES Export the small M1A TeX compilation matrix.
% The function records export failures separately from TeX engine failures.

    if nargin < 1 || isempty(outputDirectory)
        outputDirectory = fullfile(fileparts(mfilename('fullpath')), ...
                                   'output', 'm1a-tex');
    end
    if ~exist(outputDirectory, 'dir')
        mkdir(outputDirectory);
    end

    addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));
    cases = {@plotLine, @plotScatter, @plotLogAxis, @plotImage, ...
             @plotSurface, @plotUnicode};
    names = {'line', 'scatter', 'log-axis', 'image', 'surface', 'unicode'};
    resultFile = fullfile(outputDirectory, 'export-results.tsv');
    fid = fopen(resultFile, 'w');
    if fid < 0
        error('m2t:m1a:ResultFile', 'Cannot open %s.', resultFile);
    end
    closeResult = onCleanup(@() fclose(fid));
    fprintf(fid, 'case\tstatus\tmessage\n');

    for k = 1:numel(cases)
        status = 'PASS';
        message = '';
        fig = [];
        try
            fig = figure('visible', 'off');
            cases{k}();
            matlab2tikz(fullfile(outputDirectory, [names{k} '.tex']), ...
                        'figurehandle', fig, 'standalone', true, ...
                        'showInfo', false);
        catch err
            status = 'EXPORT FAILURE';
            message = err.message;
        end
        if ~isempty(fig) && ishandle(fig)
            close(fig);
        end
        message = strrep(strrep(message, sprintf('\r'), ' '), sprintf('\n'), ' ');
        fprintf(fid, '%s\t%s\t%s\n', names{k}, status, message);
        fprintf('M1A_EXPORT|%s|%s|%s\n', names{k}, status, message);
    end
end

function plotLine()
    x = linspace(0, 2*pi, 30);
    plot(x, sin(x), 'LineWidth', 1.2);
    xlabel('x'); ylabel('sin(x)'); grid on;
end

function plotScatter()
    x = 1:12;
    scatter(x, mod(x.^2, 11) + 1, 28, x, 'filled');
    xlabel('sample'); ylabel('value');
end

function plotLogAxis()
    loglog([1 10 100 1000], [1 4 16 64], '-o');
    grid on;
end

function plotImage()
    imagesc(peaks(20));
    colorbar;
end

function plotSurface()
    [x, y, z] = peaks(20);
    surf(x, y, z);
    shading interp;
end

function plotUnicode()
    plot(0:4, (0:4).^2);
    title('Resistance Ω and angle α', 'interpreter', 'none');
    xlabel('length μm', 'interpreter', 'none');
end
