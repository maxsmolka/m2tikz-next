function points = legendTopInset(legend, profile)
%LEGENDTOPINSET Physical space for an explicitly axes-owned upper legend.
    points=0;
    if ~legend.visible||isempty(legend.entries)||~strcmp(legend.location,'north_outside'),return;end
    rows=ceil(numel(legend.entries)/legend.layout.columns);
    points=rows*(1.2*profile.legend.textPt+4)+8;
end
