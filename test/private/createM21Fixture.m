function fig = createM21Fixture(name)
%CREATEM21FIXTURE Build deterministic axes/scatter/errorbar fixtures.
    fig = figure('Visible', 'off');
    switch name
        case 'manual_x_ticks'
            plot(0:2, [0 1 4]); set(gca, 'XTick', [0 1 2], 'XTickLabel', {'zero','one','two'});
        case 'manual_y_ticks'
            plot(0:2, [0 1 4]); set(gca, 'YTick', [0 2 4], 'YTickLabel', {'low','mid','high'});
        case 'reverse_x'
            plot(0:3, [0 1 4 9]); set(gca, 'XDir', 'reverse');
        case 'reverse_y'
            plot(0:3, [0 1 4 9]); set(gca, 'YDir', 'reverse');
        case 'box_on'
            plot(0:3, [0 1 4 9]); box on;
        case 'box_off'
            plot(0:3, [0 1 4 9]); box off;
        case 'plain_text'
            plot(0:2, [0 1 0]); xlabel('plain_a_b', 'Interpreter', 'none');
        case 'tex_text'
            plot(0:2, [0 1 0]); ylabel('x_{1}', 'Interpreter', 'tex');
        case 'latex_text'
            plot(0:2, [0 1 0]); title('$x^2$', 'Interpreter', 'latex');
        case 'legend_on'
            plot(1:3, [1 2 1], 'DisplayName', 'First'); hold on;
            plot(1:3, [2 1 3], 'DisplayName', 'Second'); hold off;
            legend('show'); legend('location', 'southwest');
        case 'legend_off'
            plot(1:3, [1 2 1], 'DisplayName', 'Named but hidden');
        case 'scatter'
            scatter(1:4, [2 1 4 3], 49, [0.8 0.1 0.2], 'o', 'DisplayName', 'Samples');
        case 'errorbar_symmetric'
            item = errorbar(1:4, [2 3 2 4], [0.2 0.3 0.1 0.4]);
            set(item, 'DisplayName', 'Symmetric');
        case 'errorbar_asymmetric'
            item = errorbar(1:4, [2 3 2 4], [0.1 0.2 0.3 0.1], ...
                            [0.3 0.4 0.2 0.5]);
            set(item, 'DisplayName', 'Asymmetric');
        case 'mixed_line_scatter'
            plot(1:4, [1 2 2 4], 'DisplayName', 'Line'); hold on;
            scatter(1:4, [2 1 3 3], 36, [0.8 0.1 0.2], 'o', 'DisplayName', 'Scatter');
            hold off; legend('show');
        case 'mixed_line_errorbar'
            plot(1:4, [1 2 2 4], 'DisplayName', 'Line'); hold on;
            item = errorbar(1:4, [2 3 2 3], [0.2 0.1 0.3 0.2]);
            set(item, 'DisplayName', 'Errorbar');
            hold off; legend('show');
        otherwise
            close(fig); error('M2T2:TestFixture', 'Unknown M2.1 fixture %s.', name);
    end
end
