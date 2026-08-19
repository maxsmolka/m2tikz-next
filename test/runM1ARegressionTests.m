function results = runM1ARegressionTests()
%RUNM1AREGRESSIONTESTS Focused regressions found by the M0 runtime audit.
% These tests intentionally avoid golden files and assert observable export
% behavior so they run on both MATLAB and Octave.

    testRoot = fileparts(mfilename('fullpath'));
    addpath(fullfile(testRoot, '..', 'src'));
    output = fullfile(testRoot, 'output', 'm1a-regressions');
    if ~exist(output, 'dir')
        mkdir(output);
    end

    tests = {@strictLogTickLabels, @octaveBarPlot, @octaveColorbar};
    names = {'M2T-RUNTIME-001', 'M2T-RUNTIME-002', 'M2T-RUNTIME-003'};
    results = repmat(struct('name','','passed',false,'message',''), numel(tests), 1);

    for k = 1:numel(tests)
        results(k).name = names{k};
        close all;
        try
            tests{k}(output);
            results(k).passed = true;
            fprintf('PASS %s\n', names{k});
        catch err
            results(k).message = err.message;
            fprintf('FAIL %s: %s\n', names{k}, err.message);
        end
    end
    close all;

    passed = sum([results.passed]);
    failed = numel(results) - passed;
    fprintf('M1A_REGRESSION_SUMMARY executed=%d passed=%d failed=%d skipped=0\n', ...
        numel(results), passed, failed);
    if failed > 0 && nargout == 0
        error('matlab2tikz:M1ARegressionFailure', ...
            '%d M1A regression test(s) failed.', failed);
    end
end

function strictLogTickLabels(output)
    fig = figure('visible','off');
    loglog([1e-2,1e2],[1e-5,1e5]);
    filename = fullfile(output, 'strict-log-ticks.tex');
    matlab2tikz(filename, 'figurehandle', fig, 'strict', true, ...
        'standalone', true, 'showInfo', false, 'checkForUpdates', false);
    assertFileContains(filename, '$10^{');
end

function octaveBarPlot(output)
    fig = figure('visible','off');
    bar([1 2 3; 3 2 1]);
    filename = fullfile(output, 'bar.tex');
    matlab2tikz(filename, 'figurehandle', fig, 'standalone', true, ...
        'showInfo', false, 'checkForUpdates', false);
    assertFileContains(filename, 'ybar');
end

function octaveColorbar(output)
    fig = figure('visible','off');
    imagesc(peaks(20));
    cbar = colorbar;
    filename = fullfile(output, 'colorbar.tex');
    matlab2tikz(filename, 'figurehandle', fig, 'standalone', true, ...
        'showInfo', false, 'checkForUpdates', false);
    assertFileContains(filename, 'colorbar');

    % ACID also exercises the manual-position path, which needs the same
    % associated-axes capability lookup on Octave.
    position = get(cbar, 'position');
    set(cbar, 'position', position + [0.01 0 0 0]);
    filename = fullfile(output, 'colorbar-manual.tex');
    matlab2tikz(filename, 'figurehandle', fig, 'standalone', true, ...
        'showInfo', false, 'checkForUpdates', false);
    assertFileContains(filename, 'colorbar');
end

function assertFileContains(filename, expected)
    assert(exist(filename, 'file') == 2, 'Expected output file was not created.');
    contents = fileread(filename);
    assert(~isempty(strfind(contents, expected)), ...
        'Expected output to contain "%s".', expected);
end
