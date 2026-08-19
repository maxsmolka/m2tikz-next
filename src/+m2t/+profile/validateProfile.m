function validateProfile(profile)
%VALIDATEPROFILE Validate normalized profile data independently of graphics.
    if ~(isstruct(profile) && isscalar(profile) && ...
         isfield(profile, 'name') && isfield(profile, 'enabled'))
        invalid('profile identity is missing');
    end
    if ~(ischar(profile.name) && isrow(profile.name) && ~isempty(profile.name))
        invalid('name must be nonempty text');
    end
    if ~(islogical(profile.enabled) && isscalar(profile.enabled))
        invalid('enabled must be a logical scalar');
    end
    if ~profile.enabled, return; end

    required = {'figure','axes','text','line','scatter','legend','colorbar'};
    for k = 1:numel(required)
        if ~isfield(profile, required{k}), invalid(['missing section ' required{k}]); end
    end
    figureFields = {'defaultWidth','widthNames','widthMillimeters','widthTeXPoints', ...
                    'minimumAspectRatio','maximumAspectRatio','standaloneBorderPt'};
    requireFields(profile.figure, figureFields, 'figure');
    if ~(iscell(profile.figure.widthNames) && ~isempty(profile.figure.widthNames) && ...
         all(cellfun(@(value) ischar(value) && isrow(value) && ~isempty(value), ...
                     profile.figure.widthNames)))
        invalid('widthNames must contain nonempty text presets');
    end
    if ~(isnumeric(profile.figure.widthMillimeters) && ...
         isnumeric(profile.figure.widthTeXPoints))
        invalid('physical widths must be numeric');
    end
    if numel(profile.figure.widthNames) ~= numel(profile.figure.widthMillimeters) || ...
       numel(profile.figure.widthNames) ~= numel(profile.figure.widthTeXPoints)
        invalid('width preset arrays have different lengths');
    end
    if ~any(strcmp(profile.figure.defaultWidth, profile.figure.widthNames))
        invalid('defaultWidth does not name a width preset');
    end
    positive = [profile.figure.widthMillimeters profile.figure.widthTeXPoints ...
                profile.figure.minimumAspectRatio profile.figure.maximumAspectRatio];
    if any(~isfinite(positive)) || any(positive <= 0) || ...
       profile.figure.minimumAspectRatio > profile.figure.maximumAspectRatio
        invalid('figure dimensions or aspect-ratio bounds are invalid');
    end
    if ~(isnumeric(profile.figure.standaloneBorderPt) && ...
         isscalar(profile.figure.standaloneBorderPt) && ...
         isfinite(profile.figure.standaloneBorderPt) && ...
         profile.figure.standaloneBorderPt >= 0)
        invalid('standaloneBorderPt must be a finite nonnegative scalar');
    end
    textFields = {'basePt','axesLabelPt','titlePt','tickLabelPt'};
    requireFields(profile.text, textFields, 'text');
    requireFields(profile.legend, {'textPt'}, 'legend');
    requireFields(profile.colorbar, {'labelPt','tickLabelPt'}, 'colorbar');
    sizes = [profile.text.basePt profile.text.axesLabelPt profile.text.titlePt ...
             profile.text.tickLabelPt profile.legend.textPt ...
             profile.colorbar.labelPt profile.colorbar.tickLabelPt];
    if ~(isnumeric(sizes) && all(isfinite(sizes)) && all(sizes > 0))
        invalid('typography sizes must be positive finite points');
    end
end

function requireFields(value, names, section)
    for k = 1:numel(names)
        if ~isfield(value, names{k}), invalid([section ' missing ' names{k}]); end
    end
end

function invalid(reason)
    error('M2T:PROFILE_INVALID', 'Invalid publication profile: %s.', reason);
end
