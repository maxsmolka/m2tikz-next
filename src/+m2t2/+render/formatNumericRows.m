function output=formatNumericRows(values)
%FORMATNUMERICROWS Buffered rows; each input column is one output record.
% Keep the existing 15-significant-digit text contract, NaNs and negative zero.
    if isempty(values),output='';return;end
    if any(isinf(values(:)))
        error('M2T2:E003:InvalidIR','M2T2-E003 InvalidIR: renderer received an infinite number');
    end
    values(values==0)=0;
    values(isnan(values))=NaN; % Octave NA is also the established nan gap token.
    format=[repmat('%.15g ',1,size(values,1)-1) '%.15g\n'];
    output=sprintf(format,values);
    output=strrep(output,',','.');output=strrep(output,'NaN','nan');
    output(end)=[]; % Caller joins blocks with exactly one LF, as before.
end
