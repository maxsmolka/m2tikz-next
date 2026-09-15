function node=orderScatter3(node,axesNode)
%ORDERSCATTER3 Stable far-to-near billboard order; coordinates stay exact.
    if ~strcmp(axesNode.sceneOrder,'depth') || isempty(node.x),return;end
    az=axesNode.view(1)*pi/180;el=axesNode.view(2)*pi/180;
    direction=[sin(az)*cos(el),-cos(az)*cos(el),sin(el)];
    signs=1-2*strcmp({axesNode.xdirection,axesNode.ydirection,axesNode.zdirection},'reverse');
    weights=direction.*signs./axesNode.dataAspectRatio;
    depth=node.x(:)*weights(1)+node.y(:)*weights(2)+node.z(:)*weights(3);
    [~,order]=sortrows([depth,(1:numel(depth))'],[1 2]);order=reshape(order,1,[]);
    node.x=node.x(order);node.y=node.y(order);node.z=node.z(order);
    if strcmp(node.sizeMode,'per_point'),node.markerSize=node.markerSize(order);end
    if strcmp(node.colorMode,'per_point_rgb'),node.colorData=node.colorData(order,:);
    elseif strcmp(node.colorMode,'scalar_mapped'),node.colorData=node.colorData(order);end
end
