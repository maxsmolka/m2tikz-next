function summary=runM63TiledMatlabTests(outputDirectory)
%RUNM63TILEDMATLABTESTS Native acceptance; never substitute Octave for MATLAB.
    assert(~exist('OCTAVE_VERSION','builtin'),'Native MATLAB is required.');
    root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
    if nargin<1,outputDirectory=fullfile(root,'.audit','m63-tiled-matlab');end
    if exist(outputDirectory,'dir')~=7,mkdir(outputDirectory);end
    cases={'normal_nexttile',@normalCase;'explicit_order',@explicitCase; ...
        'tile_span',@spanCase;'column_major',@columnCase;'shared_labels',@labelsCase; ...
        'legend_colorbar_ownership',@decorationCase;'source_lifecycle',@lifecycleCase; ...
        'profile_85',@()profileCase('single-column');'profile_170',@()profileCase('double-column'); ...
        'local_shared_85',@()profileCase('single-column',true);'local_shared_170',@()profileCase('double-column',true); ...
        'dynamic_rejected',@()negativeCase('flow');'nested_rejected',@()negativeCase('nested'); ...
        'outer_colorbar_rejected',@()negativeCase('colorbar');'outer_legend_rejected',@()negativeCase('legend'); ...
        'subtitle_rejected',@()negativeCase('subtitle')};
    spacings={'loose','compact','tight','none'}; paddings={'loose','compact','tight'};
    for s=1:numel(spacings)
        for p=1:numel(paddings)
            spacing=spacings{s};padding=paddings{p};
            cases(end+1,:)={['spacing_' spacing '_' padding],@()spacingCase(spacing,padding)}; %#ok<AGROW>
        end
    end
    rows=cell(size(cases,1),3);failures=0;
    for k=1:size(cases,1)
        try,cases{k,2}();status='PASS';detail='assertions passed';
        catch err,status='FAIL';failures=failures+1;detail=regexprep([err.identifier ': ' err.message],'[\r\n\t]+',' ');end
        rows(k,:)={cases{k,1},status,detail};
    end
    path=fullfile(outputDirectory,'tiled-matlab-results.tsv');writeRows(path,rows);
    summary=struct('tests',size(rows,1),'failures',failures,'resultPath',path);
    fprintf('%s',fileread(path));assert(failures==0,'M6.3 native acceptance failed.');
    function normalCase()
        [f,t,c]=base(2,2);for n=1:4,plot(nexttile(t),[0 1],[n n+1]);end
        ir=m2t2.reader.readFigure(f);assert(numel(ir.axes)==4&&strcmp(ir.layout.tiled.arrangement,'fixed'));
        for n=1:4,assert(ir.axes{n}.series{1}.y(1)==n);end;saveIR(ir,'normal');clear c;
    end
    function explicitCase()
        [f,t,c]=base(2,2);for n=[4 2 1],plot(nexttile(t,n),[0 1],[n n+1]);end
        ir=m2t2.reader.readFigure(f);assert(isequal(cellfun(@(a)a.series{1}.y(1),ir.axes),[1 2 4]));saveIR(ir,'explicit');clear c;
    end
    function spanCase()
        [f,t,c]=base(2,3);plot(nexttile(t,2,[2 2]),[0 1],[2 3]);plot(nexttile(t,1),[0 1],[1 2]);
        ir=m2t2.reader.readFigure(f);cellNode=ir.layout.cells{2};assert(cellNode.rowSpan==2&&cellNode.columnSpan==2);
        assert(cellNode.row==1&&cellNode.column==2);saveIR(ir,'span');clear c;
    end
    function columnCase()
        [f,t,c]=base(2,2);t.TileIndexing='columnmajor';for n=[4 3 2 1],plot(nexttile(t,n),[0 1],[n n+1]);end
        ir=m2t2.reader.readFigure(f);assert(isequal(cellfun(@(a)a.series{1}.y(1),ir.axes),[1 3 2 4]));saveIR(ir,'column');clear c;
    end
    function labelsCase()
        [f,t,c]=base(1,2);plot(nexttile(t),1:3);plot(nexttile(t),3:-1:1);
        title(t,'Shared title');xlabel(t,'Shared X');ylabel(t,'Shared Y');
        ir=m2t2.reader.readFigure(f);assert(numel(ir.elements)==3);
        for n=1:3,assert(strcmp(ir.elements{n}.owner.kind,'layout'));end
        saveIR(ir,'labels');clear c;
    end
    function decorationCase()
        [f,t,c]=base(1,2);a=nexttile(t);plot(a,1:3,'DisplayName','wave');legend(a,'show');
        b=nexttile(t);imagesc(b,[1 2;3 4]);colorbar(b);
        ir=m2t2.reader.readFigure(f);assert(ir.axes{1}.legend.visible);
        assert(numel(ir.elements)==1&&strcmp(ir.elements{1}.owner.id,ir.axes{2}.id));saveIR(ir,'decorations');clear c;
    end
    function lifecycleCase()
        [f,t,c]=base(1,2);a=nexttile(t);h=plot(a,1:3);plot(nexttile(t),3:-1:1);drawnow;
        before={t.GridSize,t.TileIndexing,t.TileSpacing,t.Padding,t.Units,a.Units,a.Position,h.XData,h.YData};
        first=m2t2.reader.readFigure(f);second=m2t2.reader.readFigure(f);
        after={t.GridSize,t.TileIndexing,t.TileSpacing,t.Padding,t.Units,a.Units,a.Position,h.XData,h.YData};
        assert(isequal(before,after)&&isequal(first,second));clear c;
    end
    function profileCase(width,localLabels)
        if nargin<2,localLabels=false;end
        [f,t,c]=base(1,2);plot(nexttile(t),1:3);plot(nexttile(t),3:-1:1);title(t,'Shared title');xlabel(t,'Shared X');ylabel(t,'Shared Y');
        if localLabels
            for n=1:2,a=nexttile(t,n);title(a,['Panel ' num2str(n)]);xlabel(a,'Local X');ylabel(a,'Local Y');end
        end
        ir=m2t2.reader.readFigure(f);selection=m2t.profile.getSelection('publication',width);
        transformed=m2t.profile.apply(ir,selection.profile,selection.width);assert(transformed.success);
        assert(transformed.ir.axes{1}.placement.x*transformed.ir.size(1)>=36-1e-10);
        assert(isequal(transformed.ir.layout,ir.layout));
        name=width;if localLabels,name=['local-shared-' width];end
        saveIR(transformed.ir,name,transformed.renderConfig);clear c;
    end
    function spacingCase(spacing,padding)
        [f,t,c]=base(2,2);t.TileSpacing=spacing;t.Padding=padding;
        for n=1:4,plot(nexttile(t),[0 1],[n n+1]);end
        drawnow;
        if strcmp(spacing,'none')
            r=m2t.export(f,fullfile(outputDirectory,['none-' padding]));
            assert(~r.success&&strcmp(r.diagnostics(1).code,'M2T2:E056:UnsupportedTiledLayout'));clear c;return;
        end
        ir=m2t2.reader.readFigure(f);
        assert(strcmp(ir.layout.tiled.spacing,spacing)&&strcmp(ir.layout.tiled.padding,padding));
        for n=1:4
            a=nexttile(t,n);p=a.Position;q=ir.axes{n}.placement;
            assert(max(abs(p-[q.x q.y q.width q.height]))<1e-10);
        end
        saveIR(ir,['spacing-' spacing '-' padding]);clear c;
    end
    function negativeCase(kind)
        [f,t,c]=base(1,2);a=nexttile(t);plot(a,1:3);code='M2T2:E056:UnsupportedTiledLayout';
        switch kind
            case 'flow',clear c;f=figure('Visible','off');c=onCleanup(@()close(f));t=tiledlayout(f,'flow');plot(nexttile(t),1:3);
            case 'nested',inner=tiledlayout(t,1,1);inner.Layout.Tile=2;plot(nexttile(inner),1:3);
            case 'colorbar',cb=colorbar(a);cb.Layout.Tile='east';code='M2T2:E058:UnsupportedTileDecoration';
            case 'legend',lg=legend(a,'wave');lg.Layout.Tile='east';code='M2T2:E058:UnsupportedTileDecoration';
            case 'subtitle',subtitle(t,'Not supported');
        end
        target=fullfile(outputDirectory,['unsupported-' kind]);r=m2t.export(f,target);
        assert(~r.success&&strcmp(r.status,'unsupported')&&strcmp(r.diagnostics(1).code,code));
        assert(exist([target '.tex'],'file')~=2&&exist([target '.pdf'],'file')~=2);clear c;
    end
    function saveIR(ir,name,config)
        if nargin<3,config=m2t2.render.defaultConfig();end
        m2t.internal.writeTextFile(fullfile(outputDirectory,[name '.json']),jsonencode(ir));
        m2t.internal.writeTextFile(fullfile(outputDirectory,[name '.tex']),m2t2.render.renderPgfplots(ir,true,config));
    end
end
function [f,t,c]=base(rows,columns)
    f=figure('Visible','off','Units','pixels','Position',[100 100 800 500],'Color','w');c=onCleanup(@()close(f));
    t=tiledlayout(f,rows,columns,'TileSpacing','compact','Padding','compact');
end
function writeRows(path,rows)
    fid=fopen(path,'wb');assert(fid>=0);c=onCleanup(@()fclose(fid));fprintf(fid,'case\tstatus\tdetail\n');
    for k=1:size(rows,1),fprintf(fid,'%s\t%s\t%s\n',rows{k,:});end;clear c;
end
