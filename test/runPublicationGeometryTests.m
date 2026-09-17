function summary=runPublicationGeometryTests(out,compile)
%RUNPUBLICATIONGEOMETRYTESTS P01-P13 plus inert default-profile controls.
    root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
    if nargin<1,out=fullfile(root,'.audit','publication-geometry');end
    if nargin<2,compile=false;end
    if exist(out,'dir')~=7,mkdir(out);end
    native=~exist('OCTAVE_VERSION','builtin');records={};
    for k=1:13
        [f,ir,layer]=fixture(k,native,root);guard=onCleanup(@()close(f));
        original=m2t2.ir.toJson(ir);
        width='single-column';if any(k==[2 6 7 8 12]),width='double-column';end
        for control=[false true]
            name=sprintf('P%02d',k);profile=m2t.profile.publication();selected=width;
            if control,name=[name '-default'];profile=m2t.profile.getProfile('none');selected=[];end %#ok<AGROW>
            t=m2t.profile.apply(ir,profile,selected);assert(t.success);
            assert(strcmp(original,m2t2.ir.toJson(ir)),'Source IR changed.');
            if control,assert(isequaln(t.ir,ir));else,assertScience(ir,t.ir);end
            plan=m2t2.render.makePgfplotsPlan(t.ir,true,t.renderConfig,'hybrid',[name '-assets']);
            again=m2t.profile.apply(ir,profile,selected);
            repeated=m2t2.render.makePgfplotsPlan(again.ir,true,again.renderConfig,'hybrid',[name '-assets']);
            assert(strcmp(plan.tex,repeated.tex));
            m2t.internal.writeTextFile(fullfile(out,[name '.tex']),plan.tex);
            if compile
                if strcmp(layer,'native-reader')
                    args={'ImageBackend','hybrid','Overwrite',true};
                    if ~control,args=[args {'Profile','publication','Width',width}];end %#ok<AGROW>
                    r=m2t.export(f,fullfile(out,name),args{:});assert(r.success);
                    assert(strcmp(original,m2t2.ir.toJson(m2t2.reader.readFigure(f))),'Caller figure changed.');
                else
                    folder=fullfile(out,[name '-assets']);if exist(folder,'dir')~=7,mkdir(folder);end
                    for j=1:numel(plan.assets),m2t2.render.writePngAsset(plan.assets(j),fullfile(folder,plan.assets(j).filename));end
                    r=m2t.internal.compileLuaLatex(fullfile(out,[name '.tex']),fullfile(out,[name '.pdf']),'lualatex');assert(r.success);
                end
                checked=m2t.internal.validatePdf(fullfile(out,[name '.pdf']));assert(checked.success);
            end
            titles={};
            for j=1:numel(t.ir.axes)
                a=t.ir.axes{j};
                if ~isempty(a.title.value)
                    titles{end+1}=struct('text',a.title.value,'plotTopPt', ...
                        (a.placement.y+a.placement.height)*t.ir.size(2)*72/72.27, ...
                        'checkAbovePlot',~control&&a.dimensionality==2); %#ok<AGROW>
                end
            end
            for j=1:numel(t.ir.elements)
                e=t.ir.elements{j};if strcmp(e.kind,'m2t2.sharedlabel')&&strcmp(e.role,'title')
                    titles{end+1}=struct('text',e.text.value,'plotTopPt',0,'checkAbovePlot',false); %#ok<AGROW>
                end
            end
            border=t.renderConfig.standaloneBorderPt;
            records{end+1}=struct('case',name,'evidence',layer,'pdf',[name '.pdf'], ...
                'widthMm',(t.ir.size(1)+2*border)*25.4/72.27, ...
                'heightMm',(t.ir.size(2)+2*border)*25.4/72.27,'titles',{titles}, ...
                'ir',t.ir,'control',control); %#ok<AGROW>
        end
        clear guard;
    end
    focusedConstraints();
    m2t.internal.writeTextFile(fullfile(out,'geometry-manifest.json'),jsonencode(records));
    summary=struct('cases',13,'controls',13,'failures',0);
    fprintf('PUBLICATION_GEOMETRY_PASS: 13 cases + 13 default controls compile=%d nativeMatlab=%d\n',compile,native);
end

function [f,ir,layer]=fixture(k,native,root)
    f=figure('Visible','off','Color','w','Position',[100 100 560 420]);
    a=axes('Parent',f,'Color','w','XColor','k','YColor','k','Position',[.13 .11 .775 .815]);
    layer='native-reader';
    if ~native&&any(k==[7 8 9])
        layer='portable-only';file='tiled-layout';if k==9,file='dual-y';end
        ir=m2t2.ir.fromJson(fileread(fullfile(root,'test','fixtures','ir','compatibility',[file '.json'])));
        if isempty(ir.size),ir.size=[420 315];end
        if k==9,ir.axes{1}.placement=m2t2.ir.makePlacement(.13,.15,.72,.7);end
        for j=1:numel(ir.axes),ir.axes{j}.title=m2t2.ir.makeText(sprintf('Panel%c',64+j),'plain');end
        if k==8
            e=m2t2.ir.makeSharedLabel('title',m2t2.ir.makeText('Shared','plain'));
            e.owner=m2t2.ir.makeOwner('layout','layout');e.placement=m2t2.ir.makePlacement(.45,.94,.1,.02);ir.elements{end+1}=e;
        end
        return;
    end
    switch k
        case {7 8}
            delete(a);grid=tiledlayout(f,1,2);
            for j=1:2,a=nexttile(grid);line('Parent',a,'XData',[0 1 2],'YData',[1 0 1],'Color','k');title(a,sprintf('Panel%c',64+j),'Interpreter','none');set(a,'Color','w','XColor','k','YColor','k');end
            if k==8,title(grid,'Shared','Interpreter','none');end
        case 9
            yyaxis(a,'left');plot(a,[0 1 2],[1 0 1]);ylabel(a,'Left');
            yyaxis(a,'right');plot(a,[0 1 2],[10 20 10]);ylabel(a,'Right');title(a,'Acceptance','Interpreter','none');
        case 6
            delete(a);
            for j=1:2,a=axes('Parent',f,'Position',[.11+.49*(j-1) .16 .34 .7]);line('Parent',a,'XData',[0 1 2],'YData',[1 0 1],'Color','k');title(a,sprintf('Panel%c',64+j),'Interpreter','none');set(a,'Color','w','XColor','k','YColor','k');end
        case 10
            scatter(a,1:4,[2 1 4 3],[16 25 36 49],[1 0 0;0 1 0;0 0 1;1 0 1],'filled');title(a,'Acceptance','Interpreter','none');
        case 11
            rgb=uint8(cat(3,[255 0;0 255],[0 255;255 0],zeros(2)));
            image('Parent',a,'CData',rgb,'AlphaData',[1 .5;.25 0],'AlphaDataMapping','none');title(a,'Acceptance','Interpreter','none');
        case 12
            scatter3(a,[-.8 0 .8],[.4 -.4 .6],[-.5 .5 0],144,[.2 .4 .8],'filled');view(a,30,25);
            xlabel(a,'X');ylabel(a,'Y');zlabel(a,'Z');title(a,'Acceptance','Interpreter','none');
        case 5
            imagesc(a,[0 1;2 3]);cb=colorbar(a);ylabel(cb,'Intensity');title(a,'Acceptance','Interpreter','none');
        otherwise
            h=line('Parent',a,'XData',[0 1 2],'YData',[1 0 1],'Color','k');
            if k~=13,title(a,'Acceptance','Interpreter','none');end
            if k==3,xlabel(a,'Time');ylabel(a,'Response');end
            if k==4,legend(a,h,'Series','Location','northeast');end
    end
    set(a,'Color','w','XColor','k','YColor','k');drawnow;ir=m2t2.reader.readFigure(f);
end

function assertScience(before,after)
    after.size=before.size;
    for k=1:numel(before.axes),after.axes{k}.placement=before.axes{k}.placement;end
    for k=1:numel(before.elements),after.elements{k}.placement=before.elements{k}.placement;end
    assert(isequaln(before,after),'Non-geometric scientific content changed.');
end

function focusedConstraints()
    a=m2t2.ir.makeAxes();a.title=m2t2.ir.makeText('Acceptance','plain');
    s=m2t2.ir.makeLineSeries();s.x=[0 1];s.y=[0 1];a.series={s};
    ir=m2t2.ir.makeFigure({a});ir.size=[420 315];
    t=m2t.profile.apply(ir,m2t.profile.publication(),'single-column');p=t.ir.axes{1}.placement;
    assert((1-p.y-p.height)*t.ir.size(2)>=26-1e-9);
    assert(p.width*t.ir.size(1)>=16&&p.height*t.ir.size(2)>=16);
    profile=m2t.profile.publication();assert(profile.text.titlePt==10);
    % Untitled, sufficiently padded geometry must remain byte-identical.
    ir.axes{1}.title=m2t2.ir.makeText();ir.axes{1}.placement=m2t2.ir.makePlacement(.2,.2,.6,.6);
    t=m2t.profile.apply(ir,m2t.profile.publication(),'single-column');assert(isequal(t.ir.axes{1}.placement,ir.axes{1}.placement));
    % Impossible fixed-size plotting area fails explicitly, not with success.
    ir.axes{1}.placement=m2t2.ir.makePlacement(.4,.4,.001,.001);
    caught=false;try,m2t.profile.apply(ir,m2t.profile.publication(),'single-column');catch err,caught=strcmp(err.identifier,'M2T:PROFILE_GEOMETRY_INVALID');end
    assert(caught);
end
