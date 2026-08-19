function summary = runM23ReaderTests(outputDirectory)
%RUNM23READERTESTS Verify C1-C10 colorbar normalization and ownership.
    root = fileparts(fileparts(mfilename('fullpath'))); addpath(fullfile(root, 'src'));
    addpath(fullfile(root, 'test', 'private'));
    if nargin < 1, outputDirectory = fullfile(root, '.audit', 'm2.3'); end
    names = {'default','eastoutside','westoutside','horizontal','manual', ...
             'ticks','label','first_only','separate','overlap'};
    rows = cell(numel(names), 4); failures = 0;
    for k = 1:numel(names)
        figureHandle = [];
        try
            [figureHandle, expected] = createM23ColorbarFixture(names{k});
            ir = m2t2.reader.readFigure(figureHandle); checkCase(names{k}, ir, expected);
            status = 'PASS'; detail = '';
        catch err
            failures = failures + 1; status = 'FAIL'; detail = oneLine(err.message);
        end
        if ~isempty(figureHandle) && ishandle(figureHandle), close(figureHandle); end
        rows(k, :) = {['C' num2str(k)], status, detail, names{k}};
    end
    ensureDirectory(outputDirectory); writeRows(fullfile(outputDirectory, 'm23-reader-results.tsv'), rows);
    summary = struct('failures', failures, 'tests', numel(names));
    if failures, error('M2T2:M23ReaderTestsFailed', '%d M2.3 reader tests failed.', failures); end
end

function checkCase(name, ir, expected)
    assert(numel(ir.elements) == expected.count);
    for k = 1:numel(ir.elements)
        cb = ir.elements{k}; assert(strcmp(cb.kind, 'm2t2.colorbar'));
        assert(strcmp(cb.id, sprintf('colorbar-%d', k)));
        assert(strcmp(cb.owner.kind, 'axes'));
        assert(isequal(cb.associatedAxesIds, {cb.owner.id}));
        a = find(cellfun(@(item) strcmp(item.id, cb.owner.id), ir.axes), 1); assert(~isempty(a));
        assert(isequal(cb.limits, ir.axes{a}.colorMapping.limits));
        assert(strcmp(cb.scale, ir.axes{a}.colorMapping.scale));
        p = cb.placement; assert(p.width > 0 && p.height > 0);
    end
    cb = ir.elements{1};
    if strcmp(name, 'westoutside'), assert(strcmp(cb.location, 'westoutside')); end
    if strcmp(name, 'horizontal')
        assert(strcmp(cb.orientation, 'horizontal')); assert(strcmp(cb.location, 'southoutside'));
    end
    if strcmp(name, 'manual')
        assert(max(abs([cb.placement.x cb.placement.y cb.placement.width cb.placement.height] - ...
                       [0.80 0.20 0.04 0.50])) < 1e-8);
    end
    if strcmp(name, 'ticks')
        assert(strcmp(cb.ticks.mode, 'manual')); assert(isequal(cb.ticks.values, [1 2.5 4]));
        assert(strcmp(cb.ticks.labels{2}.value, 'mid'));
    end
    if strcmp(name, 'label'), assert(strcmp(cb.label.value, 'Temperature')); end
    if strcmp(name, 'first_only'), assert(numel(ir.axes) == 2 && strcmp(cb.owner.id, 'axes-1')); end
    if strcmp(name, 'separate')
        assert(numel(unique(cellfun(@(item) item.owner.id, ir.elements, 'UniformOutput', false))) == 2);
    end
    if strcmp(name, 'overlap')
        assert(numel(ir.axes) == 2); assert(strcmp(cb.owner.id, 'axes-2'));
    end
end

function ensureDirectory(path), if exist(path, 'dir') ~= 7, mkdir(path); end, end
function writeRows(path, rows)
    fid = fopen(path, 'w'); cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, 'case\tstatus\tdetail\tfixture\n');
    for k = 1:size(rows,1), fprintf(fid, '%s\t%s\t%s\t%s\n', rows{k,:}); end
end
function value = oneLine(value)
    value = strrep(value, sprintf('\r'), ' '); value = strrep(value, sprintf('\n'), ' ');
end
