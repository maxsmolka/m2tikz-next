function lines = renderScatter(node, colorName, colorMapping)
%RENDERSCATTER Render explicit size and color modes through PGFPlots scatter.
    if nargin<3,colorMapping=[];end
    is3d=strcmp(node.kind,'m2t2.scatter3');command='addplot';
    if is3d,command='addplot3';end
    if strcmp(node.sizeMode, 'per_point')
        lines={};start=1;
        while start<=numel(node.x)
            stop=start;
            while stop<numel(node.x) && node.markerSize(stop+1)==node.markerSize(start)
                stop=stop+1;
            end
            part=node;part.sizeMode='constant';part.markerSize=node.markerSize(start);
            part.x=node.x(start:stop);part.y=node.y(start:stop);
            if is3d,part.z=node.z(start:stop);end
            if strcmp(node.colorMode,'per_point_rgb')
                part.colorData=node.colorData(start:stop,:);part.color=part.colorData(1,:);
            elseif strcmp(node.colorMode,'scalar_mapped')
                part.colorData=node.colorData(start:stop);
            end
            % PGFPlots can defer 3-D painting until all plot definitions exist.
            % Each size run therefore owns distinct color and class names.
            partName=sprintf('%srun%d',colorName,start);bs=char(92);
            aliases={[bs 'colorlet{' partName '}{' colorName '}'], ...
                [bs 'colorlet{' partName 'edge}{' colorName 'edge}'], ...
                [bs 'colorlet{' partName 'face}{' colorName 'face}']};
            lines=[lines,aliases,m2t2.render.renderScatter(part,partName,colorMapping)]; %#ok<AGROW>
            start=stop+1;
        end
        return;
    end
    if strcmp(node.sizeMode, 'constant') && strcmp(node.colorMode, 'constant_rgb')
        options = m2t2.render.seriesOptions(node, colorName); bs = char(92);
        if is3d,coordinates=m2t2.render.formatCoordinates3(node.x,node.y,node.z);
        else,coordinates=m2t2.render.formatCoordinates(node.x,node.y);end
        lines = {[bs command '[' m2t2.util.joinCell(options, ',') '] coordinates {'], ...
                 coordinates, '};'};
        return;
    end

    bs = char(92); filled = ~strcmp(node.faceMode, 'none');
    options = {'only marks','scatter', ...
        ['mark=' m2t2.render.scatterMarkerName(node.marker, filled)], ...
        ['mark size=' m2t2.util.formatNumber(node.markerSize/2) 'pt'], ...
        'forget plot'};
    definitions = {};
    if strcmp(node.colorMode, 'scalar_mapped')
        if isempty(colorMapping),error('M2T2:E003:InvalidIR','M2T2-E003 InvalidIR: scalar scatter requires color mapping');end
        indices=m2t2.render.imageColorIndices(node.colorData,colorMapping,'scaled',1);
        [definitions,classes,meta]=mappedClasses(node,colorName,colorMapping,indices);
        options{end+1} = 'scatter src=explicit symbolic';
        options{end+1} = ['scatter/classes={' m2t2.util.joinCell(classes, ',') '}'];
    else
        options{end+1} = 'scatter src=explicit symbolic';
        if strcmp(node.colorMode, 'per_point_rgb')
            [definitions, classes, meta] = rgbClasses(node, colorName);
        else
            classes = {['m2t2class={' symbolicStyle(node,colorName,colorName) '}']};
            meta = repmat({'m2t2class'},1,numel(node.x));
        end
        options{end+1} = ['scatter/classes={' m2t2.util.joinCell(classes, ',') '}'];
    end
    rows = cell(1,numel(node.x));
    for k=1:numel(rows)
        position=[m2t2.util.formatNumber(node.x(k)) ' ' m2t2.util.formatNumber(node.y(k))];
        if is3d,position=[position ' ' m2t2.util.formatNumber(node.z(k))];end
        if strcmp(node.colorMode,'scalar_mapped'),position=[position ' ' m2t2.util.formatNumber(node.colorData(k))];end
        rows{k}=[position ' ' meta{k}];
    end
    columns='x=x,y=y,meta=meta';header='x y meta';
    if is3d,columns='x=x,y=y,z=z,meta=meta';header='x y z meta';end
    if strcmp(node.colorMode,'scalar_mapped')
        header='x y value meta';if is3d,header='x y z value meta';end
    end
    % Explicit roles must not inherit cycle-list marker colors/scalings.
    lines = [definitions, {[bs command '[' m2t2.util.joinCell(options, ',') '] table[' columns '] {'], ...
        header, m2t2.util.joinCell(rows,sprintf('\n')), '};'}];
end

function value=symbolicStyle(node,colorName,dataColor)
    value=['solid,draw=' role(node.edgeMode,[colorName 'edge'],dataColor) ...
        ',fill=' role(node.faceMode,[colorName 'face'],dataColor)];
    value=[value,visibilityStyle(node)];
end

function value=visibilityStyle(node)
    % PGF's filled markers stroke their path even with TikZ draw=none.
    value='';
    if strcmp(node.edgeMode,'none'),value=[value ',draw opacity=0'];end
    if strcmp(node.faceMode,'none'),value=[value ',fill opacity=0'];end
end

function value=role(mode,constantColor,dataColor)
    if strcmp(mode,'none'),value='none';elseif strcmp(mode,'constant'),value=constantColor;else,value=dataColor;end
end

function [definitions,classes,meta]=rgbClasses(node,colorName)
    definitions={};classes={};meta=cell(1,size(node.colorData,1));uniqueColors=zeros(0,3);
    for k=1:size(node.colorData,1)
        index=find(all(abs(uniqueColors-node.colorData(k,:))<1e-15,2),1);
        if isempty(index),index=size(uniqueColors,1)+1;uniqueColors(index,:)=node.colorData(k,:);end %#ok<AGROW>
        meta{k}=sprintf('%sclass%d',colorName,index);
    end
    bs=char(92);
    for k=1:size(uniqueColors,1)
        name=sprintf('%sp%d',colorName,k);c=uniqueColors(k,:);
        definitions{end+1}=[bs 'definecolor{' name '}{rgb}{' ...
            m2t2.util.formatNumber(c(1)) ',' m2t2.util.formatNumber(c(2)) ',' ...
            m2t2.util.formatNumber(c(3)) '}']; %#ok<AGROW>
        classes{end+1}=[sprintf('%sclass%d',colorName,k) '={' ...
            symbolicStyle(node,colorName,name) '}']; %#ok<AGROW>
    end
end

function [definitions,classes,meta]=mappedClasses(node,colorName,mapping,indices)
    % Resolve bins before finite decimal serialization; preserve raw values separately.
    used=unique(indices);definitions=cell(1,numel(used));classes=definitions;bs=char(92);
    meta=arrayfun(@(i)sprintf('%sindex%d',colorName,i),indices,'UniformOutput',false);
    for k=1:numel(used)
        name=sprintf('%smap%d',colorName,used(k));c=mapping.colormap(used(k)+1,:);
        definitions{k}=[bs 'definecolor{' name '}{rgb}{' m2t2.util.formatNumber(c(1)) ',' ...
            m2t2.util.formatNumber(c(2)) ',' m2t2.util.formatNumber(c(3)) '}'];
        classes{k}=[sprintf('%sindex%d',colorName,used(k)) '={' symbolicStyle(node,colorName,name) '}'];
    end
end
