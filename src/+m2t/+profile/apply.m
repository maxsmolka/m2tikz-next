function transformation = apply(ir, profile, width)
%APPLY Transform validated IR geometry and create generic render configuration.
    if nargin < 3, width = []; end
    m2t2.ir.validate(ir);
    m2t.profile.validateProfile(profile);
    transformation = struct( ...
        'success', false, ...
        'ir', ir, ...
        'renderConfig', m2t2.render.defaultConfig(), ...
        'metadata', metadata('none', 'source', [], ir.size), ...
        'diagnostics', m2t.internal.emptyDiagnostics());

    if ~profile.enabled
        if ~isempty(width)
            transformation.diagnostics(end + 1) = m2t.internal.makeDiagnostic( ...
                'error', 'M2T:PROFILE_WIDTH_INVALID', ...
                'Width is only valid when Profile="publication".', 'analysis');
            return
        end
        transformation.success = true;
        return
    end

    [presetName, presetIndex, widthDiagnostic] = resolveWidth(width, profile);
    if ~isempty(widthDiagnostic)
        transformation.diagnostics(end + 1) = widthDiagnostic;
        return
    end
    if ~(isnumeric(ir.size) && numel(ir.size) == 2 && ...
         all(isfinite(ir.size)) && all(ir.size > 0))
        transformation.diagnostics(end + 1) = m2t.internal.makeDiagnostic( ...
            'error', 'M2T:PROFILE_GEOMETRY_INVALID', ...
            'The source FigureIR must have a positive finite physical size.', 'analysis');
        return
    end

    sourceAspectRatio = ir.size(2) / ir.size(1);
    targetAspectRatio = min(max(sourceAspectRatio, ...
        profile.figure.minimumAspectRatio), profile.figure.maximumAspectRatio);
    if targetAspectRatio ~= sourceAspectRatio
        message = sprintf(['Source aspect ratio %.6g was clamped to %.6g ' ...
                           'for usable publication geometry.'], ...
                          sourceAspectRatio, targetAspectRatio);
        transformation.diagnostics(end + 1) = m2t.internal.makeDiagnostic( ...
            'warning', 'M2T:PROFILE_ASPECT_CLAMPED', message, 'analysis');
    end

    targetWidth = profile.figure.widthTeXPoints(presetIndex);
    transformed = ir;
    transformed.size = [targetWidth targetWidth * targetAspectRatio];
    transformation.ir = transformed;
    transformation.renderConfig = renderConfig(profile);
    transformation.metadata = metadata(profile.name, presetName, ...
        profile.figure.widthMillimeters(presetIndex), transformed.size);
    transformation.success = true;
end

function [name, index, diagnostic] = resolveWidth(width, profile)
    diagnostic = m2t.internal.emptyDiagnostics();
    if isempty(width)
        name = profile.figure.defaultWidth;
    else
        if isa(width, 'string') && isscalar(width), width = char(width); end
        if ~(ischar(width) && isrow(width) && ~isempty(width))
            name = ''; index = [];
            diagnostic = m2t.internal.makeDiagnostic( ...
                'error', 'M2T:PROFILE_WIDTH_INVALID', ...
                'Width must be "single-column" or "double-column".', 'analysis');
            return
        end
        name = lower(width);
    end
    index = find(strcmp(name, profile.figure.widthNames), 1);
    if isempty(index)
        diagnostic = m2t.internal.makeDiagnostic( ...
            'error', 'M2T:PROFILE_WIDTH_INVALID', ...
            sprintf('Unsupported publication Width preset: %s.', name), 'analysis');
    end
end

function config = renderConfig(profile)
    config = m2t2.render.defaultConfig();
    config.standaloneBorderPt = profile.figure.standaloneBorderPt;
    config.typography.basePt = profile.text.basePt;
    config.typography.axesLabelPt = profile.text.axesLabelPt;
    config.typography.titlePt = profile.text.titlePt;
    config.typography.tickLabelPt = profile.text.tickLabelPt;
    config.typography.legendPt = profile.legend.textPt;
    config.typography.colorbarLabelPt = profile.colorbar.labelPt;
    config.typography.colorbarTickLabelPt = profile.colorbar.tickLabelPt;
end

function value = metadata(name, width, widthMillimeters, figureSize)
    value = struct('name', name, 'width', width, ...
                   'widthMillimeters', widthMillimeters, ...
                   'figureSize', figureSize, 'figureSizeUnit', 'pt');
end
