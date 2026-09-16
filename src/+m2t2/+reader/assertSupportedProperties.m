function assertSupportedProperties(handle,path,role)
%ASSERTSUPPORTEDPROPERTIES Central guards for unrepresented semantic state.
% Missing runtime properties are not invented; family readers validate data.
    switch role
        case 'axes'
            view=property(handle,'View',[0 90]);
            if abs(view(2)-90)>1e-10&&~all(strcmp({get(handle,'XScale'),get(handle,'YScale'),get(handle,'ZScale')},'linear'))
                error('M2T2:E062:Unsupported3DCamera','M2T2-E062 Unsupported3DCamera: path=%s requires linear 3-D axes',path);
            end
            require(handle,'Visible','on',path);
            require(handle,'Clipping','on',path);
            background=get(handle,'Color');
            if ~(isequal(background,[1 1 1])||strcmp(background,'none')),fail(path,'Color background');end
            require(handle,'XAxisLocation','bottom',path);
            rulers=property(handle,'YAxis',[]);
            if numel(rulers)<2,require(handle,'YAxisLocation','left',path);end
            subtitle=property(handle,'Subtitle',[]);
            if ~isempty(subtitle)&&~isempty(get(subtitle,'String')),fail(path,'Subtitle');end
            for name={'X','Y','Z'}
                require(handle,[name{1} 'TickLabelRotation'],0,path);
                require(handle,[name{1} 'MinorGrid'],'off',path);
                ruler=property(handle,[name{1} 'Axis'],[]);
                if ~isempty(ruler)&&~all(arrayfun(@(r)strcmp(class(r),'matlab.graphics.axis.decorator.NumericRuler'),ruler))
                    fail(path,[name{1} 'Axis type']);
                end
            end
            view=property(handle,'View',[0 90]);
            if abs(view(2)-90)<1e-10&&view(1)~=0,fail(path,'View azimuth');end
        case {'line','errorbar'}
            m2t2.reader.assertSupportedProperties(handle,path,'primitive');
            marker=property(handle,'Marker','none');
            if ~strcmp(marker,'none')
                indices=property(handle,'MarkerIndices',1:numel(get(handle,'XData')));
                if ~isequal(reshape(indices,1,[]),1:numel(get(handle,'XData'))),fail(path,'MarkerIndices');end
                edge=property(handle,'MarkerEdgeColor','auto');
                if ~isequal(edge,'auto')&&~isequal(edge,get(handle,'Color')),fail(path,'MarkerEdgeColor');end
                require(handle,'MarkerFaceColor','none',path);
            end
            if strcmp(role,'errorbar'),require(handle,'CapSize',6,path);end
        case 'legend'
            require(handle,'Direction','normal',path);
            title=property(handle,'Title',[]);
            if ~isempty(title)&&~isempty(get(title,'String')),fail(path,'Title');end
        case 'colorbar'
            require(handle,'Visible','on',path);
            if strcmp(property(handle,'Location','manual'),'manual'),fail(path,'manual orientation');end
        case 'text'
            require(handle,'Clipping','off',path);
            require(handle,'BackgroundColor','none',path);
            require(handle,'EdgeColor','none',path);
        case 'primitive'
            require(handle,'Clipping','on',path);
            brush=property(handle,'BrushData',[]);
            if any(brush(:)~=0),fail(path,'BrushData');end
            children=allchild(handle);
            if strcmp(get(handle,'Type'),'bar')
                baseline=property(handle,'Baseline',[]);
                children=children(~arrayfun(@(c)isequal(c,baseline),children));
            end
            if ~strcmp(get(handle,'Type'),'hggroup')&&~isempty(children)
                error('M2T2:E001:UnsupportedObject','M2T2-E001 UnsupportedObject: unrepresented primitive child at %s',path);
            end
    end
end
function require(handle,name,expected,path)
    actual=property(handle,name,expected);
    if ischar(expected),matches=strcmp(actual,expected);else,matches=isequal(actual,expected);end
    if ~matches,fail(path,name);end
end
function value=property(handle,name,default)
    try,value=get(handle,name);catch,value=default;end
end
function fail(path,name)
    error('M2T2:E007:UnsupportedProperty','M2T2-E007 UnsupportedProperty: path=%s property=%s is not represented',path,name);
end
