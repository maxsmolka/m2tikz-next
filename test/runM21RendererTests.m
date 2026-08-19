function summary = runM21RendererTests(outputDirectory)
%RUNM21RENDERERTESTS Test v2 rendering using only hand-built IR.
    root=fileparts(fileparts(mfilename('fullpath'))); addpath(fullfile(root,'src'));
    if nargin<1, outputDirectory=fullfile(root,'.audit','m2.1'); end
    cases={@manualTicks,@reverseAxes,@textSemantics,@legendSemantics,@scatterSeries, ...
           @errorbarSeries,@mixedSeries,@jsonRoundtrip};
    names={'manual_ticks','reverse_axes_box','text_semantics','legend_order', ...
           'scatter','errorbar','mixed_series','v2_json_roundtrip'};
    rows=cell(numel(cases),4); failures=0;
    for k=1:numel(cases)
        try
            cases{k}(outputDirectory); status='PASS'; detail='';
        catch err
            failures=failures+1; status='FAIL'; detail=oneLine(err.message);
        end
        rows(k,:)={names{k},status,detail,'renderer'};
    end
    ensureDirectory(outputDirectory); writeRows(fullfile(outputDirectory,'m21-renderer-results.tsv'),rows);
    summary=struct('failures',failures,'tests',numel(cases));
    if failures, error('M2T2:M21RendererTestsFailed','%d M2.1 renderer tests failed.',failures); end
end

function manualTicks(~)
    [ir,ax]=baseIR();
    ax.xticks=m2t2.ir.makeTickSpec('manual',[0 1], ...
        {m2t2.ir.makeText('zero','plain'),m2t2.ir.makeText('x_1','plain')});
    ax.yticks=m2t2.ir.makeTickSpec('manual',[0 1], ...
        {m2t2.ir.makeText('y_{0}','tex'),m2t2.ir.makeText('$y^1$','latex')});
    ir.axes={ax}; tex=m2t2.render.renderPgfplots(ir,true);
    assertContains(tex,'xtick={0,1}');
    assertContains(tex,['xticklabels={{zero},{x' char(92) '_1}}']);
    assertContains(tex,'yticklabels={{$y_{0}$},{$y^1$}}');
end

function reverseAxes(~)
    [ir,ax]=baseIR(); ax.xdirection='reverse'; ax.ydirection='reverse'; ax.box='off'; ir.axes={ax};
    tex=m2t2.render.renderPgfplots(ir,true);
    assertContains(tex,'x dir=reverse'); assertContains(tex,'y dir=reverse');
    assertContains(tex,'axis lines=left');
end

function textSemantics(~)
    [ir,ax]=baseIR();
    ax.xlabel=m2t2.ir.makeText('plain_a','plain');
    ax.ylabel=m2t2.ir.makeText('x_{1}','tex');
    ax.title=m2t2.ir.makeText('$x^2$','latex'); ir.axes={ax};
    tex=m2t2.render.renderPgfplots(ir,true);
    assertContains(tex,['xlabel={plain' char(92) '_a}']); assertContains(tex,'ylabel={$x_{1}$}');
    assertContains(tex,'title={$x^2$}');
end

function legendSemantics(~)
    [ir,ax]=baseIR(); second=ax.series{1}; second.id='axes-1-series-2';
    second.displayName=m2t2.ir.makeText('Second','plain'); second.color=[1 0 0];
    ax.series{1}.displayName=m2t2.ir.makeText('First','plain'); ax.series{2}=second;
    ax.legend.visible=true; ax.legend.mode='manual'; ax.legend.location='south_west';
    ax.legend.entries={m2t2.ir.makeLegendEntry(second.id,m2t2.ir.makeText('Two','plain')), ...
                       m2t2.ir.makeLegendEntry(ax.series{1}.id,m2t2.ir.makeText('One','plain'))};
    ir.axes={ax}; tex=m2t2.render.renderPgfplots(ir,true);
    assertContains(tex,'legend pos=south west');
    two=strfind(tex,'addlegendentry{Two}'); one=strfind(tex,'addlegendentry{One}');
    assert(~isempty(two) && ~isempty(one) && two(1)<one(1));
end

function scatterSeries(~)
    scatter=m2t2.ir.makeScatterSeries(); scatter.id='axes-1-series-1';
    scatter.x=[1 2 3]; scatter.y=[3 1 2]; scatter.color=[0.8 0.1 0.2]; scatter.markerSize=8;
    ax=m2t2.ir.makeAxes(); ax.xlim=[1 3]; ax.ylim=[1 3]; ax.series={scatter};
    ir=m2t2.ir.makeFigure({ax}); tex=m2t2.render.renderPgfplots(ir,true);
    assertContains(tex,'only marks'); assertContains(tex,'mark size=4pt'); assertContains(tex,'(2,1)');
end

function errorbarSeries(~)
    item=m2t2.ir.makeErrorbarSeries(); item.id='axes-1-series-1';
    item.x=[1 2]; item.y=[2 3]; item.yNegative=[0.1 0.2]; item.yPositive=[0.3 0.4];
    item.xNegative=[0 0]; item.xPositive=[0 0];
    ax=m2t2.ir.makeAxes(); ax.xlim=[1 2]; ax.ylim=[1 4]; ax.series={item};
    ir=m2t2.ir.makeFigure({ax}); tex=m2t2.render.renderPgfplots(ir,true);
    assertContains(tex,'y error minus=yneg'); assertContains(tex,'y error plus=ypos');
    assertContains(tex,['x y yneg ypos ' char(92) char(92)]);
    assertContains(tex,'1 2 0.1 0.3');
end

function mixedSeries(~)
    line=m2t2.ir.makeLineSeries(); line.id='axes-1-series-1'; line.x=[1 2]; line.y=[1 2];
    scatter=m2t2.ir.makeScatterSeries(); scatter.id='axes-1-series-2'; scatter.x=[1 2]; scatter.y=[2 1];
    errorbar=m2t2.ir.makeErrorbarSeries(); errorbar.id='axes-1-series-3';
    errorbar.x=[1 2]; errorbar.y=[1.5 1.5]; errorbar.xNegative=[0 0]; errorbar.xPositive=[0 0];
    errorbar.yNegative=[0.1 0.1]; errorbar.yPositive=[0.1 0.1];
    ax=m2t2.ir.makeAxes(); ax.xlim=[1 2]; ax.ylim=[0 3]; ax.series={line,scatter,errorbar};
    ir=m2t2.ir.makeFigure({ax}); tex=m2t2.render.renderPgfplots(ir,true);
    assert(numel(regexp(tex,[char(92) char(92) 'addplot'],'match'))==3);
    assertContains(tex,'coordinates {'); assertContains(tex,'table[');
end

function jsonRoundtrip(outputDirectory)
    line=m2t2.ir.makeLineSeries(); line.id='axes-1-series-1'; line.x=[1 2]; line.y=[1 2];
    scatter=m2t2.ir.makeScatterSeries(); scatter.id='axes-1-series-2'; scatter.x=[1 2]; scatter.y=[2 1];
    errorbar=m2t2.ir.makeErrorbarSeries(); errorbar.id='axes-1-series-3';
    errorbar.x=[1 2]; errorbar.y=[1.5 1.5]; errorbar.xNegative=[0 0]; errorbar.xPositive=[0 0];
    errorbar.yNegative=[0.1 0.1]; errorbar.yPositive=[0.2 0.2];
    ax=m2t2.ir.makeAxes(); ax.xlim=[1 2]; ax.ylim=[0 3]; ax.series={line,scatter,errorbar};
    ir=m2t2.ir.makeFigure({ax}); first=m2t2.render.renderPgfplots(ir,true);
    ensureDirectory(fullfile(outputDirectory,'ir')); path=fullfile(outputDirectory,'ir','mixed-v2.json');
    fid=fopen(path,'w'); cleanup=onCleanup(@() fclose(fid)); fwrite(fid,jsonencode(ir),'char'); clear cleanup;
    decoded=m2t2.ir.fromJson(fileread(path)); second=m2t2.render.renderPgfplots(decoded,true);
    assert(strcmp(first,second));
end

function [ir,ax]=baseIR()
    line=m2t2.ir.makeLineSeries(); line.id='axes-1-series-1'; line.x=[0 1]; line.y=[0 1];
    ax=m2t2.ir.makeAxes(); ax.xlim=[0 1]; ax.ylim=[0 1]; ax.series={line};
    ir=m2t2.ir.makeFigure({ax});
end

function assertContains(text,value), assert(~isempty(strfind(text,value))); end %#ok<STREMP>
function ensureDirectory(path), if exist(path,'dir')~=7, mkdir(path); end, end
function writeRows(path,rows)
    fid=fopen(path,'w'); cleanup=onCleanup(@() fclose(fid)); fprintf(fid,'case\tstatus\tdetail\tlayer\n');
    for k=1:size(rows,1), fprintf(fid,'%s\t%s\t%s\t%s\n',rows{k,:}); end; clear cleanup;
end
function value=oneLine(value), value=strrep(strrep(value,sprintf('\r'),' '),sprintf('\n'),' '); end
