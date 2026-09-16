function node = readLegend(legendHandle, series, path, seriesHandles)
%READLEGEND Normalize basic visibility, entry selection/order, and location.
    node = m2t2.ir.makeLegend();
    if nargin<4,seriesHandles={};end
    if isempty(legendHandle) || ~ishandle(legendHandle), return; end
    node.visible = strcmpi(get(legendHandle, 'Visible'), 'on');
    if ~node.visible, return; end
    m2t2.reader.assertSupportedProperties(legendHandle,path,'legend');
    m2t2.reader.assertDecorationChildren(legendHandle,path,'legend');
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
    if ~isempty(seriesHandles)
        links=legendLinks(legendHandle,labels,path);candidates=zeros(1,numel(links));
        for k=1:numel(links)
            index=find(cellfun(@(h)isequal(h,links{k}),seriesHandles));
            if isempty(index)
                for j=1:numel(seriesHandles)
                    if strcmp(series{j}.kind,'m2t2.boxplot')&& ...
                            isequal(get(links{k},'Parent'),seriesHandles{j})&&strcmp(get(links{k},'Tag'),'Box')
                        index(end+1)=j; %#ok<AGROW>
                    end
                end
            end
            if numel(index)~=1||~series{index}.visible
                error('M2T2:E010:UnsupportedSharedLegend','Legend references an unknown, ambiguous or invisible series: %s',path);
            end
            candidates(k)=index;
        end
        if numel(unique(candidates))~=numel(candidates)
            error('M2T2:E010:UnsupportedSharedLegend','Multiple labels for one normalized compound: %s',path);
        end
    end
    if numel(labels) > numel(candidates)
        error('M2T2:E004:NormalizationFailed', ...
              'M2T2-E004 NormalizationFailed: path=%s reason=more legend entries than visible series', path);
    end
    node.entries = cell(1, numel(labels));
    automatic = true;
    for k = 1:numel(labels)
        item = series{candidates(k)};
        if ~any(strcmp(item.kind,{'m2t2.line','m2t2.line3','m2t2.scatter','m2t2.scatter3','m2t2.errorbar','m2t2.bar','m2t2.boxplot','m2t2.patch3'}))
            unsupported(path,'series kind',item.kind);
        end
        text = m2t2.ir.makeText(m2t2.util.textValue(labels{k}, path), runtimeInterpreter);
        node.entries{k} = m2t2.ir.makeLegendEntry(item.id, text);
        automatic = automatic && strcmp(text.value, item.displayName.value);
    end
    if automatic, node.mode = 'automatic'; else, node.mode = 'manual'; end
end

function links=legendLinks(handle,labels,path)
    raw=[];try,raw=get(handle,'PlotChildren');catch,end
    if isempty(raw),try,raw=getappdata(handle,'__peer_objects__');catch,end,end
    links={};
    if ~isempty(raw)
        for k=1:numel(raw),links{end+1}=raw(k);end %#ok<AGROW>
    else
        % Octave gnuplot legends expose linked text through per-child appdata.
        children=flipud(allchild(handle));
        for k=1:numel(children)
            if ~strcmp(get(children(k),'Type'),'text'),continue;end
            linked=getappdata(children(k),'handle');if isempty(linked),continue;end
            if numel(links)>=numel(labels)||~strcmp(get(children(k),'String'),labels{numel(links)+1})
                error('M2T2:E010:UnsupportedSharedLegend','Ambiguous runtime legend label order: %s',path);
            end
            links{end+1}=linked; %#ok<AGROW>
        end
    end
    if numel(links)~=numel(labels)
        error('M2T2:E010:UnsupportedSharedLegend','Runtime legend links must resolve every label: %s',path);
    end
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
