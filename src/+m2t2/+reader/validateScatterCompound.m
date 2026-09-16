function validateScatterCompound(handle,node,path)
%VALIDATESCATTERCOMPOUND Prove the observed Octave gnuplot patch partition.
    children=flipud(allchild(handle));count=numel(node.x);groups={};
    sizes=node.markerSize;if isscalar(sizes),sizes=repmat(sizes,1,count);end
    if count<=100
        groups=num2cell(1:count);renderSizes=sizes;
    elseif strcmp(node.sizeMode,'constant')
        groups={1:count};renderSizes=node.markerSize;
    else
        rounded=ceil(sizes*10)/10;renderSizes=unique(rounded);
        for k=1:numel(renderSizes),groups{k}=find(rounded==renderSizes(k));end
    end
    if numel(children)~=numel(groups),fail(path,'patch partition count');end
    for k=1:numel(children)
        p=children(k);indices=groups{k};
        if ~isempty(allchild(p)),fail(path,'nested patch child');end
        for role={'x','y','z'}
            expected=[];if isfield(node,role{1}),expected=node.(role{1})(indices);end
            if ~isequal(reshape(get(p,[upper(role{1}) 'Data']),1,[]),reshape(expected,1,[])),fail(path,'patch coordinates');end
        end
        if node.visible&&~strcmp(get(p,'Visible'),'on'),fail(path,'hidden patch');end
        names={'FaceColor','EdgeColor','LineStyle','Clipping','Marker','LineWidth'};
        expected={'none','none','none','on',get(handle,'Marker'),get(handle,'LineWidth')};
        for j=1:numel(names),if ~isequal(get(p,names{j}),expected{j}),fail(path,['patch ' names{j}]);end,end
        if get(p,'MarkerSize')~=renderSizes(k),fail(path,'patch marker size');end
        for role={'Edge','Face'}
            name=['Marker' role{1} 'Color'];wanted=get(handle,name);actual=get(p,name);
            matches=isequal(actual,wanted);
            % Constructor uses resolved constant color instead of flat, and
            % can draw a same-color outline around an opaque filled marker.
            if strcmp(node.colorMode,'constant_rgb')
                if isequal(wanted,'flat'),matches=matches||isequal(actual,node.color);end
                if strcmp(role{1},'Edge')&&isequal(wanted,'none')&&~strcmp(node.faceMode,'none')
                    matches=matches||isequal(actual,get(p,'MarkerFaceColor'));
                end
            elseif count>100&&strcmp(node.colorMode,'per_point_rgb')&&isequal(wanted,'flat')
                matches=matches||isequal(actual,node.colorData(1,:));
            end
            if ~matches,fail(path,['patch ' name]);end
        end
        if ~strcmp(node.colorMode,'constant_rgb')
            wanted=node.colorData;if strcmp(node.colorMode,'scalar_mapped'),wanted=wanted(indices).';else,wanted=wanted(indices,:);end
            if count>100&&strcmp(node.colorMode,'per_point_rgb')
                % gnuplot's large-patch RGB display uses the first row; the
                % authoritative per-point parent RGB is retained in FigureIR.
                if ~isequal(get(p,'MarkerFaceColor'),node.colorData(1,:))&&~isequal(get(p,'MarkerEdgeColor'),node.colorData(1,:)),fail(path,'large RGB patch color');end
            elseif ~isequal(get(p,'FaceVertexCData'),wanted),fail(path,'patch color data');end
        end
    end
end
function fail(path,reason)
    error('M2T2:E007:UnsupportedProperty','M2T2-E007 UnsupportedProperty: path=%s inconsistent scatter compound %s',path,reason);
end
