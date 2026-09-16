function summary=runM67UnsupportedTexTests(outputDirectory)
%RUNM67UNSUPPORTEDTEXTESTS Real successful workflows around hardened boundaries.
    root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
    if nargin<1,outputDirectory=fullfile(root,'.audit','m67-tex');end
    if exist(outputDirectory,'dir')~=7,mkdir(outputDirectory);end
    names={'hidden-handle','tagged-text','legend-order','colorbar-reverse','single-row-hybrid','ordered-3d','grouped-bars','opaque-overlay','transparent-overlay'};
    for k=1:numel(names)
        f=figure('Visible','off','Color','w');guard=onCleanup(@()close(f));a=axes('Parent',f);
        h=plot(a,1:3,[2 1 3],'r-','LineWidth',2);backend='vector';
        switch k
            case 1,set(h,'HandleVisibility','off');
            case 2,text(2,2,'Retained text','Parent',a,'Tag','colorbar','Color',[0 0 0]);
            case 3
                hold(a,'on');q=plot(a,1:3,[3 2 1],'b--','LineWidth',2);
                legend(a,[q h],{'Second blue','First red'},'Location','northeast');
            case 4
                cla(a);imagesc(a,[0 .25 .5; .75 1 .5]);colormap(a,[0 0 1;1 0 0]);caxis(a,[0 1]);cb=colorbar(a);
                if exist('OCTAVE_VERSION','builtin'),set(cb,'YDir','reverse','YTick',[0 .5 1],'YTickLabel',{'low','mid','high'});
                else,set(cb,'Direction','reverse','Ticks',[0 .5 1],'TickLabels',{'low','mid','high'});end
            case 5,cla(a);imagesc(a,[0 .5 1]);colormap(a,[0 0 1;1 0 0]);caxis(a,[0 1]);backend='hybrid';
            case 6
                cla(a);[x,y]=meshgrid(linspace(-1,1,9));surf(a,x,y,.3*x.*y,'FaceColor','interp','EdgeColor','none');
                hold(a,'on');plot3(a,[-1 1],[0 0],[.6 .6],'k-','LineWidth',2);view(a,30,25);set(a,'SortMethod','childorder');
            case 7
                cla(a);b=bar(a,[2 4 7],[1 3;2 4;3 5],.65,'grouped');set(b(1),'FaceColor',[0 0 1]);set(b(2),'FaceColor',[1 0 0]);legend(a,b,{'First blue','Second red'});
            case {8,9}
                b=axes('Parent',f,'Position',get(a,'Position'));plot(b,1:3,[3 2 1],'b-','LineWidth',2);
                background='white';if k==9,background='none';end
                set(b,'Color',background,'XColor','k','YColor','k');
        end
        set(a,'Color','w','XColor','k','YColor','k','ZColor','k');drawnow;
        before=m2t2.reader.readFigure(f);base=fullfile(outputDirectory,names{k});
        r=m2t.export(f,base,'ImageBackend',backend,'Overwrite',true);
        if ~r.success,disp(r.diagnostics);end;assert(r.success&&exist(r.pdfPath,'file')==2);
        assert(strcmp(jsonencode(before),jsonencode(m2t2.reader.readFigure(f))));
        if ~exist('OCTAVE_VERSION','builtin'),exportgraphics(f,[base '-source.png'],'Resolution',120);end
        clear guard;
    end
    summary=struct('tests',numel(names),'failures',0);fprintf('M67_REAL_WORKFLOW_PASS: %d/%d\n',numel(names),numel(names));
end
