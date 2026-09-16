function node = readErrorbar(handle, path)
%READERRORBAR Normalize Octave hggroup or MATLAB ErrorBar public properties.
    m2t2.reader.assertSupportedProperties(handle,path,'errorbar');
    [x, y, gaps] = m2t2.util.normalizeXY(property(handle, {'XData'}, []), ...
                                          property(handle, {'YData'}, []), path);
    count = numel(x);
    xNegative = errorVector(property(handle, {'XNegativeDelta','LData','XLData'}, []), count, path, 'xNegative');
    xPositive = errorVector(property(handle, {'XPositiveDelta','UData','XUData'}, []), count, path, 'xPositive');
    yNegative = errorVector(property(handle, {'YNegativeDelta','LData'}, []), count, path, 'yNegative');
    yPositive = errorVector(property(handle, {'YPositiveDelta','UData'}, []), count, path, 'yPositive');

    % Octave exposes LData/UData for y and XLData/XUData for x. Avoid using
    % LData/UData as x errors when the dedicated x properties are absent.
    if hasProperty(handle, 'XLData')
        xNegative = errorVector(get(handle, 'XLData'), count, path, 'xNegative');
        xPositive = errorVector(get(handle, 'XUData'), count, path, 'xPositive');
    elseif ~hasProperty(handle, 'XNegativeDelta')
        xNegative = zeros(1, count); xPositive = zeros(1, count);
    end
    errorNames = {'xNegative','xPositive','yNegative','yPositive'};
    values = {xNegative,xPositive,yNegative,yPositive};
    for k = 1:numel(values)
        value = values{k};
        if any(~isfinite(value(~gaps))) || any(value(~gaps) < 0)
            error('M2T2:E004:NormalizationFailed', ...
                  'M2T2-E004 NormalizationFailed: path=%s.%s reason=errors must be finite and non-negative', ...
                  path, errorNames{k});
        end
        value(gaps) = NaN; values{k} = value;
    end

    node = m2t2.ir.makeErrorbarSeries();
    node.x = x; node.y = y;
    node.xNegative = values{1}; node.xPositive = values{2};
    node.yNegative = values{3}; node.yPositive = values{4};
    node.color = m2t2.util.normalizeColor(get(handle, 'Color'), [path '.color']);
    node.width = double(get(handle, 'LineWidth'));
    node.style = m2t2.util.normalizeLineStyle(get(handle, 'LineStyle'), [path '.style']);
    node.marker = m2t2.util.normalizeMarker(get(handle, 'Marker'), [path '.marker']);
    node.markerSize = double(get(handle, 'MarkerSize'));
    node.displayName = m2t2.ir.makeText( ...
        m2t2.util.textValue(get(handle, 'DisplayName'), [path '.displayName']), 'plain');
    node.visible = strcmpi(get(handle, 'Visible'), 'on');
    if strcmp(get(handle,'Type'),'hggroup'),validateCompound(handle,node,path);end
end

function validateCompound(handle,node,path)
    format=get(handle,'Format');
    if ~any(strcmp(format,{'xerr','yerr','xyerr'})),bad('Format');end
    children=allchild(handle);center=[];
    for k=1:numel(children)
        m2t2.reader.assertSupportedProperties(children(k),path,'line');
        [x,y]=m2t2.util.normalizeXY(get(children(k),'XData'),get(children(k),'YData'),path);
        if isequaln(x,node.x)&&isequaln(y,node.y),center(end+1)=k;end %#ok<AGROW>
        if (node.visible&&~strcmp(get(children(k),'Visible'),'on'))|| ...
                ~isequal(get(children(k),'Color'),get(handle,'Color'))
            bad('child visibility/color');
        end
    end
    if numel(children)~=2||numel(center)~=1,bad('child geometry');end
    names={'Marker','MarkerSize','LineStyle','LineWidth'};
    for k=1:numel(names)
        if ~isequal(get(children(center),names{k}),get(handle,names{k})),bad('center-line style');end
    end
    if ~strcmp(get(children(3-center),'LineStyle'),'-')||~strcmp(get(children(3-center),'Marker'),'none')|| ...
            get(children(3-center),'LineWidth')~=get(handle,'LineWidth'),bad('error-line style');end
    h=children(3-center);x=reshape(double(get(h,'XData')),1,[]);y=reshape(double(get(h,'YData')),1,[]);
    count=numel(node.x);blocks=1+strcmp(format,'xyerr');
    if numel(x)~=9*count*blocks||numel(y)~=numel(x),bad('error geometry size');end
    for block=1:blocks
        horizontal=strcmp(format,'xerr')||(strcmp(format,'xyerr')&&block==1);
        for k=1:count
            if ~isfinite(node.x(k))||~isfinite(node.y(k)),continue;end
            offset=(block-1)*9*count+(k-1)*9;ix=offset+(1:9);xx=x(ix);yy=y(ix);
            if ~all(isnan(xx([3 6 9])))||~all(isnan(yy([3 6 9]))),bad('error segment separators');end
            if horizontal
                low=node.x(k)-node.xNegative(k);high=node.x(k)+node.xPositive(k);
                if ~isequal(xx([1 2 4 5 7 8]),[low high high high low low])|| ...
                        ~isequal(yy(1:2),[node.y(k) node.y(k)]),bad('horizontal errors');end
                centers=[mean(yy(4:5)) mean(yy(7:8))];expected=node.y(k);
            else
                low=node.y(k)-node.yNegative(k);high=node.y(k)+node.yPositive(k);
                if ~isequal(yy([1 2 4 5 7 8]),[low high high high low low])|| ...
                        ~isequal(xx(1:2),[node.x(k) node.x(k)]),bad('vertical errors');end
                centers=[mean(xx(4:5)) mean(xx(7:8))];expected=node.x(k);
            end
            if any(abs(centers-expected)>8*eps(max(1,abs(expected)))),bad('error cap positions');end
        end
    end
    function bad(reason)
        error('M2T2:E007:UnsupportedProperty','M2T2-E007 UnsupportedProperty: path=%s errorbar %s differs from semantic properties',path,reason);
    end
end

function value = errorVector(value, count, path, name)
    value = reshape(double(value), 1, []);
    if isempty(value), value = zeros(1, count); end
    if isscalar(value) && count ~= 1, value = repmat(value, 1, count); end
    if numel(value) ~= count
        error('M2T2:E004:NormalizationFailed', ...
              'M2T2-E004 NormalizationFailed: path=%s.%s reason=error length mismatch', path, name);
    end
end

function value = property(handle, names, default)
    for k = 1:numel(names)
        try
            value = get(handle, names{k}); return;
        catch
        end
    end
    value = default;
end

function yes = hasProperty(handle, name)
    try, get(handle, name); yes = true; catch, yes = false; end
end
