function sizePoints = readFigureSize(figureHandle, path)
%READFIGURESIZE Read renderer-neutral physical figure size in PostScript points.
    originalUnits = get(figureHandle, 'PaperUnits');
    restore = onCleanup(@() set(figureHandle, 'PaperUnits', originalUnits)); %#ok<NASGU>
    set(figureHandle, 'PaperUnits', 'points');
    paperPosition = reshape(double(get(figureHandle, 'PaperPosition')), 1, []);
    if numel(paperPosition) ~= 4 || any(~isfinite(paperPosition(3:4))) || ...
            any(paperPosition(3:4) <= 0)
        error('M2T2:E009:InvalidPlacement', ...
              'M2T2-E009 InvalidPlacement: path=%s reason=invalid physical figure size', path);
    end
    sizePoints = paperPosition(3:4);
end
