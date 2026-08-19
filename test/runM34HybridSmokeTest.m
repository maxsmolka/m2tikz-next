function result = runM34HybridSmokeTest(outputDirectory)
%RUNM34HYBRIDSMOKETEST Compile one compact hosted-CI hybrid image fixture.
    repositoryRoot=fileparts(fileparts(mfilename('fullpath')));
    if nargin<1,outputDirectory=fullfile(repositoryRoot,'.audit','m34-hybrid-smoke');end
    addpath(fullfile(repositoryRoot,'src'));
    if exist(outputDirectory,'dir')==7,rmdir(outputDirectory,'s');end,mkdir(outputDirectory);
    fig=figure('Visible','off');cleanup=onCleanup(@()closeFigure(fig));
    ax=axes('Parent',fig);values=peaks(50);imagesc(ax,values);set(ax,'YDir','normal');
    colormap(ax,[0 .15 .5;1 1 1;.65 0 0]);colorbar(ax);
    result=m2t.export(fig,fullfile(outputDirectory,'heatmap'), ...
        'Profile','publication','ImageBackend','hybrid');
    if ~(result.success && strcmp(result.render.effectiveImageBackend,'hybrid') && ...
            numel(result.render.assets)==1 && exist(result.render.assets{1},'file')==2 && ...
            exist(result.texPath,'file')==2 && exist(result.pdfPath,'file')==2)
        error('M2T:M34HybridSmokeFailed','Hosted M3.4 hybrid smoke export failed.');
    end
    clear cleanup;
end
function closeFigure(fig),if ishandle(fig),close(fig);end,end
