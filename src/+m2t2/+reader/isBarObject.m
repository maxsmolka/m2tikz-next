function yes = isBarObject(handle, axesHandle)
%ISBAROBJECT Recognize a semantic bar by positive runtime capabilities.
    yes = false;
    try
        if ~sameHandle(get(handle, 'Parent'), axesHandle), return; end
        type = char(get(handle, 'Type'));
        required = {'XData','YData','BarWidth','BaseValue','Horizontal', ...
                    'BarLayout','FaceColor','EdgeColor','LineStyle','LineWidth'};
        for k = 1:numel(required), get(handle, required{k}); end
        if strcmp(type, 'bar')
            yes = true;
            return
        end
        if ~strcmp(type, 'hggroup'), return; end
        children = allchild(handle);
        patchCount = 0;
        for k = 1:numel(children)
            if strcmp(get(children(k), 'Type'), 'patch') && ...
                    sameHandle(get(children(k), 'Parent'), handle)
                patchCount = patchCount + 1;
            end
        end
        baseline = get(handle, 'Baseline');
        yes = patchCount == 1 && ishandle(baseline) && ...
              strcmp(get(baseline, 'Type'), 'line');
    catch
        yes = false;
    end
end

function yes = sameHandle(first, second)
    try, value = first == second; yes = isscalar(value) && logical(value);
    catch, yes = isequal(first, second); end
end
