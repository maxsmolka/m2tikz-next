function checkOutputProducts(paths, overwrite)
%CHECKOUTPUTPRODUCTS Preflight every product before output writes or removals.
    products = {paths.texPath, paths.pdfPath, paths.logPath};
    for k = 1:numel(products)
        m2t.internal.assertOwnedPath(products{k});
        kind = exist(products{k}, 'file');
        if kind == 7
            error('M2T:E006:UnsafeOutputProduct', ...
                  'A file product is an existing directory: %s.', products{k});
        end
        if kind ~= 0 && ~overwrite, collision(products{k}); end
    end
    m2t.internal.assertOwnedPath(paths.assetDirectory);
    kind = exist(paths.assetDirectory, 'file');
    if kind ~= 0 && ~overwrite, collision(paths.assetDirectory); end
    if kind ~= 0 && kind ~= 7
        error('M2T:E006:UnsafeOutputProduct', ...
              'The asset directory is an existing file: %s.', paths.assetDirectory);
    end
    if kind == 7 && overwrite
        children = dir(paths.assetDirectory);
        for k = 1:numel(children)
            name = children(k).name;
            if any(strcmp(name, {'.','..'})), continue; end
            child = fullfile(paths.assetDirectory, name);
            m2t.internal.assertOwnedPath(child);
            if children(k).isdir || isempty(regexp(name, '^image-[0-9]{4,}\.png$', 'once'))
                error('M2T:E006:UnsafeOutputProduct', ...
                      'Asset directory contains an unrecognized product: %s.', child);
            end
        end
    end
end

function collision(path)
    error('M2T:E003:OutputExists', ...
          'Export product already exists: %s. Pass Overwrite=true to replace it.', path);
end
