function points = legendBottomInset(legend, profile)
%LEGENDBOTTOMINSET Additional physical space below ticks and the X label.
    points=0;
    if ~legend.visible||isempty(legend.entries)||~strcmp(legend.location,'south_outside'),return;end
    rows=ceil(numel(legend.entries)/legend.layout.columns);
    points=rows*(1.2*profile.legend.textPt+4)+8;
end
