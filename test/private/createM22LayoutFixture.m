function fig = createM22LayoutFixture(name)
%CREATEM22LAYOUTFIXTURE Build deterministic multiple-axes geometry fixtures.
    fig = figure('Visible', 'off');
    set(fig, 'PaperUnits', 'points', 'PaperPosition', [0 0 432 324]);
    try, set(fig, 'PaperPositionMode', 'manual'); catch, end

    switch name
        case 'two_independent'
            a = axes('Parent', fig, 'Position', [0.10 0.55 0.35 0.35]);
            plot(a, 1:3, [1 2 1]); title(a, 'A');
            b = axes('Parent', fig, 'Position', [0.55 0.10 0.35 0.35]);
            plot(b, 1:3, [3 1 2]); title(b, 'B');
        case 'subplot_2x1'
            a = subplot(2, 1, 1, 'Parent', fig); plot(a, 1:3, [1 2 1]); title(a, 'A');
            b = subplot(2, 1, 2, 'Parent', fig); plot(b, 1:3, [3 1 2]); title(b, 'B');
        case 'subplot_1x2'
            a = subplot(1, 2, 1, 'Parent', fig); plot(a, 1:3, [1 2 1]); title(a, 'A');
            b = subplot(1, 2, 2, 'Parent', fig); plot(b, 1:3, [3 1 2]); title(b, 'B');
        case 'subplot_2x2'
            for k = 1:4
                a = subplot(2, 2, k, 'Parent', fig);
                plot(a, 1:3, [k k + 1 k]); title(a, sprintf('A%d', k));
            end
        case 'manual_position'
            a = axes('Parent', fig, 'Position', [0.22 0.18 0.61 0.57]);
            plot(a, 0:3, [0 1 4 9]); title(a, 'Manual');
            set(a, 'XTick', [0 1 2 3], 'XTickLabel', {'zero','one','two','three'});
        case 'unequal_widths'
            a = axes('Parent', fig, 'Position', [0.08 0.18 0.25 0.68]);
            plot(a, 1:3, [1 2 1]); title(a, 'Narrow');
            b = axes('Parent', fig, 'Position', [0.43 0.18 0.50 0.68]);
            plot(b, 1:3, [3 1 2]); title(b, 'Wide');
        case 'unequal_heights'
            a = axes('Parent', fig, 'Position', [0.18 0.08 0.68 0.25]);
            plot(a, 1:3, [1 2 1]); title(a, 'Short');
            b = axes('Parent', fig, 'Position', [0.18 0.43 0.68 0.50]);
            plot(b, 1:3, [3 1 2]); title(b, 'Tall');
        case 'overlapping_axes'
            a = axes('Parent', fig, 'Position', [0.10 0.10 0.62 0.62]);
            plot(a, 1:3, [1 2 1], 'Color', [0 0.447 0.741]); title(a, 'Back');
            b = axes('Parent', fig, 'Position', [0.28 0.28 0.62 0.62], ...
                     'Color', 'none');
            plot(b, 1:3, [3 1 2], 'Color', [0.85 0.325 0.098]); title(b, 'Front');
        case 'different_scales'
            a = subplot(1, 2, 1, 'Parent', fig); plot(a, 1:3, [1 2 3]); title(a, 'Linear');
            b = subplot(1, 2, 2, 'Parent', fig); semilogy(b, 1:3, [1 10 100]); title(b, 'Log');
        case 'mixed_series_axes'
            a = subplot(1, 2, 1, 'Parent', fig);
            plot(a, 1:4, [1 2 1 3], 'DisplayName', 'Line'); title(a, 'Lines');
            lg = legend(a, 'show'); set(lg, 'Location', 'northwest');
            b = subplot(1, 2, 2, 'Parent', fig);
            scatter(b, 1:4, [2 1 3 2], 36, [0.8 0.1 0.2], 'o', ...
                    'DisplayName', 'Samples');
            hold(b, 'on');
            item = errorbar(b, 1:4, [1 2 2 3], [0.1 0.2 0.1 0.3]);
            set(item, 'DisplayName', 'Error');
            hold(b, 'off'); title(b, 'Mixed');
            box(b, 'on');
            lg = legend(b, 'show'); set(lg, 'Location', 'southeast');
        otherwise
            close(fig);
            error('M2T2:TestFixture', 'Unknown M2.2 fixture %s.', name);
    end
end
