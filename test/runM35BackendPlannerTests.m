function summary = runM35BackendPlannerTests(outputDirectory)
%RUNM35BACKENDPLANNERTESTS Validate deterministic scalar-image planning.
    repositoryRoot = fileparts(fileparts(mfilename('fullpath')));
    if nargin < 1
        outputDirectory = fullfile(repositoryRoot, '.audit', 'm35-planner');
    end
    addpath(fullfile(repositoryRoot, 'src'));
    resetDirectory(outputDirectory);
    cases = { ...
        'P1_explicit_vector', @() explicitDecision('vector','vector','explicit_vector',10000); ...
        'P2_explicit_hybrid', @() explicitDecision('hybrid','hybrid','explicit_hybrid',4); ...
        'P3_auto_tiny_vector', @() publicAuto(outputDirectory, 10, 10, 'vector'); ...
        'P4_below_threshold', @() boundaryDecision(4095,'vector'); ...
        'P5_exact_threshold', @() boundaryDecision(4096,'vector'); ...
        'P6_above_threshold', @() boundaryDecision(4097,'hybrid'); ...
        'P7_auto_250_hybrid', @() sizeDecision(250,250,'hybrid'); ...
        'P8_auto_500_hybrid', @() sizeDecision(500,500,'hybrid'); ...
        'P9_rectangular_equivalence', @() rectangularEquivalence(); ...
        'P10_no_image', @() noImageDecision(); ...
        'P11_profile_independence', @() profileIndependence(); ...
        'P12_mixed_image_line', @() mixedPublic(outputDirectory); ...
        'P13_multiple_axes', @() multipleAxesDecision(); ...
        'P14_exportset_auto_default', @() setAuto(outputDirectory); ...
        'P15_exportset_override', @() setOverride(outputDirectory); ...
        'P16_manifest_metadata', @() manifestMetadata(outputDirectory); ...
        'P17_deterministic_repeat', @() deterministicRepeat(); ...
        'P18_rgb_unsupported', @() unsupportedRgb(outputDirectory); ...
        'P19_alpha_unsupported', @() unsupportedAlpha(outputDirectory); ...
        'P20_invalid_backend', @() invalidBackend(outputDirectory); ...
        'P21_policy_metadata', @() policyMetadata(); ...
        'P22_explicit_vector_large', @() explicitDecision('vector','vector','explicit_vector',250000); ...
        'P23_explicit_hybrid_tiny', @() publicExplicitHybrid(outputDirectory); ...
        'P24_architecture_invariant', @() architectureInvariant(repositoryRoot)};
    rows = cell(size(cases,1),4); failures = 0;
    for k = 1:size(cases,1)
        try
            detail = cases{k,2}(); status = 'PASS';
        catch err
            status = 'FAIL'; failures = failures + 1;
            detail = sprintf('%s: %s', identifierText(err.identifier), oneLine(err.message));
        end
        rows(k,:) = {cases{k,1},status,detail,'planner'};
    end
    resultPath = fullfile(outputDirectory,'planner-results.tsv'); writeRows(resultPath,rows);
    summary = struct('failures',failures,'tests',size(rows,1),'resultPath',resultPath);
    if failures > 0
        fprintf(2,'M3.5 planner diagnostics from %s:\n%s',resultPath,fileread(resultPath));
        error('M2T:M35PlannerTestsFailed','%d M3.5 planner tests failed.',failures);
    end
end

function detail = explicitDecision(requested, selected, reason, cells)
    decision=m2t.planning.selectImageBackend(imageIr(1,cells),requested);
    assert(strcmp(decision.selected,selected)&&strcmp(decision.reason,reason));
    detail=sprintf('%s request selects %s for %d cells',requested,selected,cells);
end

function detail = publicAuto(root, rows, columns, selected)
    [fig,cleanup]=imageFigure(reshape(1:(rows*columns),rows,columns));
    result=m2t.export(fig,fullfile(root,sprintf('auto-%dx%d',rows,columns)), ...
        'ImageBackend','auto'); assert(result.success);
    assertDecision(result,'auto',selected,reasonFor(selected));
    if strcmp(selected,'hybrid'),assert(numel(result.render.assets)==1);else,assert(isempty(result.render.assets));end
    detail=sprintf('%dx%d auto selected %s and compiled',rows,columns,selected);clear cleanup;
end

function detail = boundaryDecision(cells, expected)
    decision=m2t.planning.selectImageBackend(imageIr(1,cells),'auto');
    assert(strcmp(decision.selected,expected)&&decision.maxImageCells==cells);
    detail=sprintf('%d cells select %s',cells,expected);
end

function detail = sizeDecision(rows,columns,expected)
    decision=m2t.planning.selectImageBackend(imageIr(rows,columns),'auto');
    assert(strcmp(decision.selected,expected));
    detail=sprintf('%dx%d=%d selects %s',rows,columns,rows*columns,expected);
end

function detail = rectangularEquivalence()
    shapes=[100 100;50 200;20 500;1 10000]; selected=cell(1,4);
    for k=1:4
        decision=m2t.planning.selectImageBackend(imageIr(shapes(k,1),shapes(k,2)),'auto');
        selected{k}=decision.selected;
    end
    assert(all(strcmp(selected,'hybrid')));
    detail='100x100, 50x200, 20x500, and 1x10000 all select hybrid';
end

function detail = noImageDecision()
    ax=m2t2.ir.makeAxes();line=m2t2.ir.makeLineSeries();line.x=[1 2];line.y=[1 2];ax.series={line};
    decision=m2t.planning.selectImageBackend(m2t2.ir.makeFigure({ax}),'auto');
    assert(strcmp(decision.selected,'vector')&&strcmp(decision.reason,'no_image_layer'));
    detail='line-only FigureIR selects vector with no_image_layer';
end

function detail = profileIndependence()
    [fig,cleanup]=imageFigure(peaks(80));analysis=m2t.internal.analyzeFigure(fig);
    before=m2t.planning.selectImageBackend(analysis.ir,'auto');
    selection=m2t.profile.getSelection('publication',[]);
    transformed=m2t.profile.apply(analysis.ir,selection.profile,selection.width);
    after=m2t.planning.selectImageBackend(transformed.ir,'auto');
    assert(strcmp(before.selected,after.selected)&&strcmp(before.reason,after.reason));
    detail='profile geometry does not change the 6400-cell decision';clear cleanup;
end

function detail = mixedPublic(root)
    fig=figure('Visible','off');cleanup=onCleanup(@()closeFigure(fig));ax=axes('Parent',fig);
    imagesc(ax,peaks(70));hold(ax,'on');plot(ax,1:70,35+10*sin((1:70)/8),'k-');
    result=m2t.export(fig,fullfile(root,'mixed'),'ImageBackend','auto');
    assert(result.success);assertDecision(result,'auto','hybrid','dense_scalar_image');
    assert(~isempty(strfind(fileread(result.texPath),'\addplot+['))); %#ok<STREMP>
    detail='dense image is hybrid while line stays vector';clear cleanup;
end

function detail = multipleAxesDecision()
    first=imageAxes(20,20,'axes-1');second=imageAxes(80,80,'axes-2');
    decision=m2t.planning.selectImageBackend(m2t2.ir.makeFigure({first second}),'auto');
    assert(decision.imageLayerCount==2&&decision.maxImageCells==6400);
    assert(strcmp(decision.selected,'hybrid'));
    detail='figure-level decision uses largest of two visible image layers';
end

function detail = setAuto(root)
    [small,c1]=imageFigure(peaks(10));[dense,c2]=imageFigure(peaks(65));
    entries=struct('figure',{small,dense},'name',{'small-auto','dense-auto'});
    result=m2t.exportSet(entries,fullfile(root,'set-auto'),'ImageBackend','auto');assert(result.success);
    assert(strcmp(result.entries(1).effective.selectedImageBackend,'vector'));
    assert(strcmp(result.entries(2).effective.selectedImageBackend,'hybrid'));
    detail='set auto resolves small vector and dense hybrid';clear c1 c2;
end

function detail = setOverride(root)
    [fig,cleanup]=imageFigure(peaks(10));
    entry=struct('figure',fig,'name','forced-hybrid','imageBackend','hybrid');
    result=m2t.exportSet(entry,fullfile(root,'set-override'),'ImageBackend','auto');assert(result.success);
    assert(strcmp(result.entries(1).effective.requestedImageBackend,'hybrid'));
    assert(strcmp(result.entries(1).effective.backendReason,'explicit_hybrid'));
    detail='entry explicit hybrid overrides set auto';clear cleanup;
end

function detail = manifestMetadata(root)
    [fig,cleanup]=imageFigure(peaks(65));entry=struct('figure',fig,'name','planned');
    result=m2t.exportSet(entry,fullfile(root,'manifest'),'ImageBackend','auto');assert(result.success);
    text=fileread(result.manifestPath);
    assertContains(text,'"requestedImageBackend":"auto"');
    assertContains(text,'"selectedImageBackend":"hybrid"');
    assertContains(text,'"backendReason":"dense_scalar_image"');
    assertContains(text,'"backendPolicy":"default-v1"');
    detail='schema 1 manifest contains additive planner fields';clear cleanup;
end

function detail = deterministicRepeat()
    ir=imageIr(65,65);first=m2t.planning.selectImageBackend(ir,'auto');
    second=m2t.planning.selectImageBackend(ir,'auto');assert(isequal(first,second));
    detail='repeated normalized input returns identical decision struct';
end

function detail = unsupportedRgb(root)
    rgb=zeros(2,3,3);rgb(:,:,1)=1;fig=figure('Visible','off');cleanup=onCleanup(@()closeFigure(fig));
    image(axes('Parent',fig),rgb);result=m2t.export(fig,fullfile(root,'rgb'),'ImageBackend','auto');
    assert(~result.success&&strcmp(result.status,'unsupported'));
    assert(strcmp(result.diagnostics(1).code,'M2T2:E_IMAGE_RGB_UNSUPPORTED'));
    detail='auto does not hide RGB capability rejection';clear cleanup;
end

function detail = unsupportedAlpha(root)
    [fig,cleanup]=imageFigure([1 2;3 4]);handle=findobj(fig,'Type','image');set(handle,'AlphaData',0.5);
    result=m2t.export(fig,fullfile(root,'alpha'),'ImageBackend','auto');
    assert(~result.success&&strcmp(result.diagnostics(1).code,'M2T2:E_IMAGE_ALPHA_UNSUPPORTED'));
    detail='auto does not hide source-alpha capability rejection';clear cleanup;
end

function detail = invalidBackend(root)
    [fig,cleanup]=imageFigure([1 2;3 4]);result=m2t.export(fig,fullfile(root,'invalid'),'ImageBackend','adaptive');
    assert(~result.success&&strcmp(result.diagnostics(1).code,'M2T:IMAGE_BACKEND_UNKNOWN'));
    assert(exist([fullfile(root,'invalid') '.tex'],'file')~=2);
    detail='unknown request remains a structured no-output error';clear cleanup;
end

function detail = policyMetadata()
    policy=m2t.planning.defaultPolicy();decision=m2t.planning.selectImageBackend(imageIr(64,64),'auto');
    assert(strcmp(policy.id,'default-v1')&&policy.version==1&&policy.maxVectorCells==4096);
    assert(isequal(decision.policy,policy));
    bad=policy;bad.maxVectorCells=0;caught=false;try,m2t.planning.selectImageBackend(imageIr(2,2),'auto',bad);catch err,caught=strcmp(err.identifier,'M2T:BACKEND_POLICY_INVALID');end;assert(caught);
    detail='default-v1 threshold 4096 is exposed and validated';
end

function detail = publicExplicitHybrid(root)
    [fig,cleanup]=imageFigure([1 2;3 4]);result=m2t.export(fig,fullfile(root,'tiny-hybrid'),'ImageBackend','hybrid');
    assert(result.success);assertDecision(result,'hybrid','hybrid','explicit_hybrid');assert(numel(result.render.assets)==1);
    detail='explicit hybrid compiles a tiny image despite auto policy';clear cleanup;
end

function detail = architectureInvariant(root)
    planner=fileread(fullfile(root,'src','+m2t','+planning','selectImageBackend.m'));
    forbidden={'get(','ishandle','graphics_toolkit','imwrite','compileLuaLatex','makePgfplotsPlan'};
    for k=1:numel(forbidden),assert(isempty(strfind(lower(planner),lower(forbidden{k}))));end %#ok<STREMP>
    renderer=fileread(fullfile(root,'src','+m2t2','+render','makePgfplotsPlan.m'));
    assert(isempty(strfind(renderer,'maxVectorCells'))); %#ok<STREMP>
    detail='planner is handle/toolkit/compiler/PNG-free and renderer has no heuristic';
end

function ir = imageIr(rows,columns)
    ir=m2t2.ir.makeFigure({imageAxes(rows,columns,'axes-1')});
end

function ax = imageAxes(rows,columns,id)
    image=m2t2.ir.makeImageSeries();image.x=1:columns;image.y=1:rows;
    image.cdata=zeros(rows,columns);ax=m2t2.ir.makeAxes();ax.id=id;
    ax.xlim=[0.5 max(1.5,columns+0.5)];ax.ylim=[0.5 max(1.5,rows+0.5)];ax.series={image};
end

function [fig,cleanup] = imageFigure(data)
    fig=figure('Visible','off');cleanup=onCleanup(@()closeFigure(fig));imagesc(axes('Parent',fig),data);
end

function value = reasonFor(selected)
    if strcmp(selected,'vector'),value='small_scalar_image';else,value='dense_scalar_image';end
end
function assertDecision(result,requested,selected,reason)
    assert(strcmp(result.render.imageBackend.requested,requested));
    assert(strcmp(result.render.imageBackend.selected,selected));
    assert(strcmp(result.render.imageBackend.reason,reason));
    assert(strcmp(result.render.effectiveImageBackend,selected));
end
function assertContains(text,pattern),assert(~isempty(strfind(text,pattern)));end %#ok<STREMP>
function closeFigure(fig),if ishandle(fig),close(fig);end,end
function resetDirectory(path),if exist(path,'dir')==7,rmdir(path,'s');end,mkdir(path);end
function value=oneLine(value),value=regexprep(value,'[\r\n\t]+',' ');end
function value=identifierText(value),if isempty(value),value='<none>';end,end
function writeRows(path,rows)
    fid=fopen(path,'wb');assert(fid>=0);cleanup=onCleanup(@()fclose(fid));
    fprintf(fid,'case\tstatus\tdetail\tlayer\n');
    for k=1:size(rows,1),fprintf(fid,'%s\t%s\t%s\t%s\n',rows{k,:});end
    clear cleanup;
end
