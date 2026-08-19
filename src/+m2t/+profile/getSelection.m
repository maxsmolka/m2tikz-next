function selection = getSelection(name, width)
%GETSELECTION Resolve and validate public profile/width configuration.
    if nargin < 2, width = []; end
    profile = m2t.profile.getProfile(name);
    if ~profile.enabled
        if ~isempty(width)
            error('M2T:PROFILE_WIDTH_INVALID', ...
                  'Width is only valid when Profile="publication".');
        end
        selection = struct('profile', profile, 'width', [], ...
                           'profileName', 'none', 'widthName', 'source');
        return
    end

    if isempty(width)
        widthName = profile.figure.defaultWidth;
    else
        if isa(width, 'string') && isscalar(width), width = char(width); end
        if ~(ischar(width) && isrow(width) && ~isempty(width))
            error('M2T:PROFILE_WIDTH_INVALID', ...
                  'Width must be "single-column" or "double-column".');
        end
        widthName = lower(width);
    end
    if ~any(strcmp(widthName, profile.figure.widthNames))
        error('M2T:PROFILE_WIDTH_INVALID', ...
              'Unsupported publication Width preset: %s.', widthName);
    end
    selection = struct('profile', profile, 'width', widthName, ...
                       'profileName', profile.name, 'widthName', widthName);
end
