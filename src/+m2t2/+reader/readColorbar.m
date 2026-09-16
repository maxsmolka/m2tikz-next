function node = readColorbar(handle, ownerAxes, path, id)
%READCOLORBAR Normalize a runtime colorbar as an explicit display node.
    if nargin < 4, id = 'colorbar-1'; end
    m2t2.reader.assertSupportedProperties(handle,path,'colorbar');
    node = m2t2.ir.makeColorbar(); node.id = id;
    node.owner = m2t2.ir.makeOwner('axes', ownerAxes.id);
    node.associatedAxesIds = {ownerAxes.id};
    node.placement = m2t2.reader.readNormalizedPosition(handle, [path '.placement']);
    node.location = lower(property(handle, 'Location', 'manual'));
    if ~any(strcmp(node.location, {'eastoutside','westoutside','northoutside','southoutside'}))
        node.location = 'manual';
    end
    vertical = property(handle, '__vertical__', '');
    if isempty(vertical)
        vertical = ~any(strcmp(node.location, {'northoutside','southoutside'}));
    else
        vertical = strcmpi(vertical, 'on');
    end
    if vertical, node.orientation = 'vertical'; else, node.orientation = 'horizontal'; end
    node.direction = lower(property(handle, 'Direction', 'normal'));
    if ~any(strcmp(node.direction, {'normal','reverse'})), node.direction = 'normal'; end
    node.scale = ownerAxes.colorMapping.scale;
    if ~strcmp(node.scale,'linear')
        error('M2T2:E007:UnsupportedProperty','Colorbar requires linear scalar mapping: %s',path);
    end
    node.limits = ownerAxes.colorMapping.limits;
    displayedLimits=property(handle,'Limits',node.limits);
    if strcmp(get(handle,'Type'),'axes')
        axisName='Y';if ~vertical,axisName='X';end
        displayedLimits=get(handle,[axisName 'Lim']);
    end
    if ~isequal(reshape(double(displayedLimits),1,[]),node.limits)
        error('M2T2:E011:UnsupportedColorbarOwnership','Colorbar display limits differ from its axes mapping: %s',path);
    end
    ticksMode = lower(property(handle, 'TicksMode', 'auto'));
    if strcmp(ticksMode, 'manual')
        values = reshape(double(property(handle, 'Ticks', [])), 1, []);
        rawLabels = property(handle, 'TickLabels', {});
        labels = normalizeLabels(rawLabels, numel(values));
        node.ticks = m2t2.ir.makeTickSpec('manual', values, labels);
    end
    labelHandle = property(handle, 'Label', []);
    if strcmp(get(handle,'Type'),'axes')
        axisName='Y';if ~vertical,axisName='X';end
        node.direction=lower(get(handle,[axisName 'Dir']));
        node.ticks=m2t2.reader.readTickSpec(handle,axisName,[path '.ticks']);
        labelHandle=get(handle,[axisName 'Label']);
    end
    if ~isempty(labelHandle), node.label = m2t2.reader.readText(labelHandle, [path '.label']); end
    m2t2.reader.assertDecorationChildren(handle,path,'colorbar',labelHandle,size(ownerAxes.colorMapping.colormap,1));
end

function labels = normalizeLabels(raw, count)
    if ischar(raw), raw = cellstr(raw); end
    if ~iscell(raw), raw = num2cell(raw); end
    raw = reshape(raw, 1, []); labels = cell(1, count);
    for k = 1:count
        if numel(raw)~=count,error('M2T2:E007:UnsupportedProperty','Colorbar tick value/label counts differ.');end
        value = raw{k};
        labels{k} = m2t2.ir.makeText(m2t2.util.textValue(value), 'plain');
    end
end

function value = property(handle, name, default)
    value = m2t2.reader.optionalProperty(handle, name, default);
end
