function lines = renderScatter(node, colorName)
%RENDERSCATTER Render explicit size and color modes through PGFPlots scatter.
    if strcmp(node.sizeMode, 'per_point')
        lines={};start=1;
        while start<=numel(node.x)
            stop=start;
            while stop<numel(node.x) && node.markerSize(stop+1)==node.markerSize(start)
                stop=stop+1;
            end
            part=node;part.sizeMode='constant';part.markerSize=node.markerSize(start);
            part.x=node.x(start:stop);part.y=node.y(start:stop);
            if strcmp(node.colorMode,'per_point_rgb')
                part.colorData=node.colorData(start:stop,:);part.color=part.colorData(1,:);
            elseif strcmp(node.colorMode,'scalar_mapped')
                part.colorData=node.colorData(start:stop);
            end
            lines=[lines,m2t2.render.renderScatter(part,colorName)]; %#ok<AGROW>
            start=stop+1;
        end
        return;
    end
    if strcmp(node.sizeMode, 'constant') && strcmp(node.colorMode, 'constant_rgb')
        options = m2t2.render.seriesOptions(node, colorName); bs = char(92);
        lines = {[bs 'addplot+[' m2t2.util.joinCell(options, ',') '] coordinates {'], ...
                 m2t2.render.formatCoordinates(node.x, node.y), '};'};
        return;
    end

    bs = char(92); filled = ~strcmp(node.faceMode, 'none');
    options = {'only marks','scatter', ...
        ['mark=' m2t2.render.scatterMarkerName(node.marker, filled)], ...
        ['mark size=' m2t2.util.formatNumber(node.markerSize/2) 'pt'], ...
        'forget plot'};
    definitions = {};
    if strcmp(node.colorMode, 'scalar_mapped')
        options{end+1} = 'scatter src=explicit';
        options{end+1} = ['scatter/use mapped color={' mappedStyle(node, colorName) '}'];
        meta = arrayfun(@m2t2.util.formatNumber,node.colorData,'UniformOutput',false);
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
        rows{k}=[m2t2.util.formatNumber(node.x(k)) ' ' ...
            m2t2.util.formatNumber(node.y(k)) ' ' ...
            meta{k}];
    end
    lines = [definitions, {[bs 'addplot+[' m2t2.util.joinCell(options, ',') '] table[x=x,y=y,meta=meta] {'], ...
        'x y meta', m2t2.util.joinCell(rows,sprintf('\n')), '};'}];
end

function value=mappedStyle(node,colorName)
    value=['solid,draw=' role(node.edgeMode,[colorName 'edge'],'mapped color') ...
        ',fill=' role(node.faceMode,[colorName 'face'],'mapped color')];
end

function value=symbolicStyle(node,colorName,dataColor)
    value=['solid,draw=' role(node.edgeMode,[colorName 'edge'],dataColor) ...
        ',fill=' role(node.faceMode,[colorName 'face'],dataColor)];
end

function value=role(mode,constantColor,dataColor)
    if strcmp(mode,'none'),value='none';elseif strcmp(mode,'constant'),value=constantColor;else,value=dataColor;end
end

function [definitions,classes,meta]=rgbClasses(node,colorName)
    definitions={};classes={};meta=cell(1,size(node.colorData,1));uniqueColors=zeros(0,3);
    for k=1:size(node.colorData,1)
        index=find(all(abs(uniqueColors-node.colorData(k,:))<1e-15,2),1);
        if isempty(index),index=size(uniqueColors,1)+1;uniqueColors(index,:)=node.colorData(k,:);end %#ok<AGROW>
        meta{k}=sprintf('m2t2class%d',index);
    end
    bs=char(92);
    for k=1:size(uniqueColors,1)
        name=sprintf('%sp%d',colorName,k);c=uniqueColors(k,:);
        definitions{end+1}=[bs 'definecolor{' name '}{rgb}{' ...
            m2t2.util.formatNumber(c(1)) ',' m2t2.util.formatNumber(c(2)) ',' ...
            m2t2.util.formatNumber(c(3)) '}']; %#ok<AGROW>
        classes{end+1}=[sprintf('m2t2class%d',k) '={' ...
            symbolicStyle(node,colorName,name) '}']; %#ok<AGROW>
    end
end
