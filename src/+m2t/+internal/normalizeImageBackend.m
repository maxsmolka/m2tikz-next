function value = normalizeImageBackend(value)
%NORMALIZEIMAGEBACKEND Validate the scalar-image rendering request.
    if isa(value, 'string') && isscalar(value), value = char(value); end
    if ~(ischar(value) && isrow(value) && ~isempty(value))
        error('M2T:IMAGE_BACKEND_UNKNOWN', ...
              'ImageBackend must be "vector", "hybrid", or "auto".');
    end
    value = lower(value);
    if ~any(strcmp(value, {'vector','hybrid','auto'}))
        error('M2T:IMAGE_BACKEND_UNKNOWN', ...
              ['Unknown ImageBackend: %s. Expected "vector", "hybrid", ' ...
               'or "auto".'], value);
    end
end
