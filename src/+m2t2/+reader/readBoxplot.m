function node=readBoxplot(handle,axesHandle,path,axesId)
%READBOXPLOT Read resolved statistics from a validated MATLAB boxplot.
    if ~m2t2.reader.isBoxplotObject(handle,axesHandle)
        fail('M2T2:E028:AmbiguousBoxplotCompound','AmbiguousBoxplotCompound',path,'signature is incomplete');
    end
    args=getappdata(handle,'inputArgs');
    orientation=option(args,'Orientation','vertical');
    if ~strcmpi(orientation,'vertical')
        fail('M2T2:E024:UnsupportedBoxplotOrientation','UnsupportedBoxplotOrientation',path,orientation);
    end
    if getappdata(handle,'notchon')
        fail('M2T2:E029:UnsupportedBoxplotNotch','UnsupportedBoxplotNotch',path,'notched boxes');
    end
    requireOption(args,'PlotStyle','traditional',path);
    requireOption(args,'BoxStyle','filled',path);
    requireOption(args,'MedianStyle','line',path);
    stats=getappdata(handle,'boxvalplot');positions=reshape(double(getappdata(handle,'gpos')),1,[]);
    required={'wlo','q1','q2','q3','whi','outliers'};
    if height(stats)~=numel(positions)||any(~ismember(required,stats.Properties.VariableNames))
        fail('M2T2:E027:MalformedBoxplotStatistics','MalformedBoxplotStatistics',path,'resolved statistics table is incomplete');
    end
    numeric=[stats.wlo stats.q1 stats.q2 stats.q3 stats.whi];
    if isempty(positions)||any(~isfinite(positions))||any(diff(positions)<=0)
        fail('M2T2:E030:UnsupportedBoxplotGrouping','UnsupportedBoxplotGrouping',path,'group positions must be finite and strictly increasing');
    end
    if any(~isfinite(numeric(:)))||any(numeric(:,1)>numeric(:,2)|numeric(:,2)>numeric(:,3)|numeric(:,3)>numeric(:,4)|numeric(:,4)>numeric(:,5))
        fail('M2T2:E027:MalformedBoxplotStatistics','MalformedBoxplotStatistics',path,'statistics are nonfinite or unordered');
    end
    roles=roleChildren(handle,path,numel(positions));
    try
        boxStyle=uniformLine(roles.box,path,'Box');medianStyle=uniformLine(roles.median,path,'Median');
        whiskerStyle=uniformLine(roles.whisker,path,'Whisker');outlierStyle=uniformOutliers(roles.outlier,path);
    catch err
        if strcmp(err.identifier,'M2T2:E004:NormalizationFailed')
            fail('M2T2:E026:UnsupportedBoxplotStyle','UnsupportedBoxplotStyle',path,err.message);
        end
        rethrow(err);
    end
    widths=zeros(1,numel(roles.median));
    for k=1:numel(roles.median),x=double(get(roles.median(k),'XData'));widths(k)=max(x)-min(x);end
    if any(~isfinite(widths))||any(widths<=0)||max(abs(widths-widths(1)))>1e-10
        fail('M2T2:E026:UnsupportedBoxplotStyle','UnsupportedBoxplotStyle',path,'nonuniform box widths');
    end
    [outX,outY]=outliers(stats,positions,path);
    node=m2t2.ir.makeBoxplotSeries();node.owner=m2t2.ir.makeOwner('axes',axesId);
    node.positions=positions;node.lowerWhisker=reshape(double(stats.wlo),1,[]);
    node.q1=reshape(double(stats.q1),1,[]);node.median=reshape(double(stats.q2),1,[]);
    node.q3=reshape(double(stats.q3),1,[]);node.upperWhisker=reshape(double(stats.whi),1,[]);
    node.outlierPositions=outX;node.outlierValues=outY;node.boxWidth=widths(1);
    node.boxColor=boxStyle.color;node.boxLineWidth=boxStyle.width;
    node.medianColor=medianStyle.color;node.medianLineWidth=medianStyle.width;node.medianLineStyle=medianStyle.style;
    node.whiskerColor=whiskerStyle.color;node.whiskerLineWidth=whiskerStyle.width;node.whiskerLineStyle=whiskerStyle.style;
    node.outlierMarker=outlierStyle.marker;node.outlierMarkerSize=outlierStyle.size;node.outlierColor=outlierStyle.color;
    node.visible=strcmpi(get(handle,'Visible'),'on');
    node.displayName=m2t2.ir.makeText(m2t2.util.textValue(get(handle,'DisplayName'),[path '.DisplayName']),'plain');
end

function value=option(args,name,default)
    value=default;
    for k=1:numel(args)-1
        if ischar(args{k})&&strcmpi(args{k},name),value=char(args{k+1});return;end
    end
end
function requireOption(args,name,expected,path)
    actual=option(args,name,expected);
    if ~strcmpi(actual,expected),fail('M2T2:E025:UnsupportedBoxplotVariant','UnsupportedBoxplotVariant',path,[name '=' actual]);end
end
function roles=roleChildren(handle,path,count)
    children=allchild(handle);roles=struct('box',[],'median',[],'whisker',[],'outlier',[]);
    for k=1:numel(children)
        if ~strcmp(get(children(k),'Type'),'line')
            fail('M2T2:E028:AmbiguousBoxplotCompound','AmbiguousBoxplotCompound',path,'non-line child');
        end
        tag=get(children(k),'Tag');
        switch tag
            case 'Box',roles.box(end+1)=children(k); %#ok<AGROW>
            case 'Median',roles.median(end+1)=children(k); %#ok<AGROW>
            case 'Whisker',roles.whisker(end+1)=children(k); %#ok<AGROW>
            case 'Outliers',roles.outlier(end+1)=children(k); %#ok<AGROW>
            otherwise,fail('M2T2:E028:AmbiguousBoxplotCompound','AmbiguousBoxplotCompound',path,['unknown child role ' tag]);
        end
    end
    if any([numel(roles.box),numel(roles.median),numel(roles.whisker),numel(roles.outlier)]~=count)
        fail('M2T2:E028:AmbiguousBoxplotCompound','AmbiguousBoxplotCompound',path,'role counts do not match group count');
    end
end
function s=uniformLine(handles,path,role)
    s=lineStyle(handles(1),path,role);
    for k=2:numel(handles),v=lineStyle(handles(k),path,role);if ~isequal(v,s),fail('M2T2:E026:UnsupportedBoxplotStyle','UnsupportedBoxplotStyle',path,[role ' style varies by group']);end,end
end
function s=lineStyle(h,path,role)
    s=struct('color',m2t2.util.normalizeColor(get(h,'Color'),[path '.' role '.Color']), ...
        'width',double(get(h,'LineWidth')),'style',m2t2.util.normalizeLineStyle(get(h,'LineStyle'),[path '.' role '.LineStyle']));
end
function s=uniformOutliers(handles,path)
    first=handles(1);s=struct('color',markerColor(first,[path '.Outliers.MarkerEdgeColor']), ...
        'marker',m2t2.util.normalizeMarker(get(first,'Marker'),[path '.Outliers.Marker']), ...
        'size',double(get(first,'MarkerSize')));
    if strcmp(s.marker,'none'),fail('M2T2:E026:UnsupportedBoxplotStyle','UnsupportedBoxplotStyle',path,'outlier marker is none');end
    for k=2:numel(handles)
        v=struct('color',markerColor(handles(k),[path '.Outliers.MarkerEdgeColor']), ...
            'marker',m2t2.util.normalizeMarker(get(handles(k),'Marker'),[path '.Outliers.Marker']), ...
            'size',double(get(handles(k),'MarkerSize')));
        if ~isequal(v,s),fail('M2T2:E026:UnsupportedBoxplotStyle','UnsupportedBoxplotStyle',path,'outlier style varies by group');end
    end
end
function color=markerColor(handle,path)
    value=get(handle,'MarkerEdgeColor');if ischar(value)&&strcmpi(value,'auto'),value=get(handle,'Color');end
    color=m2t2.util.normalizeColor(value,path);
end
function [x,y]=outliers(stats,positions,path)
    x=[];y=[];
    for k=1:numel(positions)
        values=reshape(double(stats.outliers{k}),1,[]);
        if any(~isfinite(values)),fail('M2T2:E027:MalformedBoxplotStatistics','MalformedBoxplotStatistics',path,'outliers must be finite');end
        x=[x repmat(positions(k),1,numel(values))];y=[y values]; %#ok<AGROW>
    end
end
function fail(id,name,path,reason)
    error(id,'M2T2-%s %s: path=%s reason=%s',id(6:9),name,path,reason);
end
