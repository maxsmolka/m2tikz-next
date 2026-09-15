function rows=benchmarkModernLargeData(outputDirectory,source,scale,compileTex)
%BENCHMARKMODERNLARGEDATA Stage measurements, never a wall-clock CI gate.
% SOURCE='native' measures the installed runtime reader; 'ir' has no handles.
% SCALE='full' uses 100k samples, 512/1024 images and a 129-square surface.
% SCALE='smoke' exercises the same assertions with small portable fixtures.
% Compilation is optional; full-size vector images are deliberately excluded.
    root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
    if nargin<1,outputDirectory=fullfile(root,'.audit','modern-large-data');end
    if nargin<2,source='ir';end
    if nargin<3,scale='full';end
    if nargin<4,compileTex=false;end
    assert(any(strcmp(source,{'native','ir'}))&&any(strcmp(scale,{'full','smoke'})));
    if strcmp(scale,'full'),points=100000;small=512;large=1024;surfaceSize=129;
    else,points=101;small=8;large=16;surfaceSize=9;end
    specs={'line',points,'vector';'scatter',points,'vector';'scatter-mapped',points,'vector'; ...
        'scalar',small,'vector';'scalar',large,'vector';'scalar',small,'hybrid'; ...
        'scalar',large,'hybrid';'rgb',small,'hybrid';'rgb',large,'hybrid'; ...
        'surface',surfaceSize,'vector'};
    paths=m2t.internal.normalizeOutputBase(fullfile(outputDirectory,'measurements'));outputDirectory=paths.directory;
    if exist(outputDirectory,'dir')~=7,mkdir(outputDirectory);end
    if exist('OCTAVE_VERSION','builtin'),runtime=['Octave ' OCTAVE_VERSION];else,runtime=['MATLAB ' version];end
    rows=repmat(struct('caseName','','source',source,'runtime',runtime,'count',0, ...
        'fixtureSeconds',0,'readerSeconds',NaN,'validationSeconds',0,'plannerSeconds',0, ...
        'planRenderSeconds',0,'planRenderCpuSeconds',0,'writeSeconds',0,'texBytes',0,'assetBytes',0, ...
        'irVariableBytes',0,'compileSeconds',NaN,'compileStatus','NOT_REQUESTED'),1,size(specs,1));
    for caseIndex=1:size(specs,1)
        family=specs{caseIndex,1};n=specs{caseIndex,2};backend=specs{caseIndex,3};
        name=sprintf('%s-%d-%s',family,n,backend);row=rows(caseIndex);row.caseName=name;
        started=tic;expected=fixture(family,n);fig=[];
        if strcmp(source,'native'),fig=nativeFigure(expected,family);end
        cleanup=onCleanup(@()closeOwned(fig));row.fixtureSeconds=toc(started);
        if strcmp(source,'native'),started=tic;ir=m2t2.reader.readFigure(fig);row.readerSeconds=toc(started);
        else,ir=expected;end
        assertData(expected.axes{1}.series{1},ir.axes{1}.series{1});
        item=ir.axes{1}.series{1};if isfield(item,'cdata'),row.count=size(item.cdata,1)*size(item.cdata,2);else,row.count=numel(item.x);end
        info=whos('ir');row.irVariableBytes=info.bytes; % Variable footprint, NOT peak process memory.
        started=tic;m2t2.ir.validate(ir);row.validationSeconds=toc(started);
        started=tic;decision=m2t.planning.selectImageBackend(ir,backend);row.plannerSeconds=toc(started);
        assert(strcmp(decision.selected,backend));assetName=[name '-assets'];
        cpuStarted=cputime;started=tic;plan=m2t2.render.makePgfplotsPlan(ir,true,m2t2.render.defaultConfig(),backend,assetName);row.planRenderSeconds=toc(started);row.planRenderCpuSeconds=cputime-cpuStarted;
        assertData(expected.axes{1}.series{1},ir.axes{1}.series{1});
        if ~isempty(plan.assets)
            assert(numel(plan.assets)==1&&plan.assets(1).width==n&&plan.assets(1).height==n);
        elseif any(strcmp(family,{'line','scatter'}))
            assert(numel(strfind(plan.tex,sprintf('\n  (')))==n,'Coordinate count was reduced.');
        elseif any(strcmp(family,{'scatter-mapped','scalar','surface'}))
            assert(numel(regexp(plan.tex,'(?m)^[-0-9][^\n]*$','match'))==row.count,'Table rows were reduced.');
        end
        started=tic;base=fullfile(outputDirectory,name);m2t.internal.writeTextFile([base '.tex'],plan.tex);
        row.texBytes=fileBytes([base '.tex']);
        if ~isempty(plan.assets)
            folder=fullfile(outputDirectory,assetName);if exist(folder,'dir')~=7,mkdir(folder);end
            for assetIndex=1:numel(plan.assets)
                target=fullfile(folder,plan.assets(assetIndex).filename);
                m2t2.render.writePngAsset(plan.assets(assetIndex),target);row.assetBytes=row.assetBytes+fileBytes(target);
                [encoded,map]=imread(target);
                if ~isempty(map)
                    indices=double(encoded);if isinteger(encoded)||islogical(encoded),indices=indices+1;end
                    rgb=zeros([size(encoded) 3],'uint8');
                    for channel=1:3,values=map(:,channel);rgb(:,:,channel)=uint8(round(reshape(values(indices(:)),size(encoded))*255));end
                    encoded=rgb;
                else
                    if islogical(encoded),encoded=uint8(encoded)*255;end
                    if ismatrix(encoded),encoded=repmat(encoded,[1 1 3]);end
                end
                assert(isequal(encoded,plan.assets(assetIndex).rgb),'Encoded PNG pixels changed.');
            end
        end
        row.writeSeconds=toc(started);
        if compileTex
            if strcmp(family,'scalar')&&strcmp(backend,'vector')&&n>128
                row.compileStatus='SKIPPED_LARGE_VECTOR_IMAGE';
            else
                started=tic;result=m2t.internal.compileLuaLatex([base '.tex'],[base '.pdf']);row.compileSeconds=toc(started);
                if result.success,row.compileStatus='PASS';else,row.compileStatus='FAIL';end
            end
        end
        rows(caseIndex)=row;writeRows(rows(1:caseIndex),fullfile(outputDirectory,'measurements.tsv'));
        fprintf('M66_MEASURED %s: read=%.3f plan=%.3f render=%.3f tex=%d assets=%d compile=%s\n', ...
            name,row.readerSeconds,row.plannerSeconds,row.planRenderSeconds,row.texBytes,row.assetBytes,row.compileStatus);
        clear cleanup;
    end
end
function ir=fixture(family,n)
    a=m2t2.ir.makeAxes();a.id='axes-1';a.xlim=[0 100];a.ylim=[-1.1 1.1];
    switch family
        case 'line',s=m2t2.ir.makeLineSeries();s.x=linspace(0,100,n);s.y=sin(s.x);
        case {'scatter','scatter-mapped'}
            s=m2t2.ir.makeScatterSeries();s.x=linspace(0,100,n);s.y=sin(s.x);s.markerSize=2;
            if strcmp(family,'scatter-mapped'),s.colorMode='scalar_mapped';s.colorData=mod(0:n-1,257)/256;s.edgeMode='data';end
        case {'scalar','rgb'}
            s=m2t2.ir.makeImageSeries();s.x=1:n;s.y=1:n;[x,y]=meshgrid(0:n-1);s.cdata=mod(x+3*y,256)/255;
            if strcmp(family,'rgb'),s.colorMode='rgb';s.mapping='none';s.cdata=cat(3,s.cdata,mod(2*x+y,256)/255,mod(3*x+2*y,256)/255);end
            a.xlim=[.5 n+.5];a.ylim=[.5 n+.5];a.ydirection='reverse';
        case 'surface'
            s=m2t2.ir.makeSurfaceSeries();[s.x,s.y]=meshgrid(linspace(-2,2,n));s.z=sin(s.x).*cos(s.y);s.c=s.z;
            a.kind='m2t2.axes3d';a.dimensionality=3;a.xlim=[-2 2];a.ylim=[-2 2];a.zlim=[-1 1];a.view=[30 25];a.colorMapping.limits=[-1 1];
    end
    s.id='data';a.series={s};ir=m2t2.ir.makeFigure({a});ir.size=[400 300];
end
function f=nativeFigure(ir,family)
    a=ir.axes{1};s=a.series{1};f=figure('Visible','off','Position',[100 100 640 480]);ax=axes(f);
    switch family
        case 'line',plot(ax,s.x,s.y);
        case 'scatter',scatter(ax,s.x,s.y,4,[0 0 1]);
        case 'scatter-mapped',scatter(ax,s.x,s.y,4,s.colorData);
        case 'scalar',imagesc(ax,s.x,s.y,s.cdata);
        case 'rgb',image(ax,'XData',[s.x(1) s.x(end)],'YData',[s.y(1) s.y(end)],'CData',s.cdata);
        case 'surface',surf(ax,s.x,s.y,s.z,s.c,'EdgeColor','none','FaceColor','interp');view(ax,30,25);
    end
    set(ax,'XLim',a.xlim,'YLim',a.ylim,'CLim',a.colorMapping.limits);colormap(ax,a.colorMapping.colormap);drawnow;
end
function assertData(expected,actual)
    assert(strcmp(expected.kind,actual.kind));
    names={'x','y','z','c','cdata','colorData','markerSize'};
    for k=1:numel(names)
        field=names{k};if isfield(expected,field),assert(isequaln(expected.(field),actual.(field)),['Data changed: ' field]);end
    end
end
function closeOwned(f),if ~isempty(f)&&ishandle(f),close(f);end,end
function bytes=fileBytes(path),entry=dir(path);bytes=entry.bytes;end
function writeRows(rows,path)
    names=fieldnames(rows);lines={m2t2.util.joinCell(names',sprintf('\t'))};
    for r=1:numel(rows)
        values=cell(1,numel(names));for c=1:numel(names),v=rows(r).(names{c});if isnumeric(v),v=sprintf('%.9g',v);end;values{c}=v;end
        lines{end+1}=m2t2.util.joinCell(values,sprintf('\t')); %#ok<AGROW>
    end
    m2t.internal.writeTextFile(path,[m2t2.util.joinCell(lines,sprintf('\n')) sprintf('\n')]);
end
