function writePngAsset(asset, path)
%WRITEPNGASSET Encode one deterministic lossless RGBA rendering asset.
    if all(asset.alpha(:) == 255)
        imwrite(asset.rgb, path, 'png');
    else
        imwrite(asset.rgb, path, 'png', 'Alpha', asset.alpha);
    end
    removeTimeMetadata(path);
end

function removeTimeMetadata(path)
    fid = fopen(path, 'rb');
    if fid < 0, error('M2T2:E_PNG_WRITE_FAILED', 'Cannot read generated PNG: %s', path); end
    cleanup = onCleanup(@() fclose(fid));
    bytes = fread(fid, Inf, '*uint8')'; clear cleanup;
    signature = uint8([137 80 78 71 13 10 26 10]);
    if numel(bytes) < 8 || ~isequal(bytes(1:8), signature)
        error('M2T2:E_PNG_WRITE_FAILED', 'Generated image is not a valid PNG: %s', path);
    end
    output = bytes(1:8); offset = 9;
    while offset <= numel(bytes)
        if offset + 11 > numel(bytes)
            error('M2T2:E_PNG_WRITE_FAILED', 'Generated PNG is truncated: %s', path);
        end
        lengthValue = double(bytes(offset)) * 16777216 + ...
                      double(bytes(offset + 1)) * 65536 + ...
                      double(bytes(offset + 2)) * 256 + double(bytes(offset + 3));
        final = offset + 11 + lengthValue;
        if final > numel(bytes)
            error('M2T2:E_PNG_WRITE_FAILED', 'Generated PNG chunk is truncated: %s', path);
        end
        chunkType = char(bytes(offset + 4:offset + 7));
        if ~strcmp(chunkType, 'tIME')
            output = [output bytes(offset:final)]; %#ok<AGROW>
        end
        offset = final + 1;
    end
    fid = fopen(path, 'wb');
    if fid < 0, error('M2T2:E_PNG_WRITE_FAILED', 'Cannot normalize generated PNG: %s', path); end
    cleanup = onCleanup(@() fclose(fid)); fwrite(fid, output, 'uint8'); clear cleanup;
end
