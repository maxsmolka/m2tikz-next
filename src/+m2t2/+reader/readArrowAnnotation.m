function node = readArrowAnnotation(handle, pane, path, id)
%READARROWANNOTATION Normalize supported figure-owned arrow capabilities.
    if ~sameHandle(get(handle, 'Parent'), pane)
        ownership(path, 'annotation child is not owned by the discovered pane');
    end
    type = char(get(handle, 'Type'));
    switch type
        case 'arrowshape'
            annotationKind = 'arrow';
        case 'doubleendarrowshape'
            annotationKind = 'doublearrow';
        otherwise
            unsupportedType(path, type);
    end
    units = lower(char(get(handle, 'Units')));
    if ~strcmp(units, 'normalized')
        coordinateSpace(path, units);
    end
    x = reshape(double(get(handle, 'X')), 1, []);
    y = reshape(double(get(handle, 'Y')), 1, []);
    if numel(x) ~= 2 || numel(y) ~= 2 || any(~isfinite([x y]))
        malformed(path, 'X and Y must be finite endpoint pairs');
    end
    node = m2t2.ir.makeArrowAnnotation(annotationKind);
    node.id = id;
    node.start = [x(1) y(1)];
    node.end = [x(2) y(2)];
    node.style = m2t2.util.normalizeLineStyle(char(get(handle, 'LineStyle')), ...
        [path '.LineStyle']);
    if strcmp(node.style, 'none')
        error('M2T2:E007:UnsupportedProperty', ...
            'M2T2-E007 UnsupportedProperty: path=%s property=LineStyle value=none', path);
    end
    node.width = double(get(handle, 'LineWidth'));
    node.color = m2t2.util.normalizeColor(get(handle, 'Color'), [path '.Color']);
    node.visible = strcmpi(char(get(handle, 'Visible')), 'on');
    if strcmp(annotationKind, 'arrow')
        node.startHead = m2t2.ir.makeArrowHead();
        node.endHead = readHead(handle, 'Head', [path '.endHead']);
    else
        node.startHead = readHead(handle, 'Head1', [path '.startHead']);
        node.endHead = readHead(handle, 'Head2', [path '.endHead']);
    end
end

function head = readHead(handle, prefix, path)
    style = lower(char(get(handle, [prefix 'Style'])));
    if ~any(strcmp(style, {'none','vback2'}))
        error('M2T2:E007:UnsupportedProperty', ...
            'M2T2-E007 UnsupportedProperty: path=%s property=Style value=%s', ...
            path, style);
    end
    if strcmp(style, 'none')
        head = m2t2.ir.makeArrowHead();
        return
    end
    length = double(get(handle, [prefix 'Length']));
    width = double(get(handle, [prefix 'Width']));
    if ~(isscalar(length) && isfinite(length) && length > 0 && ...
            isscalar(width) && isfinite(width) && width > 0)
        malformed(path, 'arrow-head length and width must be positive finite scalars');
    end
    head = m2t2.ir.makeArrowHead(style, length, width);
end

function yes = sameHandle(first, second)
    try
        value = first == second;
        yes = isscalar(value) && logical(value);
    catch
        yes = isequal(first, second);
    end
end

function unsupportedType(path, type)
    error('M2T2:E013:UnsupportedAnnotationType', ...
        'M2T2-E013 UnsupportedAnnotationType: path=%s type=%s', path, type);
end

function coordinateSpace(path, value)
    error('M2T2:E014:UnsupportedAnnotationCoordinateSpace', ...
        'M2T2-E014 UnsupportedAnnotationCoordinateSpace: path=%s value=%s', ...
        path, value);
end

function malformed(path, reason)
    error('M2T2:E016:MalformedAnnotation', ...
        'M2T2-E016 MalformedAnnotation: path=%s reason=%s', path, reason);
end

function ownership(path, reason)
    error('M2T2:E017:UnsupportedAnnotationOwnership', ...
        'M2T2-E017 UnsupportedAnnotationOwnership: path=%s reason=%s', ...
        path, reason);
end
