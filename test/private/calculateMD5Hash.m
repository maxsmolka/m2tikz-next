function hash = calculateMD5Hash(filename)
% CALCULATEMD5HASH calculate a MD5 hash of a file
%
% This functionality is built-in into Octave but uses Java in MATLAB.

    switch getEnvironment
        case 'Octave'
            if exist('md5sum', 'file') || exist('md5sum', 'builtin')
                hash = md5sum(filename);
            else
                % md5sum was removed from recent Octave releases. The hash
                % function hashes strings, so read the file in binary mode and
                % preserve every byte when converting to a character vector.
                fid = fopen(filename, 'rb');
                if fid < 0
                    error('calculateMD5Hash:FileOpenFailed', ...
                        'Could not open "%s" for hashing.', filename);
                end
                finally_close = onCleanup(@()fclose(fid));
                data = fread(fid, Inf, '*uint8')';
                hash = builtin('hash', 'md5', char(data));
            end

        case 'MATLAB'
            % There are some MD5 implementations in MATLAB, but those
            % tend to be slow and licensing is unclear.
            % Rolling our own implementation is unwanted, especially since this
            % is a  cryptographic hash, even though its security has been
            % broken. Instead we make use of the Java libraries.
            % Unless the "-nojvm" flag is specified, this should work well.

            MD5 = java.security.MessageDigest.getInstance('MD5');

            % Open the file
            fid = fopen(filename, 'r');

            % Make sure fid is closed
            finally_close = onCleanup(@()fclose(fid));

            % Faster file digest based on code by Jan Simon as in
            % http://www.mathworks.com/matlabcentral/fileexchange/31272-datahash
            data = fread(fid, '*uint8');
            MD5.update(data);

            hash = reshape(dec2hex(typecast(MD5.digest(),'uint8')).', 1, 32);
    end

    hash = lower(hash);
end
