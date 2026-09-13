function state = readTiledLayout(handle)
%READTILEDLAYOUT Read one fixed, figure-owned tiled layout without inference.
    fail = 'M2T2:E056:UnsupportedTiledLayout';
    if ~strcmp(get(get(handle,'Parent'),'Type'),'figure') || ...
            ~strcmp(get(handle,'TileArrangement'),'fixed') || ...
            ~strcmp(get(handle,'Visible'),'on')
        error(fail, 'Only a visible, fixed, figure-owned tiled layout is supported.');
    end
    originalUnits = get(handle,'Units'); restore = onCleanup(@() set(handle,'Units',originalUnits));
    set(handle,'Units','normalized'); outer = double(get(handle,'OuterPosition'));
    if ~isequal(outer,[0 0 1 1])
        error(fail, 'A tiled layout must occupy the complete figure canvas.');
    end
    clear restore;
    grid = double(get(handle,'GridSize')); indexing = char(get(handle,'TileIndexing'));
    if numel(grid) ~= 2 || any(~isfinite(grid)) || any(grid < 1) || any(grid ~= fix(grid)) || ...
            ~any(strcmp(indexing,{'rowmajor','columnmajor'}))
        error('M2T2:E057:InvalidTileCell', 'Invalid fixed grid or tile indexing.');
    end
    spacing = char(get(handle,'TileSpacing')); padding = char(get(handle,'Padding'));
    if ~any(strcmp(spacing,{'loose','compact','tight'})) || ...
            ~any(strcmp(padding,{'loose','compact','tight'}))
        error(fail, 'Unsupported tile spacing or padding.');
    end
    if ~isempty(m2t2.util.textValue(get(get(handle,'Subtitle'),'String')))
        error(fail, 'Layout subtitles are not in the shared-label contract.');
    end
    axesHandles = {}; legends = {}; colorbars = {};
    children = allchild(handle);
    for k = 1:numel(children)
        type = char(get(children(k),'Type'));
        switch type
            case 'axes', axesHandles{end+1} = children(k); %#ok<AGROW>
            case 'legend', legends{end+1} = children(k); %#ok<AGROW>
            case 'colorbar', colorbars{end+1} = children(k); %#ok<AGROW>
            otherwise
                error(fail, 'Unsupported or nested tiled-layout child: %s.', type);
        end
    end
    if isempty(axesHandles), error(fail, 'A tiled layout must contain supported axes.'); end
    positions = zeros(numel(axesHandles),4); keys = zeros(1,numel(axesHandles));
    occupied = false(grid);
    for k = 1:numel(axesHandles)
        options = get(axesHandles{k},'Layout'); tile = options.Tile; span = double(options.TileSpan);
        if ~isnumeric(tile) || ~isscalar(tile) || ~isfinite(tile) || tile < 1 || ...
                tile ~= fix(tile) || tile > prod(grid) || numel(span) ~= 2 || ...
                any(~isfinite(span)) || any(span < 1) || any(span ~= fix(span))
            error('M2T2:E057:InvalidTileCell', 'Invalid tile number or span.');
        end
        if strcmp(indexing,'rowmajor')
            row = floor((tile-1)/grid(2))+1; column = mod(tile-1,grid(2))+1;
        else
            row = mod(tile-1,grid(1))+1; column = floor((tile-1)/grid(1))+1;
        end
        last = [row column]+span-1;
        if any(last > grid) || any(any(occupied(row:last(1),column:last(2))))
            error('M2T2:E057:InvalidTileCell', 'Tile cells overlap or exceed the fixed grid.');
        end
        occupied(row:last(1),column:last(2)) = true;
        positions(k,:) = [row column span]; keys(k) = (row-1)*grid(2)+column;
    end
    [~, order] = sort(keys); axesHandles = axesHandles(order); positions = positions(order,:);
    cells = cell(1,numel(axesHandles));
    for k = 1:numel(cells)
        p = positions(k,:); cells{k} = m2t2.ir.makeLayoutCell(sprintf('axes-%d',k),p(1),p(2),p(3),p(4));
    end
    decorations = [legends colorbars];
    for k = 1:numel(decorations)
        tile = get(decorations{k},'Layout');
        if ~isnumeric(tile.Tile) || ~isscalar(tile.Tile) || ~isequal(double(tile.TileSpan),[1 1])
            error('M2T2:E058:UnsupportedTileDecoration', ...
                'Layout-owned outer/multi-tile legends or colorbars are unsupported.');
        end
        owner = get(decorations{k},'Axes'); ownerIndex = find(cellfun(@(a) isequal(a,owner),axesHandles));
        if numel(ownerIndex) ~= 1 || tile.Tile ~= get(owner,'Layout').Tile
            error('M2T2:E058:UnsupportedTileDecoration', 'Decoration must remain in its owning axes tile.');
        end
    end
    labels = {}; roles = {'title','xlabel','ylabel'}; properties = {'Title','XLabel','YLabel'};
    for k = 1:numel(roles)
        h = get(handle,properties{k}); text = m2t2.reader.readText(h,['figure.layout.' roles{k}]);
        if isempty(text.value) || ~strcmp(get(h,'Visible'),'on'), continue; end
        if (strcmp(roles{k},'ylabel') && get(h,'Rotation') ~= 90) || ...
                (~strcmp(roles{k},'ylabel') && get(h,'Rotation') ~= 0)
            error(fail, 'Custom shared-label rotation is unsupported.');
        end
        label = m2t2.ir.makeSharedLabel(roles{k},text);
        label.owner = m2t2.ir.makeOwner('layout','layout'); labels{end+1} = label; %#ok<AGROW>
    end
    state = struct('axes',{axesHandles},'legends',{legends},'colorbars',{colorbars}, ...
        'labels',{labels},'layout',m2t2.ir.makeTiledLayout(grid(1),grid(2),cells,indexing,spacing,padding));
end
