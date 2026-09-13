function paths = normalizeOutputBase(outputBase)
%NORMALIZEOUTPUTBASE Resolve a user-provided extension-free output base.
    if isa(outputBase, 'string') && isscalar(outputBase), outputBase = char(outputBase); end
    if ~(ischar(outputBase) && isrow(outputBase) && ~isempty(strtrim(outputBase)))
        error('M2T:E001:InvalidArgument', ...
              'outputBase must be a non-empty text scalar.');
    end
    if any(double(outputBase) < 32) || any(double(outputBase) == 127)
        error('M2T:E002:InvalidOutputPath', ...
              'outputBase contains an invalid control character.');
    end
    if ~isAbsolute(outputBase), outputBase = fullfile(pwd, outputBase); end
    [directory, name, extension] = fileparts(outputBase);
    name = [name extension];
    if isempty(name) || any(strcmp(name, {'.','..'})) || ...
            any(outputBase(end) == [char(47) char(92)])
        error('M2T:E002:InvalidOutputPath', ...
              'outputBase must include a file name without an extension.');
    end
    % Stems may contain dots. Keep their complete spelling for owned assets.
    % File names embedded in generated TeX must not introduce TeX tokens.
    if any(ismember(name, [char(92) '"%#{}$&^~']))
        error('M2T:E002:InvalidOutputPath', ...
              'Output file name contains unsupported TeX/path characters.');
    end
    if ispc && (any(ismember(outputBase(3:end), ':<>"|?*%!')) || ...
            ~isempty(regexp(name, '^(?i:CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(?:\.|$)', 'once')) || ...
            any(name(end) == '. '))
        error('M2T:E002:InvalidOutputPath', 'Unsupported Windows output file name.');
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
