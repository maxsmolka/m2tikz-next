function summary=runM66ColorMappingMatlabTests(outputDirectory)
%RUNM66COLORMAPPINGMATLABTESTS Native finite-colormap reference figures.
    assert(~exist('OCTAVE_VERSION','builtin'),'Native MATLAB required.');
    root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
    if nargin<1,outputDirectory=fullfile(root,'.audit','m66-colors-matlab');end
    if exist(outputDirectory,'dir')~=7,mkdir(outputDirectory);end
    names={'scatter','scatter3','surface','image'};
    for k=1:4
        f=figure('Visible','off','Color','w');guard=onCleanup(@()close(f));a=axes(f);
        values=[0 .25 .5 .75 1];
        if k==1,scatter(a,1:5,ones(1,5),400,values,'filled');
        elseif k==2,scatter3(a,1:5,ones(1,5),ones(1,5),[100 225 400 225 100],values,'filled');view(a,30,25);
        elseif k==3,[x,y]=meshgrid(1:5,[0 1]);surf(a,x,y,ones(2,5),repmat(values,2,1),'FaceColor','interp','EdgeColor','none');view(a,30,25);
        else,imagesc(a,repmat(values,2,1));end
        colormap(a,[0 0 1;1 0 0]);clim(a,[0 1]);colorbar(a);set(a,'Color','w','XColor','k','YColor','k','ZColor','k');drawnow;
        ir=m2t2.reader.readFigure(f);before=jsonencode(ir);tex=m2t2.render.renderPgfplots(ir,true);
        assert(strcmp(before,jsonencode(m2t2.reader.readFigure(f))));
        mapping=ir.axes{1}.colorMapping;assert(isequal(m2t2.render.imageColorIndices(values,mapping),[0 0 1 1 1]));
        base=fullfile(outputDirectory,names{k});m2t.internal.writeTextFile([base '.tex'],tex);
        exportgraphics(f,[base '-source.png'],'Resolution',120);clear guard;
    end
    summary=struct('tests',4,'failures',0);fprintf('M66_NATIVE_COLORMAPPING_PASS: 4/4\n');
end
