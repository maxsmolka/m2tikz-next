function [fig, expected] = createM2LineFixture(name)
%CREATEM2LINEFIXTURE Build one deterministic M2 line-only fixture.
    fig = figure('Visible', 'off');
    expected = struct('name', name, 'seriesCount', 1, 'xscale', 'linear', ...
        'yscale', 'linear', 'xlabel', '', 'ylabel', '', 'title', '');
    switch name
        case 'minimal'
            x = 0:10;
            plot(x, x);
        case 'multiple'
            plot(0:3, [0 1 4 9]); hold on;
            plot(0:3, [0 1 2 3]); hold off;
            expected.seriesCount = 2;
        case 'styled'
            plot(1:4, [4 1 3 2], '--or', 'LineWidth', 2, 'MarkerSize', 8);
        case 'labels'
            plot(0:2, [2 1 2]);
            xlabel('Time'); ylabel('Value'); title('Label fixture'); grid on;
            expected.xlabel = 'Time'; expected.ylabel = 'Value'; expected.title = 'Label fixture';
        case 'display_name'
            plot(1:3, [1 3 2], 'DisplayName', 'Measured'); hold on;
            plot(1:3, [2 2 4], 'DisplayName', 'Reference'); hold off;
            legend('show');
            expected.seriesCount = 2;
        case 'log_x'
            semilogx([1 10 100], [1 2 4]);
            expected.xscale = 'log';
        case 'log_y'
            semilogy([1 2 3], [1 10 100]);
            expected.yscale = 'log';
        case 'nan_gap'
            plot(1:5, [1 2 NaN 4 5]);
        case 'inf_gap'
            plot(1:5, [1 2 Inf 4 5]);
        case 'empty'
            line('XData', [], 'YData', []);
        otherwise
            close(fig);
            error('M2T2:TestFixture', 'Unknown fixture %s.', name);
    end
end
