function summary = runM23RendererTests(outputDirectory)
%RUNM23RENDERERTESTS Exercise figure-free figure-element rendering and JSON.
    root = fileparts(fileparts(mfilename('fullpath'))); addpath(fullfile(root, 'src'));
    if nargin < 1, outputDirectory = fullfile(root, '.audit', 'm2.3'); end
    tests = {@singleColorbar,@manualColorbar,@independentColorbars,@sharedColorbar, ...
             @sharedLegend,@sharedXlabel,@sharedYlabel,@sharedTitle,@jsonCompatibility, ...
             @invalidReference,@unsupportedOwnership};
    names = {'single_colorbar','manual_colorbar','independent_colorbars','shared_colorbar', ...
             'shared_legend','shared_xlabel','shared_ylabel','shared_title','json_compatibility', ...
             'invalid_reference','unsupported_ownership'};
    rows = cell(numel(tests), 4); failures = 0; ensureDirectory(outputDirectory);
    for k = 1:numel(tests)
        try
            ir = tests{k}(); tex = '';
            if isstruct(ir), tex = m2t2.render.renderPgfplots(ir, true); writeText(fullfile(outputDirectory, [names{k} '.tex']), tex); end
            status = 'PASS'; detail = '';
        catch err
            failures = failures + 1; status = 'FAIL'; detail = oneLine(err.message);
        end
        rows(k,:) = {names{k},status,detail,'renderer'};
    end
    writeRows(fullfile(outputDirectory, 'm23-renderer-results.tsv'), rows);
    summary = struct('failures', failures, 'tests', numel(tests));
    if failures, error('M2T2:M23RendererTestsFailed', '%d M2.3 renderer tests failed.', failures); end
end

function ir = singleColorbar()
    ir = baseFigure(1); cb = colorbarFor(ir.axes{1}, [0.88 0.12 0.04 0.72]); ir.elements = {cb};
    tex = m2t2.render.renderPgfplots(ir, true); assertContains(tex, 'colorbar style={');
end
function ir = manualColorbar()
    ir = baseFigure(1); cb = colorbarFor(ir.axes{1}, [0.74 0.25 0.05 0.50]); cb.location = 'manual';
    cb.ticks = m2t2.ir.makeTickSpec('manual', [0 0.5 1], texts({'low','mid','high'}));
    cb.label = m2t2.ir.makeText('Intensity'); ir.elements = {cb};
    tex = m2t2.render.renderPgfplots(ir, true); assertContains(tex, 'at={(296pt,75pt)}'); assertContains(tex, 'ytick={0,0.5,1}');
end
function ir = independentColorbars()
    ir = baseFigure(2); ir.elements = {colorbarFor(ir.axes{1}, [0.45 0.15 0.025 0.7]), ...
                                      colorbarFor(ir.axes{2}, [0.94 0.15 0.025 0.7])};
    ir.elements{2}.id = 'colorbar-2'; ir.elements{2}.owner.id = 'axes-2';
    ir.elements{2}.associatedAxesIds = {'axes-2'};
    tex = m2t2.render.renderPgfplots(ir, true); assert(countText(tex, 'colorbar style={') == 2);
end
function ir = sharedColorbar()
    ir = baseFigure(2); cb = colorbarFor(ir.axes{1}, [0.94 0.15 0.025 0.7]);
    cb.owner = m2t2.ir.makeOwner('figure','figure'); cb.associatedAxesIds = {'axes-1','axes-2'};
    ir.elements = {cb}; m2t2.ir.validate(ir);
end
function ir = sharedLegend()
    ir = baseFigure(2); lg = m2t2.ir.makeSharedLegend();
    lg.entries = {m2t2.ir.makeSharedLegendEntry('axes-1','axes-1-series-1',m2t2.ir.makeText('First')), ...
                  m2t2.ir.makeSharedLegendEntry('axes-2','axes-2-series-1',m2t2.ir.makeText('Second'))};
    ir.elements = {lg}; tex = m2t2.render.renderPgfplots(ir,true); assert(countText(tex, 'addlegendentry') == 2);
end
function ir = sharedXlabel()
    ir = baseFigure(2); ir.elements = {m2t2.ir.makeSharedLabel('xlabel',m2t2.ir.makeText('Shared X'))};
    assertContains(m2t2.render.renderPgfplots(ir,true),'Shared X');
end
function ir = sharedYlabel()
    ir = baseFigure(2); ir.elements = {m2t2.ir.makeSharedLabel('ylabel',m2t2.ir.makeText('Shared Y'))};
    assertContains(m2t2.render.renderPgfplots(ir,true),'rotate=90');
end
function ir = sharedTitle()
    ir = baseFigure(2); ir.elements = {m2t2.ir.makeSharedLabel('title',m2t2.ir.makeText('Shared Title'))};
    assertContains(m2t2.render.renderPgfplots(ir,true),'291pt');
end
function result = jsonCompatibility()
    ir = sharedLegend(); ir.elements{2} = m2t2.ir.makeSharedLabel('title',m2t2.ir.makeText('Shared Title'));
    ir.elements{3} = colorbarFor(ir.axes{1}, [0.94 0.15 0.025 0.7]);
    loaded = m2t2.ir.fromJson(jsonencode(ir));
    assert(strcmp(m2t2.render.renderPgfplots(ir,true),m2t2.render.renderPgfplots(loaded,true)));
    old = rmfield(baseFigure(1), 'elements'); loadedOld = m2t2.ir.fromJson(jsonencode(old)); assert(isempty(loadedOld.elements));
    result = ir;
end
function result = invalidReference()
    ir = baseFigure(1); cb = colorbarFor(ir.axes{1}, [0.9 0.1 0.03 0.8]); cb.associatedAxesIds = {'missing'}; ir.elements = {cb};
    try, m2t2.ir.validate(ir); error('M2T2:ExpectedFailure','Missing reference accepted.');
    catch err, assert(strcmp(err.identifier,'M2T2:E012:InvalidFigureElementReference')); end
    result = false;
end
function result = unsupportedOwnership()
    ir=baseFigure(2);ir.axes{2}.colorMapping.colormap=[0 1 0;1 0 1];
    cb=colorbarFor(ir.axes{1},[0.94 0.15 0.025 0.7]);cb.owner=m2t2.ir.makeOwner('figure','figure');cb.associatedAxesIds={'axes-1','axes-2'};ir.elements={cb};
    try,m2t2.ir.validate(ir);error('M2T2:ExpectedFailure','Mismatched mappings accepted.');
    catch err,assert(strcmp(err.identifier,'M2T2:E011:UnsupportedColorbarOwnership'));end
    result=false;
end
function ir = baseFigure(count)
    items = cell(1,count);
    for k=1:count
        ax=m2t2.ir.makeAxes(); ax.id=sprintf('axes-%d',k);
        ax.placement=m2t2.ir.makePlacement(0.08+(k-1)*0.49,0.15,0.36,0.7);
        line=m2t2.ir.makeLineSeries(); line.id=sprintf('axes-%d-series-1',k); line.x=[0 1];line.y=[k k+1];line.displayName=m2t2.ir.makeText(sprintf('Series %d',k));ax.series={line};items{k}=ax;
    end
    ir=m2t2.ir.makeFigure(items);ir.size=[400 300];
end
function cb = colorbarFor(ax, p)
    cb=m2t2.ir.makeColorbar();cb.owner=m2t2.ir.makeOwner('axes',ax.id);cb.associatedAxesIds={ax.id};
    cb.placement=m2t2.ir.makePlacement(p(1),p(2),p(3),p(4));cb.limits=ax.colorMapping.limits;cb.scale=ax.colorMapping.scale;
end
function values=texts(raw),values=cellfun(@(v)m2t2.ir.makeText(v),raw,'UniformOutput',false);end
function assertContains(text,value),assert(~isempty(strfind(text,value)));end %#ok<STREMP>
function count=countText(text,value),count=numel(strfind(text,value));end
function ensureDirectory(path),if exist(path,'dir')~=7,mkdir(path);end,end
function writeText(path,value),fid=fopen(path,'w');cleanup=onCleanup(@()fclose(fid));fwrite(fid,value,'char');end
function writeRows(path,rows),fid=fopen(path,'w');cleanup=onCleanup(@()fclose(fid));fprintf(fid,'case\tstatus\tdetail\tlayer\n');for k=1:size(rows,1),fprintf(fid,'%s\t%s\t%s\t%s\n',rows{k,:});end,end
function value=oneLine(value),value=strrep(value,sprintf('\r'),' ');value=strrep(value,sprintf('\n'),' ');end
