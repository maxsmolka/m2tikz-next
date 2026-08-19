function layout = makeLayout(kind, rows, columns, cells)
%MAKELAYOUT Construct optional logical figure-layout metadata.
    if nargin < 1, kind = 'freeform'; end
    if nargin < 2, rows = 0; end
    if nargin < 3, columns = 0; end
    if nargin < 4, cells = {}; end
    layout = struct('kind', kind, 'rows', rows, 'columns', columns, ...
                    'cells', {cells});
end
