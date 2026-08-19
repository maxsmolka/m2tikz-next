function placement = readNormalizedPosition(axesHandle, path)
%READNORMALIZEDPOSITION Read the axes plotting rectangle in figure coordinates.
    originalUnits = get(axesHandle, 'Units');
    restore = onCleanup(@() set(axesHandle, 'Units', originalUnits)); %#ok<NASGU>
    set(axesHandle, 'Units', 'normalized');
    value = reshape(double(get(axesHandle, 'Position')), 1, []);
    if numel(value) ~= 4
        invalid(path, 'Position must contain four values');
    end
    tolerance = 1e-10;
    value(abs(value) < tolerance) = 0;
    value(abs(value - 1) < tolerance) = 1;
    placement = m2t2.ir.makePlacement(value(1), value(2), value(3), value(4));
end

function invalid(path, reason)
    error('M2T2:E009:InvalidPlacement', ...
          'M2T2-E009 InvalidPlacement: path=%s reason=%s', path, reason);
end
