function outputPath = example_rich_image_alpha(outputPath)
%EXAMPLE_RICH_IMAGE_ALPHA Export synthetic truecolor data with an alpha mask.
    root=fileparts(fileparts(fileparts(mfilename('fullpath'))));addpath(fullfile(root,'src'));
    if nargin<1,outputPath=fullfile(root,'.audit','public-preview','examples','12-rich-image-alpha.tex');end
    [folder,name,extension]=fileparts(outputPath);outputBase=outputPath;
    if strcmpi(extension,'.tex'),outputBase=fullfile(folder,name);end
    [x,y]=meshgrid(linspace(-1,1,96));radius=sqrt(x.^2+y.^2);
    rgb=zeros(96,96,3);rgb(:,:,1)=0.15+0.75*(x+1)/2;
    rgb(:,:,2)=0.2+0.65*(y+1)/2;rgb(:,:,3)=0.85-0.55*(x+1)/2;
    alpha=max(0,min(1,(0.92-radius)/0.22));
    fig=figure('Visible','off');cleanup=onCleanup(@()close(fig));ax=axes('Parent',fig);
    handle=image(ax,[-1 1],[-1 1],rgb);set(handle,'AlphaData',alpha,'AlphaDataMapping','none');
    set(ax,'YDir','normal','Color',[1 1 1]);axis(ax,'image');
    xlabel(ax,'Horizontal coordinate');ylabel(ax,'Vertical coordinate');
    title(ax,'Truecolor image with deterministic alpha mask');
    result=m2t.export(fig,outputBase,'ImageBackend','auto','Overwrite',true);
    if ~result.success,error(result.diagnostics(1).code,'%s',result.diagnostics(1).message);end
    outputPath=result.texPath;clear cleanup;
end
