function results=example_publication_profile(outputDirectory)
%EXAMPLE_PUBLICATION_PROFILE Compare default and fixed-width exports.
    repositoryRoot=fileparts(fileparts(fileparts(mfilename('fullpath'))));
    if nargin<1||isempty(outputDirectory),outputDirectory=fullfile(repositoryRoot,'.audit','public-preview','examples','06-publication-profile');end
    addpath(fullfile(repositoryRoot,'src'));if exist(outputDirectory,'dir')~=7,mkdir(outputDirectory);end
    fig=figure('Visible','off');cleanup=onCleanup(@()close(fig));x=linspace(0,2*pi,40);
    plot(x,sin(x),'LineWidth',1.2,'DisplayName','Series A');hold on;plot(x,cos(x),'--','DisplayName','Series B');
    xlabel('x');ylabel('response');title('Synthetic comparison');legend('show');grid on;
    results=struct();results.default=m2t.export(fig,fullfile(outputDirectory,'default'),'Overwrite',true);
    results.singleColumn=m2t.export(fig,fullfile(outputDirectory,'single-column-85mm'),'Profile','publication','Width','single-column','Overwrite',true);
    results.doubleColumn=m2t.export(fig,fullfile(outputDirectory,'double-column-170mm'),'Profile','publication','Width','double-column','Overwrite',true);
    results.publication=results.singleColumn;
    if ~(results.default.success&&results.singleColumn.success&&results.doubleColumn.success),error('M2T:ExampleFailed','Default or publication-profile export failed.');end
    clear cleanup;
end
