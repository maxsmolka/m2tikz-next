function layout = makeTiledLayout(rows, columns, cells, indexing, spacing, padding)
%MAKETILEDLAYOUT Explicit fixed-grid intent plus resolved physical geometry.
    if nargin < 4, indexing = 'rowmajor'; end
    if nargin < 5, spacing = 'loose'; end
    if nargin < 6, padding = 'loose'; end
    layout = m2t2.ir.makeLayout('grid', rows, columns, cells);
    layout.tiled = struct('arrangement', 'fixed', 'indexing', indexing, ...
        'spacing', spacing, 'padding', padding, 'geometry', 'resolved-runtime');
end
