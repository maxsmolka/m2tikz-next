function outcome = compileLuaLatex(texPath, pdfPath, compiler)
%COMPILELUALATEX Compile standalone TeX in an isolated temporary directory.
    if nargin < 3, compiler = 'lualatex'; end
    compiler = textScalar(compiler, 'compiler');
    outcome = struct('success', false, 'compiler', compiler, 'logPath', '', ...
                     'diagnostics', m2t.internal.emptyDiagnostics());
    failureLog = [stripExtension(pdfPath) '.compile.log'];

    versionCommand = [quoteArgument(compiler) ' --version 2>&1'];
    [available, ~] = system(versionCommand);
    if available ~= 0
        message = sprintf('LuaLaTeX was not found on PATH (command: %s).', compiler);
        outcome.diagnostics(end + 1) = m2t.internal.makeDiagnostic( ...
            'error', 'M2T:C001:CompilerNotFound', message, 'compile');
        return
    end

    buildDirectory = tempname;
    [created, message] = mkdir(buildDirectory);
    if ~created
        outcome.diagnostics(end + 1) = m2t.internal.makeDiagnostic( ...
            'error', 'M2T:C002:BuildDirectoryFailed', ...
            sprintf('Cannot create temporary compiler directory: %s', message), 'compile');
        return
    end
    cacheDirectory = fullfile(tempdir, 'm2t-texmf-cache');
    if exist(cacheDirectory, 'dir') ~= 7, mkdir(cacheDirectory); end
    previousTexmfVar = getenv('TEXMFVAR');
    previousTexmfCache = getenv('TEXMFCACHE');
    previousTexInputs = getenv('TEXINPUTS');
    setenv('TEXMFVAR', cacheDirectory);
    setenv('TEXMFCACHE', cacheDirectory);
    texDirectory = fileparts(texPath);
    setenv('TEXINPUTS', [texDirectory pathsep previousTexInputs pathsep]);
    cleanup = onCleanup(@() cleanupCompiler( ...
        buildDirectory, previousTexmfVar, previousTexmfCache, previousTexInputs));

    command = [quoteArgument(compiler) ...
        ' -interaction=nonstopmode -halt-on-error -file-line-error' ...
        ' -output-directory=' quoteArgument(buildDirectory) ...
        ' ' quoteArgument(texPath) ' 2>&1'];
    [exitCode, processOutput] = system(command);
    [~, name] = fileparts(texPath);
    engineLog = fullfile(buildDirectory, [name '.log']);
    logText = readIfPresent(engineLog);

    if exitCode ~= 0
        combined = combineLogs(processOutput, logText);
        try
            m2t.internal.writeTextFile(failureLog, combined);
            outcome.logPath = failureLog;
        catch
            outcome.logPath = '';
        end
        firstError = firstTexError(combined);
        if isempty(firstError)
            firstError = sprintf('LuaLaTeX exited with code %d.', exitCode);
        end
        if ~isempty(outcome.logPath)
            message = sprintf('%s Log: %s', firstError, outcome.logPath);
        else
            message = firstError;
        end
        outcome.diagnostics(end + 1) = m2t.internal.makeDiagnostic( ...
            'error', 'M2T:C003:CompilationFailed', message, 'compile');
        return
    end

    candidate = fullfile(buildDirectory, [name '.pdf']);
    if exist(candidate, 'file') == 2
        try
            copyBinary(candidate, pdfPath);
        catch err
            outcome.diagnostics(end + 1) = m2t.internal.makeDiagnostic( ...
                'error', 'M2T:C004:PdfCopyFailed', ...
                sprintf('LuaLaTeX succeeded but the PDF could not be copied: %s', err.message), ...
                'compile');
            return
        end
    end
    outcome.success = true;
    clear cleanup;
end

function value = quoteArgument(value)
    value = textScalar(value, 'process argument');
    if any(value == sprintf('\r')) || any(value == sprintf('\n'))
        error('M2T:C005:UnsafeProcessArgument', ...
              'Process arguments must not contain line breaks.');
    end
    if ispc
        if any(value == '"') || any(value == '%')
            error('M2T:C005:UnsafeProcessArgument', ...
                  'Windows process arguments must not contain double quotes or percent signs.');
        end
        value = strrep(value, '\', '/');
        value = ['"' value '"'];
    else
        value = strrep(value, '\', '\\');
        value = strrep(value, '"', '\"');
        value = strrep(value, '$', '\$');
        value = strrep(value, '`', '\`');
        value = ['"' value '"'];
    end
end

function value = textScalar(value, name)
    if isa(value, 'string') && isscalar(value), value = char(value); end
    if ~(ischar(value) && (isrow(value) || isempty(value)))
        error('M2T:E001:InvalidArgument', '%s must be text.', name);
    end
end

function value = stripExtension(path)
    [folder, name] = fileparts(path);
    value = fullfile(folder, name);
end

function value = readIfPresent(path)
    if exist(path, 'file') == 2, value = fileread(path); else, value = ''; end
end

function value = combineLogs(processOutput, engineLog)
    value = processOutput;
    if ~isempty(engineLog)
        value = [value sprintf('\n--- LuaLaTeX engine log ---\n') engineLog];
    end
end

function value = firstTexError(logText)
    value = '';
    lines = regexp(logText, '\r\n|\n|\r', 'split');
    for k = 1:numel(lines)
        if ~isempty(regexp(lines{k}, '^\s*!', 'once'))
            value = strtrim(lines{k});
            return
        end
    end
    normalized = regexprep(logText, '\s+', ' ');
    if ~isempty(regexpi(normalized, 'no writeable cache path', 'once'))
        value = 'LuaLaTeX has no writable font/package cache path.';
        return
    end
    if ~isempty(regexpi(normalized, ...
            'Undefined\s+control\s+s\s*e\s*q\s*u\s*e\s*n\s*c\s*e', 'once'))
        value = 'Undefined control sequence.';
        return
    end
    patterns = {'LaTeX Error:', 'Package .* Error:', ...
                'Undefined control sequence', 'font.+cannot be found'};
    for p = 1:numel(patterns)
        for k = 1:numel(lines)
            if ~isempty(regexpi(lines{k}, patterns{p}, 'once'))
                value = strtrim(lines{k});
                return
            end
        end
    end
end

function cleanupCompiler(path, previousTexmfVar, previousTexmfCache, previousTexInputs)
    setenv('TEXMFVAR', previousTexmfVar);
    setenv('TEXMFCACHE', previousTexmfCache);
    setenv('TEXINPUTS', previousTexInputs);
    if exist(path, 'dir') == 7, rmdir(path, 's'); end
end

function copyBinary(source, target)
    input = fopen(source, 'rb');
    if input < 0, error('Cannot read compiler PDF: %s', source); end
    output = fopen(target, 'wb');
    if output < 0
        fclose(input);
        error('Cannot open final PDF: %s', target);
    end
    try
        while true
            bytes = fread(input, 65536, '*uint8');
            if isempty(bytes), break; end
            if fwrite(output, bytes, 'uint8') ~= numel(bytes)
                error('Incomplete PDF write: %s', target);
            end
        end
        fclose(input);
        fclose(output);
    catch err
        try, fclose(input); catch, end
        try, fclose(output); catch, end
        rethrow(err);
    end
end
