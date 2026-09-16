function writeTextFile(path, text)
%WRITETEXTFILE Write UTF-8 bytes without BOM or platform newline conversion.
    if isa(text,'string')&&isscalar(text),text=char(text);end
    if ~(ischar(text)&&(isrow(text)||isempty(text)))
        error('M2T:E004:WriteFailed','Output text must be a character row.');
    end
    encoded=zeros(1,0,'uint8');
    if ~isempty(text)
        try
            encoded=unicode2native(text,'UTF-8');decoded=native2unicode(encoded,'UTF-8');
        catch err
            error('M2T:E004:WriteFailed','Cannot encode output text as UTF-8: %s',err.message);
        end
        if ~strcmp(decoded,text)
            error('M2T:E004:WriteFailed','Output text cannot be represented losslessly as UTF-8.');
        end
    end
    fid = fopen(path, 'wb');
    if fid < 0
        error('M2T:E004:WriteFailed', 'Cannot open output for %s.', path);
    end
    try
        written = fwrite(fid, encoded, 'uint8');
        closeStatus = fclose(fid);
    catch err
        try, fclose(fid); catch, end
        rethrow(err);
    end
    if written ~= numel(encoded)
        error('M2T:E004:WriteFailed', 'Incomplete write for %s.', path);
    end
    if closeStatus ~= 0
        error('M2T:E004:WriteFailed', 'Cannot close output for %s.', path);
    end
end
