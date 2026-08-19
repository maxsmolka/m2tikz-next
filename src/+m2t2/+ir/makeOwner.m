function owner = makeOwner(kind, id)
%MAKEOWNER Construct a runtime-neutral figure-element owner reference.
    if nargin < 1, kind = 'figure'; end
    if nargin < 2, id = 'figure'; end
    owner = struct('kind', kind, 'id', id);
end
