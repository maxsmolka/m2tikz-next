function results = runM1B3DRegressionTests()
%RUNM1B3DREGRESSIONTESTS Focused public-camera 3D compatibility regressions.
% All scenarios exercise the same root cause, M2T-RUNTIME-005: axes with a
% constrained plot box must not depend on an undocumented view transform.

    testRoot = fileparts(mfilename('fullpath'));
    addpath(fullfile(testRoot, '..', 'src'));
    output = fullfile(testRoot, 'output', 'm1b-3d-regressions');
    if ~exist(output, 'dir'), mkdir(output); end

    cases = {@line3dCase, @surfaceCase, @meshCase, @viewAngleCase, ...
             @axisLimitsCase, @manualCameraCase};
    names = {'line3d', 'surface', 'mesh', 'view-angle', ...
             'axis-limits', 'manual-camera'};
    ids = {'M2T-RUNTIME-005', 'M2T-RUNTIME-005', 'M2T-RUNTIME-005', ...
           'M2T-RUNTIME-005', 'M2T-RUNTIME-005', 'M2T-RUNTIME-006'};
    results = repmat(struct('id', '', 'case', '', ...
        'passed', false, 'message', ''), numel(cases), 1);

    for k = 1:numel(cases)
        close all;
        results(k).id = ids{k};
        results(k).case = names{k};
        try
            fig = figure('visible', 'off');
            cases{k}();
            filename = fullfile(output, [names{k} '.tex']);
            matlab2tikz(filename, 'figurehandle', fig, 'standalone', true, ...
                'showInfo', false, 'checkForUpdates', false);
            validate3DExport(filename, names{k});
            results(k).passed = true;
            fprintf('PASS %s/%s\n', ids{k}, names{k});
        catch err
            results(k).message = err.message;
            fprintf('FAIL %s/%s: %s\n', ids{k}, names{k}, err.message);
        end
    end
    close all;
    passed = sum([results.passed]);
    failed = numel(results) - passed;
    fprintf('M1B_3D_SUMMARY executed=%d passed=%d failed=%d skipped=0\n', ...
        numel(results), passed, failed);
    if failed > 0 && nargout == 0
        error('matlab2tikz:M1B3DRegressionFailure', ...
              '%d M1B 3D regression scenario(s) failed.', failed);
    end
end

function line3dCase()
    t = linspace(0, 4*pi, 40);
    plot3(cos(t), sin(t), t/4);
    daspect([1 1 1]); grid on;
end

function surfaceCase()
    [x, y, z] = peaks(12);
    surf(x, y, z);
    daspect([1 1 1]);
end

function meshCase()
    [x, y] = meshgrid(-2:0.4:2);
    mesh(x, y, x.^2 - y.^2);
    daspect([1 1 2]);
end

function viewAngleCase()
    [x, y, z] = peaks(10);
    surf(x, y, z);
    daspect([1 1 1]); view(125, 22);
end

function axisLimitsCase()
    t = linspace(0, 2*pi, 30);
    plot3(cos(t), sin(t), sin(2*t));
    xlim([-2 2]); ylim([-1.5 1.5]); zlim([-3 3]);
    daspect([1 1 2]); view(35, 40);
end

function manualCameraCase()
    [x, y, z] = peaks(10);
    surf(x, y, z);
    daspect([1 1 1]);
    set(gca, 'CameraPosition', [14 -18 12], ...
             'CameraTarget', [0 0 0], ...
             'CameraUpVector', [0 0 1]);
end

function validate3DExport(filename, caseName)
    assert(exist(filename, 'file') == 2, 'Expected output file was not created.');
    contents = fileread(filename);
    assert(~isempty(strfind(contents, '\begin{axis}')), 'Missing axis structure.');
    assert(~isempty(strfind(contents, '\addplot3')), 'Missing 3D plot structure.');
    if strcmp(caseName, 'manual-camera')
        tokens = regexp(contents, 'view=\{([^}]*)\}\{([^}]*)\}', 'tokens', 'once');
        assert(~isempty(tokens), 'Missing view option for manual camera.');
        azimuth = str2double(tokens{1});
        elevation = str2double(tokens{2});
        assert(abs(azimuth - 37.875) < 0.2 && abs(elevation - 27.759) < 0.2, ...
            'Manual camera was exported as stale view angles {%g}{%g}.', ...
            azimuth, elevation);
    end
end
