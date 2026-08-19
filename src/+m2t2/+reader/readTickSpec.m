function ticks = readTickSpec(axesHandle, axisName, path)
%READTICKSPEC Preserve manual ticks; leave automatic ticks unmaterialized.
    tickMode = get(axesHandle, [axisName 'TickMode']);
    labelMode = get(axesHandle, [axisName 'TickLabelMode']);
    if strcmpi(tickMode, 'auto') && strcmpi(labelMode, 'auto')
        ticks = m2t2.ir.makeTickSpec();
        return;
    end
    values = reshape(double(get(axesHandle, [axisName 'Tick'])), 1, []);
    rawLabels = get(axesHandle, [axisName 'TickLabel']);
    labels = labelCells(rawLabels);
    if numel(labels) ~= numel(values)
        error('M2T2:E004:NormalizationFailed', ...
              'M2T2-E004 NormalizationFailed: path=%s reason=tick value/label count mismatch', path);
    end
    interpreter = tickInterpreter(axesHandle, path);
    textLabels = cell(1, numel(labels));
    for k = 1:numel(labels)
        textLabels{k} = m2t2.ir.makeText(m2t2.util.textValue(labels{k}, path), interpreter);
    end
    ticks = m2t2.ir.makeTickSpec('manual', values, textLabels);
end

function labels = labelCells(raw)
    if iscell(raw)
        labels = reshape(raw, 1, []);
    elseif ischar(raw)
        labels = reshape(cellstr(raw), 1, []);
    elseif isnumeric(raw)
        labels = num2cell(reshape(raw, 1, []));
    else
        labels = {raw};
    end
end

function value = tickInterpreter(axesHandle, path)
    try
        runtimeValue = get(axesHandle, 'TickLabelInterpreter');
        value = m2t2.util.normalizeTextInterpreter(runtimeValue, path);
    catch err
        if strcmp(err.identifier, 'M2T2:E007:UnsupportedProperty'), rethrow(err); end
        value = 'plain';
    end
end
