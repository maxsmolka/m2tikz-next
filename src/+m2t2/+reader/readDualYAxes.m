function [node, annotations] = readDualYAxes(ax, path, axesId, legendHandle)
%READDUALYAXES Explicit side membership via documented active-side Children.
%   Never infer ownership from data ranges, colors, names or hidden indices.
    active = get(ax,'YAxisLocation');
    cleanup = onCleanup(@()yyaxis(ax,active)); %#ok<NASGU>
    rulers = get(ax,'YAxis');
    if numel(rulers)~=2 || ~isequal(get(ax,'View'),[0 90])
        fail('UnsupportedDualYState',path,'exactly two Cartesian 2-D rulers required');
    end
    if ~strcmp(class(get(ax,'XAxis')),'matlab.graphics.axis.decorator.NumericRuler') || ...
            ~strcmp(get(ax,'DataAspectRatioMode'),'auto') || ...
            ~strcmp(get(ax,'PlotBoxAspectRatioMode'),'auto')
        fail('InvalidDualYXState',path,'numeric shared X and automatic aspect ratios required');
    end
    allHandles = flipud(allchild(ax));
    for k=1:numel(allHandles)
        if ~any(strcmp(get(allHandles(k),'Type'),{'line','scatter'}))
            fail('UnsupportedDualYState',path,'only line/scatter children are supported');
        end
    end
    sides={'left','right'}; nodes=cell(1,2); handles=cell(1,2);
    colors=cell(1,2);
    for side=1:2
        yyaxis(ax,sides{side}); handles{side}=flipud(get(ax,'Children'));
        [nodes{side}, annotations]=m2t2.reader.readAxes(ax,path,axesId,[],true);
        assert(isempty(annotations));
        ruler=rulers(side); colors{side}=get(ruler,'Color');
        if ~strcmp(get(ruler,'Visible'),'on') || ...
                get(ruler,'TickLabelRotation')~=0 || ...
                ~isequal(get(ruler,'TickLabelColor'),colors{side}) || ...
                ~standardMinorTicks(ruler) || ...
                get(ruler,'Exponent')~=0 || ~strcmp(get(ruler,'TickLabelFormat'),'%g')
            fail('UnsupportedDualYState',path,'hidden/rotated/minor/exponent or independently colored ruler ticks');
        end
        if ~isequal(get(get(ruler,'Label'),'Color'),colors{side})
            fail('UnsupportedDualYState',path,'independently colored Y label');
        end
    end
    shared={'xlim','xscale','xdirection','xticks','xlabel','placement','colorMapping'};
    for k=1:numel(shared)
        if ~isequaln(nodes{1}.(shared{k}),nodes{2}.(shared{k}))
            fail('InvalidDualYXState',path,'X, placement and color mapping must be shared');
        end
    end
    node=nodes{1}; right=nodes{2};
    node.dualY=struct('leftColor',reshape(double(colors{1}),1,[]), ...
        'right',struct('limits',right.ylim,'scale',right.yscale, ...
        'direction',right.ydirection,'ticks',right.yticks,'label',right.ylabel, ...
        'color',reshape(double(colors{2}),1,[])));
    node.series=cell(1,numel(allHandles));
    for k=1:numel(allHandles)
        li=find(handles{1}==allHandles(k));ri=find(handles{2}==allHandles(k));
        if numel(li)+numel(ri)~=1
            fail('AmbiguousDualYOwnership',path,'every child must occur on exactly one side, including hidden handles');
        end
        if ~isempty(li),side=1;index=li;else,side=2;index=ri;end
        item=nodes{side}.series{index};item.yAxis=sides{side};
        item.id=sprintf('%s-series-%d',axesId,k);node.series{k}=item;
    end
    node.legend=m2t2.reader.readLegend(legendHandle,node.series,[path '.legend']);
    if node.legend.visible
        if ~strcmp(get(legendHandle,'Direction'),'normal')
            fail('UnsupportedDualYState',path,'reversed legend presentation is unsupported');
        end
        try, linked=get(legendHandle,'PlotChildren');
        catch, fail('AmbiguousDualYOwnership',path,'legend links unavailable');end
        if numel(linked)~=numel(node.legend.entries)
            fail('AmbiguousDualYOwnership',path,'legend link count differs from labels');
        end
        for k=1:numel(linked)
            index=find(allHandles==linked(k));
            if numel(index)~=1 || ~node.series{index}.visible
                fail('AmbiguousDualYOwnership',path,'legend references an unknown/invisible series');
            end
            node.legend.entries{k}.seriesId=node.series{index}.id;
        end
        node.legend.mode='manual';
    end
    % All numeric limits and positive-log domains are checked before rendering.
    m2t2.ir.validate(m2t2.ir.makeFigure({node}));
end

function yes=standardMinorTicks(ruler)
    if strcmp(get(ruler,'Scale'),'log')
        yes=strcmp(get(ruler,'MinorTick'),'on')&&strcmp(get(ruler,'MinorTickValuesMode'),'auto');
    else
        yes=strcmp(get(ruler,'MinorTick'),'off');
    end
end

function fail(kind,path,reason)
    kinds={'AmbiguousDualYOwnership','UnsupportedDualYState','InvalidDualYXState'};
    codes={'E059','E060','E061'};code=codes{strcmp(kind,kinds)};
    error(['M2T2:' code ':' kind],'%s: path=%s reason=%s',kind,path,reason);
end
