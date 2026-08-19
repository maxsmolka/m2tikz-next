function result = exportSet(entries, outputDirectory, varargin)
%EXPORTSET Export, compile, and validate an explicitly supplied figure set.
%   RESULT = M2T.EXPORTSET(ENTRIES, OUTPUTDIRECTORY) processes struct-array
%   entries with required fields `figure` and `name`. Profile, Width, and
%   Overwrite and ImageBackend are inherited from set defaults and may be
%   overridden by an entry. ContinueOnError defaults to true.

    totalTimer = tic;
    result = emptySetResult();
    printSummary = nargout == 0;
    if isstruct(entries), result.summary.total = numel(entries); end

    preflightTimer = tic;
    try
        [plan, options, normalizedDirectory] = preflight( ...
            entries, outputDirectory, varargin{:});
        result.outputDirectory = normalizedDirectory;
        result.manifestPath = fullfile(normalizedDirectory, 'm2t-manifest.json');
        result.summary.total = numel(plan);
    catch err
        result.timings.preflight = toc(preflightTimer);
        result.diagnostics(end + 1) = setDiagnostic(err);
        result.status = 'invalid_set';
        result = complete(result, totalTimer, printSummary);
        return
    end
    result.timings.preflight = toc(preflightTimer);

    exportTimer = tic;
    result.entries = repmat(entryResultTemplate(), 1, numel(plan));
    stop = false;
    for k = 1:numel(plan)
        if stop
            single = skippedResult(plan(k));
        else
            callOptions = exportCallOptions(plan(k));
            single = m2t.export(plan(k).figure, plan(k).outputBase, callOptions{:});
            if ~single.success && ~options.continueOnError, stop = true; end
        end
        result.entries(k) = struct( ...
            'name', plan(k).name, ...
            'effective', effectiveMetadata(plan(k), single), ...
            'result', single);
    end
    result.timings.export = toc(exportTimer);
    result.summary = summarize(result.entries);
    result.status = aggregateStatus(result.summary);

    try
        manifest = createManifest(result.entries, options);
        writeManifest(result.manifestPath, manifest, options.export.overwrite);
    catch err
        result.diagnostics(end + 1) = m2t.internal.makeDiagnostic( ...
            'error', 'M2T:SET_MANIFEST_WRITE_FAILED', err.message, 'set');
        if result.summary.succeeded > 0
            result.status = 'partial_failure';
        else
            result.status = 'failed';
        end
    end
    result.success = strcmp(result.status, 'success');
    result = complete(result, totalTimer, printSummary);
end

function [plan, options, outputDirectory] = preflight(entries, outputValue, varargin)
    options = parseSetOptions(varargin{:});
    outputDirectory = normalizeOutputDirectory(outputValue);
    if ~(isstruct(entries) && isvector(entries) && ~isempty(entries))
        error('M2T:SET_INVALID_ENTRY', ...
              'entries must be a nonempty struct vector.');
    end
    fields = fieldnames(entries);
    required = {'figure','name'};
    allowed = [required {'profile','width','overwrite','imageBackend'}];
    for k = 1:numel(required)
        if ~any(strcmp(fields, required{k}))
            error('M2T:SET_INVALID_ENTRY', ...
                  'Every entry must provide the field %s.', required{k});
        end
    end
    unexpected = fields(~cellfun(@(name) any(strcmp(name, allowed)), fields));
    if ~isempty(unexpected)
        error('M2T:SET_INVALID_ENTRY', ...
              'Unsupported entry override field: %s.', unexpected{1});
    end

    plan = repmat(planTemplate(), 1, numel(entries));
    names = cell(1, numel(entries));
    for k = 1:numel(entries)
        name = validName(entries(k).name, k);
        names{k} = lower(name);
        effective = options.export;
        effective.profile = override(entries(k), 'profile', effective.profile);
        effective.width = override(entries(k), 'width', effective.width);
        effective.overwrite = override(entries(k), 'overwrite', effective.overwrite);
        effective.imageBackend = override(entries(k), 'imageBackend', effective.imageBackend);
        if ~(islogical(effective.overwrite) && isscalar(effective.overwrite))
            error('M2T:SET_INVALID_ENTRY', ...
                  'Entry %d Overwrite must be a logical scalar.', k);
        end
        try
            selection = m2t.profile.getSelection(effective.profile, effective.width);
            effective.imageBackend = m2t.internal.normalizeImageBackend(effective.imageBackend);
        catch err
            error('M2T:SET_INVALID_ENTRY', ...
                  'Entry %d has invalid profile configuration: %s', k, err.message);
        end
        plan(k) = struct( ...
            'figure', entries(k).figure, ...
            'name', name, ...
            'outputBase', fullfile(outputDirectory, name), ...
            'profile', selection.profileName, ...
            'width', selection.widthName, ...
            'overwrite', effective.overwrite, ...
            'imageBackend', effective.imageBackend);
    end
    if numel(unique(names)) ~= numel(names)
        error('M2T:SET_DUPLICATE_NAME', ...
              'Figure-set entry names must be unique (case-insensitive).');
    end

    manifestPath = fullfile(outputDirectory, 'm2t-manifest.json');
    if ~options.export.overwrite && exist(manifestPath, 'file') == 2
        error('M2T:SET_OUTPUT_EXISTS', ...
              'Existing figure-set manifest: %s.', manifestPath);
    end
    for k = 1:numel(plan)
        if plan(k).overwrite, continue; end
        products = {[plan(k).outputBase '.tex'], [plan(k).outputBase '.pdf'], ...
                    [plan(k).outputBase '.compile.log']};
        existing = products(cellfun(@(path) exist(path, 'file') == 2, products));
        if ~isempty(existing)
            error('M2T:SET_OUTPUT_EXISTS', ...
                  'Existing export product for entry %s: %s.', ...
                  plan(k).name, existing{1});
        end
        assetDirectory = [plan(k).outputBase '-assets'];
        if exist(assetDirectory, 'dir') == 7
            error('M2T:SET_OUTPUT_EXISTS', ...
                  'Existing image asset directory for entry %s: %s.', ...
                  plan(k).name, assetDirectory);
        end
    end
end

function options = parseSetOptions(varargin)
    if mod(numel(varargin), 2) ~= 0
        error('M2T:SET_INVALID_OPTION', ...
              'Figure-set options must be provided in name-value pairs.');
    end
    continueOnError = true;
    exportArguments = {};
    for k = 1:2:numel(varargin)
        name = optionName(varargin{k});
        if strcmpi(name, 'ContinueOnError')
            value = varargin{k + 1};
            if ~(islogical(value) && isscalar(value))
                error('M2T:SET_INVALID_OPTION', ...
                      'ContinueOnError must be a logical scalar.');
            end
            continueOnError = value;
        else
            exportArguments(end + 1:end + 2) = varargin(k:k + 1); %#ok<AGROW>
        end
    end
    try
        exportOptions = m2t.internal.parseExportOptions(exportArguments{:});
        selection = m2t.profile.getSelection(exportOptions.profile, exportOptions.width);
    catch err
        error('M2T:SET_INVALID_OPTION', '%s', err.message);
    end
    exportOptions.profile = selection.profileName;
    if strcmp(selection.widthName, 'source')
        exportOptions.width = [];
    else
        exportOptions.width = selection.widthName;
    end
    options = struct('export', exportOptions, ...
                     'continueOnError', continueOnError, ...
                     'profileName', selection.profileName, ...
                     'widthName', selection.widthName);
end

function value = override(entry, field, inherited)
    value = inherited;
    if isfield(entry, field)
        candidate = entry.(field);
        if ~isempty(candidate), value = candidate; end
    end
end

function value = validName(value, index)
    if isa(value, 'string') && isscalar(value), value = char(value); end
    if ~(ischar(value) && isrow(value) && ~isempty(value))
        error('M2T:SET_INVALID_NAME', ...
              'Entry %d name must be nonempty text.', index);
    end
    if isempty(regexp(value, '^[A-Za-z0-9][A-Za-z0-9_-]*$', 'once'))
        error('M2T:SET_INVALID_NAME', ...
              ['Entry %d name must be a filename stem containing only ' ...
               'letters, digits, hyphens, and underscores.'], index);
    end
end

function directory = normalizeOutputDirectory(value)
    if isa(value, 'string') && isscalar(value), value = char(value); end
    if ~(ischar(value) && isrow(value) && ~isempty(strtrim(value)))
        error('M2T:SET_INVALID_OUTPUT', ...
              'outputDirectory must be a nonempty text scalar.');
    end
    if any(value == sprintf('\r')) || any(value == sprintf('\n')) || ...
       any(value == char(0))
        error('M2T:SET_INVALID_OUTPUT', ...
              'outputDirectory contains an invalid control character.');
    end
    if ~isAbsolute(value), value = fullfile(pwd, value); end
    directory = value;
    if exist(directory, 'file') == 2
        error('M2T:SET_INVALID_OUTPUT', ...
              'outputDirectory is an existing file: %s.', directory);
    end
end

function yes = isAbsolute(path)
    if ispc
        yes = ~isempty(regexp(path, '^[A-Za-z]:[\\/]', 'once')) || ...
              strncmp(path, '\\', 2) || strncmp(path, '//', 2);
    else
        yes = strncmp(path, '/', 1);
    end
end

function callOptions = exportCallOptions(item)
    callOptions = {'Profile', item.profile, 'Overwrite', item.overwrite, ...
                   'ImageBackend', item.imageBackend};
    if ~strcmp(item.width, 'source')
        callOptions(end + 1:end + 2) = {'Width', item.width};
    end
end

function value = effectiveMetadata(item, result)
    value = struct('profile', item.profile, 'width', item.width, ...
                   'overwrite', item.overwrite, ...
                   'imageBackend', result.render.effectiveImageBackend, ...
                   'requestedImageBackend', item.imageBackend, ...
                   'selectedImageBackend', result.render.imageBackend.selected, ...
                   'backendReason', result.render.imageBackend.reason, ...
                   'backendPolicy', result.render.imageBackend.policy.id);
end

function result = skippedResult(item)
    result = m2t.internal.emptyExportResult();
    result.status = 'skipped';
    result.texPath = [item.outputBase '.tex'];
    result.pdfPath = [item.outputBase '.pdf'];
    result.logPath = [item.outputBase '.compile.log'];
    result.profile.name = item.profile;
    result.profile.width = item.width;
    result.render.requestedImageBackend = item.imageBackend;
    result.render.effectiveImageBackend = item.imageBackend;
    result.render.imageBackend.requested = item.imageBackend;
    result.render.imageBackend.selected = '';
    result.render.imageBackend.reason = 'not_planned';
    result.diagnostics(end + 1) = m2t.internal.makeDiagnostic( ...
        'error', 'M2T:SET_SKIPPED_AFTER_FAILURE', ...
        'Entry was skipped after an earlier figure failed.', 'set');
end

function summary = summarize(entries)
    statuses = arrayfun(@(item) item.result.status, entries, ...
                        'UniformOutput', false);
    summary = struct( ...
        'total', numel(entries), ...
        'succeeded', sum(strcmp(statuses, 'success')), ...
        'failed', sum(~strcmp(statuses, 'success') & ...
                      ~strcmp(statuses, 'unsupported') & ...
                      ~strcmp(statuses, 'skipped')), ...
        'unsupported', sum(strcmp(statuses, 'unsupported')), ...
        'skipped', sum(strcmp(statuses, 'skipped')));
end

function status = aggregateStatus(summary)
    if summary.succeeded == summary.total
        status = 'success';
    elseif summary.succeeded > 0
        status = 'partial_failure';
    else
        status = 'failed';
    end
end

function manifest = createManifest(entries, options)
    figures = repmat(struct('name', '', 'status', '', 'tex', '', 'pdf', '', ...
                            'profile', '', 'width', '', 'imageBackend', '', ...
                            'requestedImageBackend', '', ...
                            'selectedImageBackend', '', 'backendReason', '', ...
                            'backendPolicy', '', ...
                            'assets', {cell(1, 0)}), 1, numel(entries));
    for k = 1:numel(entries)
        assetNames = cellfun(@(path) relativeAssetPath(path, entries(k).name), ...
            entries(k).result.render.assets, 'UniformOutput', false);
        figures(k) = struct( ...
            'name', entries(k).name, ...
            'status', entries(k).result.status, ...
            'tex', [entries(k).name '.tex'], ...
            'pdf', [entries(k).name '.pdf'], ...
            'profile', entries(k).effective.profile, ...
            'width', entries(k).effective.width, ...
            'imageBackend', entries(k).effective.imageBackend, ...
            'requestedImageBackend', entries(k).effective.requestedImageBackend, ...
            'selectedImageBackend', entries(k).effective.selectedImageBackend, ...
            'backendReason', entries(k).effective.backendReason, ...
            'backendPolicy', entries(k).effective.backendPolicy, ...
            'assets', {assetNames});
    end
    defaults = struct( ...
        'profile', options.profileName, ...
        'width', options.widthName, ...
        'overwrite', options.export.overwrite, ...
        'imageBackend', options.export.imageBackend, ...
        'continueOnError', options.continueOnError);
    manifest = struct('schemaVersion', 1, ...
                      'generatedBy', 'm2tikz-next m2t.exportSet', ...
                      'defaults', defaults, 'figures', figures);
end

function writeManifest(path, manifest, overwrite)
    directory = fileparts(path);
    if exist(directory, 'dir') ~= 7
        [created, message] = mkdir(directory);
        if ~created
            error('Cannot create manifest directory %s: %s', directory, message);
        end
    end
    if ~overwrite && exist(path, 'file') == 2
        error('Manifest appeared after preflight and will not be overwritten: %s', path);
    end
    m2t.internal.writeTextFile(path, [jsonencode(manifest) sprintf('\n')]);
end

function result = emptySetResult()
    result = struct( ...
        'success', false, ...
        'status', 'invalid_set', ...
        'outputDirectory', '', ...
        'manifestPath', '', ...
        'entries', repmat(entryResultTemplate(), 1, 0), ...
        'diagnostics', m2t.internal.emptyDiagnostics(), ...
        'summary', struct('total', 0, 'succeeded', 0, 'failed', 0, ...
                          'unsupported', 0, 'skipped', 0), ...
        'timings', struct('preflight', 0, 'export', 0, 'total', 0));
end

function value = entryResultTemplate()
    value = struct('name', '', ...
                   'effective', struct('profile', 'none', 'width', 'source', ...
                                       'overwrite', false, ...
                                       'imageBackend', 'vector', ...
                                       'requestedImageBackend', 'vector', ...
                                       'selectedImageBackend', 'vector', ...
                                       'backendReason', 'not_planned', ...
                                       'backendPolicy', 'default-v1'), ...
                   'result', m2t.internal.emptyExportResult());
end

function value = planTemplate()
    value = struct('figure', [], 'name', '', 'outputBase', '', ...
                   'profile', 'none', 'width', 'source', 'overwrite', false, ...
                   'imageBackend', 'vector');
end

function value = relativeAssetPath(path, entryName)
    [~, filename, extension] = fileparts(path);
    value = [entryName '-assets/' filename extension];
end

function value = optionName(value)
    if isa(value, 'string') && isscalar(value), value = char(value); end
    if ~(ischar(value) && isrow(value) && ~isempty(value))
        error('M2T:SET_INVALID_OPTION', 'Option names must be nonempty text.');
    end
end

function diagnostic = setDiagnostic(err)
    code = err.identifier;
    if isempty(code) || isempty(strfind(code, 'M2T:SET_')) %#ok<STREMP>
        code = 'M2T:SET_INVALID_ENTRY';
    end
    diagnostic = m2t.internal.makeDiagnostic('error', code, err.message, 'set');
end

function result = complete(result, totalTimer, printSummary)
    result.timings.total = toc(totalTimer);
    if ~printSummary, return; end
    fprintf('m2tikz-next figure set\n\n');
    fprintf('%d figures\n%d succeeded\n%d failed\n%d unsupported\n%d skipped\n\n', ...
            result.summary.total, result.summary.succeeded, ...
            result.summary.failed, result.summary.unsupported, ...
            result.summary.skipped);
    if ~isempty(result.outputDirectory)
        fprintf('Output: %s\n', result.outputDirectory);
    elseif ~isempty(result.diagnostics)
        fprintf(2, 'Set validation: %s\n', result.diagnostics(1).message);
    end
end
