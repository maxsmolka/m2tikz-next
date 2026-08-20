function value = scatterMarkerName(name, filled)
%SCATTERMARKERNAME Map canonical scatter markers, including filled variants.
    value = m2t2.render.markerName(name);
    if ~filled, return; end
    source = {'circle','square','diamond','triangle_up','triangle_down', ...
              'triangle_right','triangle_left','pentagram','hexagram'};
    target = {'*','square*','diamond*','triangle*','triangle*', ...
              'triangle*','triangle*','star','star'};
    index = find(strcmp(name, source), 1);
    if ~isempty(index), value = target{index}; end
end
