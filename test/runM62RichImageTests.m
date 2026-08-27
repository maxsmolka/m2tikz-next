function summary = runM62RichImageTests(outputDirectory)
%RUNM62RICHIMAGETESTS Validate bounded RGB, alpha, mapping, and planner semantics.
    root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
    if nargin<1,outputDirectory=fullfile(root,'.audit','m62-rich-image');end
    if exist(outputDirectory,'dir')==7,rmdir(outputDirectory,'s');end,mkdir(outputDirectory);
    cases={...
      'I01_scalar_opaque',@scalarOpaque; 'I02_constant_alpha',@constantAlpha;...
      'I03_per_pixel_alpha',@perPixelAlpha; 'I04_rgb_double',@rgbDouble;...
      'I05_rgb_uint8',@rgbUint8; 'I06_rgb_uint16',@rgbUint16;...
      'I07_direct_scalar',@directScalar; 'I08_auto_rgb',@autoRgb;...
      'I09_auto_alpha',@autoAlpha; 'I10_forced_vector_rich',@forcedVector;...
      'I11_hybrid_rgb_asset',@hybridRgb; 'I12_hybrid_alpha_asset',@hybridAlpha;...
      'I13_scalar_nan',@scalarNan; 'I14_json_replay',@jsonReplay;...
      'I15_old_v2_replay',@oldReplay; 'I16_determinism',@determinism;...
      'I17_lifecycle',@lifecycle; 'I18_coordinates_ydir',@coordinates;...
      'I19_mixed_scalar_rgb',@mixedColorOwnership; 'I20_scale_512',@scale512;...
      'N01_alpha_shape',@badAlphaShape; 'N02_alpha_range',@badAlphaRange;...
      'N03_alpha_mapping',@badAlphaMapping; 'N04_rgb_nan',@badRgb;...
      'N05_bad_ir_dimension',@badIrDimension; 'N06_nonuniform_hybrid',@nonuniformHybrid};
    rows=cell(size(cases,1),4);failures=0;
    for k=1:size(cases,1)
      try,detail=cases{k,2}();status='PASS';catch err,status='FAIL';failures=failures+1;detail=[id(err) ': ' one(err.message)];end
      rows(k,:)={cases{k,1},status,detail,'rich-image'};
    end
    path=fullfile(outputDirectory,'rich-image-results.tsv');writeRows(path,rows);
    summary=struct('tests',size(rows,1),'failures',failures,'resultPath',path);
    if failures,fprintf(2,'%s',fileread(path));error('M2T:M62RichImageTestsFailed','%d M6.2 tests failed.',failures);end

    function d=scalarOpaque(),[f,~,c]=scalarFig();n=imageNode(f);assert(strcmp(n.colorMode,'scalar')&&strcmp(n.alphaMode,'opaque'));d='legacy scalar contract preserved';clear c;end
    function d=constantAlpha(),[f,h,c]=scalarFig();set(h,'AlphaData',0.4);n=imageNode(f);assert(strcmp(n.alphaMode,'constant')&&n.alphaData==0.4);d='constant alpha owned by image';clear c;end
    function d=perPixelAlpha(),[f,h,c]=scalarFig();a=[0 .25;.5 1];set(h,'AlphaData',a);n=imageNode(f);assert(strcmp(n.alphaMode,'per_pixel')&&isequal(n.alphaData,a));d='per-pixel alpha retained';clear c;end
    function d=rgbDouble(),[f,~,c]=rgbFig(rgbData());ir=m2t2.reader.readFigure(f);n=ir.axes{1}.series{1};assert(strcmp(n.colorMode,'rgb')&&strcmp(n.mapping,'none')&&isequal(n.cdata,rgbData()));p=m2t2.render.makePgfplotsPlan(ir,true,m2t2.render.defaultConfig(),'hybrid','a');assert(isempty(strfind(p.tex,'point meta min=')));d='double RGB normalized without CLim TeX';clear c;end
    function d=rgbUint8(),v=uint8(round(rgbData()*255));[f,~,c]=rgbFig(v);n=imageNode(f);assert(max(abs(n.cdata(:)-double(v(:))/255))<1e-12);d='uint8 RGB normalized by 255';clear c;end
    function d=rgbUint16(),v=uint16(round(rgbData()*65535));[f,~,c]=rgbFig(v);n=imageNode(f);assert(max(abs(n.cdata(:)-double(v(:))/65535))<1e-12);d='uint16 RGB normalized by 65535';clear c;end
    function d=directScalar(),f=figure('Visible','off');c=onCleanup(@()closeFig(f));h=image(axes('Parent',f),[1 2;3 4]);set(h,'CDataMapping','direct');n=imageNode(f);assert(strcmp(n.mapping,'direct')&&n.directIndexBase==1);d='direct scalar indices explicit';clear c;end
    function d=autoRgb(),[f,~,c]=rgbFig(rgbData());q=m2t.planning.selectImageBackend(m2t2.reader.readFigure(f),'auto');assert(strcmp(q.selected,'hybrid')&&strcmp(q.reason,'truecolor_requires_hybrid'));d='RGB semantic planner reason stable';clear c;end
    function d=autoAlpha(),[f,h,c]=scalarFig();set(h,'AlphaData',.5);q=m2t.planning.selectImageBackend(m2t2.reader.readFigure(f),'auto');assert(strcmp(q.reason,'alpha_requires_hybrid'));d='alpha semantic planner reason stable';clear c;end
    function d=forcedVector(),[f,~,c]=rgbFig(rgbData());caught=false;try,m2t.planning.selectImageBackend(m2t2.reader.readFigure(f),'vector');catch err,caught=strcmp(err.identifier,'M2T2:E053:UnsupportedVectorRichImage');end;assert(caught);d='forced vector fails precisely';clear c;end
    function d=hybridRgb(),[f,~,c]=rgbFig(rgbData());p=plan(f);a=p.assets(1);assert(isequal(a.rgb,uint8(round(rgbData()*255)))&&all(a.alpha(:)==255));d='RGB channel order exact';clear c;end
    function d=hybridAlpha(),[f,h,c]=rgbFig(rgbData());set(h,'AlphaData',[0 .25;.5 1]);a=plan(f).assets(1);assert(isequal(a.alpha,uint8(round([0 .25;.5 1]*255))));d='alpha channel exact';clear c;end
    function d=scalarNan(),[f,h,c]=scalarFig();set(h,'CData',[1 NaN;3 4]);a=plan(f).assets(1);assert(a.alpha(1,2)==0);d='scalar NaN is transparent missing cell';clear c;end
    function d=jsonReplay(),[f,h,c]=rgbFig(rgbData());set(h,'AlphaData',[0 .25;.5 1]);ir=m2t2.reader.readFigure(f);r=m2t2.ir.fromJson(jsonencode(ir));m2t2.ir.validate(r);a=ir.axes{1}.series{1};b=r.axes{1}.series{1};assert(isequal(a,b));d='rich image JSON round-trip exact';clear c;end
    function d=oldReplay(),[f,~,c]=scalarFig();ir=m2t2.reader.readFigure(f);s=ir.axes{1}.series{1};s=rmfield(s,{'colorMode','directIndexBase','alphaMode','alphaData'});ir.axes{1}.series{1}=s;r=m2t2.ir.fromJson(jsonencode(ir));n=r.axes{1}.series{1};assert(strcmp(n.colorMode,'scalar')&&strcmp(n.alphaMode,'opaque'));d='old v2 defaults restored';clear c;end
    function d=determinism(),[f,h,c]=rgbFig(rgbData());set(h,'AlphaData',[0 .25;.5 1]);a=plan(f);b=plan(f);assert(isequal(a,b));p1=fullfile(outputDirectory,'deterministic-a.png');p2=fullfile(outputDirectory,'deterministic-b.png');m2t2.render.writePngAsset(a.assets(1),p1);m2t2.render.writePngAsset(b.assets(1),p2);assert(isequal(readBytes(p1),readBytes(p2)));d='IR planner TeX and same-encoder PNG bytes deterministic';clear c;end
    function d=lifecycle(),[f,h,c]=rgbFig(rgbData());set(h,'AlphaData',.5);before={get(h,'CData'),get(h,'AlphaData'),get(h,'XData'),get(h,'YData')};m2t2.reader.readFigure(f);after={get(h,'CData'),get(h,'AlphaData'),get(h,'XData'),get(h,'YData')};assert(isequal(before,after));d='reader does not mutate source';clear c;end
    function d=coordinates(),[f,h,c]=rgbFig(rgbData());set(h,'XData',[-2 4],'YData',[3 -1]);set(get(h,'Parent'),'YDir','normal');ir=m2t2.reader.readFigure(f);n=ir.axes{1}.series{1};assert(isequal(n.x,[-2 4])&&isequal(n.y,[3 -1])&&strcmp(ir.axes{1}.ydirection,'normal'));d='extent and YDir retained';clear c;end
    function d=mixedColorOwnership(),f=figure('Visible','off');c=onCleanup(@()closeFig(f));a1=subplot(1,2,1,'Parent',f);imagesc(a1,[1 2;3 4]);colorbar(a1);a2=subplot(1,2,2,'Parent',f);image(a2,rgbData());ir=m2t2.reader.readFigure(f);assert(numel(ir.elements)==1);d='RGB creates no fake colorbar';clear c;end
    function d=scale512(),v=repmat(reshape(linspace(0,1,512),1,512,1),512,1,3);n=m2t2.ir.makeImageSeries();n.x=1:512;n.y=1:512;n.cdata=v;n.colorMode='rgb';n.mapping='none';ax=m2t2.ir.makeAxes();ax.series={n};ir=m2t2.ir.makeFigure({ax});t=tic;q=m2t.planning.selectImageBackend(ir,'auto');p=m2t2.render.makePgfplotsPlan(ir,true,m2t2.render.defaultConfig(),q.selected,'assets');elapsed=toc(t);assert(strcmp(q.selected,'hybrid')&&isequal(size(p.assets(1).rgb),[512 512 3]));d=sprintf('512x512 retained, plan %.4gs',elapsed);end
    function d=badAlphaShape(),[f,h,c]=scalarFig();caught=false;try,set(h,'AlphaData',[1 1 1]);m2t2.reader.readFigure(f);catch err,caught=strcmp(err.identifier,'M2T2:E050:MalformedImageAlphaData');end;assert(caught);d='malformed alpha shape rejected';clear c;end
    function d=badAlphaRange(),[f,h,c]=scalarFig();set(h,'AlphaData',1.2);caught=catchRead(f,'M2T2:E050:MalformedImageAlphaData');assert(caught);d='alpha outside [0,1] rejected';clear c;end
    function d=badAlphaMapping(),[f,h,c]=scalarFig();set(h,'AlphaDataMapping','scaled');assert(catchRead(f,'M2T2:E051:UnsupportedImageAlphaMapping'));d='scaled alpha mapping rejected';clear c;end
    function d=badRgb(),v=rgbData();v(1)=NaN;[f,~,c]=rgbFig(v);assert(catchRead(f,'M2T2:E049:UnsupportedImageRGB'));d='RGB NaN rejected';clear c;end
    function d=badIrDimension(),n=m2t2.ir.makeImageSeries();n.x=1:2;n.y=1:2;n.cdata=zeros(2,2,4);n.colorMode='rgb';n.mapping='none';ax=m2t2.ir.makeAxes();ax.series={n};caught=false;try,m2t2.ir.validate(m2t2.ir.makeFigure({ax}));catch,caught=true;end;assert(caught);d='unsupported dimensionality rejected by IR';end
    function d=nonuniformHybrid(),n=m2t2.ir.makeImageSeries();n.x=[1 2 4];n.y=1:2;n.cdata=zeros(2,3);ax=m2t2.ir.makeAxes();ax.series={n};caught=false;try,m2t2.render.makePgfplotsPlan(m2t2.ir.makeFigure({ax}),true,m2t2.render.defaultConfig(),'hybrid','a');catch err,caught=strcmp(err.identifier,'M2T:IMAGE_HYBRID_COORDINATES_UNSUPPORTED');end;assert(caught);d='nonuniform hybrid placement rejected';end
    function p=plan(f),ir=m2t2.reader.readFigure(f);p=m2t2.render.makePgfplotsPlan(ir,true,m2t2.render.defaultConfig(),'hybrid','assets');end
    function yes=catchRead(f,code),yes=false;try,m2t2.reader.readFigure(f);catch err,yes=strcmp(err.identifier,code);end,end
end

function [f,h,c]=scalarFig(),f=figure('Visible','off');c=onCleanup(@()closeFig(f));h=imagesc(axes('Parent',f),[1 2;3 4]);end
function [f,h,c]=rgbFig(v),f=figure('Visible','off');c=onCleanup(@()closeFig(f));h=image(axes('Parent',f),v);end
function v=rgbData(),v=zeros(2,2,3);v(:,:,1)=[1 0;0 .5];v(:,:,2)=[0 1;.5 0];v(:,:,3)=[0 .25;1 .5];end
function n=imageNode(f),ir=m2t2.reader.readFigure(f);n=ir.axes{1}.series{1};end
function b=readBytes(path),fid=fopen(path,'rb');assert(fid>=0);c=onCleanup(@()fclose(fid));b=fread(fid,Inf,'*uint8');clear c;end
function closeFig(f),if ishandle(f),close(f);end,end
function v=id(err),v=err.identifier;if isempty(v),v='<none>';end,end
function v=one(v),v=regexprep(v,'[\r\n\t]+',' ');end
function writeRows(path,rows),fid=fopen(path,'wb');assert(fid>=0);c=onCleanup(@()fclose(fid));fprintf(fid,'case\tstatus\tdetail\tlayer\n');for k=1:size(rows,1),fprintf(fid,'%s\t%s\t%s\t%s\n',rows{k,:});end,clear c;end
