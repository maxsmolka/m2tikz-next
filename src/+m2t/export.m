function result = export(figureHandle, outputBase, varargin)
%EXPORT Analyze, export, compile, and validate one supported figure.
%   RESULT = M2T.EXPORT(FIGURE, OUTPUTBASE) writes OUTPUTBASE.tex and
%   OUTPUTBASE.pdf. Existing export products are preserved unless the
%   caller passes 'Overwrite', true.
%   'Profile', 'publication' applies the opt-in publication profile;
%   'Width' selects 'single-column' or 'double-column'.
%   'ImageBackend' selects 'vector' (default), 'hybrid', or 'auto'.

    totalTimer = tic;
    result = m2t.internal.emptyExportResult();
    printSummary = nargout == 0;

    try
        options = m2t.internal.parseExportOptions(varargin{:});
        paths = m2t.internal.normalizeOutputBase(outputBase);
        result.texPath = paths.texPath;
        result.pdfPath = paths.pdfPath;
        result.logPath = paths.logPath;
        result.render.requestedImageBackend = options.imageBackend;
        result.render.effectiveImageBackend = options.imageBackend;
        result.render.imageBackend.requested = options.imageBackend;
        result.render.imageBackend.selected = '';
        result.render.imageBackend.reason = 'not_planned';
    catch err
        result.diagnostics(end + 1) = diagnosticFromError(err, 'export');
        result = complete(result, totalTimer, printSummary);
        return
    end

    stageTimer = tic;
    try
        selection = m2t.profile.getSelection(options.profile, options.width);
    catch err
        result.timings.analysis = toc(stageTimer);
        result.diagnostics(end + 1) = diagnosticFromError(err, 'analysis');
        result = complete(result, totalTimer, printSummary);
        return
    end
    analysis = m2t.internal.analyzeFigure(figureHandle);
    result.timings.analysis = toc(stageTimer);
    result.capability = analysis.classification;
    result.diagnostics = appendDiagnostics(result.diagnostics, analysis.diagnostics);
    if ~strcmp(analysis.classification, 'supported')
        if strcmp(analysis.classification, 'unsupported')
            result.status = 'unsupported';
        else
            result.status = 'export_failed';
        end
        result = complete(result, totalTimer, printSummary);
        return
    end

    try
        decision = m2t.planning.selectImageBackend(analysis.ir, options.imageBackend);
        result.render.requestedImageBackend = decision.requested;
        result.render.effectiveImageBackend = decision.selected;
        result.render.imageBackend = decision;
    catch err
        result.diagnostics(end + 1) = diagnosticFromError(err, 'planning');
        result = complete(result, totalTimer, printSummary);
        return
    end

    try
        transformation = m2t.profile.apply( ...
            analysis.ir, selection.profile, selection.width);
    catch err
        result.timings.analysis = toc(stageTimer);
        result.diagnostics(end + 1) = diagnosticFromError(err, 'analysis');
        result = complete(result, totalTimer, printSummary);
        return
    end
    result.timings.analysis = toc(stageTimer);
    result.profile = transformation.metadata;
    result.diagnostics = appendDiagnostics(result.diagnostics, ...
                                           transformation.diagnostics);
    if ~transformation.success
        result.status = 'export_failed';
        result = complete(result, totalTimer, printSummary);
        return
    end

    stageTimer = tic;
    try
        plan = m2t2.render.makePgfplotsPlan( ...
            transformation.ir, true, transformation.renderConfig, ...
            decision.selected, paths.assetDirectoryName);
        prepareOutputs(paths, options.overwrite);
        result.render.assets = writeAssets(plan.assets, paths.assetDirectory);
        m2t.internal.writeTextFile(paths.texPath, plan.tex);
    catch err
        result.timings.export = toc(stageTimer);
        result.diagnostics(end + 1) = diagnosticFromError(err, 'export');
        result = complete(result, totalTimer, printSummary);
        return
    end
    result.timings.export = toc(stageTimer);

    stageTimer = tic;
    try
        compilation = m2t.internal.compileLuaLatex(paths.texPath, paths.pdfPath, 'lualatex');
    catch err
        result.timings.compile = toc(stageTimer);
        result.status = 'compile_failed';
        result.diagnostics(end + 1) = diagnosticFromError(err, 'compile');
        result = complete(result, totalTimer, printSummary);
        return
    end
    result.timings.compile = toc(stageTimer);
    result.compiler = compilation.compiler;
    result.logPath = compilation.logPath;
    result.diagnostics = appendDiagnostics(result.diagnostics, compilation.diagnostics);
    if ~compilation.success
        result.status = 'compile_failed';
        result = complete(result, totalTimer, printSummary);
        return
    end

    stageTimer = tic;
    try
        validation = m2t.internal.validatePdf(paths.pdfPath);
    catch err
        result.timings.validation = toc(stageTimer);
        result.status = 'validation_failed';
        result.diagnostics(end + 1) = diagnosticFromError(err, 'validation');
        result = complete(result, totalTimer, printSummary);
        return
    end
    result.timings.validation = toc(stageTimer);
    result.diagnostics = appendDiagnostics(result.diagnostics, validation.diagnostics);
    if ~validation.success
        result.status = 'validation_failed';
        result = complete(result, totalTimer, printSummary);
        return
    end

    result.success = true;
    result.status = 'success';
    result = complete(result, totalTimer, printSummary);
end

function prepareOutputs(paths, overwrite)
    if exist(paths.directory, 'file') == 2
        error('M2T:E002:InvalidOutputPath', ...
              'Output directory is an existing file: %s', paths.directory);
    end
    if exist(paths.directory, 'dir') ~= 7
        [created, message] = mkdir(paths.directory);
        if ~created
            error('M2T:E002:InvalidOutputPath', ...
                  'Cannot create output directory %s: %s', paths.directory, message);
        end
    end

    products = {paths.texPath, paths.pdfPath, paths.logPath};
    existing = products(cellfun(@(path) exist(path, 'file') == 2, products));
    if exist(paths.assetDirectory, 'dir') == 7
        existing{end + 1} = paths.assetDirectory;
    end
    if ~overwrite && ~isempty(existing)
        error('M2T:E003:OutputExists', ...
              'Export product already exists: %s. Pass Overwrite=true to replace it.', ...
              existing{1});
    end
    if overwrite
        for k = 2:numel(products)
            if exist(products{k}, 'file') == 2, deleteWorkflowFile(products{k}); end
        end
        if exist(paths.assetDirectory, 'dir') == 7
            deleteAssetDirectory(paths.assetDirectory, paths.directory);
        end
    end
end

function paths = writeAssets(assets, directory)
    paths = cell(1, numel(assets));
    if isempty(assets), return; end
    if exist(directory, 'dir') ~= 7
        [created, message] = mkdir(directory);
        if ~created
            error('M2T:E004:WriteFailed', ...
                  'Cannot create image asset directory %s: %s', directory, message);
        end
    end
    for k = 1:numel(assets)
        path = fullfile(directory, assets(k).filename);
        m2t2.render.writePngAsset(assets(k), path);
        paths{k} = path;
    end
end

function deleteAssetDirectory(path, expectedParent)
    parent = fileparts(path);
    if ~strcmp(parent, expectedParent) || isempty(expectedParent)
        error('M2T:E004:WriteFailed', ...
              'Refusing to remove image asset directory outside output parent: %s', path);
    end
    [status, message] = rmdir(path, 's');
    if ~status || exist(path, 'dir') == 7
        error('M2T:E004:WriteFailed', ...
              'Cannot remove existing image asset directory %s: %s', path, message);
    end
end

function deleteWorkflowFile(path)
    if exist('unlink', 'builtin') == 5 || exist('unlink', 'file') == 2
        [status, message] = unlink(path);
        if status ~= 0
            error('M2T:E004:WriteFailed', ...
                  'Cannot remove existing export product %s: %s', path, message);
        end
    else
        try
            delete(path);
        catch err
            error('M2T:E004:WriteFailed', ...
                  'Cannot remove existing export product %s: %s', path, err.message);
        end
    end
    if exist(path, 'file') == 2
        error('M2T:E004:WriteFailed', ...
              'Cannot remove existing export product: %s', path);
    end
end

function item = diagnosticFromError(err, stage)
    code = err.identifier;
    if isempty(code), code = 'M2T:E999:UnexpectedFailure'; end
    item = m2t.internal.makeDiagnostic('error', code, err.message, stage);
end

function target = appendDiagnostics(target, additions)
    if ~isempty(additions), target = [target additions]; end
end

function result = complete(result, totalTimer, printSummary)
    result.timings.total = toc(totalTimer);
    if ~printSummary, return; end
    if result.success
        fprintf('m2t.export: success\n  TeX: %s\n  PDF: %s\n', ...
                result.texPath, result.pdfPath);
    elseif isempty(result.diagnostics)
        fprintf(2, 'm2t.export: %s\n', result.status);
    else
        fprintf(2, 'm2t.export: %s - %s\n', ...
                result.status, result.diagnostics(1).message);
    end
end
