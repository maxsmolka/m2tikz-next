function [figureHandle, expected] = createM23ColorbarFixture(name)
%CREATEM23COLORBARFIXTURE Build one deterministic Octave colorbar fixture.
    figureHandle = figure('Visible', 'off', 'PaperUnits', 'points', ...
        'PaperPosition', [0 0 432 324]); expected = struct();
    switch name
        case {'default','eastoutside','westoutside','horizontal','manual','ticks','label'}
            ax = axes('Parent', figureHandle); imagesc(ax, [1 2; 3 4]);
            switch name
                case 'westoutside', cb = colorbar(ax, 'westoutside');
                case 'horizontal', cb = colorbar(ax, 'southoutside');
                otherwise, cb = colorbar(ax, 'eastoutside');
            end
            if strcmp(name, 'manual')
                set(cb, 'Units', 'normalized', 'Position', [0.80 0.20 0.04 0.50]);
            elseif strcmp(name, 'ticks')
                set(cb, 'Ticks', [1 2.5 4], 'TickLabels', {'low','mid','high'});
            elseif strcmp(name, 'label')
                ylabel(cb, 'Temperature');
            end
            expected.count = 1; expected.owner = 1;
        case {'first_only','separate'}
            ax1 = subplot(1, 2, 1, 'Parent', figureHandle); imagesc(ax1, [1 2;3 4]); colorbar(ax1);
            ax2 = subplot(1, 2, 2, 'Parent', figureHandle);
            if strcmp(name, 'separate')
                imagesc(ax2, [10 20;30 40]); colorbar(ax2, 'westoutside');
            else
                plot(ax2, [1 2], [2 1]);
            end
            expected.count = 1 + strcmp(name, 'separate');
        case 'overlap'
            ax1 = axes('Parent', figureHandle, 'Position', [0.10 0.10 0.55 0.70]);
            plot(ax1, [1 2], [1 2]);
            ax2 = axes('Parent', figureHandle, 'Position', [0.35 0.25 0.45 0.60]);
            imagesc(ax2, [5 6;7 8]); cb = colorbar(ax2); %#ok<NASGU>
            expected.count = 1;
        otherwise
            error('M2T2:UnknownFixture', 'Unknown M2.3 fixture %s.', name);
    end
    drawnow();
end
