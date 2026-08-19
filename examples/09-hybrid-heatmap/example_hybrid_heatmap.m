function results = example_hybrid_heatmap(outputDirectory)
%EXAMPLE_HYBRID_HEATMAP Compare explicit vector and hybrid image backends.
    repositoryRoot=fileparts(fileparts(fileparts(mfilename('fullpath'))));
    if nargin<1||isempty(outputDirectory),outputDirectory=fullfile(repositoryRoot,'.audit', ...
            'public-preview','examples','09-hybrid-heatmap');end
    addpath(fullfile(repositoryRoot,'src'));if exist(outputDirectory,'dir')~=7,mkdir(outputDirectory);end
    x=linspace(-3,3,100);y=linspace(-2,2,100);[X,Y]=meshgrid(x,y);
    field=exp(-(X.^2+Y.^2))-0.4*exp(-((X-1.4).^2+2*(Y+.4).^2));
    fig=figure('Visible','off');cleanup=onCleanup(@()close(fig));ax=axes('Parent',fig);
    imagesc(ax,x,y,field);set(ax,'YDir','normal','CLim',[-.35 1]);
    colormap(ax,[.05 .15 .45;.2 .65 .7;1 .95 .7;.65 .05 .05]);
    xlabel(ax,'Position x');ylabel(ax,'Position y');title(ax,'Dense residual field');
    cb=colorbar(ax);ylabel(cb,'Normalized residual');
    results.vector=m2t.export(fig,fullfile(outputDirectory,'vector'), ...
        'ImageBackend','vector','Profile','publication','Overwrite',true);
    results.hybrid=m2t.export(fig,fullfile(outputDirectory,'hybrid'), ...
        'ImageBackend','hybrid','Profile','publication','Overwrite',true);
    if ~(results.vector.success&&results.hybrid.success)
        error('M2T:ExampleFailed','Vector or hybrid heatmap export failed.');
    end
    clear cleanup;
end
