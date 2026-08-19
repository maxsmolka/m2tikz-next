function rows = benchmarkM21RendererProfile(outputDirectory)
%BENCHMARKM21RENDERERPROFILE Isolate safe line-renderer cost categories.
    root=fileparts(fileparts(mfilename('fullpath'))); addpath(fullfile(root,'src'));
    if nargin<1, outputDirectory=fullfile(root,'benchmarks','output','m2.1-renderer'); end
    if exist(outputDirectory,'dir')~=7, mkdir(outputDirectory); end
    counts=[100 10000 100000]; rows=cell(numel(counts),7);
    for k=1:numel(counts)
        count=counts(k); x=linspace(0,20,count); y=sin(x)+0.05*cos(11*x);
        line=m2t2.ir.makeLineSeries(); line.id='axes-1-series-1'; line.x=x; line.y=y;
        ax=m2t2.ir.makeAxes(); ax.xlim=[0 20]; ax.ylim=[-1.1 1.1]; ax.series={line};
        ir=m2t2.ir.makeFigure({ax});
        timer=tic; coordinateBlock=m2t2.render.formatCoordinates(x,y); coordinateSeconds=toc(timer);
        timer=tic; style=m2t2.render.seriesOptions(line,'profilecolor'); styleSeconds=toc(timer);
        timer=tic; m2t2.util.joinCell({style{:},coordinateBlock},sprintf('\n')); joinSeconds=toc(timer);
        timer=tic; tex=m2t2.render.renderPgfplots(ir,true); rendererSeconds=toc(timer);
        path=fullfile(outputDirectory,sprintf('line-%d.tex',count));
        timer=tic; fid=fopen(path,'w'); fwrite(fid,tex,'char'); fclose(fid); writeSeconds=toc(timer);
        rows(k,:)={count,coordinateSeconds,styleSeconds,joinSeconds,rendererSeconds,writeSeconds,numel(tex)};
    end
    fid=fopen(fullfile(outputDirectory,'renderer-profile.tsv'),'w');cleanup=onCleanup(@() fclose(fid));
    fprintf(fid,'points\tcoordinate_serialization_s\tstyle_s\tjoin_s\trenderer_s\tfile_write_s\ttex_bytes\n');
    for k=1:size(rows,1),fprintf(fid,'%d\t%.9f\t%.9f\t%.9f\t%.9f\t%.9f\t%d\n',rows{k,:});end
    clear cleanup;
end
