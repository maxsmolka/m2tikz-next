function generateM1BGoldenCandidates(reviewRoot, run1, run2)
%GENERATEM1BGOLDENCANDIDATES Build a conservative, traceable ACID review set.
% Successful automation never approves a Golden by itself: cases without a
% case-specific semantic oracle remain MANUAL_REVIEW_REQUIRED.

    testRoot = fileparts(mfilename('fullpath'));
    repoRoot = fileparts(testRoot);
    if nargin < 1 || isempty(reviewRoot)
        reviewRoot = fullfile(repoRoot, '.audit', 'm1b-golden-review');
    end
    if ~exist(reviewRoot, 'dir'), mkdir(reviewRoot); end
    addpath(fullfile(repoRoot, 'src'));
    addpath(fullfile(testRoot, 'suites'));
    if nargin < 3 || isempty(run1) || isempty(run2)
        runsRoot = fullfile(reviewRoot, 'runs');
        if ~exist(runsRoot, 'dir'), mkdir(runsRoot); end
        run1 = tempname(runsRoot); mkdir(run1);
        run2 = tempname(runsRoot); mkdir(run2);
        fprintf('M1B review export pass 1: %s\n', run1);
        testHeadless('output', run1);
        fprintf('M1B review export pass 2: %s\n', run2);
        testHeadless('output', run2);
    else
        fprintf('M1B reusing completed export passes: %s | %s\n', run1, run2);
    end
    functions = ACID(0);

    resultsPath = fullfile(reviewRoot, 'results.tsv');
    fid = fopen(resultsPath, 'w');
    if fid < 0, error('m2t:m1b:ResultFile', 'Cannot open %s.', resultsPath); end
    closeResults = onCleanup(@() fclose(fid));
    fprintf(fid, ['ACID_ID\tFUNCTION\tEXPORT_STATUS\tTEX_STATUS\tPDF_STATUS\t', ...
        'OLD_REFERENCE_AVAILABLE\tNEW_HASH\tREVIEW_STATUS\tNOTES\t', ...
        'NONEMPTY\tAXIS_COUNT\tADDPLOT_COUNT\tLABEL_TOKEN_COUNT\t', ...
        'ASSET_STATUS\tDETERMINISTIC\tNAN_INF_STATUS\n']);

    oldReference = fullfile(testRoot, 'suites', 'ACID.Octave.11.3.0.md5');
    for k = 1:numel(functions)
        caseName = sprintf('ACID-%03d', k);
        caseRoot = fullfile(reviewRoot, caseName);
        sourceDir = fullfile(caseRoot, 'source');
        texDir = fullfile(caseRoot, 'generated-tex');
        pdfDir = fullfile(caseRoot, 'compiled-pdf');
        metadataDir = fullfile(caseRoot, 'metadata');
        ensureDirectories({sourceDir, texDir, pdfDir, metadataDir});

        functionName = func2str(functions{k});
        writeSourceMetadata(fullfile(sourceDir, 'case.txt'), k, functionName, '');

        exportStatus = 'PASS';
        reviewStatus = 'MANUAL_REVIEW_REQUIRED';
        notes = ['Automated structural, asset, compilation, and determinism ', ...
                 'checks do not replace case-specific semantic/visual approval.'];
        newHash = '';
        nonempty = 0; axisCount = 0; addplotCount = 0; labelCount = 0;
        assetStatus = 'NOT CHECKED'; deterministic = 0; nanInfStatus = 'NOT CHECKED';
        texStatus = 'PENDING'; pdfStatus = 'PENDING';

        skipReason = knownSkipReason(k);
        tex1 = generatedTexPath(run1, k);
        tex2 = generatedTexPath(run2, k);
        if ~isempty(skipReason)
            exportStatus = 'SKIPPED';
            reviewStatus = 'REJECTED';
            notes = skipReason;
            texStatus = 'NOT APPLICABLE'; pdfStatus = 'NOT APPLICABLE';
        elseif exist(tex1, 'file') ~= 2
            exportStatus = 'EXPORT FAILURE';
            reviewStatus = 'REJECTED';
            notes = 'No generated TeX exists after the completed export pass.';
            texStatus = 'NOT APPLICABLE'; pdfStatus = 'NOT APPLICABLE';
        else
            nonempty = exist(tex1, 'file') == 2 && fileSize(tex1) > 0;
            if nonempty
                contents = fileread(tex1);
                axisCount = countToken(contents, '\begin{axis}');
                addplotCount = countToken(contents, '\addplot');
                labelCount = countToken(contents, 'label={') + ...
                             countToken(contents, 'title={') + ...
                             countToken(contents, '\addlegendentry');
                [assetStatus, assets] = inspectAssets(tex1, contents);
                deterministic = compareGeneratedSet(tex1, tex2, assets);
                newHash = calculateMD5Hash(tex1);
                nanInfStatus = classifyNanInf(contents);
                copyBinaryFile(tex1, fullfile(texDir, sprintf('test%d-converted.tex', k)));
                copyAssets(fileparts(tex1), texDir, assets);
            else
                exportStatus = 'EXPORT FAILURE';
                reviewStatus = 'REJECTED';
                notes = 'Generated TeX is missing or empty.';
                texStatus = 'NOT APPLICABLE'; pdfStatus = 'NOT APPLICABLE';
            end
            if nonempty && (~deterministic || strcmp(assetStatus, 'MISSING'))
                reviewStatus = 'REJECTED';
                notes = 'Determinism or referenced-asset validation failed.';
            end
        end

        writeCaseMetadata(fullfile(metadataDir, 'automated-checks.tsv'), ...
            k, functionName, exportStatus, newHash, nonempty, axisCount, ...
            addplotCount, labelCount, assetStatus, deterministic, ...
            nanInfStatus, reviewStatus, notes);
        fprintf(fid, '%d\t%s\t%s\t%s\t%s\t%d\t%s\t%s\t%s\t%d\t%d\t%d\t%d\t%s\t%d\t%s\n', ...
            k, tsv(functionName), exportStatus, texStatus, pdfStatus, ...
            exist(oldReference, 'file') == 2, newHash, reviewStatus, ...
            tsv(notes), nonempty, axisCount, addplotCount, labelCount, ...
            assetStatus, deterministic, nanInfStatus);
    end
    fprintf('M1B candidate table: %s\n', resultsPath);
end

function reason = knownSkipReason(id)
    legacy = [12 42 43 44 46 54 59 62 71 72 75 76 80 82 98];
    if id == 17
        reason = ['UNSUPPORTED TEST FIXTURE IN OCTAVE: nonlinear colorbars ', ...
                  'cannot be created.'];
    elseif id == 48 || id == 49
        reason = 'OPTIONAL DEPENDENCY CAPABILITY MISSING: dfilt.';
    elseif any(id == legacy)
        reason = 'LEGACY EXPLICIT SKIP: fixture/toolbox capability unavailable.';
    else
        reason = '';
    end
end

function path = generatedTexPath(runRoot, id)
    path = fullfile(runRoot, 'data', 'converted', ...
                    sprintf('test%d-converted.tex', id));
end

function ensureDirectories(paths)
    for k = 1:numel(paths)
        if ~exist(paths{k}, 'dir'), mkdir(paths{k}); end
    end
end

function writeSourceMetadata(path, id, functionName, description)
    fid = fopen(path, 'w'); cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, 'ACID_ID=%d\nFUNCTION=%s\nSOURCE=test/suites/ACID.m\nDESCRIPTION=%s\n', ...
        id, functionName, tsv(description));
end

function writeCaseMetadata(path, id, functionName, exportStatus, hashValue, ...
        nonempty, axisCount, addplotCount, labelCount, assetStatus, ...
        deterministic, nanInfStatus, reviewStatus, notes)
    fid = fopen(path, 'w'); cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, ['ACID_ID\tFUNCTION\tEXPORT_STATUS\tNEW_HASH\tNONEMPTY\t', ...
        'AXIS_COUNT\tADDPLOT_COUNT\tLABEL_TOKEN_COUNT\tASSET_STATUS\t', ...
        'DETERMINISTIC\tNAN_INF_STATUS\tREVIEW_STATUS\tNOTES\n']);
    fprintf(fid, '%d\t%s\t%s\t%s\t%d\t%d\t%d\t%d\t%s\t%d\t%s\t%s\t%s\n', ...
        id, functionName, exportStatus, hashValue, nonempty, axisCount, ...
        addplotCount, labelCount, assetStatus, deterministic, nanInfStatus, ...
        reviewStatus, tsv(notes));
end

function bytes = fileSize(path)
    f = fopen(path, 'rb'); cleanup = onCleanup(@() fclose(f));
    fseek(f, 0, 'eof'); bytes = ftell(f);
end

function count = countToken(contents, token)
    count = numel(strfind(contents, token));
end

function [status, assets] = inspectAssets(texPath, contents)
    assets = regexp(contents, '[^{}[:space:]]+\.(png|jpg|jpeg|pdf|tsv)', 'match');
    assets = unique(assets);
    status = 'NONE';
    if isempty(assets), return; end
    status = 'PRESENT';
    for k = 1:numel(assets)
        if exist(fullfile(fileparts(texPath), strrep(assets{k}, '/', filesep)), 'file') ~= 2
            status = 'MISSING';
            return
        end
    end
end

function equal = compareGeneratedSet(tex1, tex2, assets)
    equal = exist(tex2, 'file') == 2 && ...
            strcmp(calculateMD5Hash(tex1), calculateMD5Hash(tex2));
    for k = 1:numel(assets)
        asset1 = fullfile(fileparts(tex1), strrep(assets{k}, '/', filesep));
        asset2 = fullfile(fileparts(tex2), strrep(assets{k}, '/', filesep));
        equal = equal && exist(asset2, 'file') == 2 && ...
                strcmp(calculateMD5Hash(asset1), calculateMD5Hash(asset2));
    end
end

function copyAssets(sourceDir, targetDir, assets)
    for k = 1:numel(assets)
        relative = strrep(assets{k}, '/', filesep);
        source = fullfile(sourceDir, relative);
        target = fullfile(targetDir, relative);
        parent = fileparts(target);
        if ~exist(parent, 'dir'), mkdir(parent); end
        copyBinaryFile(source, target);
    end
end

function copyBinaryFile(source, target)
    input = fopen(source, 'rb');
    if input < 0, error('m2t:m1b:CopySource', 'Cannot open %s.', source); end
    closeInput = onCleanup(@() fclose(input));
    data = fread(input, Inf, '*uint8');
    output = fopen(target, 'wb');
    if output < 0, error('m2t:m1b:CopyTarget', 'Cannot open %s.', target); end
    closeOutput = onCleanup(@() fclose(output));
    fwrite(output, data, 'uint8');
end

function status = classifyNanInf(contents)
    if ~isempty(regexpi(contents, '(^|[^A-Za-z])(nan|[+-]?inf)([^A-Za-z]|$)', 'once'))
        status = 'PRESENT_REVIEW_REQUIRED';
    else
        status = 'NONE';
    end
end

function value = tsv(value)
    if isempty(value), value = ''; return; end
    value = strrep(value, sprintf('\t'), ' ');
    value = strrep(value, sprintf('\r'), ' ');
    value = strrep(value, sprintf('\n'), ' ');
end
