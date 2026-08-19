function node = readColorbar(handle, ownerAxes, path, id)
%READCOLORBAR Normalize a runtime colorbar as an explicit display node.
    if nargin < 4, id = 'colorbar-1'; end
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
    node.limits = ownerAxes.colorMapping.limits;
    ticksMode = lower(property(handle, 'TicksMode', 'auto'));
    if strcmp(ticksMode, 'manual')
        values = reshape(double(property(handle, 'Ticks', [])), 1, []);
        rawLabels = property(handle, 'TickLabels', {});
        labels = normalizeLabels(rawLabels, numel(values));
        node.ticks = m2t2.ir.makeTickSpec('manual', values, labels);
    end
    labelHandle = property(handle, 'Label', []);
    if ~isempty(labelHandle), node.label = m2t2.reader.readText(labelHandle, [path '.label']); end
end

function labels = normalizeLabels(raw, count)
    if ischar(raw), raw = cellstr(raw); end
    if ~iscell(raw), raw = num2cell(raw); end
    raw = reshape(raw, 1, []); labels = cell(1, count);
    for k = 1:count
        if k <= numel(raw), value = raw{k}; else, value = num2str(k); end
        labels{k} = m2t2.ir.makeText(m2t2.util.textValue(value), 'plain');
    end
end

function value = property(handle, name, default)
    try, value = get(handle, name); catch, value = default; end
end
