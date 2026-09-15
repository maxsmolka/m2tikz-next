function ir = fitTiledMargins(ir, profile)
%FITTILEDMARGINS Lay out explicit grid cells with physical text gutters.
%   Source-size geometry is untouched; this opt-in profile policy uses logical
%   cells, never inferred rectangles. Scientific series and cell order remain.
    if any(cellfun(@(a) strcmp(a.owner.kind,'figure'),ir.annotations))
        error('M2T:PROFILE_GEOMETRY_INVALID', ...
            'Tiled profile gutters do not support figure-space annotations.');
    end
    labels = cellfun(@(e) strcmp(e.kind,'m2t2.sharedlabel'), ir.elements);
    roles = cellfun(@(e) e.role, ir.elements(labels), 'UniformOutput',false);
    tick=profile.text.tickLabelPt; label=profile.text.axesLabelPt;
    titleSize=profile.text.titlePt; width=ir.size(1); height=ir.size(2);
    levels={'tight','compact','loose'}; values=[2 4 8];
    padding=values(strcmp(ir.layout.tiled.padding,levels));
    gap=values(strcmp(ir.layout.tiled.spacing,levels));
    left=padding+any(strcmp(roles,'ylabel'))*(label+7);
    bottom=padding+any(strcmp(roles,'xlabel'))*(label+7);
    right=padding; top=padding+any(strcmp(roles,'title'))*(titleSize+8);
    slotWidth=(width-left-right-(ir.layout.columns-1)*gap)/ir.layout.columns;
    slotHeight=(height-bottom-top-(ir.layout.rows-1)*gap)/ir.layout.rows;
    original=ir.axes;
    for k=1:numel(ir.axes)
        a=ir.axes{k};cellIndex=find(cellfun(@(c)strcmp(c.axesId,a.id),ir.layout.cells),1);
        cellNode=ir.layout.cells{cellIndex};
        insetLeft=3*tick+~isempty(a.ylabel.value)*(label+5);
        insetBottom=2*tick+~isempty(a.xlabel.value)*(label+5);
        insetRight=tick;insetTop=tick+~isempty(a.title.value)*(titleSize+8);
        if isfield(a,'dualY')
            insetRight=3*tick+~isempty(a.dualY.right.label.value)*(label+5);
        end
        for e=1:numel(ir.elements)
            node=ir.elements{e};if labels(e),continue;end
            if ~strcmp(node.kind,'m2t2.colorbar')||~strcmp(node.owner.kind,'axes')
                error('M2T:PROFILE_GEOMETRY_INVALID','Unsupported tiled profile decoration ownership.');
            end
            if ~strcmp(node.owner.id,a.id),continue;end
            reserve=4*tick+~isempty(node.label.value)*(label+5);
            if isfield(a,'dualY') && strcmp(node.location,'eastoutside')
                reserve=6*tick+~isempty(node.label.value)*(label+5);
            end
            switch node.location
                case 'eastoutside',insetRight=insetRight+reserve;
                case 'westoutside',insetLeft=insetLeft+reserve;
                case 'northoutside',insetTop=insetTop+reserve;
                case 'southoutside',insetBottom=insetBottom+reserve;
                otherwise,error('M2T:PROFILE_GEOMETRY_INVALID','Manual tiled colorbar placement is unsupported in profiles.');
            end
        end
        cellWidth=cellNode.columnSpan*slotWidth+(cellNode.columnSpan-1)*gap;
        cellHeight=cellNode.rowSpan*slotHeight+(cellNode.rowSpan-1)*gap;
        plotWidth=cellWidth-insetLeft-insetRight;plotHeight=cellHeight-insetBottom-insetTop;
        if plotWidth<2*tick||plotHeight<2*tick
            error('M2T:PROFILE_GEOMETRY_INVALID','Tiled grid is too dense for the selected physical profile.');
        end
        x=left+(cellNode.column-1)*(slotWidth+gap)+insetLeft;
        y=height-top-(cellNode.row-1)*(slotHeight+gap)-cellHeight+insetBottom;
        ir.axes{k}.placement=m2t2.ir.makePlacement(x/width,y/height,plotWidth/width,plotHeight/height);
    end
    for k=1:numel(ir.elements)
        node=ir.elements{k};
        if labels(k)
            switch node.role
                case 'title',center=[.5 1-(titleSize/2+3)/height];
                case 'xlabel',center=[.5 (label/2+3)/height];
                otherwise,center=[(label/2+3)/width .5];
            end
            node.placement=m2t2.ir.makePlacement(center(1)-.5/width,center(2)-.5/height,1/width,1/height);
        else
            owner=find(cellfun(@(a)strcmp(a.id,node.owner.id),original),1);
            before=original{owner}.placement;after=ir.axes{owner}.placement;p=node.placement;
            p.x=after.x+(p.x-before.x)*after.width/before.width;
            p.y=after.y+(p.y-before.y)*after.height/before.height;
            p.width=p.width*after.width/before.width;p.height=p.height*after.height/before.height;
            if isfield(original{owner},'dualY') && strcmp(node.location,'eastoutside')
                reserve=3*tick+~isempty(original{owner}.dualY.right.label.value)*(label+5);
                p.x=after.x+after.width+(reserve+tick)/width;
                p.width=tick/width;
            end
            node.placement=p;
        end
        ir.elements{k}=node;
    end
    m2t2.ir.validate(ir);
end
