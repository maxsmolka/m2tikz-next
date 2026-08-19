function summary = runM51AnnotationTests(outputDirectory)
%RUNM51ANNOTATIONTESTS Validate annotations with synthetic MATLAB figures.
    root = fileparts(fileparts(mfilename('fullpath')));
    if nargin < 1, outputDirectory = fullfile(root, '.audit', 'm51-annotations'); end
    addpath(fullfile(root, 'src')); ensureDirectory(outputDirectory);
    cases = { ...
        'A01_axes_text_basic', @textBasic; ...
        'A02_axes_text_interpreters', @textInterpreters; ...
        'A03_axes_text_alignment', @textAlignment; ...
        'A04_axes_text_rotation', @textRotation; ...
        'A05_axes_text_color_font', @textStyle; ...
        'A06_arrow_basic', @() arrowBasic('arrow'); ...
        'A07_double_arrow_basic', @() arrowBasic('doublearrow'); ...
        'A08_arrow_style', @arrowStyle; ...
        'A09_annotation_ownership', @ownership; ...
        'A10_empty_annotation_pane', @emptyPane; ...
        'A11_supported_nonempty_pane', @supportedPane; ...
        'A12_unsupported_mixed_pane', @unsupportedMixedPane; ...
        'A13_json_replay_text', @jsonText; ...
        'A14_json_replay_arrow', @jsonArrow; ...
        'A15_renderer_handle_free', @rendererHandleFree; ...
        'A16_profile_single_column', @() profileCase('single-column',85); ...
        'A17_profile_double_column', @() profileCase('double-column',170); ...
        'A18_multiple_axes_ownership', @multipleAxes; ...
        'A19_deterministic_repeat', @deterministic; ...
        'A20_figure_lifecycle', @lifecycle; ...
        'A22_dense_text', @syntheticText; ...
        'A23_dense_double_arrow', @syntheticArrow; ...
        'A24_overlay_text', @syntheticOverlay; ...
        'A25_line_text_double_arrow', @lineTextDoubleArrow; ...
        'A26_line_text_arrow', @lineTextArrow; ...
        'A21_figure_set_annotations', @figureSet; ...
        'NC1_labels_remain_axes_semantics', @labelsRemainAxes; ...
        'NC3_arbitrary_hggroup_rejected', @arbitraryGroup; ...
        'NC5_unsupported_shapes_rejected', @unsupportedShapes};
    rows = cell(size(cases,1),4); failures = 0;
    for k = 1:size(cases,1)
        try, detail = cases{k,2}(); status = 'PASS';
        catch err, status = 'FAIL'; failures = failures + 1;
            detail = sprintf('%s: %s',identifier(err.identifier),oneLine(err.message));
        end
        rows(k,:) = {cases{k,1},status,detail,'M5.1'};
    end
    resultPath = fullfile(outputDirectory,'m51-results.tsv'); writeRows(resultPath,rows);
    summary = struct('failures',failures,'tests',size(rows,1),'resultPath',resultPath);
    if failures
        fprintf(2,'M5.1 diagnostics from %s:\n%s',resultPath,fileread(resultPath));
        error('M2T:M51AnnotationTestsFailed','%d M5.1 tests failed.',failures);
    end

    function detail = textBasic()
        [fig,ax,c] = lineFigure(); text(ax,1,2,'User note'); ir=read(fig);
        n=onlyAnnotation(ir); assert(strcmp(n.kind,'m2t2.textannotation'));
        assert(strcmp(n.owner.id,'axes-1')&&strcmp(n.coordinateSpace,'axes_data'));
        assert(isequal(n.position,[1 2])&&strcmp(n.text.value,'User note'));
        detail='axes-owned data-coordinate TextAnnotationIR'; clear c;
    end
    function detail = textInterpreters()
        [fig,ax,c]=lineFigure();text(ax,.5,1,'x_{1}','Interpreter','tex');text(ax,1.5,2,'$y^2$','Interpreter','latex');ir=read(fig);
        assert(numel(ir.annotations)==2); values=cellfun(@(n)n.text.interpreter,ir.annotations,'UniformOutput',false);
        assert(isequal(values,{'tex','latex'}));detail='TeX and LaTeX semantics preserved';clear c;
    end
    function detail = textAlignment()
        [fig,ax,c]=lineFigure();text(ax,1,2,'A','HorizontalAlignment','right','VerticalAlignment','bottom');n=onlyAnnotation(read(fig));
        assert(strcmp(n.horizontalAlignment,'right')&&strcmp(n.verticalAlignment,'bottom'));detail='horizontal and vertical alignment preserved';clear c;
    end
    function detail = textRotation()
        [fig,ax,c]=lineFigure();text(ax,1,2,'A','Rotation',90);n=onlyAnnotation(read(fig));assert(n.rotation==90);detail='90 degree rotation preserved';clear c;
    end
    function detail = textStyle()
        [fig,ax,c]=lineFigure();text(ax,1,2,'A','FontSize',13,'FontWeight','bold','FontAngle','italic','Color',[.1 .2 .3]);n=onlyAnnotation(read(fig));
        assert(n.fontSize==13&&strcmp(n.fontWeight,'bold')&&strcmp(n.fontAngle,'italic')&&max(abs(n.color-[.1 .2 .3]))<1e-12);detail='font and RGB style preserved';clear c;
    end
    function detail = arrowBasic(kind)
        [fig,~,c]=lineFigure();annotation(fig,kind,[.2 .7],[.3 .8]);n=onlyAnnotation(read(fig));
        assert(strcmp(n.annotationKind,kind)&&isequal(n.start,[.2 .3])&&isequal(n.end,[.7 .8]));
        assert(strcmp(n.owner.kind,'figure')&&strcmp(n.coordinateSpace,'figure_normalized'));
        if strcmp(kind,'doublearrow'),assert(~strcmp(n.startHead.style,'none'));else,assert(strcmp(n.startHead.style,'none'));end
        detail=[kind ' endpoints and heads preserved'];clear c;
    end
    function detail = arrowStyle()
        [fig,~,c]=lineFigure();annotation(fig,'arrow',[.1 .8],[.2 .7],'LineStyle','--','LineWidth',1.5,'Color',[.8 .1 .2],'HeadStyle','vback2','HeadLength',9,'HeadWidth',7);n=onlyAnnotation(read(fig));
        assert(strcmp(n.style,'dashed')&&n.width==1.5&&max(abs(n.color-[.8 .1 .2]))<1e-12&&n.endHead.length==9&&n.endHead.width==7);detail='line and arrow-head style preserved';clear c;
    end
    function detail = ownership()
        [fig,ax,c]=lineFigure();text(ax,1,2,'T');annotation(fig,'arrow',[.1 .5],[.2 .6]);ir=read(fig);
        assert(strcmp(ir.annotations{1}.owner.kind,'axes')&&strcmp(ir.annotations{2}.owner.kind,'figure'));detail='scientific ownership normalized past helper pane';clear c;
    end
    function detail = emptyPane()
        [fig,~,c]=lineFigure();pane=findall(fig,'Type','annotationpane','Tag','scribeOverlay');assert(numel(pane)==1&&isempty(allchild(pane)));ir=read(fig);assert(isempty(ir.annotations));detail='empty scribeOverlay ignored';clear c;
    end
    function detail = supportedPane()
        [fig,~,c]=lineFigure();annotation(fig,'arrow',[.1 .5],[.2 .6]);pane=findall(fig,'Type','annotationpane','Tag','scribeOverlay');assert(~isempty(allchild(pane)));ir=read(fig);assert(numel(ir.annotations)==1);detail='supported nonempty pane normalized narrowly';clear c;
    end
    function detail = unsupportedMixedPane()
        [fig,~,c]=lineFigure();annotation(fig,'arrow',[.1 .5],[.2 .6]);annotation(fig,'rectangle',[.2 .2 .2 .1]);expectError(@()read(fig),'M2T2:E013:UnsupportedAnnotationType','rectangleshape');detail='mixed pane rejects unsupported child';clear c;
    end
    function detail = jsonText()
        [fig,ax,c]=lineFigure();text(ax,1,2,'Replay');ir=read(fig);loaded=m2t2.ir.fromJson(jsonencode(ir));assert(isequal(loaded.annotations{1},ir.annotations{1}));detail='text JSON replay exact';clear c;
    end
    function detail = jsonArrow()
        [fig,~,c]=lineFigure();annotation(fig,'doublearrow',[.1 .8],[.2 .7]);ir=read(fig);loaded=m2t2.ir.fromJson(jsonencode(ir));assert(isequal(loaded.annotations{1},ir.annotations{1}));detail='arrow JSON replay exact';clear c;
    end
    function detail = rendererHandleFree()
        files={fullfile(root,'src','+m2t2','+render','renderTextAnnotation.m'),fullfile(root,'src','+m2t2','+render','renderArrowAnnotation.m')};
        for i=1:numel(files),source=fileread(files{i});assert(isempty(regexp(source,'\b(get|set|ishandle|allchild|findall)\s*\(','once')));end
        detail='annotation renderers contain no runtime graphics access';
    end
    function detail = profileCase(width,millimeters)
        [fig,ax,c]=lineFigure();text(ax,1,2,'Profile');annotation(fig,'arrow',[.2 .7],[.3 .8]);dir=fullfile(outputDirectory,['profile-' width]);r=exportFigure(fig,dir,'Profile','publication','Width',width);assert(r.profile.widthMillimeters==millimeters);detail=[width ' compiled; data/normalized coordinates remain IR-based'];clear c;
    end
    function detail = multipleAxes()
        fig=figure('Visible','off');c=onCleanup(@()close(fig));a1=axes('Parent',fig,'Position',[.1 .15 .65 .7]);plot(a1,1:3,[1 2 3]);a2=axes('Parent',fig,'Position',[.55 .55 .35 .3]);plot(a2,1:3,[3 2 1]);text(a2,2,2,'Inset');ir=read(fig);
        assert(numel(ir.axes)==2&&~isempty(ir.axes{2}.overlayOf)&&strcmp(onlyAnnotation(ir).owner.id,'axes-2'));detail='overlap geometry and second-axes ownership preserved';clear c;
    end
    function detail = deterministic()
        [fig,ax,c]=lineFigure();text(ax,1,2,'Stable');annotation(fig,'doublearrow',[.2 .7],[.3 .8]);a=read(fig);b=read(fig);assert(strcmp(jsonencode(a),jsonencode(b)));assert(strcmp(m2t2.render.renderPgfplots(a,true),m2t2.render.renderPgfplots(b,true)));detail='IR and TeX repeat byte-identically';clear c;
    end
    function detail = lifecycle()
        [fig,ax,c]=lineFigure();t=text(ax,1,2,'State','Rotation',25);a=annotation(fig,'arrow',[.2 .7],[.3 .8]);before={fig.Visible,ax.Position,ax.XLim,ax.YLim,t.Position,t.Units,a.X,a.Y,a.Units};read(fig);after={fig.Visible,ax.Position,ax.XLim,ax.YLim,t.Position,t.Units,a.X,a.Y,a.Units};assert(isequal(before,after)&&isgraphics(fig));detail='figure, axes, text, arrow and coordinates unchanged';clear c;
    end
    function detail = syntheticText()
        fig=figure('Visible','off');c=onCleanup(@()close(fig));ax=axes('Parent',fig);hold(ax,'on');for i=1:6,plot(ax,linspace(0,6,40),sin(linspace(0,6,40)+i/4));end;text(ax,5,.5,'note A','Color',[.85 .33 .1]);text(ax,1.2,.1,'note B','Color',[0 .45 .74]);exportFigure(fig,fullfile(outputDirectory,'synthetic-text'));assert(numel(read(fig).annotations)==2);detail='6 lines + 2 text annotations compiled';clear c;
    end
    function detail = syntheticArrow()
        fig=figure('Visible','off');c=onCleanup(@()close(fig));ax=axes('Parent',fig);hold(ax,'on');for i=1:5,plot(ax,linspace(0,10,80),i+sin(linspace(0,10,80)));end;annotation(fig,'doublearrow',[.25 .55],[.35 .35],'LineWidth',1.2);exportFigure(fig,fullfile(outputDirectory,'synthetic-arrow'));detail='dense lines + double-arrow compiled';clear c;
    end
    function detail = syntheticOverlay()
        fig=figure('Visible','off');c=onCleanup(@()close(fig));a1=axes('Parent',fig,'Position',[.1 .12 .78 .78]);hold(a1,'on');for i=1:8,plot(a1,1:10,(1:10)+i/10);end;a2=axes('Parent',fig,'Position',[.55 .52 .3 .3]);hold(a2,'on');for i=1:3,plot(a2,1:10,(1:10)+i);end;text(a1,4,8,'span A','Rotation',90,'HorizontalAlignment','center');text(a1,7,11,'span B','Rotation',90);exportFigure(fig,fullfile(outputDirectory,'synthetic-overlay'),'Profile','publication','Width','double-column');ir=read(fig);assert(numel(ir.axes)==2&&numel(ir.annotations)==2&&all(cellfun(@(n)strcmp(n.owner.id,'axes-1'),ir.annotations)));detail='11 series, overlap, text compiled';clear c;
    end
    function detail = lineTextDoubleArrow()
        [fig,ax,c]=lineFigure();hold(ax,'on');for i=1:4,plot(ax,0:3,[0 1 4 9]+i);end;annotation(fig,'doublearrow',[.2 .5],[.3 .3]);text(ax,1,5,'interval','HorizontalAlignment','right');exportFigure(fig,fullfile(outputDirectory,'line-double-arrow'));detail='5 lines + double-arrow + text compiled';clear c;
    end
    function detail = lineTextArrow()
        [fig,ax,c]=lineFigure();hold(ax,'on');for i=1:3,plot(ax,0:3,[0 1 4 9]+i);end;annotation(fig,'arrow',[.2 .5],[.3 .6]);text(ax,1,5,'threshold','VerticalAlignment','bottom');exportFigure(fig,fullfile(outputDirectory,'line-arrow'));detail='4 lines + arrow + text compiled';clear c;
    end
    function detail = figureSet()
        [f1,a1,c1]=lineFigure();text(a1,1,2,'Text');[f2,~,c2]=lineFigure();annotation(f2,'arrow',[.2 .7],[.3 .8]);f3=figure('Visible','off');c3=onCleanup(@()close(f3));a=axes('Parent',f3,'Position',[.1 .1 .7 .7]);plot(a,1:3);b=axes('Parent',f3,'Position',[.6 .6 .25 .25]);plot(b,1:3);text(b,2,2,'Inset');entries=struct('figure',{f1,f2,f3},'name',{'text','arrow','overlay'},'width',{[],[],[]});dir=fullfile(outputDirectory,'set');r=m2t.exportSet(entries,dir,'Overwrite',true,'ContinueOnError',true);assert(r.success&&r.summary.succeeded==3&&exist(r.manifestPath,'file')==2);first=fileread(r.manifestPath);r=m2t.exportSet(entries,dir,'Overwrite',true,'ContinueOnError',true);assert(r.success&&strcmp(first,fileread(r.manifestPath)));detail='three annotated entries and deterministic manifest';clear c1 c2 c3;
    end
    function detail = labelsRemainAxes()
        [fig,ax,c]=lineFigure();xlabel(ax,'X');ylabel(ax,'Y');title(ax,'T');ir=read(fig);assert(isempty(ir.annotations)&&strcmp(ir.axes{1}.xlabel.value,'X')&&strcmp(ir.axes{1}.ylabel.value,'Y')&&strcmp(ir.axes{1}.title.value,'T'));detail='xlabel/ylabel/title remain axes TextIR';clear c;
    end
    function detail = arbitraryGroup()
        [fig,ax,c]=lineFigure();g=hggroup('Parent',ax);line('Parent',g,'XData',1:3,'YData',1:3);expectError(@()read(fig),'M2T2:E001:UnsupportedObject','type=hggroup');detail='arbitrary hggroup remains unsupported';clear c;
    end
    function detail = unsupportedShapes()
        shapes={'rectangle','ellipse','textbox'};for i=1:numel(shapes),[fig,~,c]=lineFigure();annotation(fig,shapes{i},[.2 .2 .2 .1]);expectError(@()read(fig),'M2T2:E013:UnsupportedAnnotationType','shape');clear c;end;detail='rectangle, ellipse and textbox rejected precisely';
    end
    function ir = read(fig),ir=m2t2.reader.readFigure(fig);end
    function n = onlyAnnotation(ir),assert(numel(ir.annotations)==1);n=ir.annotations{1};end
    function r = exportFigure(fig,dir,varargin),ensureDirectory(dir);r=m2t.export(fig,fullfile(dir,'figure'),'Overwrite',true,varargin{:});if ~r.success,error('M2T:M51ExportFailed','%s',diagnostics(r));end;assert(exist(r.pdfPath,'file')==2&&dirInfo(r.pdfPath).bytes>0);end
end

function [fig,ax,cleanup] = lineFigure()
    fig=figure('Visible','off');cleanup=onCleanup(@()closeIfValid(fig));ax=axes('Parent',fig);plot(ax,0:3,[0 1 4 9]);
end
function expectError(callback,id,fragment)
    caught=false;try,callback();catch err,caught=strcmp(err.identifier,id)&&contains(err.message,fragment);end;assert(caught);
end
function value=diagnostics(result),if isempty(result.diagnostics),value=result.status;else,value=result.diagnostics(1).message;end,end
function value=dirInfo(path),value=dir(path);end
function closeIfValid(fig),if isgraphics(fig),close(fig);end,end
function ensureDirectory(path),if exist(path,'dir')~=7,mkdir(path);end,end
function writeRows(path,rows),fid=fopen(path,'wb');assert(fid>=0);c=onCleanup(@()fclose(fid));fprintf(fid,'case\tstatus\tdetail\tlayer\n');for k=1:size(rows,1),fprintf(fid,'%s\t%s\t%s\t%s\n',rows{k,:});end;clear c;end
function value=oneLine(value),value=regexprep(value,'[\r\n\t]+',' ');end
function value=identifier(value),if isempty(value),value='<none>';end,end
