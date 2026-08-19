% Octave/MATLAB runtime audit harness. Writes only below .audit/runtime-baseline.
audit_root = fileparts(fileparts(mfilename('fullpath')));
baseline = fullfile(audit_root, '.audit', 'runtime-baseline');
tex_dir = fullfile(baseline, 'tex');
results_dir = fullfile(baseline, 'results');
if ~exist(tex_dir, 'dir'), mkdir(tex_dir); end
if ~exist(results_dir, 'dir'), mkdir(results_dir); end
det_a = fullfile(tex_dir, 'determinism-a');
det_b = fullfile(tex_dir, 'determinism-b');
if ~exist(det_a, 'dir'), mkdir(det_a); end
if ~exist(det_b, 'dir'), mkdir(det_b); end
addpath(fullfile(audit_root, 'src'));

case_names = {'line2d','multiple_legend','log_axes','subplot','scatter','bar', ...
    'errorbar','histogram','imagesc','contour','surface3d','colorbar', ...
    'date_axis','latex_labels','unicode','transparency','nan_inf','large_data'};
n = numel(case_names);
results = repmat(struct('name','','figure_created',false,'export_ok',false, ...
    'tex_created',false,'deterministic',false,'status','','error',''), 1, n);

for k = 1:n
    results(k).name = case_names{k};
    try
        close all;
        fig = figure('visible','off');
        switch case_names{k}
            case 'line2d'
                x=linspace(0,2*pi,100); plot(x,sin(x));
            case 'multiple_legend'
                x=1:10; plot(x,[x;2*x]'); legend('a','b');
            case 'log_axes'
                loglog(logspace(-2,2),logspace(-5,5));
            case 'subplot'
                subplot(1,2,1); plot(1:3); subplot(1,2,2); plot(3:-1:1);
            case 'scatter'
                scatter(1:10,linspace(0,1,10),20:10:110,1:10,'filled');
            case 'bar'
                bar([1 2 3;3 2 1]);
            case 'errorbar'
                errorbar(1:5,1:5,.1:.1:.5);
            case 'histogram'
                if exist('histogram','file') ~= 2
                    error('audit:notImplemented','histogram not implemented in Octave');
                end
                histogram(mod(1:100,11));
            case 'imagesc'
                imagesc(peaks(20));
            case 'contour'
                contour(peaks(20));
            case 'surface3d'
                surf(peaks(20));
            case 'colorbar'
                imagesc(peaks(20)); colorbar;
            case 'date_axis'
                plot(datenum(2020,1,1:10),1:10); datetick('x');
            case 'latex_labels'
                plot(1:3); xlabel('$x_1$','interpreter','latex');
                title('$\alpha+\beta$','interpreter','latex');
            case 'unicode'
                utf8_bytes = uint8([71 114 195 182 195 159 101 32 194 181 32 206 169 32 194 167]);
                plot(1:3); title(native2unicode(utf8_bytes,'UTF-8'));
            case 'transparency'
                p=patch([0 1 1 0],[0 0 1 1],'r'); set(p,'facealpha',.3);
            case 'nan_inf'
                plot(1:6,[1 NaN 2 Inf 3 -Inf]);
            case 'large_data'
                x=linspace(0,100,1000000); plot(x,sin(x));
        end
        results(k).figure_created = ishandle(fig);
        first = fullfile(det_a, [case_names{k} '.tex']);
        second = fullfile(det_b, [case_names{k} '.tex']);
        matlab2tikz(first, 'figurehandle', fig, 'standalone', true, 'showInfo', false);
        results(k).export_ok = true;
        check_fid = fopen(first,'rb');
        results(k).tex_created = check_fid >= 0;
        if check_fid >= 0, fclose(check_fid); end
        matlab2tikz(second, 'figurehandle', fig, 'standalone', true, 'showInfo', false);
        results(k).deterministic = strcmp(fileread(first), fileread(second));
        results(k).status = 'EXPORTED';
    catch err
        results(k).error = err.message;
        if strcmp(err.identifier, 'audit:notImplemented')
            results(k).status = 'NOT TESTABLE WITH OCTAVE';
        else
            results(k).status = 'EXPORT FAILED';
        end
    end
end

% Dedicated external-data and standalone export checks.
mode_results = struct('external_ok',false,'external_error','', ...
    'standalone_ok',false,'standalone_error','');
try
    close all; fig = figure('visible','off'); plot(1:10);
    external_file = fullfile(tex_dir, 'external-data.tex');
    matlab2tikz(external_file, 'figurehandle', fig, 'externalData', true, ...
        'dataPath', fullfile(baseline,'data'), 'relativeDataPath', '../data', ...
        'standalone', true, 'showInfo', false);
    mode_results.external_ok = exist(external_file, 'file') == 2;
catch err
    mode_results.external_error = err.message;
end
try
    close all; fig = figure('visible','off'); plot(1:10);
    standalone_file = fullfile(tex_dir, 'standalone.tex');
    matlab2tikz(standalone_file, 'figurehandle', fig, 'standalone', true, ...
        'showInfo', false);
    mode_results.standalone_ok = exist(standalone_file, 'file') == 2;
catch err
    mode_results.standalone_error = err.message;
end

save(fullfile(results_dir,'harness-results.mat'),'results','mode_results');
fid = fopen(fullfile(results_dir,'harness-results.tsv'),'w');
cleanup_fid = onCleanup(@() fclose(fid));
fprintf(fid,'name\tfigure_created\texport_ok\ttex_created\tdeterministic\tstatus\terror\n');
for k = 1:n
    safe_error = strrep(strrep(results(k).error, sprintf('\r'), ' '), sprintf('\n'), ' ');
    fprintf(fid,'%s\t%d\t%d\t%d\t%d\t%s\t%s\n', results(k).name, ...
        results(k).figure_created, results(k).export_ok, results(k).tex_created, ...
        results(k).deterministic, results(k).status, safe_error);
end
disp('M0_HARNESS_COMPLETE');
disp(results);
disp(mode_results);
