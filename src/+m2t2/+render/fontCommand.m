function value = fontCommand(points)
%FONTCOMMAND Render a portable TeX-native font-size command.
    if isempty(points), value = ''; return; end
    bs = char(92);
    leading = points * 1.2;
    value = [bs 'fontsize{' m2t2.util.formatNumber(points) 'pt}{' ...
             m2t2.util.formatNumber(leading) 'pt}' bs 'selectfont'];
end
