function node = readTextAnnotation(handle, path, id, axesId)
%READTEXTANNOTATION Normalize a supported axes-owned 2-D text object.
    units = lower(char(get(handle, 'Units')));
    if ~strcmp(units, 'data')
        coordinateSpace(path, units);
    end
    position = reshape(double(get(handle, 'Position')), 1, []);
    if numel(position) ~= 3 || any(~isfinite(position)) || abs(position(3)) > 1e-12
        malformed([path '.Position'], 'expected finite 2-D data position [x y 0]');
    end
    try
        textNode = m2t2.reader.readText(handle, [path '.text']);
    catch err
        if strcmp(err.identifier, 'M2T2:E007:UnsupportedProperty')
            error('M2T2:E015:UnsupportedAnnotationInterpreter', ...
                'M2T2-E015 UnsupportedAnnotationInterpreter: path=%s value=%s', ...
                path, char(get(handle, 'Interpreter')));
        end
        rethrow(err);
    end
    node = m2t2.ir.makeTextAnnotation();
    node.id = id;
    node.owner = m2t2.ir.makeOwner('axes', axesId);
    node.position = position(1:2);
    node.text = textNode;
    node.horizontalAlignment = lower(char(get(handle, 'HorizontalAlignment')));
    node.verticalAlignment = lower(char(get(handle, 'VerticalAlignment')));
    node.rotation = double(get(handle, 'Rotation'));
    node.fontSize = double(get(handle, 'FontSize'));
    node.fontWeight = lower(char(get(handle, 'FontWeight')));
    node.fontAngle = lower(char(get(handle, 'FontAngle')));
    node.color = m2t2.util.normalizeColor(get(handle, 'Color'), [path '.Color']);
    node.visible = strcmpi(char(get(handle, 'Visible')), 'on');
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
