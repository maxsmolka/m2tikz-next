function paths = normalizeOutputBase(outputBase)
%NORMALIZEOUTPUTBASE Resolve a user-provided extension-free output base.
    if isa(outputBase, 'string') && isscalar(outputBase), outputBase = char(outputBase); end
    if ~(ischar(outputBase) && isrow(outputBase) && ~isempty(strtrim(outputBase)))
        error('M2T:E001:InvalidArgument', ...
              'outputBase must be a non-empty text scalar.');
    end
    if any(outputBase == sprintf('\r')) || any(outputBase == sprintf('\n')) || ...
       any(outputBase == char(0))
        error('M2T:E002:InvalidOutputPath', ...
              'outputBase contains an invalid control character.');
    end
    if ~isAbsolute(outputBase), outputBase = fullfile(pwd, outputBase); end
    [directory, name] = fileparts(outputBase);
    if isempty(name)
        error('M2T:E002:InvalidOutputPath', ...
              'outputBase must include a file name without an extension.');
    end
    paths = struct('base', outputBase, 'directory', directory, ...
                   'texPath', [outputBase '.tex'], ...
                   'pdfPath', [outputBase '.pdf'], ...
                   'logPath', [outputBase '.compile.log'], ...
                   'assetDirectory', [outputBase '-assets'], ...
                   'assetDirectoryName', [name '-assets']);
end

function yes = isAbsolute(path)
    if ispc
        yes = ~isempty(regexp(path, '^[A-Za-z]:[\\/]', 'once')) || ...
              strncmp(path, '\\', 2) || strncmp(path, '//', 2);
    else
        yes = strncmp(path, '/', 1);
    end
end
