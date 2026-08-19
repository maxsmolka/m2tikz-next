function cellNode = makeLayoutCell(axesId, row, column, rowSpan, columnSpan)
%MAKELAYOUTCELL Map an axes ID to logical one-based grid coordinates.
    if nargin < 1, axesId = ''; end
    if nargin < 2, row = 1; end
    if nargin < 3, column = 1; end
    if nargin < 4, rowSpan = 1; end
    if nargin < 5, columnSpan = 1; end
    cellNode = struct('axesId', axesId, 'row', row, 'column', column, ...
                      'rowSpan', rowSpan, 'columnSpan', columnSpan);
end
