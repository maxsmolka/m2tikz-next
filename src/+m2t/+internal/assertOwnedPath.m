function assertOwnedPath(path)
%ASSERTOWNEDPATH Reject redirected export products; explicit parents are allowed.
%   Inspect the final component, including dangling symbolic links. Parent
%   directories are caller-selected and may themselves be linked directories.
    if exist('OCTAVE_VERSION', 'builtin')
        [info, failure] = lstat(path);
        if failure == 0 && ~isempty(info.modestr) && info.modestr(1) == 'l'
            unsafe(path);
        end
        return;
    end
    if ~usejava('jvm')
        error('M2T:E006:UnsafeOutputProduct', ...
              'Safe product-path inspection requires the MATLAB JVM.');
    end
    file = javaObject('java.io.File', path);
    if javaMethod('isSymbolicLink', 'java.nio.file.Files', file.toPath())
        unsafe(path);
    end
    noFollow = javaArray('java.nio.file.LinkOption', 1);
    noFollow(1) = javaMethod('valueOf', 'java.nio.file.LinkOption', 'NOFOLLOW_LINKS');
    if javaMethod('exists', 'java.nio.file.Files', file.toPath(), noFollow)
        attributes = javaMethod('readAttributes', 'java.nio.file.Files', ...
            file.toPath(), 'basic:isOther', noFollow);
        if attributes.get('isOther'), unsafe(path); end
    end
    if file.exists()
        follow = javaArray('java.nio.file.LinkOption', 0);
        parent = file.getAbsoluteFile().getParentFile();
        expected = fullfile(char(parent.toPath().toRealPath(follow)), char(file.getName()));
        actual = char(file.toPath().toRealPath(follow));
        if ispc, equal = strcmpi(expected, actual); else, equal = strcmp(expected, actual); end
        if ~equal, unsafe(path); end
    end
end

function unsafe(path)
    error('M2T:E006:UnsafeOutputProduct', ...
          'Refusing redirected export product: %s.', path);
end
