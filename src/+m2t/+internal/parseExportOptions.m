function options = parseExportOptions(varargin)
%PARSEEXPORTOPTIONS Parse the shared M3 single-figure option vocabulary.
    options = struct('overwrite', false, 'profile', 'none', 'width', [], ...
                     'imageBackend', 'vector');
    if mod(numel(varargin), 2) ~= 0
        error('M2T:E001:InvalidArgument', ...
              'Name-value options must be provided in pairs.');
    end
    for k = 1:2:numel(varargin)
        name = textScalar(varargin{k}, 'option name');
        switch lower(name)
            case 'overwrite'
                value = varargin{k + 1};
                if ~(islogical(value) && isscalar(value))
                    error('M2T:E001:InvalidArgument', ...
                          'Overwrite must be a logical scalar.');
                end
                options.overwrite = value;
            case 'profile'
                options.profile = varargin{k + 1};
            case 'width'
                options.width = varargin{k + 1};
            case 'imagebackend'
                options.imageBackend = m2t.internal.normalizeImageBackend(varargin{k + 1});
            otherwise
                error('M2T:E001:InvalidArgument', 'Unknown option: %s.', name);
        end
    end
end

function value = textScalar(value, name)
    if isa(value, 'string') && isscalar(value), value = char(value); end
    if ~(ischar(value) && (isrow(value) || isempty(value)))
        error('M2T:E001:InvalidArgument', '%s must be text.', name);
    end
end
