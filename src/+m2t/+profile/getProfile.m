function profile = getProfile(name)
%GETPROFILE Resolve one named, data-driven publication profile.
    name = textScalar(name);
    switch lower(name)
        case 'none'
            profile = struct('name', 'none', 'enabled', false);
        case 'publication'
            profile = m2t.profile.publication();
        otherwise
            error('M2T:PROFILE_UNKNOWN', 'Unknown publication profile: %s.', name);
    end
    m2t.profile.validateProfile(profile);
end

function value = textScalar(value)
    if isa(value, 'string') && isscalar(value), value = char(value); end
    if ~(ischar(value) && isrow(value) && ~isempty(value))
        error('M2T:PROFILE_UNKNOWN', 'Profile must be "none" or "publication".');
    end
end
