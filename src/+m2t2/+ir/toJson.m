function text = toJson(ir)
%TOJSON Encode validated FigureIR v2 with stable keys and unambiguous NaN gaps.
%   Internal codec, not a new end-user export API. Known normalization and
%   lexical key ordering yield repeatable bytes in one JSON runtime version.
    m2t2.ir.validate(ir);
    normalized = m2t2.ir.fromJson(encodeValue(ir));
    text = encodeValue(normalized);
end

function text = encodeValue(value)
    if isstruct(value)
        if ~isscalar(value)
            if ~isempty(value)&&~isvector(value),invalid('struct arrays must be vectors');end
            items=arrayfun(@(item)encodeValue(item),value,'UniformOutput',false);
            text=['[' strjoin(items(:).',',') ']'];return;
        end
        names=sort(fieldnames(value));items=cell(1,numel(names));
        for k=1:numel(names),items{k}=[jsonencode(names{k}) ':' encodeValue(value.(names{k}))];end
        text=['{' strjoin(items,',') '}'];
    elseif iscell(value)
        if ~isempty(value)&&~isvector(value),invalid('cell arrays must be vectors');end
        items=cellfun(@encodeValue,value,'UniformOutput',false);
        text=['[' strjoin(items(:).',',') ']'];
    elseif isnumeric(value)
        if ~isreal(value)||any(isinf(value(:))),invalid('numeric values must be real without infinity');end
        if isinteger(value)&&any(abs(double(value(:)))>flintmax),invalid('integer values above exact double range are unsupported');end
        value=double(value);value(value==0)=0;value(isnan(value))=NaN;
        if isempty(value),text='[]';
        elseif isscalar(value)
            if isnan(value),text='[null]';else,text=number(value);end
        else,text=numericArray(value,size(value),1,1);end
    elseif islogical(value) || (ischar(value)&&(isempty(value)||isrow(value)))
        text=jsonencode(value);
    else
        invalid('only JSON-safe data values are serializable');
    end
end

function text=numericArray(value,shape,dimension,offset)
    items=cell(1,shape(dimension));stride=prod(shape(1:dimension-1));
    for k=1:numel(items)
        index=offset+(k-1)*stride;
        if dimension==numel(shape),items{k}=number(value(index));
        else,items{k}=numericArray(value,shape,dimension+1,index);end
    end
    text=['[' strjoin(items,',') ']'];
end

function text=number(value)
    if isnan(value),text='null';else,text=strrep(sprintf('%.17g',value),',','.');end
end

function invalid(reason)
    error('M2T2:E003:InvalidIR','M2T2-E003 InvalidIR: %s',reason);
end
