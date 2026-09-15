function text=formatCoordinates3(x,y,z)
%FORMATCOORDINATES3 Preserve explicit triples and shared NaN gaps.
    points=cell(1,numel(x));
    for k=1:numel(x)
        if isnan(x(k)),points{k}='(nan,nan,nan)';
        else,points{k}=['(' m2t2.util.formatNumber(x(k)) ',' ...
            m2t2.util.formatNumber(y(k)) ',' m2t2.util.formatNumber(z(k)) ')'];end
    end
    text=m2t2.util.joinCell(points,' ');
end
