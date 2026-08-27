function summary=runM62RichImageTexTests(outputDirectory)
%RUNM62RICHIMAGETEXTESTS Compile representative rich-image/publication outputs.
    root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
    if nargin<1,outputDirectory=fullfile(root,'.audit','m62-rich-image-tex');end
    if exist(outputDirectory,'dir')==7,rmdir(outputDirectory,'s');end,mkdir(outputDirectory);
    cases={...
      'T01_scalar_vector',@()scalarCase('vector',false,false);...
      'T02_scalar_hybrid',@()scalarCase('hybrid',false,false);...
      'T03_rgb',@()rgbCase(false,false);...
      'T04_rgb_alpha',@()rgbCase(true,false);...
      'T05_scalar_alpha',@()scalarCase('auto',true,false);...
      'T06_image_colorbar',@()scalarCase('vector',false,true);...
      'T07_rgb_line',@()rgbCase(true,true);...
      'T08_image_scatter',@scatterCase;...
      'T09_publication_85',@()profileCase('single-column');...
      'T10_publication_170',@()profileCase('double-column');...
      'T11_figure_set',@figureSetCase};
    rows=cell(size(cases,1),4);failures=0;
    for k=1:size(cases,1)
      try,detail=cases{k,2}();status='PASS';catch err,status='FAIL';failures=failures+1;detail=[id(err) ': ' one(err.message)];end
      rows(k,:)={cases{k,1},status,detail,'tex'};
    end
    path=fullfile(outputDirectory,'tex-results.tsv');writeRows(path,rows);
    summary=struct('tests',size(rows,1),'failures',failures,'resultPath',path);
    if failures,fprintf(2,'%s',fileread(path));error('M2T:M62RichImageTexTestsFailed','%d M6.2 TeX tests failed.',failures);end

    function d=scalarCase(backend,alpha,colorbarOn),f=figure('Visible','off');c=onCleanup(@()closeFig(f));ax=axes('Parent',f);[xx,yy]=meshgrid(linspace(-2,2,32),linspace(3,-1,24));h=imagesc(ax,linspace(-2,2,32),linspace(3,-1,24),sin(xx).*exp(-yy.^2/5));if alpha,set(h,'AlphaData',repmat(linspace(0,1,32),24,1));end;if colorbarOn,colorbar(ax);end;r=exportOne(f,[backend '-' num2str(alpha) '-' num2str(colorbarOn)],backend);d=['compiled ' r.render.effectiveImageBackend];clear c;end
    function d=rgbCase(alpha,lineOn),f=figure('Visible','off');c=onCleanup(@()closeFig(f));ax=axes('Parent',f);v=rgbRamp(48,64);h=image(ax,[-2 3],[4 -1],v);if alpha,set(h,'AlphaData',repmat(linspace(0,1,64),48,1));end;if lineOn,hold(ax,'on');plot(ax,[-2 3],[1 2],'k-','LineWidth',1.5);end;r=exportOne(f,['rgb-' num2str(alpha) '-' num2str(lineOn)],'auto');assert(strcmp(r.render.effectiveImageBackend,'hybrid'));d='RGB hybrid with vector overlay compiled';clear c;end
    function d=scatterCase(),f=figure('Visible','off');c=onCleanup(@()closeFig(f));ax=axes('Parent',f);imagesc(ax,[0 1],[0 1],reshape(linspace(0,1,400),20,20));hold(ax,'on');scatter(ax,[.2 .5 .8],[.8 .5 .2],[30 60 90],[.1 .5 .9],'filled');colorbar(ax);r=exportOne(f,'image-scatter','auto');d=['shared scalar mapping compiled ' r.render.effectiveImageBackend];clear c;end
    function d=profileCase(width),f=figure('Visible','off');c=onCleanup(@()closeFig(f));image(axes('Parent',f),rgbRamp(40,60));r=m2t.export(f,fullfile(outputDirectory,['profile-' width]),'ImageBackend','auto','Profile','publication','Width',width,'Overwrite',true);assertSuccess(r);d=[width ' compiled'];clear c;end
    function d=figureSetCase(),f1=figure('Visible','off');f2=figure('Visible','off');f3=figure('Visible','off');c=onCleanup(@()closeMany([f1 f2 f3]));h=image(axes('Parent',f1),rgbRamp(24,32));set(h,'AlphaData',.65);plot(axes('Parent',f2),1:4,[1 3 2 4]);bar(axes('Parent',f3),[1 2 3],[2 1 3]);entries=struct('figure',{f1,f2,f3},'name',{'rich-image','line','bar'});r=m2t.exportSet(entries,fullfile(outputDirectory,'set'),'ImageBackend','auto','Profile','publication','Overwrite',true);assert(r.success);text=fileread(r.manifestPath);assert(~isempty(strfind(text,'alpha_requires_hybrid')));d='deterministic mixed manifest and compilation passed';clear c;end
    function r=exportOne(f,name,backend),r=m2t.export(f,fullfile(outputDirectory,name),'ImageBackend',backend,'Overwrite',true);assertSuccess(r);end
end

function v=rgbRamp(rows,columns),[x,y]=meshgrid(linspace(0,1,columns),linspace(0,1,rows));v=zeros(rows,columns,3);v(:,:,1)=x;v(:,:,2)=y;v(:,:,3)=1-x.*y;end
function assertSuccess(r),assert(r.success&&strcmp(r.status,'success')&&exist(r.pdfPath,'file')==2);end
function closeFig(f),if ishandle(f),close(f);end,end
function closeMany(f),for k=1:numel(f),closeFig(f(k));end,end
function v=id(err),v=err.identifier;if isempty(v),v='<none>';end,end
function v=one(v),v=regexprep(v,'[\r\n\t]+',' ');end
function writeRows(path,rows),fid=fopen(path,'wb');assert(fid>=0);c=onCleanup(@()fclose(fid));fprintf(fid,'case\tstatus\tdetail\tlayer\n');for k=1:size(rows,1),fprintf(fid,'%s\t%s\t%s\t%s\n',rows{k,:});end,clear c;end
