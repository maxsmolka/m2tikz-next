function decision = selectImageBackend(ir, requested, policy)
%SELECTIMAGEBACKEND Select vector or hybrid from normalized FigureIR only.
    if nargin < 3, policy = m2t.planning.defaultPolicy(); end
    requested = m2t.internal.normalizeImageBackend(requested);
    validatePolicy(policy);
    m2t2.ir.validate(ir);

    imageCells = zeros(1, 0); hasRgb = false; hasAlpha = false;
    for a = 1:numel(ir.axes)
        for s = 1:numel(ir.axes{a}.series)
            item = ir.axes{a}.series{s};
            if strcmp(item.kind, 'm2t2.image') && item.visible
                imageCells(end + 1) = size(item.cdata,1) * size(item.cdata,2); %#ok<AGROW>
                hasRgb = hasRgb || strcmp(item.colorMode, 'rgb');
                hasAlpha = hasAlpha || ~strcmp(item.alphaMode, 'opaque');
            end
        end
    end

    if strcmp(requested, 'vector') && (hasRgb || hasAlpha)
        error('M2T2:E053:UnsupportedVectorRichImage', ...
              'M2T2:E053:UnsupportedVectorRichImage: RGB and alpha require hybrid');
    elseif strcmp(requested, 'vector')
        selected = 'vector'; reason = 'explicit_vector';
    elseif strcmp(requested, 'hybrid')
        selected = 'hybrid'; reason = 'explicit_hybrid';
    elseif isempty(imageCells)
        selected = 'vector'; reason = 'no_image_layer';
    elseif hasAlpha
        selected = 'hybrid'; reason = 'alpha_requires_hybrid';
    elseif hasRgb
        selected = 'hybrid'; reason = 'truecolor_requires_hybrid';
    elseif max(imageCells) <= policy.maxVectorCells
        selected = 'vector'; reason = 'small_scalar_image';
    else
        selected = 'hybrid'; reason = 'dense_scalar_image';
    end

    decision = struct('requested', requested, 'selected', selected, ...
                      'reason', reason, 'policy', policy, ...
                      'imageLayerCount', numel(imageCells), ...
                      'maxImageCells', maximumOrZero(imageCells));
end

function validatePolicy(policy)
    required = {'name','version','maxVectorCells','id'};
    if ~(isstruct(policy) && isscalar(policy) && ...
            all(cellfun(@(name) isfield(policy, name), required)))
        invalid('Policy must be a scalar struct with name, version, maxVectorCells, and id.');
    end
    if ~(ischar(policy.name) && isrow(policy.name) && ~isempty(policy.name) && ...
            ischar(policy.id) && isrow(policy.id) && ~isempty(policy.id) && ...
            isnumeric(policy.version) && isscalar(policy.version) && ...
            isfinite(policy.version) && policy.version >= 1 && policy.version == fix(policy.version) && ...
            isnumeric(policy.maxVectorCells) && isscalar(policy.maxVectorCells) && ...
            isfinite(policy.maxVectorCells) && policy.maxVectorCells >= 1 && ...
            policy.maxVectorCells == fix(policy.maxVectorCells))
        invalid('Policy fields must contain nonempty text and positive integer values.');
    end
end

function invalid(message)
    error('M2T:BACKEND_POLICY_INVALID', '%s', message);
end

function value = maximumOrZero(values)
    if isempty(values), value = 0; else, value = max(values); end
end
