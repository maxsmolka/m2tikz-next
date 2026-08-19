function writeTextFile(path, text)
%WRITETEXTFILE Write one workflow-owned text product after policy checks.
    fid = fopen(path, 'wb');
    if fid < 0
        error('M2T:E004:WriteFailed', 'Cannot open output for %s.', path);
    end
    try
        written = fwrite(fid, text, 'char');
        closeStatus = fclose(fid);
    catch err
        try, fclose(fid); catch, end
        rethrow(err);
    end
    if written ~= numel(text)
        error('M2T:E004:WriteFailed', 'Incomplete write for %s.', path);
    end
    if closeStatus ~= 0
        error('M2T:E004:WriteFailed', 'Cannot close output for %s.', path);
    end
end
