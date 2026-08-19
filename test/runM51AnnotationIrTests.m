function summary = runM51AnnotationIrTests(outputDirectory)
%RUNM51ANNOTATIONIRTESTS Validate annotation IR and rendering without runtime graphics.
    root = fileparts(fileparts(mfilename('fullpath')));
    addpath(fullfile(root, 'src'));
    if nargin < 1, outputDirectory = fullfile(root, '.audit', 'm51-annotation-ir'); end
    ensureDirectory(outputDirectory);

    cases = {@textAnnotation, @arrowAnnotation, @doubleArrowAnnotation, ...
             @jsonRoundtrip, @olderV2DefaultsEmpty, @invalidTextOwner, ...
             @invalidCoordinateSpace, @invalidArrowHeads, @unknownKind};
    names = {'text_annotation','arrow_annotation','double_arrow_annotation', ...
             'json_roundtrip','older_v2_defaults_empty','invalid_text_owner', ...
             'invalid_coordinate_space','invalid_arrow_heads','unknown_kind'};
    rows = cell(numel(cases), 4); failures = 0;
    for k = 1:numel(cases)
        try
            cases{k}(); status = 'PASS'; detail = '';
        catch err
            failures = failures + 1; status = 'FAIL';
            detail = sprintf('%s: %s', err.identifier, oneLine(err.message));
        end
        rows(k,:) = {names{k}, status, detail, 'annotation-ir'};
    end
    resultPath = fullfile(outputDirectory, 'm51-annotation-ir-results.tsv');
    writeRows(resultPath, rows);
    summary = struct('failures', failures, 'tests', numel(cases), 'resultPath', resultPath);
    if failures
        fprintf(2, 'M5.1 annotation IR diagnostics from %s:\n%s', resultPath, fileread(resultPath));
        error('M2T2:M51AnnotationIrTestsFailed', '%d M5.1 annotation IR tests failed.', failures);
    end
end

function textAnnotation()
    [ir, ax] = baseIR();
    item = m2t2.ir.makeTextAnnotation();
    item.position = [0.25 0.75]; item.text = m2t2.ir.makeText('x_{1}', 'tex');
    item.horizontalAlignment = 'right'; item.rotation = 30; item.fontWeight = 'bold';
    ir.axes = {ax}; ir.annotations = {item}; m2t2.ir.validate(ir);
    tex = m2t2.render.renderPgfplots(ir, true);
    assertContains(tex, 'at (axis cs:0.25,0.75)');
    assertContains(tex, 'anchor=east'); assertContains(tex, 'rotate=30');
    assertContains(tex, '$x_{1}$');
end

function arrowAnnotation()
    [ir, ax] = baseIR(); item = m2t2.ir.makeArrowAnnotation('arrow');
    item.start = [0.1 0.2]; item.end = [0.8 0.7]; item.style = 'dashed'; item.width = 1.5;
    ir.axes = {ax}; ir.annotations = {item}; m2t2.ir.validate(ir);
    tex = m2t2.render.renderPgfplots(ir, true);
    assertContains(tex, 'arrows.meta'); assertContains(tex, 'dashed');
    assertContains(tex, '(1.2pt,1.6pt)'); assertContains(tex, '(9.6pt,5.6pt)');
end

function doubleArrowAnnotation()
    [ir, ax] = baseIR(); item = m2t2.ir.makeArrowAnnotation('doublearrow');
    item.startHead = m2t2.ir.makeArrowHead('vback2', 8, 6);
    item.endHead = m2t2.ir.makeArrowHead('vback2', 9, 7);
    ir.axes = {ax}; ir.annotations = {item}; m2t2.ir.validate(ir);
    tex = m2t2.render.renderPgfplots(ir, true);
    assertContains(tex, '{Latex[length=8pt,width=6pt]}-{Latex[length=9pt,width=7pt]}');
end

function jsonRoundtrip()
    [ir, ax] = baseIR(); textItem = m2t2.ir.makeTextAnnotation();
    arrowItem = m2t2.ir.makeArrowAnnotation('doublearrow');
    arrowItem.startHead = m2t2.ir.makeArrowHead('vback2', 10, 10);
    ir.axes = {ax}; ir.annotations = {textItem, arrowItem};
    decoded = m2t2.ir.fromJson(jsonencode(ir));
    assert(numel(decoded.annotations) == 2);
    assert(strcmp(decoded.annotations{1}.kind, 'm2t2.textannotation'));
    assert(strcmp(decoded.annotations{2}.kind, 'm2t2.arrowannotation'));
    assert(strcmp(m2t2.render.renderPgfplots(ir, true), m2t2.render.renderPgfplots(decoded, true)));
end

function olderV2DefaultsEmpty()
    [ir, ax] = baseIR(); ir.axes = {ax}; ir = rmfield(ir, 'annotations');
    decoded = m2t2.ir.fromJson(jsonencode(ir));
    assert(isfield(decoded, 'annotations') && isempty(decoded.annotations));
end

function invalidTextOwner()
    [ir, ax] = baseIR(); item = m2t2.ir.makeTextAnnotation();
    item.owner = m2t2.ir.makeOwner('figure', 'figure'); ir.axes = {ax}; ir.annotations = {item};
    expectInvalid(@() m2t2.ir.validate(ir), 'text annotations must be axes-owned');
end

function invalidCoordinateSpace()
    [ir, ax] = baseIR(); item = m2t2.ir.makeArrowAnnotation();
    item.coordinateSpace = 'axes_data'; ir.axes = {ax}; ir.annotations = {item};
    expectInvalid(@() m2t2.ir.validate(ir), 'unsupported value axes_data');
end

function invalidArrowHeads()
    [ir, ax] = baseIR(); item = m2t2.ir.makeArrowAnnotation('arrow');
    item.startHead = m2t2.ir.makeArrowHead('vback2', 10, 10); ir.axes = {ax}; ir.annotations = {item};
    expectInvalid(@() m2t2.ir.validate(ir), 'single arrow may only have an end head');
end

function unknownKind()
    [ir, ax] = baseIR(); item = m2t2.ir.makeTextAnnotation(); item.kind = 'm2t2.annotation';
    ir.axes = {ax}; ir.annotations = {item};
    expectInvalid(@() m2t2.ir.validate(ir), 'unsupported annotation kind');
end

function [ir, ax] = baseIR()
    line = m2t2.ir.makeLineSeries(); line.id = 'axes-1-series-1'; line.x = [0 1]; line.y = [0 1];
    ax = m2t2.ir.makeAxes(); ax.series = {line};
    ir = m2t2.ir.makeFigure({ax}); ir.size = [12 8];
end

function expectInvalid(action, fragment)
    try, action(); catch err
        assert(strcmp(err.identifier, 'M2T2:E003:InvalidIR'));
        assertContains(err.message, fragment); return;
    end
    error('M2T2:ExpectedFailureMissing', 'Expected InvalidIR containing %s.', fragment);
end

function assertContains(text, value), assert(~isempty(strfind(text, value))); end %#ok<STREMP>
function ensureDirectory(path), if exist(path, 'dir') ~= 7, mkdir(path); end, end
function writeRows(path, rows)
    fid = fopen(path, 'w'); cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, 'case\tstatus\tdetail\tlayer\n');
    for k = 1:size(rows,1), fprintf(fid, '%s\t%s\t%s\t%s\n', rows{k,:}); end
    clear cleanup;
end
function value = oneLine(value), value = strrep(strrep(value, sprintf('\r'), ' '), sprintf('\n'), ' '); end
