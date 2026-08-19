function node = readPatch3(handle, path)
%READPATCH3 Read only an opaque single-triangle Fill3 decoration.
    faces = double(get(handle, 'Faces')); vertices = double(get(handle, 'Vertices'));
    if ~(isequal(size(faces), [1 3]) && isequal(sort(faces), 1:3) && ...
         isequal(size(vertices), [3 3]) && all(isfinite(vertices(:))))
        error('M2T2:E037:Unsupported3DPatchVariant', ...
            'M2T2-E037 Unsupported3DPatchVariant: path=%s reason=only one explicit finite triangle is supported', path);
    end
    faceAlpha = get(handle, 'FaceAlpha'); edgeAlpha = get(handle, 'EdgeAlpha');
    if ~(isnumeric(faceAlpha) && isscalar(faceAlpha) && faceAlpha == 1 && ...
         isnumeric(edgeAlpha) && isscalar(edgeAlpha) && edgeAlpha == 1)
        error('M2T2:E035:UnsupportedSurfaceTransparency', ...
            'M2T2-E035 UnsupportedSurfaceTransparency: path=%s reason=Fill3 decoration must be opaque', path);
    end
    node = m2t2.ir.makePatch3Series();
    node.vertices = vertices(faces, :);
    node.faceColor = m2t2.util.normalizeColor(get(handle, 'FaceColor'), [path '.faceColor']);
    edge = get(handle, 'EdgeColor'); node.edgeVisible = ~strcmpi(char(edge), 'none');
    if node.edgeVisible
        node.edgeColor = m2t2.util.normalizeColor(edge, [path '.edgeColor']);
    end
    node.lineWidth = double(get(handle, 'LineWidth'));
    node.lineStyle = m2t2.util.normalizeLineStyle(get(handle, 'LineStyle'), [path '.lineStyle']);
    node.displayName = m2t2.ir.makeText(m2t2.util.textValue( ...
        get(handle, 'DisplayName'), [path '.displayName']), 'plain');
    node.visible = strcmpi(get(handle, 'Visible'), 'on');
end
