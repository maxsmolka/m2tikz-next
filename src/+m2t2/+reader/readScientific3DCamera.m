function order=readScientific3DCamera(handle,node,path)
%READSCIENTIFIC3DCAMERA Explicit bounded camera and scene-order capability.
    modes={'CameraPositionMode','CameraTargetMode','CameraUpVectorMode','CameraViewAngleMode'};
    for k=1:numel(modes)
        if ~strcmpi(get(handle,modes{k}),'auto'),camera(path,modes{k});end
    end
    if ~all(strcmp({node.xscale,node.yscale,node.zscale},'linear')) || ...
            abs(node.view(2))>=90 || ...
            ~strcmpi(get(handle,'PlotBoxAspectRatioMode'),'auto')
        camera(path,'requires linear axes, non-polar elevation, and automatic plot box');
    end
    order=lower(char(get(handle,'SortMethod')));
    if ~any(strcmp(order,{'depth','childorder'}))
        scene(path,'unknown SortMethod');
    end
    visible=node.series(cellfun(@(item)item.visible,node.series));
    if strcmp(order,'depth') && numel(visible)>1
        scene(path,'multiple depth-sorted objects require a scene-wide occlusion implementation');
    end
    if ~all(cellfun(@(item)any(strcmp(item.kind, ...
            {'m2t2.scatter3','m2t2.line3','m2t2.surface','m2t2.patch3'})),node.series))
        scene(path,'mixed 2-D/3-D objects are unsupported');
    end
end
function camera(path,reason)
    error('M2T2:E062:Unsupported3DCamera','M2T2-E062 Unsupported3DCamera: path=%s reason=%s',path,reason);
end
function scene(path,reason)
    error('M2T2:E063:Unsupported3DScene','M2T2-E063 Unsupported3DScene: path=%s reason=%s',path,reason);
end
