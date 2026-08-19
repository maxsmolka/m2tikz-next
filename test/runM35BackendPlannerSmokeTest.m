function results = runM35BackendPlannerSmokeTest(outputDirectory)
%RUNM35BACKENDPLANNERSMOKETEST Compile compact auto/vector and auto/hybrid cases.
    repositoryRoot=fileparts(fileparts(mfilename('fullpath')));
    if nargin<1,outputDirectory=fullfile(repositoryRoot,'.audit','m35-planner-smoke');end
    addpath(fullfile(repositoryRoot,'src'));
    if exist(outputDirectory,'dir')==7,rmdir(outputDirectory,'s');end,mkdir(outputDirectory);
    small=figure('Visible','off');smallAxes=axes('Parent',small);imagesc(smallAxes,peaks(20));
    dense=figure('Visible','off');denseAxes=axes('Parent',dense);imagesc(denseAxes,peaks(65));
    cleanup=onCleanup(@()closeFigures([small dense]));
    results.small=m2t.export(small,fullfile(outputDirectory,'small'),'ImageBackend','auto');
    results.dense=m2t.export(dense,fullfile(outputDirectory,'dense'),'ImageBackend','auto');
    if ~(results.small.success&&results.dense.success&& ...
            strcmp(results.small.render.imageBackend.selected,'vector')&& ...
            strcmp(results.small.render.imageBackend.reason,'small_scalar_image')&& ...
            isempty(results.small.render.assets)&&exist(results.small.pdfPath,'file')==2&& ...
            strcmp(results.dense.render.imageBackend.selected,'hybrid')&& ...
            strcmp(results.dense.render.imageBackend.reason,'dense_scalar_image')&& ...
            numel(results.dense.render.assets)==1&&exist(results.dense.render.assets{1},'file')==2&& ...
            exist(results.dense.pdfPath,'file')==2)
        error('M2T:M35PlannerSmokeFailed','Hosted M3.5 planner smoke failed.');
    end
    clear cleanup;
end
function closeFigures(figures),for k=1:numel(figures),if ishandle(figures(k)),close(figures(k));end,end,end
