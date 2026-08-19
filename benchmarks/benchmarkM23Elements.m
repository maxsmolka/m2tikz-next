function rows = benchmarkM23Elements(outputDirectory, pointsPerAxes)
%BENCHMARKM23ELEMENTS Measure figure-element overhead at moderate data size.
    root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
    if nargin<1,outputDirectory=fullfile(root,'benchmarks','output','m2.3-elements');end
    if nargin<2,pointsPerAxes=1000;end
    if exist(outputDirectory,'dir')~=7,mkdir(outputDirectory);end
    texDir=fullfile(outputDirectory,'tex');if exist(texDir,'dir')~=7,mkdir(texDir);end
    cases={{'single_axes',1,0},{'single_colorbar',1,1},{'two_colorbars',2,2},{'four_colorbars',4,4}};
    rows=cell(numel(cases),9);
    for k=1:numel(cases)
        spec=cases{k};fig=makeFigure(spec{2},spec{3},pointsPerAxes);
        timer=tic;ir=m2t2.reader.readFigure(fig);reader=toc(timer);
        timer=tic;text=m2t2.render.renderPgfplots(ir,true);renderer=toc(timer);
        path=fullfile(texDir,[spec{1} '.tex']);fid=fopen(path,'w');cleanup=onCleanup(@()fclose(fid));fwrite(fid,text,'char');clear cleanup;close(fig);
        rows(k,:)={spec{1},spec{2},spec{3},spec{2}*pointsPerAxes,reader,renderer,reader+renderer,numel(text),path};
    end
    fid=fopen(fullfile(outputDirectory,'element-performance-raw.tsv'),'w');cleanup=onCleanup(@()fclose(fid));
    fprintf(fid,'case\taxes\tcolorbars\ttotal_points\treader_s\trenderer_s\ttotal_s\ttex_bytes\ttex_path\n');
    for k=1:size(rows,1),fprintf(fid,'%s\t%d\t%d\t%d\t%.9f\t%.9f\t%.9f\t%d\t%s\n',rows{k,:});end
end
function fig=makeFigure(axesCount,colorbarCount,points)
    fig=figure('Visible','off','PaperUnits','points','PaperPosition',[0 0 432 324]);x=linspace(0,2*pi,points);
    for k=1:axesCount
        if axesCount==1,ax=axes('Parent',fig);else,ax=subplot(ceil(axesCount/2),2,k,'Parent',fig);end
        plot(ax,x,sin(x+k/10));caxis(ax,[0 1]);if k<=colorbarCount,colorbar(ax);end
    end
end
