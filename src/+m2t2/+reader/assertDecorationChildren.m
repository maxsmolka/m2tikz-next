function assertDecorationChildren(handle,path,role,labelHandle,colorCount)
%ASSERTDECORATIONCHILDREN Guard Octave's axes-backed display containers.
    if ~strcmp(get(handle,'Type'),'axes'),return;end
    if nargin<4,labelHandle=[];end
    if nargin<5,colorCount=0;end
    labels=[get(handle,'XLabel') get(handle,'YLabel') get(handle,'ZLabel') get(handle,'Title')];
    children=allchild(handle);images=0;
    for k=1:numel(children)
        child=children(k);type=get(child,'Type');
        if any(child==labels)
            if isequal(child,labelHandle)||isempty(get(child,'String')),continue;end
            fail(path,'unrepresented decoration label');
        end
        if strcmp(role,'legend')
            linked=getappdata(child,'handle');
            if ~isscalar(linked)||~ishandle(linked)||~any(strcmp(type,{'line','patch','text'}))
                fail(path,'unlinked legend child');
            end
        elseif strcmp(type,'image')
            images=images+1;
            if ~isequal(reshape(double(get(child,'CData')),1,[]),1:colorCount)|| ...
                    ~strcmp(get(child,'CDataMapping'),'direct')||~strcmp(get(child,'Visible'),'on')|| ...
                    ~isequal(get(child,'AlphaData'),1)
                fail(path,'modified colorbar image');
            end
        else
            fail(path,'unknown colorbar child');
        end
    end
    if strcmp(role,'colorbar')&&images~=1,fail(path,'colorbar image count');end
end
function fail(path,reason)
    error('M2T2:E007:UnsupportedProperty','M2T2-E007 UnsupportedProperty: path=%s %s',path,reason);
end
