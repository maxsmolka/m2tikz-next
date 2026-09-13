function ir = fitTiledMargins(ir, profile)
%FITTILEDMARGINS Reserve physical text gutters for a fixed-grid profile.
%   Apply one affine placement transform; grid intent and scientific series
%   stay unchanged. This is an explicit profile policy, not reader inference.
    if any(cellfun(@(a) strcmp(a.owner.kind,'figure'),ir.annotations))
        error('M2T:PROFILE_GEOMETRY_INVALID', ...
            'Tiled profile gutters do not support figure-space annotations.');
    end
    labels = cellfun(@(e) strcmp(e.kind,'m2t2.sharedlabel'), ir.elements);
    roles = cellfun(@(e) e.role, ir.elements(labels), 'UniformOutput',false);
    tick = profile.text.tickLabelPt; label = profile.text.axesLabelPt;
    titleSize = profile.text.titlePt; width = ir.size(1); height = ir.size(2);
    left = 3*tick + any(strcmp(roles,'ylabel'))*(label+3);
    bottom = 2*tick + any(strcmp(roles,'xlabel'))*(label+3);
    right = 2*tick;
    top = tick + any(strcmp(roles,'title'))*(titleSize+4);
    placements = cellfun(@(a) a.placement, ir.axes, 'UniformOutput',false);
    for k = 1:numel(ir.elements)
        if ~labels(k) && ~isempty(ir.elements{k}.placement)
            placements{end+1} = ir.elements{k}.placement; %#ok<AGROW>
        end
    end
    low = [min(cellfun(@(p)p.x,placements)) min(cellfun(@(p)p.y,placements))];
    high = [max(cellfun(@(p)p.x+p.width,placements)) max(cellfun(@(p)p.y+p.height,placements))];
    lower = max(low,[left/width bottom/height]);
    upper = min(high,[1-right/width 1-top/height]);
    if any(upper <= lower)
        error('M2T:PROFILE_GEOMETRY_INVALID','No room for tiled profile text gutters.');
    end
    scale = (upper-lower)./(high-low);
    for k = 1:numel(ir.axes),ir.axes{k}.placement = transform(ir.axes{k}.placement);end
    for k = 1:numel(ir.elements)
        node = ir.elements{k};
        if labels(k)
            switch node.role
                case 'title',center=[.5 1-(titleSize/2+3)/height];
                case 'xlabel',center=[.5 (label/2+3)/height];
                otherwise,center=[(label/2+3)/width .5];
            end
            node.placement=m2t2.ir.makePlacement(center(1)-.5/width,center(2)-.5/height,1/width,1/height);
        elseif ~isempty(node.placement)
            node.placement=transform(node.placement);
        end
        ir.elements{k}=node;
    end
    m2t2.ir.validate(ir);
    function p=transform(p)
        p.x=lower(1)+(p.x-low(1))*scale(1);p.y=lower(2)+(p.y-low(2))*scale(2);
        p.width=p.width*scale(1);p.height=p.height*scale(2);
    end
end
