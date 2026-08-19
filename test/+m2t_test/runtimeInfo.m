function info = runtimeInfo()
%RUNTIMEINFO Collect compatibility metadata without identity or license data.
    isOctave = exist('OCTAVE_VERSION', 'builtin') ~= 0;
    if isOctave
        kind = 'octave'; versionText = OCTAVE_VERSION; releaseText = '';
    else
        kind = 'matlab'; versionText = version;
        try, releaseText = version('-release'); catch, releaseText = ''; end
    end
    architecture = computer('arch');
    if ispc, os = 'windows'; elseif ismac, os = 'macos'; else, os = 'linux'; end
    toolkit = '';
    if isOctave
        try, toolkit = graphics_toolkit(); catch, toolkit = ''; end
    end
    installed = ver;
    products = cell(1, numel(installed));
    for k = 1:numel(installed)
        products{k} = struct('name', installed(k).Name, 'version', installed(k).Version);
    end
    info = struct('kind', kind, 'version', versionText, 'release', releaseText, ...
                  'os', os, 'architecture', architecture, ...
                  'graphicsToolkit', toolkit, 'products', {products});
end
