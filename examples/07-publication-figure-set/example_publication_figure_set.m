function result=example_publication_figure_set(outputDirectory)
%EXAMPLE_PUBLICATION_FIGURE_SET Rebuild a synthetic publication figure set.
    repositoryRoot=fileparts(fileparts(fileparts(mfilename('fullpath'))));
    if nargin<1||isempty(outputDirectory),outputDirectory=fullfile(repositoryRoot,'.audit','public-preview','examples','07-publication-figure-set');end
    addpath(fullfile(repositoryRoot,'src'));x=linspace(0,2*pi,40);
    wave=figure('Visible','off');plot(x,sin(x),'-','DisplayName','sin(x)');hold on;plot(x,cos(x),'--','DisplayName','cos(x)');xlabel('x');ylabel('value');legend('show');grid on;
    uncertainty=figure('Visible','off');errorbar(1:6,[1 1.4 1.8 2.1 2.5 2.8],[.1 .12 .08 .15 .1 .13],'-o');xlabel('sample');ylabel('estimate');grid on;
    samples=figure('Visible','off');scatter(1:8,[1.1 1.9 3.2 3.8 5.1 6.2 6.9 8.1],36,[.15 .35 .7],'o','DisplayName','samples');xlabel('reference');ylabel('observed');legend('show');grid on;
    comparison=figure('Visible','off');first=subplot(1,2,1,'Parent',comparison);plot(first,0:5,[0 1.1 1.8 2.4 2.7 2.9]);title(first,'Method A');second=subplot(1,2,2,'Parent',comparison);plot(second,0:5,[0 .8 1.5 2.1 2.5 2.8]);title(second,'Method B');
    figures=[wave uncertainty samples comparison];cleanup=onCleanup(@()closeFigures(figures));entries=struct('figure',{wave,uncertainty,samples,comparison},'name',{'waves','uncertainty','samples','comparison'},'width',{[],[],[],'double-column'});
    result=m2t.exportSet(entries,outputDirectory,'Profile','publication','Width','single-column','Overwrite',true);
    if ~result.success,error('M2T:ExampleFailed','The publication figure-set example did not complete successfully.');end
    clear cleanup;
end
function closeFigures(figures),for k=1:numel(figures),if ishandle(figures(k)),close(figures(k));end,end,end
