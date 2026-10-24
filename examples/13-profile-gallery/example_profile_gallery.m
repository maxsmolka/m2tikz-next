function results = example_profile_gallery(outputDirectory, showFigures)
%EXAMPLE_PROFILE_GALLERY Four MATLAB figures, each exported three ways.
%   From the repository root:
%     addpath(fullfile('examples', '13-profile-gallery'));
%     results = example_profile_gallery();
%   Requires LuaLaTeX, TikZ, PGFPlots and standalone on the MATLAB PATH.
%   Outputs go to .audit/profile-gallery; reruns replace this demo's products.
%   Figures remain open for experimentation. Pass ([], false) for hidden
%   figures that are closed automatically (for example in validation).
%   This is an executable .m file; .mat files store variables, not code.

    root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    addpath(fullfile(root, 'src'));
    if nargin < 1 || isempty(outputDirectory)
        outputDirectory = fullfile(root, '.audit', 'profile-gallery');
    end
    if nargin < 2, showFigures = true; end
    if exist(outputDirectory, 'dir') ~= 7, mkdir(outputDirectory); end
    visibility = 'off';
    if showFigures, visibility = 'on'; end

    names = {'lines', 'scatter', 'errorbars', 'six-column-legend'};
    variants = {'no-profile', 'single-column-85mm', 'double-column-170mm'};
    options = {{}, {'Profile', 'publication', 'Width', 'single-column'}, ...
        {'Profile', 'publication', 'Width', 'double-column'}};
    results = struct();
    failures = 0;
    for k = 1:numel(names)
        fig = figure('Name', names{k}, 'NumberTitle', 'off', ...
            'Visible', visibility, 'Color', 'white', ...
            'Units', 'pixels', 'Position', [100 100 720 432]);
        cleanup = onCleanup(@() closeHiddenFigure(fig, showFigures));
        ax = axes('Parent', fig, 'Position', [0.16 0.18 0.76 0.62], ...
            'Color', 'white', 'XColor', 'black', 'YColor', 'black', ...
            'FontSize', 12);
        makeExample(ax, k);
        % Save an editable MATLAB source figure before any export.
        sourcePath = fullfile(outputDirectory, [names{k} '.fig']);
        savefig(fig, sourcePath);
        results(k).name = names{k};
        results(k).figurePath = sourcePath;
        for j = 1:numel(variants)
            exportOptions = options{j};
            outputBase = fullfile(outputDirectory, ...
                [names{k} '-' variants{j}]);
            % No-profile is literally an export without Profile/Width.
            result = m2t.export(fig, outputBase, exportOptions{:}, ...
                'Overwrite', true);
            results(k).exports(j).variant = variants{j};
            results(k).exports(j).result = result;
            fprintf('%-19s %-24s %s\n', names{k}, variants{j}, result.status);
            if ~result.success
                failures = failures + 1;
                for d = 1:numel(result.diagnostics)
                    fprintf('  %s\n', result.diagnostics(d).message);
                end
            end
        end
        clear cleanup;
    end
    fprintf('\nOutput directory: %s\n', outputDirectory);
    if failures > 0
        warning('M2T:GalleryExportFailed', ...
            '%d exports failed. Check results and the compiler logs.', failures);
    end
end

function makeExample(ax, index)
    x = linspace(0, 2*pi, 80);
    switch index
        case 1
            plot(ax, x, sin(x), '-', x, cos(x), '--', 'LineWidth', 1.2);
            xlabel(ax, 'Time'); ylabel(ax, 'Amplitude');
            title(ax, 'Two signals', 'Color', 'black');
            legend(ax, {'Sine', 'Cosine'}, 'Location', 'northeast');
        case 2
            samples = 1:8;
            scatter(ax, samples, [1.2 1.8 1.5 2.6 2.4 3.3 3.1 4], ...
                36, [0.15 0.45 0.7], 'o', 'DisplayName', 'Samples');
            xlabel(ax, 'Sample'); ylabel(ax, 'Value');
            title(ax, 'Measured samples', 'Color', 'black');
            legend(ax, 'show', 'Location', 'northwest');
        case 3
            errorbar(ax, 1:5, [2 3 2.5 4 3.5], ...
                [0.1 0.2 0.15 0.25 0.2], [0.3 0.2 0.25 0.2 0.3], ...
                'o-', 'LineWidth', 1.2, 'DisplayName', 'Data');
            xlabel(ax, 'Sample'); ylabel(ax, 'Value');
            title(ax, 'Measurement uncertainty', 'Color', 'black');
            legend(ax, 'show', 'Location', 'northwest');
        case 4
            hold(ax, 'on');
            colors = lines(6);
            for j = 1:6
                plot(ax, x, sin(x + (j-1)*pi/8) + (j-1)*0.3, ...
                    'Color', colors(j,:), 'LineWidth', 1.2, ...
                    'DisplayName', sprintf('S%d', j));
            end
            hold(ax, 'off');
            xlabel(ax, 'Time'); ylabel(ax, 'Amplitude');
            title(ax, 'Six signals', 'Color', 'black');
            legend(ax, 'show', 'Orientation', 'horizontal', ...
                'NumColumns', 6, 'Location', 'northoutside', 'Box', 'off');
    end
    % High-level plotting commands can reset axes to the active MATLAB theme.
    % Set the supported light background after drawing, without root defaults.
    set(ax, 'Color', 'white', 'XColor', 'black', 'YColor', 'black', ...
        'FontSize', 12);
    grid(ax, 'on');
    lgd = legend(ax);
    set(lgd, 'TextColor', 'black', 'Color', 'white', 'FontSize', 12);
end

function closeHiddenFigure(fig, showFigures)
    if ~showFigures && isgraphics(fig), close(fig); end
end
