function summary = runM34HybridImageTests(outputDirectory)
%RUNM34HYBRIDIMAGETESTS Validate explicit hybrid image assets and workflows.
    repositoryRoot = fileparts(fileparts(mfilename('fullpath')));
    if nargin < 1
        outputDirectory = fullfile(repositoryRoot, '.audit', 'm34-hybrid-image');
    end
    addpath(fullfile(repositoryRoot, 'src'));
    resetDirectory(outputDirectory);
    cases = { ...
        'R1_basic_hybrid_export', @() basicHybrid(outputDirectory); ...
        'R2_vector_default_unchanged', @() vectorDefault(outputDirectory); ...
        'R3_explicit_vector', @() explicitVector(outputDirectory); ...
        'R4_explicit_hybrid', @() explicitHybrid(outputDirectory); ...
        'R5_unknown_backend', @() unknownBackend(outputDirectory); ...
        'R6_explicit_xy', @() explicitCoordinates(outputDirectory); ...
        'R7_reversed_y', @() directionCase(outputDirectory, 'reverse'); ...
        'R8_axis_xy', @() directionCase(outputDirectory, 'normal'); ...
        'R9_custom_clim', @() rasterPixels(outputDirectory, false, 'clim'); ...
        'R10_custom_colormap', @() rasterPixels(outputDirectory, false, 'colormap'); ...
        'R11_nan_transparency', @() rasterPixels(outputDirectory, true, 'nan'); ...
        'R12_colorbar', @() colorbarCase(outputDirectory); ...
        'R13_publication_single', @() profileCase(outputDirectory, 'single-column'); ...
        'R14_publication_double', @() profileCase(outputDirectory, 'double-column'); ...
        'R15_mixed_line_image', @() mixedSeries(outputDirectory); ...
        'R16_multiple_axes', @() multipleAxes(outputDirectory); ...
        'R17_exportset_hybrid_default', @() setDefault(outputDirectory); ...
        'R18_exportset_entry_override', @() setOverride(outputDirectory); ...
        'R19_deterministic_tex', @() deterministicTex(); ...
        'R20_deterministic_png', @() deterministicAsset(outputDirectory); ...
        'R21_stale_asset_cleanup', @() staleAssetCleanup(outputDirectory); ...
        'R22_path_with_spaces', @() pathWithSpaces(outputDirectory); ...
        'R23_250x250_fixture', @() denseFixture(outputDirectory); ...
        'R24_collision_policy', @() collisionPolicy(outputDirectory)};
    rows = cell(size(cases, 1), 4); failures = 0;
    for k = 1:size(cases, 1)
        try
            detail = cases{k, 2}(); status = 'PASS';
        catch err
            status = 'FAIL'; failures = failures + 1;
            detail = sprintf('%s: %s', identifierText(err.identifier), oneLine(err.message));
        end
        rows(k, :) = {cases{k, 1}, status, detail, 'hybrid'};
    end
    resultPath = fullfile(outputDirectory, 'hybrid-results.tsv'); writeRows(resultPath, rows);
    summary = struct('failures', failures, 'tests', size(rows, 1), 'resultPath', resultPath);
    if failures > 0
        fprintf(2, 'M3.4 hybrid diagnostics from %s:\n%s', resultPath, fileread(resultPath));
        error('M2T:M34HybridTestsFailed', '%d M3.4 hybrid tests failed.', failures);
    end
end

function detail = basicHybrid(root)
    [fig, ax, cleanup] = imageFigure([1 2 3;4 5 6]); %#ok<ASGLU>
    result = m2t.export(fig, fullfile(root, 'r1-basic'), 'ImageBackend', 'hybrid');
    assertHybridSuccess(result, 1); [rgb, ~, alpha] = imread(result.render.assets{1});
    assert(isequal(size(rgb), [2 3 3]) && isempty(alpha));
    assertContains(fileread(result.texPath), '\addplot graphics[');
    detail = '2x3 PNG layer and vector PGFPlots axis compiled'; clear cleanup;
end

function detail = vectorDefault(root)
    [fig, ax, cleanup] = imageFigure([1 2;3 4]); %#ok<ASGLU>
    ir = m2t2.reader.readFigure(fig); expected = m2t2.render.renderPgfplots(ir, true);
    result = m2t.export(fig, fullfile(root, 'r2-vector-default'));
    assert(result.success && strcmp(result.render.requestedImageBackend, 'vector'));
    assert(strcmp(result.render.effectiveImageBackend, 'vector') && isempty(result.render.assets));
    assert(strcmp(fileread(result.texPath), expected));
    assertContains(fileread(result.texPath), 'matrix plot*');
    detail = 'omitted public option remains byte-identical M3.3 vector output'; clear cleanup;
end

function detail = explicitVector(root)
    [fig, ax, cleanup] = imageFigure([1 2;3 4]); %#ok<ASGLU>
    implicit = m2t.export(fig, fullfile(root, 'r3-implicit-vector'));
    explicit = m2t.export(fig, fullfile(root, 'r3-explicit-vector'), ...
                          'ImageBackend', 'vector');
    assert(implicit.success && explicit.success);
    assert(strcmp(explicit.render.requestedImageBackend, 'vector'));
    assert(strcmp(explicit.render.effectiveImageBackend, 'vector'));
    assert(isempty(explicit.render.assets));
    assert(strcmp(fileread(implicit.texPath), fileread(explicit.texPath)));
    detail = 'explicit public vector option matches omitted default'; clear cleanup;
end

function detail = explicitHybrid(root)
    [fig, ax, cleanup] = imageFigure(peaks(8)); %#ok<ASGLU>
    result = m2t.export(fig, fullfile(root, 'r4-hybrid'), 'ImageBackend', 'hybrid');
    assertHybridSuccess(result, 1);
    assert(strcmp(result.render.requestedImageBackend, 'hybrid'));
    assert(strcmp(result.render.effectiveImageBackend, 'hybrid'));
    detail = 'requested/effective backend and asset metadata exposed'; clear cleanup;
end

function detail = unknownBackend(root)
    [fig, ax, cleanup] = imageFigure([1 2;3 4]); %#ok<ASGLU>
    output = fullfile(root, 'r5-unknown');
    result = m2t.export(fig, output, 'ImageBackend', 'automatic');
    assert(~result.success && strcmp(result.diagnostics(1).code, 'M2T:IMAGE_BACKEND_UNKNOWN'));
    assert(exist([output '.tex'], 'file') ~= 2 && exist([output '-assets'], 'dir') ~= 7);
    detail = 'unknown backend rejected before output'; clear cleanup;
end

function detail = explicitCoordinates(root)
    fig = figure('Visible', 'off'); cleanup = onCleanup(@() closeFigure(fig));
    ax = axes('Parent', fig); imagesc(ax, [10 20 30], [100 200], [1 2 3;4 5 6]);
    result = m2t.export(fig, fullfile(root, 'r6-coordinates'), 'ImageBackend', 'hybrid');
    assertHybridSuccess(result, 1); tex = fileread(result.texPath);
    assertContains(tex, 'xmin=5'); assertContains(tex, 'xmax=35');
    assertContains(tex, 'ymin=50'); assertContains(tex, 'ymax=250');
    detail = 'cell edges [5,35] x [50,250] aligned'; clear cleanup;
end

function detail = directionCase(root, direction)
    [fig, ax, cleanup] = imageFigure([0 1;2 3]); set(ax, 'YDir', direction);
    result = m2t.export(fig, fullfile(root, ['r-dir-' direction]), 'ImageBackend', 'hybrid');
    assertHybridSuccess(result, 1); assertContains(fileread(result.texPath), ['y dir=' direction]);
    [rgb, ~, ~] = imread(result.render.assets{1});
    assert(~isequal(reshape(rgb(1,1,:),1,3), reshape(rgb(2,1,:),1,3)));
    detail = [direction ' YDir retained with coordinate-normal PNG rows']; clear cleanup;
end

function detail = rasterPixels(root, includeNan, suffix)
    data = [0 1;2 3]; if includeNan, data(1,2) = NaN; end
    [fig, ax, cleanup] = imageFigure(data); set(ax, 'CLim', [0 4]);
    map = [0 0 0;1 0 0;0 1 0;1 1 1]; colormap(ax, map);
    result = m2t.export(fig, fullfile(root, ['r-' suffix]), 'ImageBackend', 'hybrid');
    assertHybridSuccess(result, 1); [rgb, ~, alpha] = imread(result.render.assets{1});
    if islogical(rgb), rgb = uint8(rgb) * 255; end
    if islogical(alpha), alpha = uint8(alpha) * 255; end
    expected = uint8(255 * cat(3, [0 1;0 1], [0 0;1 1], [0 0;0 1]));
    if includeNan
        assert(alpha(1,2) == 0 && all(reshape(rgb(1,2,:),1,3) == 0));
    else
        assert(isequal(rgb, expected) && isempty(alpha));
    end
    detail = 'known CLim bins map to exact RGBA pixels'; clear cleanup;
end

function detail = colorbarCase(root)
    [fig, ax, cleanup] = imageFigure(peaks(12)); cb = colorbar(ax); ylabel(cb, 'Value');
    result = m2t.export(fig, fullfile(root, 'r12-colorbar'), 'ImageBackend', 'hybrid');
    assertHybridSuccess(result, 1); tex = fileread(result.texPath);
    assertContains(tex, 'colorbar style={'); assertContains(tex, 'ylabel={Value}');
    detail = 'ColorbarIR remains vector and compiles'; clear cleanup;
end

function detail = profileCase(root, width)
    [fig, ax, cleanup] = imageFigure(peaks(12)); colorbar(ax);
    result = m2t.export(fig, fullfile(root, ['r-profile-' width]), ...
        'ImageBackend', 'hybrid', 'Profile', 'publication', 'Width', width);
    assertHybridSuccess(result, 1); assert(strcmp(result.profile.width, width));
    [rgb, ~, ~] = imread(result.render.assets{1}); assert(isequal(size(rgb,1),12));
    detail = [width ' changes physical size, not 12x12 pixels']; clear cleanup;
end

function detail = mixedSeries(root)
    [fig, ax, cleanup] = imageFigure(peaks(15)); hold(ax, 'on');
    plot(ax, [1 15], [1 15], 'w-', 'LineWidth', 2);
    result = m2t.export(fig, fullfile(root, 'r15-mixed'), 'ImageBackend', 'hybrid');
    assertHybridSuccess(result, 1); tex = fileread(result.texPath);
    assertContains(tex, '\addplot graphics['); assertContains(tex, '\addplot+[');
    detail = 'image raster plus independent vector line'; clear cleanup;
end

function detail = multipleAxes(root)
    fig = figure('Visible','off'); cleanup = onCleanup(@() closeFigure(fig));
    first = subplot(1,2,1,'Parent',fig); imagesc(first, peaks(10));
    second = subplot(1,2,2,'Parent',fig); plot(second, 1:3, [1 3 2]);
    result = m2t.export(fig, fullfile(root, 'r16-axes'), 'ImageBackend', 'hybrid');
    assertHybridSuccess(result, 1); assert(countText(fileread(result.texPath), '\begin{axis}[') == 2);
    detail = 'hybrid image axes plus vector line axes'; clear cleanup;
end

function detail = setDefault(root)
    [fig, ax, cleanup] = imageFigure(peaks(10)); %#ok<ASGLU>
    entries = struct('figure', fig, 'name', 'heatmap');
    result = m2t.exportSet(entries, fullfile(root, 'r17-set'), ...
                           'ImageBackend', 'hybrid');
    assert(result.success && strcmp(result.entries(1).effective.imageBackend, 'hybrid'));
    manifest = jsondecode(fileread(result.manifestPath));
    assert(strcmp(manifest.defaults.imageBackend, 'hybrid'));
    assert(strcmp(manifest.figures.imageBackend, 'hybrid'));
    detail = 'set default inherited and additive schema-1 fields written'; clear cleanup;
end

function detail = setOverride(root)
    first = figure('Visible','off'); imagesc(peaks(8));
    second = figure('Visible','off'); imagesc(peaks(8));
    cleanup = onCleanup(@() closeFigures([first second]));
    entries = struct('figure',{first,second}, 'name',{'hybrid','vector'}, ...
                     'imageBackend',{[], 'vector'});
    result = m2t.exportSet(entries, fullfile(root, 'r18-set'), ...
                           'ImageBackend', 'hybrid');
    assert(result.success && strcmp(result.entries(1).effective.imageBackend,'hybrid'));
    assert(strcmp(result.entries(2).effective.imageBackend,'vector'));
    assert(numel(result.entries(1).result.render.assets)==1 && ...
           isempty(result.entries(2).result.render.assets));
    detail = 'entry override > set default > export default'; clear cleanup;
end

function detail = deterministicTex()
    [fig, ax, cleanup] = imageFigure(peaks(9)); %#ok<ASGLU>
    ir = m2t2.reader.readFigure(fig); config = m2t2.render.defaultConfig();
    first = m2t2.render.makePgfplotsPlan(ir,true,config,'hybrid','fixed-assets');
    second = m2t2.render.makePgfplotsPlan(ir,true,config,'hybrid','fixed-assets');
    assert(strcmp(first.tex, second.tex));
    detail = sprintf('byte-identical hybrid TeX bytes=%d',numel(first.tex)); clear cleanup;
end

function detail = deterministicAsset(root)
    [fig, ax, cleanup] = imageFigure(peaks(13)); %#ok<ASGLU>
    output = fullfile(root, 'r20-deterministic');
    first = m2t.export(fig, output, 'ImageBackend','hybrid','Overwrite',true);
    assertHybridSuccess(first,1); bytes = readBytes(first.render.assets{1});
    second = m2t.export(fig, output, 'ImageBackend','hybrid','Overwrite',true);
    assertHybridSuccess(second,1); assert(isequal(bytes,readBytes(second.render.assets{1})));
    detail = sprintf('byte-identical PNG bytes=%d',numel(bytes)); clear cleanup;
end

function detail = staleAssetCleanup(root)
    fig = figure('Visible','off'); cleanup = onCleanup(@() closeFigure(fig));
    ax = axes('Parent',fig); firstImage = imagesc(ax,[1 2;3 4]); hold(ax,'on');
    secondImage = imagesc(ax,[4 3;2 1]); output=fullfile(root,'r21-stale');
    first = m2t.export(fig,output,'ImageBackend','hybrid','Overwrite',true);
    assertHybridSuccess(first,2); delete(secondImage);
    second = m2t.export(fig,output,'ImageBackend','hybrid','Overwrite',true);
    assertHybridSuccess(second,1);
    assert(exist(fullfile([output '-assets'],'image-0002.png'),'file')~=2 && ishandle(firstImage));
    detail = 'owned asset directory recreated without stale image-0002'; clear cleanup;
end

function detail = pathWithSpaces(root)
    [fig, ax, cleanup] = imageFigure(peaks(10)); %#ok<ASGLU>
    result=m2t.export(fig,fullfile(root,'r22 path with spaces','heat map'), ...
                      'ImageBackend','hybrid');
    assertHybridSuccess(result,1); detail='space-containing TeX/asset path compiled'; clear cleanup;
end

function detail = denseFixture(root)
    [fig, ax, cleanup] = imageFigure(peaks(250)); %#ok<ASGLU>
    output=fullfile(root,'r23-250'); started=tic;
    result=m2t.export(fig,output,'ImageBackend','hybrid'); elapsed=toc(started);
    assertHybridSuccess(result,1); texBytes=fileBytes(result.texPath); pngBytes=fileBytes(result.render.assets{1});
    assert(texBytes < 20000 && pngBytes > 0);
    detail=sprintf('250x250 tex=%d png=%d total=%.4gs',texBytes,pngBytes,elapsed);
    clear cleanup;
end

function detail = collisionPolicy(root)
    [fig, ax, cleanup] = imageFigure(peaks(8)); %#ok<ASGLU>
    output=fullfile(root,'r24-collision'); first=m2t.export(fig,output,'ImageBackend','hybrid');
    assertHybridSuccess(first,1); second=m2t.export(fig,output,'ImageBackend','hybrid');
    assert(~second.success && strcmp(second.diagnostics(1).code,'M2T:E003:OutputExists'));
    assert(exist(first.render.assets{1},'file')==2);
    detail='Overwrite=false preserves existing TeX/PDF/assets'; clear cleanup;
end

function [fig, ax, cleanup] = imageFigure(data)
    fig=figure('Visible','off'); cleanup=onCleanup(@() closeFigure(fig));
    ax=axes('Parent',fig); imagesc(ax,data);
end

function assertHybridSuccess(result,count)
    assert(result.success && strcmp(result.status,'success'));
    assert(strcmp(result.render.effectiveImageBackend,'hybrid'));
    assert(numel(result.render.assets)==count);
    assert(exist(result.texPath,'file')==2 && exist(result.pdfPath,'file')==2);
    for k=1:count, assert(exist(result.render.assets{k},'file')==2); end
end

function bytes=readBytes(path),fid=fopen(path,'rb');assert(fid>=0);c=onCleanup(@()fclose(fid));bytes=fread(fid,Inf,'*uint8');clear c;end
function count=fileBytes(path),count=numel(readBytes(path));end
function assertContains(text,pattern),assert(~isempty(strfind(text,pattern)));end %#ok<STREMP>
function count=countText(text,pattern),count=numel(strfind(text,pattern));end %#ok<STREMP>
function closeFigure(fig),if ishandle(fig),close(fig);end,end
function closeFigures(figures),for k=1:numel(figures),closeFigure(figures(k));end,end
function resetDirectory(path),if exist(path,'dir')==7,rmdir(path,'s');end,mkdir(path);end
function value=oneLine(value),value=regexprep(value,'[\r\n\t]+',' ');end
function value=identifierText(value),if isempty(value),value='<none>';end,end
function writeRows(path,rows),fid=fopen(path,'wb');assert(fid>=0);c=onCleanup(@()fclose(fid));fprintf(fid,'case\tstatus\tdetail\tlayer\n');for k=1:size(rows,1),fprintf(fid,'%s\t%s\t%s\t%s\n',rows{k,:});end,clear c;end
