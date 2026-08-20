function summary = runM61RichScatterFigureSetTest(outputDirectory)
%RUNM61RICHSCATTERFIGURESETTEST Compile a mixed publication figure set.
    root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
    if nargin<1,outputDirectory=fullfile(root,'.audit','m61-rich-scatter-set');end
    scatterFigure=figure('Visible','off');lineFigure=figure('Visible','off');
    cleanup=onCleanup(@()closeFigures([scatterFigure lineFigure]));
    a=axes('Parent',scatterFigure);x=linspace(0,1,8);
    scatter(a,x,x.^2,linspace(20,100,8),reshape(x,[],1),'filled');
    caxis(a,[0 1]);t=linspace(0,1,16)';
    colormap(a,[0.12+0.78*t,0.18+0.62*sin(pi*t),0.82-0.70*t]);colorbar(a);
    plot(axes('Parent',lineFigure),x,sin(2*pi*x));
    entries=struct('figure',{scatterFigure,lineFigure},'name',{'rich-scatter','line'});
    first=m2t.exportSet(entries,outputDirectory,'Profile','publication', ...
        'Width','single-column','Overwrite',true);
    assert(first.success&&first.summary.succeeded==2&&first.summary.failed==0);
    manifest=fileread(first.manifestPath);
    assert(isempty(strfind(manifest,strrep(outputDirectory,'\','/')))); %#ok<STREMP>
    assert(~isempty(strfind(manifest,'"tex":"rich-scatter.tex"'))); %#ok<STREMP>
    second=m2t.exportSet(entries,outputDirectory,'Profile','publication', ...
        'Width','single-column','Overwrite',true);
    assert(second.success&&strcmp(manifest,fileread(second.manifestPath)));
    assert(all(arrayfun(@(item)strcmp(item.effective.profile,'publication'),second.entries)));
    assert(all(arrayfun(@(item)~isempty(item.result.pdfPath)&&exist(item.result.pdfPath,'file')==2,second.entries)));
    rich=fileread(second.entries(1).result.texPath);
    line=fileread(second.entries(2).result.texPath);
    assert(~isempty(strfind(rich,'scatter src=explicit'))); %#ok<STREMP>
    assert(~isempty(strfind(rich,'colormap name='))); %#ok<STREMP>
    assert(isempty(strfind(line,'scatter src=explicit'))&& ...
        isempty(strfind(line,'colormap name='))); %#ok<STREMP>
    assert(second.entries(1).result.profile.widthMillimeters==85);
    wide=m2t.export(scatterFigure,fullfile(outputDirectory,'rich-scatter-170'), ...
        'Profile','publication','Width','double-column','Overwrite',true);
    assert(wide.success&&wide.profile.widthMillimeters==170&&exist(wide.pdfPath,'file')==2);
    summary=struct('tests',2,'failures',0,'manifestPath',second.manifestPath, ...
        'detail','mixed rich-scatter/line set deterministic; scatter compiled at 85 mm and 170 mm with isolated color state');
    clear cleanup;
end

function closeFigures(figures)
    for k=1:numel(figures),if ishandle(figures(k)),close(figures(k));end,end
end
