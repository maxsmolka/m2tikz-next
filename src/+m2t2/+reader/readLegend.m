function node = readLegend(legendHandle, series, path)
%READLEGEND Normalize basic visibility, entry selection/order, and location.
    node = m2t2.ir.makeLegend();
    if isempty(legendHandle) || ~ishandle(legendHandle), return; end
    node.visible = strcmpi(get(legendHandle, 'Visible'), 'on');
    if ~node.visible, return; end
    try
        if ~strcmpi(get(legendHandle, 'Orientation'), 'vertical')
            unsupported(path, 'Orientation', get(legendHandle, 'Orientation'));
        end
    catch err
        if strcmp(err.identifier, 'M2T2:E007:UnsupportedProperty'), rethrow(err); end
    end
    try
        if double(get(legendHandle, 'NumColumns')) ~= 1
            unsupported(path, 'NumColumns', num2str(get(legendHandle, 'NumColumns')));
        end
    catch err
        if strcmp(err.identifier, 'M2T2:E007:UnsupportedProperty'), rethrow(err); end
    end
    node.location = normalizeLocation(get(legendHandle, 'Location'), path);
    runtimeInterpreter = 'plain';
    try
        runtimeInterpreter = m2t2.util.normalizeTextInterpreter( ...
            get(legendHandle, 'Interpreter'), [path '.entries']);
    catch err
        if strcmp(err.identifier, 'M2T2:E007:UnsupportedProperty'), rethrow(err); end
    end
    labels = labelCells(get(legendHandle, 'String'));
    candidates = find(cellfun(@(item) item.visible, series));
    if numel(labels) > numel(candidates)
        error('M2T2:E004:NormalizationFailed', ...
              'M2T2-E004 NormalizationFailed: path=%s reason=more legend entries than visible series', path);
    end
    node.entries = cell(1, numel(labels));
    automatic = true;
    for k = 1:numel(labels)
        item = series{candidates(k)};
        text = m2t2.ir.makeText(m2t2.util.textValue(labels{k}, path), runtimeInterpreter);
        node.entries{k} = m2t2.ir.makeLegendEntry(item.id, text);
        automatic = automatic && strcmp(text.value, item.displayName.value);
    end
    if automatic, node.mode = 'automatic'; else, node.mode = 'manual'; end
end

function values = labelCells(raw)
    if iscell(raw), values = reshape(raw, 1, []);
    elseif ischar(raw), values = reshape(cellstr(raw), 1, []);
    else, values = num2cell(reshape(raw, 1, [])); end
end

function value = normalizeLocation(runtimeValue, path)
    source = {'northeast','northwest','southeast','southwest','north','south','east','west','best'};
    target = {'north_east','north_west','south_east','south_west','north','south','east','west','north_east'};
    index = find(strcmpi(runtimeValue, source), 1);
    if isempty(index), unsupported(path, 'Location', runtimeValue); end
    value = target{index};
end

function unsupported(path, property, value)
    error('M2T2:E007:UnsupportedProperty', ...
          'M2T2-E007 UnsupportedProperty: type=legend path=%s property=%s value=%s', ...
          path, property, value);
end
