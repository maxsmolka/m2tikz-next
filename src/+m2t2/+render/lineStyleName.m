function value = lineStyleName(style)
%LINESTYLENAME Map canonical line styles to PGFPlots options.
    source = {'solid','dashed','dotted','dashdot','none'};
    target = {'solid','dashed','dotted','dash dot','only marks'};
    value = target{find(strcmp(style, source), 1)};
end
