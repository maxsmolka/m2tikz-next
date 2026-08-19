function summary = runM3CompilerTests(outputDirectory)
%RUNM3COMPILERTESTS Test LuaLaTeX orchestration without graphics figures.
    repositoryRoot = fileparts(fileparts(mfilename('fullpath')));
    if nargin < 1
        outputDirectory = fullfile(repositoryRoot, '.audit', 'm3-compiler');
    end
    addpath(fullfile(repositoryRoot, 'src'));
    if exist(outputDirectory, 'dir') == 7, rmdir(outputDirectory, 's'); end
    mkdir(outputDirectory);

    rows = cell(2, 4); failures = 0;
    [rows(1, :), failed] = runCase('known_good_tex', @() knownGood(outputDirectory));
    failures = failures + failed;
    [rows(2, :), failed] = runCase('known_invalid_tex', @() knownInvalid(outputDirectory));
    failures = failures + failed;
    resultPath = fullfile(outputDirectory, 'compiler-results.tsv');
    writeRows(resultPath, rows);
    summary = struct('failures', failures, 'tests', 2, 'resultPath', resultPath);
    if failures > 0
        fprintf(2, 'M3 compiler diagnostics from %s:\n%s', resultPath, fileread(resultPath));
        error('M2T:M3CompilerTestsFailed', '%d M3 compiler tests failed.', failures);
    end
end

function [row, failed] = runCase(name, callback)
    try
        detail = callback(); status = 'PASS'; failed = 0;
    catch err
        detail = sprintf('%s: %s', identifierText(err.identifier), oneLine(err.message));
        status = 'FAIL'; failed = 1;
    end
    row = {name, status, detail, 'compiler'};
end

function detail = knownGood(root)
    texPath = fullfile(root, 'known-good.tex');
    pdfPath = fullfile(root, 'known-good.pdf');
    bs = char(92);
    tex = sprintf('%sdocumentclass{standalone}\n%sbegin{document}\nM3\n%send{document}\n', bs, bs, bs);
    writeText(texPath, tex);
    result = m2t.internal.compileLuaLatex(texPath, pdfPath, 'lualatex');
    assert(result.success && isempty(result.diagnostics));
    validation = m2t.internal.validatePdf(pdfPath); assert(validation.success);
    detail = sprintf('pdfBytes=%d', fileSize(pdfPath));
end

function detail = knownInvalid(root)
    texPath = fullfile(root, 'known-invalid.tex');
    pdfPath = fullfile(root, 'known-invalid.pdf');
    bs = char(92);
    tex = sprintf('%sdocumentclass{standalone}\n%sbegin{document}\n%sMThreeUndefined\n%send{document}\n', ...
                  bs, bs, bs, bs);
    writeText(texPath, tex);
    result = m2t.internal.compileLuaLatex(texPath, pdfPath, 'lualatex');
    assert(~result.success && exist(pdfPath, 'file') ~= 2);
    assert(~isempty(result.diagnostics));
    assert(strcmp(result.diagnostics(1).code, 'M2T:C003:CompilationFailed'));
    assert(strcmp(result.diagnostics(1).stage, 'compile'));
    assert(~isempty(strfind(result.diagnostics(1).message, 'Undefined control sequence'))); %#ok<STREMP>
    assert(exist(result.logPath, 'file') == 2);
    detail = result.diagnostics(1).message;
end

function bytes = fileSize(path)
    fid = fopen(path, 'rb'); assert(fid >= 0);
    fseek(fid, 0, 'eof'); bytes = ftell(fid); fclose(fid);
end

function writeText(path, value)
    fid = fopen(path, 'wb'); assert(fid >= 0);
    written = fwrite(fid, value, 'char'); fclose(fid); assert(written == numel(value));
end

function writeRows(path, rows)
    fid = fopen(path, 'wb'); cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, 'case\tstatus\tdetail\tlayer\n');
    for k = 1:size(rows, 1)
        fprintf(fid, '%s\t%s\t%s\t%s\n', rows{k, 1}, rows{k, 2}, rows{k, 3}, rows{k, 4});
    end
    clear cleanup;
end

function value = oneLine(value)
    value = strrep(strrep(strrep(value, sprintf('\r'), ' '), sprintf('\n'), ' '), sprintf('\t'), ' ');
end

function value = identifierText(value)
    if isempty(value), value = '<none>'; end
end
