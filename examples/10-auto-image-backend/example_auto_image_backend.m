function results = example_auto_image_backend(outputDirectory)
%EXAMPLE_AUTO_IMAGE_BACKEND Demonstrate deterministic density planning.
    repositoryRoot=fileparts(fileparts(fileparts(mfilename('fullpath'))));
    if nargin<1||isempty(outputDirectory),outputDirectory=fullfile(repositoryRoot,'.audit', ...
            'public-preview','examples','10-auto-image-backend');end
    addpath(fullfile(repositoryRoot,'src'));if exist(outputDirectory,'dir')~=7,mkdir(outputDirectory);end
    small=figure('Visible','off');smallAxes=axes('Parent',small);
    imagesc(smallAxes,peaks(25));title(smallAxes,'Small scalar field');
    large=figure('Visible','off');largeAxes=axes('Parent',large);
    imagesc(largeAxes,peaks(100));title(largeAxes,'Dense scalar field');
    cleanup=onCleanup(@()closeFigures([small large]));
    results.small=m2t.export(small,fullfile(outputDirectory,'small'), ...
        'ImageBackend','auto','Overwrite',true);
    results.large=m2t.export(large,fullfile(outputDirectory,'large'), ...
        'ImageBackend','auto','Overwrite',true);
    if ~(results.small.success&&results.large.success),error('M2T:ExampleFailed','Auto backend example failed.');end
    fprintf('small: requested=%s selected=%s reason=%s\n', ...
        results.small.render.imageBackend.requested,results.small.render.imageBackend.selected, ...
        results.small.render.imageBackend.reason);
    fprintf('large: requested=%s selected=%s reason=%s\n', ...
        results.large.render.imageBackend.requested,results.large.render.imageBackend.selected, ...
        results.large.render.imageBackend.reason);
    clear cleanup;
end
function closeFigures(figures),for k=1:numel(figures),if ishandle(figures(k)),close(figures(k));end,end,end
