function generateM34VisualFixtures(outputDirectory)
%GENERATEM34VISUALFIXTURES Build vector/hybrid semantic comparison pairs.
    repositoryRoot=fileparts(fileparts(mfilename('fullpath')));
    if nargin<1,outputDirectory=fullfile(repositoryRoot,'.audit','m34-visual');end
    addpath(fullfile(repositoryRoot,'src'));
    if exist(outputDirectory,'dir')==7,rmdir(outputDirectory,'s');end,mkdir(outputDirectory);
    cases={'base','colormap','clim','reverse','normal','explicit','colorbar','single','double'};
    for k=1:numel(cases)
        [fig,profile,width]=fixture(cases{k});cleanup=onCleanup(@()closeFigure(fig));
        arguments={'Overwrite',true};
        if ~isempty(profile),arguments(end+1:end+4)={'Profile',profile,'Width',width};end
        vector=m2t.export(fig,fullfile(outputDirectory,[cases{k} '-vector']), ...
                          arguments{:},'ImageBackend','vector');
        hybrid=m2t.export(fig,fullfile(outputDirectory,[cases{k} '-hybrid']), ...
                          arguments{:},'ImageBackend','hybrid');
        if ~(vector.success&&hybrid.success),error('M2T:M34VisualFixtureFailed','%s failed',cases{k});end
        clear cleanup;
    end
end

function [fig,profile,width]=fixture(name)
    fig=figure('Visible','off');ax=axes('Parent',fig);profile='';width='';
    data=[0 1 2;3 4 5];imagesc(ax,[10 20 30],[100 200],data);
    set(ax,'CLim',[0 6]);colormap(ax,[0 0 .3;0 .6 .8;1 1 .7;.7 0 0]);
    xlabel(ax,'X coordinate');ylabel(ax,'Y coordinate');title(ax,['Case ' name]);
    switch name
        case 'clim',set(ax,'CLim',[-3 9]);
        case 'colormap',colormap(ax,[0 0 0;1 0 0;0 1 0;1 1 1]);
        case 'reverse',set(ax,'YDir','reverse');
        case 'normal',set(ax,'YDir','normal');
        case 'explicit',set(ax,'YDir','normal','XLim',[5 35],'YLim',[50 250]);
        case 'colorbar',cb=colorbar(ax);ylabel(cb,'Scale');
        case 'single',set(ax,'YDir','normal');colorbar(ax);profile='publication';width='single-column';
        case 'double',set(ax,'YDir','normal');colorbar(ax);profile='publication';width='double-column';
    end
end
function closeFigure(fig),if ishandle(fig),close(fig);end,end
