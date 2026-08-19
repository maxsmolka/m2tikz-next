function layout = inferLayout(axesItems)
%INFERLAYOUT Infer conservative logical grid intent from physical geometry.
    layout = m2t2.ir.makeLayout();
    count = numel(axesItems);
    if count < 2 || any(cellfun(@(item) ~isempty(item.overlayOf), axesItems))
        return;
    end
    positions = zeros(count, 4);
    for k = 1:count
        p = axesItems{k}.placement;
        positions(k, :) = [p.x p.y p.width p.height];
    end
    xCenters = positions(:, 1) + positions(:, 3) / 2;
    yCenters = positions(:, 2) + positions(:, 4) / 2;
    columns = clusters(xCenters, false);
    rows = clusters(yCenters, true);
    if numel(rows) * numel(columns) ~= count, return; end

    assignments = zeros(count, 2);
    occupied = false(numel(rows), numel(columns));
    for k = 1:count
        [~, column] = min(abs(columns - xCenters(k)));
        [~, row] = min(abs(rows - yCenters(k)));
        if occupied(row, column), return; end
        occupied(row, column) = true;
        assignments(k, :) = [row column];
    end
    if ~all(occupied(:)) || ~alignedGrid(positions, assignments, numel(rows), numel(columns))
        return;
    end
    cells = cell(1, count);
    for k = 1:count
        cells{k} = m2t2.ir.makeLayoutCell(axesItems{k}.id, ...
            assignments(k, 1), assignments(k, 2), 1, 1);
    end
    layout = m2t2.ir.makeLayout('grid', numel(rows), numel(columns), cells);
end

function centers = clusters(values, descending)
    tolerance = 0.02;
    values = sort(reshape(values, 1, []));
    centers = [];
    counts = [];
    for k = 1:numel(values)
        if isempty(centers) || abs(values(k) - centers(end)) > tolerance
            centers(end + 1) = values(k); %#ok<AGROW>
            counts(end + 1) = 1; %#ok<AGROW>
        else
            counts(end) = counts(end) + 1;
            centers(end) = centers(end) + (values(k) - centers(end)) / counts(end);
        end
    end
    if descending, centers = fliplr(centers); end
end

function yes = alignedGrid(positions, assignments, rowCount, columnCount)
    tolerance = 0.02;
    yes = true;
    for row = 1:rowCount
        group = positions(assignments(:, 1) == row, [2 4]);
        if spread(group(:, 1)) > tolerance || spread(group(:, 2)) > tolerance
            yes = false; return;
        end
    end
    for column = 1:columnCount
        group = positions(assignments(:, 2) == column, [1 3]);
        if spread(group(:, 1)) > tolerance || spread(group(:, 2)) > tolerance
            yes = false; return;
        end
    end
end

function value = spread(values)
    if isempty(values), value = inf; else, value = max(values) - min(values); end
end
