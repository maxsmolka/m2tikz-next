function ir = fitUntiledMargins(ir, profile)
%FITUNTILEDMARGINS Keep fixed-size text inside a resized, fixed-size page.
% One common affine map preserves manual axes/colorbar/inset relationships.
% Maximize the retained plot scale, then choose the smallest translation.
% Gutters use the same physical typography policy as explicit tiled cells;
% existing space is retained, not added again. No runtime text extents enter IR.
    tick=profile.text.tickLabelPt;label=profile.text.axesLabelPt;title=profile.text.titlePt;
    boxes=zeros(0,4);gutters=zeros(0,4);
    for k=1:numel(ir.axes)
        a=ir.axes{k};p=a.placement;
        boxes(end+1,:)=[p.x p.y p.width p.height]; %#ok<AGROW>
        inset=[3*tick+~isempty(a.ylabel.value)*(label+5), ...
            2*tick+~isempty(a.xlabel.value)*(label+5),tick, ...
            tick+~isempty(a.title.value)*(title+8)];
        if a.dimensionality==3
            hasLabel=any(~cellfun(@isempty,{a.xlabel.value,a.ylabel.value,a.zlabel.value}));
            inset=[3*tick+hasLabel*(label+5),2*tick+hasLabel*(label+7), ...
                3*tick+hasLabel*(label+5),2*tick+~isempty(a.title.value)*(title+8)];
        end
        gutters(end+1,:)=inset; %#ok<AGROW>
    end
    for k=1:numel(ir.elements)
        e=ir.elements{k};
        if ~strcmp(e.kind,'m2t2.colorbar')
            error('M2T:PROFILE_GEOMETRY_INVALID','Untiled profile decoration has no physical gutter policy.');
        end
        p=e.placement;boxes(end+1,:)=[p.x p.y p.width p.height]; %#ok<AGROW>
        inset=[tick tick tick tick];reserve=4*tick+~isempty(e.label.value)*(label+5);
        switch e.location
            case 'eastoutside',inset(3)=reserve;
            case 'westoutside',inset(1)=reserve;
            case 'northoutside',inset(4)=reserve;
            case 'southoutside',inset(2)=reserve;
            otherwise,error('M2T:PROFILE_GEOMETRY_INVALID','Colorbar has no resolved profile orientation.');
        end
        gutters(end+1,:)=inset; %#ok<AGROW>
    end
    if isempty(boxes),return;end
    [sx,tx]=fitDimension(boxes(:,1),boxes(:,3),gutters(:,1)/ir.size(1),gutters(:,3)/ir.size(1));
    [sy,ty]=fitDimension(boxes(:,2),boxes(:,4),gutters(:,2)/ir.size(2),gutters(:,4)/ir.size(2));
    for k=1:numel(ir.axes)
        p=map(ir.axes{k}.placement,sx,sy,tx,ty);
        if p.width*ir.size(1)<2*tick || p.height*ir.size(2)<2*tick
            error('M2T:PROFILE_GEOMETRY_INVALID','Insufficient plotting area after physical profile gutters.');
        end
        ir.axes{k}.placement=p;
    end
    for k=1:numel(ir.elements),ir.elements{k}.placement=map(ir.elements{k}.placement,sx,sy,tx,ty);end
    for k=1:numel(ir.annotations)
        a=ir.annotations{k};
        if strcmp(a.coordinateSpace,'figure_normalized')
            a.start=a.start.*[sx sy]+[tx ty];a.end=a.end.*[sx sy]+[tx ty];
            ir.annotations{k}=a;
        end
    end
    m2t2.ir.validate(ir);
end

function [scale,shift]=fitDimension(start,extent,before,after)
    finish=start+extent;scale=1;
    if all(start>=before)&&all(finish<=1-after),shift=0;return;end
    % Feasible translation intervals must overlap for every pair of boxes.
    for i=1:numel(start)
        for j=1:numel(start)
            distance=finish(j)-start(i);
            if distance>0,scale=min(scale,(1-after(j)-before(i))/distance);end
        end
    end
    if ~isfinite(scale)||scale<=0
        error('M2T:PROFILE_GEOMETRY_INVALID','Physical profile gutters leave no valid layout.');
    end
    low=max(before-scale*start);high=min(1-after-scale*finish);
    if low>high+1e-12,error('M2T:PROFILE_GEOMETRY_INVALID','Infeasible profile gutter constraints.');end
    shift=max(low,min(0,high));
end

function p=map(p,sx,sy,tx,ty)
    p.x=sx*p.x+tx;p.y=sy*p.y+ty;p.width=sx*p.width;p.height=sy*p.height;
end
