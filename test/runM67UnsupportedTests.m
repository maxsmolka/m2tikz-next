function summary=runM67UnsupportedTests(outputDirectory)
%RUNM67UNSUPPORTEDTESTS Native runtime traversal, diagnostics and no-output gate.
    root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
    if nargin<1,outputDirectory=fullfile(root,'.audit','m67-unsupported');end
    if exist(outputDirectory,'dir')~=7,mkdir(outputDirectory);end
    cases={'unknown_group','hidden_unknown_group','hidden_panel','axes_hidden', ...
        'axis_top','minor_grid','rotated_ticks','marker_face','marker_edge','clipping', ...
        'text_background','hidden_colorbar','tagged_text','hidden_line', ...
        'hidden_title','legend_subset','legend_reorder','ordinary_colorbar','repeat', ...
        'vector_one_row','hybrid_one_row','surface_camera','depth_scene','child_scene', ...
        'compound_text','scalar_ir_log','dark_axes','transparent_dark_canvas','background_white','background_none','image_clipping','scatter_clipping','text_clipping','surface_marker'};
    native=~exist('OCTAVE_VERSION','builtin');
    if native,cases=[cases,{'marker_indices','subtitle','legend_title','legend_reverse', ...
        'colorbar_limits','error_caps','unknown_annotation','hidden_dual_child','tiled_unknown', ...
        'box_median_changed','box_child_hidden','box_unknown_child','surface_log_color','brush_data','datatip','bar_datatip'}];
    else,cases=[cases,{'bar_extra_child','errorbar_extra_child','fake_errorbar', ...
        'bar_geometry_changed','error_geometry_changed','error_child_style','error_boxes','error_horizontal','error_xy', ...
        'scatter_patch_extra','scatter_patch_moved','scatter_patch_style','scatter_patch_color', ...
        'scatter_large_rgb','scatter_large_sizes','legend_extra_text','colorbar_extra_line','colorbar_modified_image'}];end
    rows=cell(numel(cases),3);failures=0;
    for k=1:numel(cases)
        try,runCase(cases{k});status='PASS';detail='assertions passed';
        catch err,status='FAIL';detail=regexprep([err.identifier ' ' err.message],'[\r\n\t]+',' ');failures=failures+1;end
        rows(k,:)={cases{k},status,detail};
    end
    report=sprintf('case\tstatus\tdetail\n');for k=1:size(rows,1),report=[report sprintf('%s\t%s\t%s\n',rows{k,:})];end %#ok<AGROW>
    m2t.internal.writeTextFile(fullfile(outputDirectory,'m67-results.tsv'),report);fprintf('%s',report);
    summary=struct('tests',numel(cases),'failures',failures);assert(failures==0,'M6.7 capability matrix failed.');
    fprintf('M67_CAPABILITY_PASS: %d/%d nativeMatlab=%d\n',numel(cases),numel(cases),native);
    function runCase(name)
        f=figure('Visible','off','Color','w');guard=onCleanup(@()close(f));a=axes('Parent',f);h=plot(a,1:3,[2 1 3]);set(a,'Color','w');
        code='M2T2:E007:UnsupportedProperty';negative=true;
        switch name
            case 'unknown_group',hggroup('Parent',a);code='M2T2:E001:UnsupportedObject';
            case 'hidden_unknown_group',hggroup('Parent',a,'Visible','off','HandleVisibility','off');code='M2T2:E001:UnsupportedObject';
            case 'hidden_panel',uipanel('Parent',f,'Visible','off');code='M2T2:E001:UnsupportedObject';
            case 'axes_hidden',set(a,'Visible','off');
            case 'axis_top',set(a,'XAxisLocation','top');
            case 'minor_grid',set(a,'XMinorGrid','on');
            case 'dark_axes',set(a,'Color',[0 0 0]);set(h,'Color',[1 1 1]);
            case 'transparent_dark_canvas',set(a,'Color','none');set(f,'Color',[0 0 0]);set(h,'Color',[1 1 1]);
            case {'background_white','background_none'}
                value='white';if strcmp(name,'background_none'),value='none';end;set(a,'Color',value);
                ir=m2t2.reader.readFigure(f);assert(strcmp(ir.axes{1}.background,value));tex=m2t2.render.renderPgfplots(ir,true);
                assert(~isempty(strfind(tex,['axis background/.style={fill=' value '}']))); %#ok<STREMP>
                assert(strcmp(tex,m2t2.render.renderPgfplots(m2t2.ir.fromJson(jsonencode(ir)),true)));negative=false;
            case 'image_clipping',cla(a);h=imagesc(a,[0 1;1 0]);set(h,'Clipping','off');
            case 'scatter_clipping',cla(a);h=scatter(a,1:3,1:3);set(h,'Clipping','off');
            case 'text_clipping',text(2,2,'text','Parent',a,'Clipping','on');
            case 'brush_data',set(h,'BrushData',[1 0 0]);
            case 'datatip',datatip(h,2,1);code='M2T2:E001:UnsupportedObject';
            case 'bar_datatip',cla(a);h=bar(a,1:3);datatip(h,2,2);code='M2T2:E001:UnsupportedObject';
            case 'surface_marker',cla(a);[x,y]=meshgrid(-1:1);h=surf(a,x,y,x.*y,'FaceColor','interp','EdgeColor','none','Marker','o');view(a,30,25);
            case 'rotated_ticks',set(a,'XTickLabelRotation',20);
            case 'marker_face',set(h,'Marker','o','MarkerFaceColor',[1 0 0]);
            case 'marker_edge',set(h,'Marker','o','MarkerEdgeColor',[1 0 0]);
            case 'marker_indices',set(h,'Marker','o','MarkerIndices',[1 3]);
            case 'clipping',set(h,'Clipping','off');
            case 'text_background',text(2,2,'threshold','Parent',a,'BackgroundColor',[1 1 0]);
            case 'hidden_colorbar',cb=colorbar(a);set(cb,'Visible','off');
            case 'subtitle',subtitle(a,'hidden semantic subtitle');
            case 'legend_title',l=legend(a,h,'line');title(l,'group');
            case 'legend_reverse',l=legend(a,h,'line');set(l,'Direction','reverse');
            case 'colorbar_limits',cb=colorbar(a);set(cb,'Limits',[.2 .8]);code='M2T2:E011:UnsupportedColorbarOwnership';
            case 'error_caps',cla(a);h=errorbar(a,1:3,[2 1 3],.2);set(h,'CapSize',20);
            case 'unknown_annotation',annotation(f,'textbox',[.2 .2 .3 .2],'String','Important');code='M2T2:E013:UnsupportedAnnotationType';
            case 'hidden_dual_child',yyaxis(a,'right');h=plot(a,1:3,[4 5 6]);set(h,'HandleVisibility','off');code='M2T2:E059:AmbiguousDualYOwnership';
            case 'tiled_unknown',delete(a);t=tiledlayout(f,1,1);a=nexttile(t);h=plot(a,1:3);hggroup('Parent',a,'HandleVisibility','off');code='M2T2:E001:UnsupportedObject';
            case 'bar_extra_child',cla(a);h=bar(a,1:3);text('Parent',h,'Position',[1 1],'String','extra');code='M2T2:E001:UnsupportedObject';
            case 'errorbar_extra_child',cla(a);h=errorbar(a,1:3,[2 1 3],.2);line('Parent',h,'XData',[1 2],'YData',[9 9]);code='M2T2:E001:UnsupportedObject';
            case 'fake_errorbar',g=hggroup('Parent',a);addproperty('ldata',g,'data',[1 1 1]);addproperty('udata',g,'data',[1 1 1]);code='M2T2:E001:UnsupportedObject';
            case 'bar_geometry_changed'
                cla(a);h=bar(a,1:3);p=findobj(h,'Type','patch');set(p,'YData',get(p,'YData')+1);code='M2T2:E023:AmbiguousBarOwnership';
            case 'error_geometry_changed'
                cla(a);h=errorbar(a,1:3,[2 1 3],.2);c=allchild(h);for q=1:numel(c),if numel(get(c(q),'YData'))>3,set(c(q),'YData',get(c(q),'YData')+1);end,end
            case 'error_boxes',cla(a);h=errorbar(a,1:3,[2 1 3],.2,'#~');
            case 'error_child_style',cla(a);h=errorbar(a,1:3,[2 1 3],.2);q=allchild(h);set(q(1),'LineWidth',3);
            case 'legend_extra_text',l=legend(a,h,'line');text('Parent',l,'Position',[.5 .5],'String','extra');
            case 'colorbar_extra_line',cb=colorbar(a);line('Parent',cb,'XData',[0 1],'YData',[.5 .5]);
            case 'colorbar_modified_image',cb=colorbar(a);p=findobj(cb,'Type','image');set(p,'CData',flipud(get(p,'CData')));
            case {'scatter_patch_extra','scatter_patch_moved','scatter_patch_style','scatter_patch_color'}
                cla(a);h=scatter(a,1:4,1:4,25,(1:4).','filled');p=allchild(h);
                if strcmp(name,'scatter_patch_extra'),patch('Parent',h,'XData',1,'YData',1);
                elseif strcmp(name,'scatter_patch_moved'),set(p(1),'XData',99);
                elseif strcmp(name,'scatter_patch_style'),set(p(1),'MarkerSize',12);
                else,set(p(1),'FaceVertexCData',99);end
            case {'scatter_large_rgb','scatter_large_sizes'}
                cla(a);n=101;sz=25;rgb=[linspace(0,1,n).' zeros(n,1) ones(n,1)];
                if strcmp(name,'scatter_large_sizes'),sz=20+mod(1:n,3);rgb=[0 0 1];end
                h=scatter(a,1:n,1:n,sz,rgb,'filled');ir=m2t2.reader.readFigure(f);s=ir.axes{1}.series{1};assert(numel(s.x)==n);
                if strcmp(name,'scatter_large_rgb'),assert(isequal(s.colorData,rgb));else,assert(isequal(s.markerSize,sqrt(sz)));end;negative=false;
            case {'error_horizontal','error_xy'}
                cla(a);format='>';if strcmp(name,'error_xy'),format='~>';end
                if strcmp(name,'error_xy'),h=errorbar(a,1:3,[2 1 3],.2,.4,format);
                else,h=errorbar(a,1:3,[2 1 3],.2,format);end
                ir=m2t2.reader.readFigure(f);s=ir.axes{1}.series{1};assert(isequal(s.xNegative,[.2 .2 .2]));
                if strcmp(name,'error_xy'),assert(isequal(s.yNegative,[.4 .4 .4]));else,assert(all(s.yNegative==0));end;negative=false;
            case {'box_median_changed','box_child_hidden','box_unknown_child'}
                cla(a);boxplot(a,[(1:20)';80],'PlotStyle','traditional','BoxStyle','filled','MedianStyle','line','Symbol','xk');g=findobj(a,'Tag','boxplot');
                if strcmp(name,'box_median_changed'),q=findobj(g,'Tag','Median');set(q,'YData',get(q,'YData')+1);
                elseif strcmp(name,'box_child_hidden'),set(findobj(g,'Tag','Whisker'),'Visible','off');
                else,text('Parent',g,'Position',[1 1],'String','extra');end
                code='M2T2:E028:AmbiguousBoxplotCompound';
            case {'surface_camera','depth_scene','child_scene','surface_log_color'}
                cla(a);[x,y]=meshgrid(-1:1);surf(a,x,y,ones(3),x+2,'FaceColor','interp','EdgeColor','none');view(a,30,25);
                if strcmp(name,'surface_camera'),set(a,'CameraTarget',[.1 0 0]);code='M2T2:E062:Unsupported3DCamera';
                elseif strcmp(name,'surface_log_color'),set(a,'ColorScale','log','CLim',[1 3]);code='M2T2:E034:UnsupportedSurfaceColorMode';
                else,hold(a,'on');plot3(a,[-1 1],[0 0],[1 1]);set(a,'SortMethod','depth');code='M2T2:E063:Unsupported3DScene';
                    if strcmp(name,'child_scene'),set(a,'SortMethod','childorder');ir=m2t2.reader.readFigure(f);assert(numel(ir.axes{1}.series)==2&&strcmp(ir.axes{1}.sceneOrder,'childorder'));negative=false;end
                end
            case 'compound_text'
                cla(a);g=hggroup('Parent',a,'Tag','patterngroup');[x,y]=meshgrid(-1:1);surface('Parent',g,'XData',x,'YData',y,'ZData',x.*y,'CData',x.*y,'Tag','3D polar plot','FaceColor','interp','EdgeColor','none');
                line('Parent',g,'XData',[0 1],'YData',[0 1],'ZData',[0 1]);patch('Parent',g,'Faces',[1 2 3],'Vertices',[0 0 0;1 0 0;0 1 0],'FaceColor',[1 0 0]);
                text('Parent',g,'Position',[0 0 0],'String','semantic compound text');view(a,30,25);code='M2T2:E001:UnsupportedObject';
            case 'scalar_ir_log'
                s=m2t2.ir.makeScatterSeries();s.x=[1 2];s.y=[1 2];s.colorMode='scalar_mapped';s.colorData=[1 2];s.edgeMode='data';
                ax=m2t2.ir.makeAxes();ax.series={s};ax.colorMapping=m2t2.ir.makeColorMapping([1 2],'log');
                try,m2t2.ir.validate(m2t2.ir.makeFigure({ax}));error('M2T:ExpectedFailure','accepted');
                catch err,assert(strcmp(err.identifier,'M2T2:E003:InvalidIR'));end;negative=false;
            case 'tagged_text'
                text(2,2,'semantic-tag','Parent',a,'Tag','colorbar');ir=m2t2.reader.readFigure(f);
                assert(numel(ir.annotations)==1&&strcmp(ir.annotations{1}.text.value,'semantic-tag'));negative=false;
            case 'hidden_line'
                set(h,'HandleVisibility','off');ir=m2t2.reader.readFigure(f);assert(numel(ir.axes{1}.series)==1);
                set(h,'Visible','off');ir=m2t2.reader.readFigure(f);assert(~ir.axes{1}.series{1}.visible);negative=false;
            case 'hidden_title'
                q=title(a,'do-not-render');set(q,'Visible','off');ir=m2t2.reader.readFigure(f);assert(isempty(ir.axes{1}.title.value));negative=false;
            case {'legend_subset','legend_reorder'}
                hold(a,'on');h2=plot(a,1:3,[3 2 1]);
                if strcmp(name,'legend_subset'),legend(a,h2,'second');expected={'axes-1-series-2'};
                else,legend(a,[h2 h],{'second','first'});expected={'axes-1-series-2','axes-1-series-1'};end
                ir=m2t2.reader.readFigure(f);actual=cellfun(@(e)e.seriesId,ir.axes{1}.legend.entries,'UniformOutput',false);assert(isequal(actual,expected));negative=false;
            case 'ordinary_colorbar'
                cb=colorbar(a);ir=m2t2.reader.readFigure(f);assert(numel(ir.elements)==1); %#ok<NASGU>
                negative=false;
            case 'repeat'
                before={get(a,'Children'),get(h,'XData'),get(h,'YData'),get(a,'XLim'),get(f,'Visible')};
                ir=m2t2.reader.readFigure(f);again=m2t2.reader.readFigure(f);assert(strcmp(jsonencode(ir),jsonencode(again)));
                after={get(a,'Children'),get(h,'XData'),get(h,'YData'),get(a,'XLim'),get(f,'Visible')};assert(isequaln(before,after));negative=false;
            case {'vector_one_row','hybrid_one_row'}
                cla(a);imagesc(a,[0 .5 1]);ir=m2t2.reader.readFigure(f);
                if strcmp(name,'vector_one_row')
                    try,m2t2.render.renderPgfplots(ir,true);error('M2T:ExpectedFailure','accepted');
                    catch err,assert(strcmp(err.identifier,'M2T2:E054:UnsupportedImageCoordinates'));end
                    r=m2t.export(f,fullfile(outputDirectory,name),'Overwrite',true);assert(~r.success&&exist(r.texPath,'file')~=2);
                else,p=m2t2.render.makePgfplotsPlan(ir,true,m2t2.render.defaultConfig(),'hybrid','owned-assets');assert(p.assets(1).height==1&&p.assets(1).width==3);end
                negative=false;
        end
        if negative
            % Isolate the intended guard from runtime theme-dependent defaults.
            if ~any(strcmp(name,{'dark_axes','transparent_dark_canvas'})),set(a,'Color','w');end
            before={get(f,'Visible'),get(a,'XLim'),get(a,'YLim'),allchild(a)};
            first=m2t.internal.analyzeFigure(f);second=m2t.internal.analyzeFigure(f);
            assert(strcmp(first.classification,'unsupported')&&strcmp(first.diagnostics(1).code,code), ...
                ['Expected ' code '; actual ' first.classification ': ' first.diagnostics(1).code ' ' first.diagnostics(1).message]);
            assert(isequal(first.diagnostics,second.diagnostics));
            base=fullfile(outputDirectory,['rejected-' name]);m2t.internal.writeTextFile([base '.tex'],'sentinel');
            r=m2t.export(f,base,'Overwrite',true);assert(~r.success&&strcmp(r.status,'unsupported'));
            assert(strcmp(fileread([base '.tex']),'sentinel')&&exist([base '.pdf'],'file')~=2);
            assert(isequaln(before,{get(f,'Visible'),get(a,'XLim'),get(a,'YLim'),allchild(a)}));
        end
        clear guard;
    end
end
