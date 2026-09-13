function summary = runS1SecurityTests(outputDirectory)
%RUNS1SECURITYTESTS Product ownership and untrusted path boundary regressions.
    repository = fileparts(fileparts(mfilename('fullpath')));
    addpath(fullfile(repository, 'src'));
    if nargin < 1, outputDirectory = fullfile(repository, '.audit', 's1-security'); end
    if exist(outputDirectory, 'dir') ~= 7, mkdir(outputDirectory); end
    root = tempname(outputDirectory); mkdir(root);
    fig = figure('Visible', 'off'); cleanup = onCleanup(@() close(fig));
    ax = axes('Parent', fig); imagesc(ax, [1 2; 3 4]);
    ir = m2t2.reader.readFigure(fig);
    cases = {'dotted_stem', @dottedStem; 'explicit_parent_path', @parentPath; ...
        'hostile_stems', @hostileStems; 'product_collisions', @collisions; ...
        'directory_product', @directoryProduct; 'foreign_assets_preserved', @foreignAssets; ...
        'nested_assets_preserved', @nestedAssets; 'owned_assets_accepted', @ownedAssets; ...
        'unsafe_asset_references', @assetReferences; 'set_traversal', @setTraversal; ...
        'set_preflight', @setPreflight; 'compiler_controls', @compilerControls; ...
        'literal_text', @literalText};
    if ispc
        cases(end+1,:) = {'windows_names', @windowsNames};
    end
    if exist('OCTAVE_VERSION', 'builtin')
        cases(end+1:end+5,:) = {'file_symlink', @() linkCase('file'); ...
            'dangling_symlink', @() linkCase('dangling'); ...
            'asset_directory_symlink', @() linkCase('directory'); ...
            'asset_file_symlink', @() linkCase('asset'); ...
            'manifest_symlink', @() linkCase('manifest')};
    end
    rows = cell(size(cases,1),3); failures = 0;
    for k = 1:size(cases,1)
        try
            cases{k,2}(); status = 'PASS'; detail = 'assertions passed';
        catch err
            status = 'FAIL'; failures = failures + 1;
            detail = regexprep([err.identifier ': ' err.message], '[\r\n\t]+', ' ');
        end
        rows(k,:) = {cases{k,1}, status, detail};
    end
    path = fullfile(root, 'security-results.tsv');
    fid = fopen(path, 'wb'); assert(fid >= 0); fileCleanup = onCleanup(@() fclose(fid));
    fprintf(fid, 'case\tstatus\tdetail\n');
    for k = 1:size(rows,1), fprintf(fid, '%s\t%s\t%s\n', rows{k,:}); end
    clear fileCleanup cleanup;
    summary = struct('tests', size(rows,1), 'failures', failures, 'resultPath', path);
    fprintf('%s', fileread(path));
    assert(failures == 0, 'S1 security tests failed.');

    function dottedStem()
        p = paths('heat map.v1');
        assert(strcmp(p.assetDirectoryName, 'heat map.v1-assets'));
        plan = m2t2.render.makePgfplotsPlan(ir, true, m2t2.render.defaultConfig(), 'hybrid', p.assetDirectoryName);
        assert(strcmp(plan.assets(1).reference, 'heat map.v1-assets/image-0001.png'));
        assert(~isempty(strfind(plan.tex, '\detokenize{heat map.v1-assets/image-0001.png}')));
    end
    function parentPath()
        p = paths(fullfile('child','..','explicit'));
        assert(~isempty(strfind(p.base, fullfile('child','..','explicit'))));
        m2t.internal.checkOutputProducts(p, false);
    end
    function hostileStems()
        names = {['a' char(9) 'b'], ['a' char(127)], 'x%y', 'x{y}', 'x#y', 'x$y', 'x"y'};
        for n = 1:numel(names)
            mustFail(@() paths(names{n}), 'M2T:E002:InvalidOutputPath');
        end
    end
    function collisions()
        suffixes = {'.tex','.pdf','.compile.log'};
        for n = 1:numel(suffixes)
            p = paths(['collision' num2str(n)]); target = [p.base suffixes{n}];
            write(target, 'preserve');
            mustFail(@() m2t.internal.checkOutputProducts(p, false), 'M2T:E003:OutputExists');
            assert(strcmp(fileread(target), 'preserve'));
        end
    end
    function directoryProduct()
        p = paths('directory-product'); write(p.texPath, 'preserve'); mkdir(p.pdfPath);
        r = m2t.export(fig, p.base, 'Overwrite', true);
        assert(~r.success && strcmp(r.diagnostics(1).code, 'M2T:E006:UnsafeOutputProduct'));
        assert(strcmp(fileread(p.texPath), 'preserve'));
    end
    function foreignAssets()
        p = paths('foreign'); mkdir(p.assetDirectory); write(p.texPath, 'preserve');
        target = fullfile(p.assetDirectory, 'notes.txt'); write(target, 'unrelated');
        r = m2t.export(fig, p.base, 'Overwrite', true, 'ImageBackend', 'hybrid');
        assert(~r.success && strcmp(r.diagnostics(1).code, 'M2T:E006:UnsafeOutputProduct'));
        assert(strcmp(fileread(target), 'unrelated') && strcmp(fileread(p.texPath), 'preserve'));
    end
    function nestedAssets()
        p = paths('nested'); mkdir(fullfile(p.assetDirectory, 'child'));
        mustFail(@() m2t.internal.checkOutputProducts(p, true), 'M2T:E006:UnsafeOutputProduct');
        assert(exist(fullfile(p.assetDirectory, 'child'), 'dir') == 7);
    end
    function ownedAssets()
        p = paths('owned'); mkdir(p.assetDirectory);
        write(fullfile(p.assetDirectory, 'image-0001.png'), 'owned product');
        m2t.internal.checkOutputProducts(p, true);
    end
    function assetReferences()
        fixture = ir;
        names = {'../outside', '/absolute', '..', 'x/y', 'x\y', 'x{y}', 'x%y'};
        for n = 1:numel(names)
            mustFail(@() m2t2.render.makePgfplotsPlan(fixture, true, m2t2.render.defaultConfig(), 'hybrid', names{n}), ...
                'M2T2:E055:UnsafeAssetReference');
        end
    end
    function setTraversal()
        r = m2t.exportSet(struct('figure', fig, 'name', '../outside'), fullfile(root,'set-traversal'));
        assert(~r.success && strcmp(r.diagnostics(1).code, 'M2T:SET_INVALID_NAME'));
        assert(exist(fullfile(root,'set-traversal'), 'dir') ~= 7);
    end
    function setPreflight()
        folder = fullfile(root,'set-preflight'); mkdir(folder); write(fullfile(folder,'second.pdf'), 'preserve');
        entries = struct('figure', {fig,fig}, 'name', {'first','second'});
        r = m2t.exportSet(entries, folder);
        assert(~r.success && strcmp(r.diagnostics(1).code, 'M2T:SET_OUTPUT_EXISTS'));
        assert(exist(fullfile(folder,'first.tex'), 'file') ~= 2);
        assert(strcmp(fileread(fullfile(folder,'second.pdf')), 'preserve'));
    end
    function compilerControls()
        target = fullfile(root,'out.pdf');
        mustFail(@() m2t.internal.compileLuaLatex(['x' char(9)], target), 'M2T:C005:UnsafeProcessArgument');
        mustFail(@() m2t.internal.compileLuaLatex('x.tex', target, ['x' char(10)]), 'M2T:C005:UnsafeProcessArgument');
    end
    function literalText()
        title(ax, '\input{outside}_$%#', 'Interpreter', 'none');
        literalIR = m2t2.reader.readFigure(fig);
        tex = m2t2.render.renderPgfplots(literalIR, true);
        assert(isempty(strfind(tex, '\input{outside}')));
        title(ax, '$x^2$', 'Interpreter', 'latex');
        mathIR = m2t2.reader.readFigure(fig);
        tex = m2t2.render.renderPgfplots(mathIR, true);
        assert(~isempty(strfind(tex, '$x^2$')));
        title(ax, '', 'Interpreter', 'tex');
    end
    function windowsNames()
        names = {'NUL','CON.txt','COM1','a:b','a!b','a.'};
        for n = 1:numel(names), mustFail(@() paths(names{n}), 'M2T:E002:InvalidOutputPath'); end
    end
    function linkCase(kind)
        p = paths(['link-' kind]); outside = fullfile(root,['sentinel-' kind]); write(outside, 'preserve');
        switch kind
            case 'file', target = p.texPath; destination = outside;
            case 'dangling', target = p.pdfPath; destination = [outside '-missing'];
            case 'directory', target = p.assetDirectory; destination = root;
            case 'asset'
                mkdir(p.assetDirectory); target = fullfile(p.assetDirectory, 'image-0001.png'); destination = outside;
            case 'manifest'
                mkdir(p.base); target = fullfile(p.base, 'm2t-manifest.json'); destination = outside;
        end
        [status, message] = symlink(destination, target); assert(status == 0, message);
        linkCleanup = onCleanup(@() unlink(target));
        if strcmp(kind, 'manifest')
            r = m2t.exportSet(struct('figure', fig, 'name', 'entry'), p.base, 'Overwrite', true);
            assert(~r.success && exist(fullfile(p.base, 'entry.tex'), 'file') ~= 2);
        else
            mustFail(@() m2t.internal.checkOutputProducts(p, true), 'M2T:E006:UnsafeOutputProduct');
        end
        assert(strcmp(fileread(outside), 'preserve')); clear linkCleanup;
    end
    function p = paths(name), p = m2t.internal.normalizeOutputBase(fullfile(root, name)); end
end

function write(path, value), m2t.internal.writeTextFile(path, value); end
function mustFail(callback, code)
    caught = false;
    try, callback(); catch err, caught = true; assert(strcmp(err.identifier, code), [err.identifier ': ' err.message]); end
    assert(caught, ['Expected ' code]);
end
