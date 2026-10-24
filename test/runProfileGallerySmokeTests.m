function summary = runProfileGallerySmokeTests(outputDirectory)
%RUNPROFILEGALLERYSMOKETESTS Compile all 12 native MATLAB gallery exports.
%   Requires MATLAB with a JVM and LuaLaTeX on PATH. Not an Octave test.
%   Every invocation creates a new evidence directory; no old evidence is erased.
    if exist('OCTAVE_VERSION', 'builtin')
        error('M2T:MatlabRequired', 'The gallery smoke test requires native MATLAB.');
    end
    root = fileparts(fileparts(mfilename('fullpath')));
    if nargin < 1 || isempty(outputDirectory)
        outputDirectory = fullfile(root, '.audit', 'profile-gallery-smoke');
    end
    if exist(outputDirectory, 'dir') ~= 7, mkdir(outputDirectory); end
    runDirectory = tempname(outputDirectory);
    previousPath = path;
    restorePath = onCleanup(@() path(previousPath));
    addpath(fullfile(root, 'src'));
    addpath(fullfile(root, 'examples', '13-profile-gallery'));

    % Verify that the example does not close, restyle or export caller figures.
    caller = figure('Visible', 'off', 'Color', [0.2 0.3 0.4]);
    closeCaller = onCleanup(@() close(caller));
    callerAxes = axes('Parent', caller);
    plot(callerAxes, [0 1], [3 4]);
    figuresBefore = findall(groot, 'Type', 'figure');
    defaultsBefore = get(groot, 'default');
    results = example_profile_gallery(runDirectory, false);
    figuresAfter = findall(groot, 'Type', 'figure');
    assert(numel(figuresAfter) == numel(figuresBefore));
    assert(all(ismember(figuresBefore, figuresAfter)), 'Caller figure was closed.');
    assert(isequaln(defaultsBefore, get(groot, 'default')), 'Root defaults changed.');
    assert(isequal(get(caller, 'Color'), [0.2 0.3 0.4]));
    assert(isequal(get(findobj(callerAxes, 'Type', 'line'), 'YData'), [3 4]));

    expectedNames = {'lines', 'scatter', 'errorbars', 'six-column-legend'};
    variants = {'no-profile', 'single-column-85mm', 'double-column-170mm'};
    profiles = {'none', 'publication', 'publication'};
    widths = {'source', 'single-column', 'double-column'};
    assert(numel(results) == 4);
    for k = 1:4
        assert(strcmp(results(k).name, expectedNames{k}));
        assert(numel(results(k).exports) == 3);
        fig = openfig(results(k).figurePath, 'invisible');
        closeSource = onCleanup(@() close(fig));
        ir = m2t2.reader.readFigure(fig);
        assert(numel(ir.axes) == 1);
        if k == 4
            lgd = findobj(fig, 'Type', 'legend');
            assert(strcmp(lgd.Orientation, 'horizontal') && lgd.NumColumns == 6);
            assert(strcmp(lgd.Location, 'northoutside') && numel(lgd.String) == 6);
            assert(numel(ir.axes{1}.series) == 6);
        end
        for j = 1:3
            item = results(k).exports(j);
            r = item.result;
            assert(strcmp(item.variant, variants{j}));
            assert(r.success && strcmp(r.status, 'success'), ...
                sprintf('Gallery export failed: %s/%s', expectedNames{k}, variants{j}));
            assert(exist(r.texPath, 'file') == 2 && exist(r.pdfPath, 'file') == 2);
            assert(strcmp(r.profile.name, profiles{j}));
            assert(strcmp(r.profile.width, widths{j}));
            if j == 1
                assert(isempty(r.profile.widthMillimeters));
                assert(max(abs(r.profile.figureSize - ir.size)) < 1e-8);
            else
                assert(r.profile.widthMillimeters == 85*(j-1));
                assert(abs(r.profile.figureSize(1)*25.4/72.27 - 85*(j-1)) < 1e-8);
            end
            pdfInfo = dir(r.pdfPath);
            assert(pdfInfo.bytes > 0);
        end
        clear closeSource;
    end
    assert(numel(dir(fullfile(runDirectory, '*.pdf'))) == 12);
    assert(numel(dir(fullfile(runDirectory, '*.fig'))) == 4);
    assert(numel(findall(groot, 'Type', 'figure')) == numel(figuresBefore));
    summary = struct('exports', 12, 'savedFigures', 4, 'failures', 0, ...
        'runtime', version, 'outputDirectory', runDirectory);
    m2t.internal.writeTextFile(fullfile(runDirectory, 'smoke-summary.json'), jsonencode(summary));
    fprintf('PROFILE_GALLERY_SMOKE_PASS: 12 exports, 4 reopened figures, caller preserved\n');
    fprintf('Evidence: %s\n', runDirectory);
    clear closeCaller restorePath;
end
