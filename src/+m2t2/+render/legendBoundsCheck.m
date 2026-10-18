function lines = legendBoundsCheck(node, axesIndex, figureSize)
%LEGENDBOUNDSCHECK Fail real compilation instead of cropping an oversized legend.
% TeX measures actual interpreted text, including mathematical labels. No font
% shrink, column-count change, approximate string metric or source mutation.
    lines={};
    if ~node.legend.visible||isempty(node.legend.entries)||~isfield(node.legend,'layout')||isempty(figureSize),return;end
    bs=char(92);name=sprintf('m2tlegend%d',axesIndex);
    lines={[bs 'begingroup']};
    anchors={'west','east','south','north'};
    extract={'x','x','y','y'};
    limits={ '-0.1pt',[m2t2.util.formatNumber(figureSize(1)+.1) 'pt'], ...
             '-0.1pt',[m2t2.util.formatNumber(figureSize(2)+.1) 'pt']};
    comparisons={'<','>','<','>'};
    for k=1:4
        lines{end+1}=[bs 'pgfextract' extract{k} '{' bs 'dimen0}{' bs 'pgfpointanchor{' name '}{' anchors{k} '}}']; %#ok<AGROW>
        lines{end+1}=[bs 'ifdim' bs 'dimen0' comparisons{k} limits{k} ...
            bs 'PackageError{m2tikz-next}{Legend exceeds figure bounds}' ...
            '{Use a larger figure or explicitly revise the legend layout.}' bs 'fi']; %#ok<AGROW>
    end
    lines{end+1}=[bs 'endgroup'];
end
