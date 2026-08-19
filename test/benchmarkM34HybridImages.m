function rows = benchmarkM34HybridImages(outputDirectory)
%BENCHMARKM34HYBRIDIMAGES Compare public vector and hybrid image exports.
    repositoryRoot=fileparts(fileparts(mfilename('fullpath')));
    if nargin<1,outputDirectory=fullfile(repositoryRoot,'.audit','m34-benchmark');end
    addpath(fullfile(repositoryRoot,'src'));
    if exist(outputDirectory,'dir')==7,rmdir(outputDirectory,'s');end,mkdir(outputDirectory);
    sizes=[25 100 250];rows=cell(0,10);
    for n=sizes
        rows(end+1,:)=measure(n,'vector',outputDirectory); %#ok<AGROW>
        rows(end+1,:)=measure(n,'hybrid',outputDirectory); %#ok<AGROW>
    end
    rows(end+1,:)=measure(500,'hybrid',outputDirectory);
    path=fullfile(outputDirectory,'benchmark.tsv');fid=fopen(path,'wb');assert(fid>=0);
    cleanup=onCleanup(@()fclose(fid));
    fprintf(fid,['size\tbackend\ttex_bytes\tasset_bytes\ttotal_bytes\t' ...
        'analysis_seconds\trender_seconds\tcompile_seconds\tvalidation_seconds\ttotal_seconds\n']);
    for k=1:size(rows,1),fprintf(fid,'%d\t%s\t%d\t%d\t%d\t%.9g\t%.9g\t%.9g\t%.9g\t%.9g\n',rows{k,:});end
    clear cleanup;disp(fileread(path));
end

function row=measure(n,backend,root)
    fig=figure('Visible','off');cleanup=onCleanup(@()closeFigure(fig));
    ax=axes('Parent',fig);imagesc(ax,peaks(n));set(ax,'YDir','normal');
    colormap(ax,[0 .15 .5;.2 .65 .7;1 1 .8;.65 0 0]);
    base=fullfile(root,sprintf('%s-%d',backend,n));
    result=m2t.export(fig,base,'ImageBackend',backend);
    if ~result.success,error('M2T:M34BenchmarkFailed','%s %d failed: %s',backend,n,result.diagnostics(1).message);end
    texBytes=fileBytes(result.texPath);assetBytes=0;
    for k=1:numel(result.render.assets),assetBytes=assetBytes+fileBytes(result.render.assets{k});end
    row={n,backend,texBytes,assetBytes,texBytes+assetBytes,result.timings.analysis, ...
         result.timings.export,result.timings.compile,result.timings.validation,result.timings.total};
    clear cleanup;
end
function count=fileBytes(path),fid=fopen(path,'rb');assert(fid>=0);c=onCleanup(@()fclose(fid));count=numel(fread(fid,Inf,'*uint8'));clear c;end
function closeFigure(fig),if ishandle(fig),close(fig);end,end
