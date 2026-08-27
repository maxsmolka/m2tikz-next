function plan = makePgfplotsPlan(ir, standalone, config, imageBackend, assetDirectoryName)
%MAKEPGFPLOTSPLAN Plan deterministic TeX and optional scalar-image PNG assets.
    if nargin < 2, standalone = true; end
    if nargin < 3, config = m2t2.render.defaultConfig(); end
    if nargin < 4, imageBackend = 'vector'; end
    if nargin < 5, assetDirectoryName = ''; end
    m2t2.ir.validate(ir);

    config.imageBackend = imageBackend;
    config.imageReferences = cell(1, numel(ir.axes));
    assets = repmat(assetTemplate(), 1, 0);
    imageIndex = 0;
    for a = 1:numel(ir.axes)
        config.imageReferences{a} = cell(1, numel(ir.axes{a}.series));
        for s = 1:numel(ir.axes{a}.series)
            item = ir.axes{a}.series{s};
            if ~strcmp(item.kind, 'm2t2.image') || ~item.visible, continue; end
            if strcmp(imageBackend, 'hybrid')
                imageIndex = imageIndex + 1;
                filename = sprintf('image-%04d.png', imageIndex);
                reference = [assetDirectoryName '/' filename];
                asset = makeAsset(item, ir.axes{a}, ...
                                  filename, reference, imageIndex);
                config.imageReferences{a}{s} = struct( ...
                    'reference', reference, 'xExtent', asset.xExtent, ...
                    'yExtent', asset.yExtent);
                assets(end + 1) = asset; %#ok<AGROW>
            end
        end
    end
    plan = struct('backend', imageBackend, 'tex', ...
                  m2t2.render.renderPgfplots(ir, standalone, config), ...
                  'assets', assets);
end

function asset = makeAsset(image, axesNode, filename, reference, index)
    requireUniform(image.x, 'x'); requireUniform(image.y, 'y');
    if strcmp(image.colorMode, 'rgb')
        valid = true(size(image.cdata,1), size(image.cdata,2));
        rgb = uint8(round(image.cdata * 255));
    else
        mapping = axesNode.colorMapping;
        indices = m2t2.render.imageColorIndices(image.cdata, mapping, ...
                                                image.mapping, image.directIndexBase);
        rgb = zeros([size(indices) 3], 'uint8'); valid = ~isnan(indices);
        for channel = 1:3
            values = zeros(size(indices)); channelMap = mapping.colormap(:, channel);
            values(valid) = channelMap(indices(valid) + 1);
            rgb(:, :, channel) = uint8(round(values * 255));
        end
    end
    if strcmp(image.alphaMode, 'per_pixel')
        alphaValues = image.alphaData;
    else
        alphaValues = repmat(image.alphaData, size(valid));
    end
    alphaValues(~valid) = 0;
    alpha = uint8(round(alphaValues * 255));
    yIncreasing = numel(image.y) == 1 || image.y(2) > image.y(1);
    flipRows = (yIncreasing && strcmp(axesNode.ydirection, 'normal')) || ...
               (~yIncreasing && strcmp(axesNode.ydirection, 'reverse'));
    if flipRows
        rgb = flipud(rgb); alpha = flipud(alpha);
    end
    xIncreasing = numel(image.x) == 1 || image.x(2) > image.x(1);
    flipColumns = (xIncreasing && strcmp(axesNode.xdirection, 'reverse')) || ...
                  (~xIncreasing && strcmp(axesNode.xdirection, 'normal'));
    if flipColumns
        rgb = fliplr(rgb); alpha = fliplr(alpha);
    end
    xExtent = coordinateExtent(image.x);
    yExtent = coordinateExtent(image.y);
    asset = assetTemplate(); asset.id = sprintf('image-%04d', index);
    asset.filename = filename; asset.reference = reference;
    asset.width = size(image.cdata, 2); asset.height = size(image.cdata, 1);
    asset.xExtent = xExtent; asset.yExtent = yExtent;
    asset.rgb = rgb; asset.alpha = alpha;
end

function requireUniform(values, axisName)
    if numel(values) < 3, return; end
    steps = diff(values); tolerance = max(1, max(abs(steps))) * 1e-12;
    if max(abs(steps - steps(1))) > tolerance
        error('M2T:IMAGE_HYBRID_COORDINATES_UNSUPPORTED', ...
              'Hybrid image %s coordinates must be uniformly spaced.', axisName);
    end
end

function extent = coordinateExtent(values)
    if numel(values) == 1
        extent = [values(1) - 0.5 values(1) + 0.5];
    else
        first = values(1) - (values(2) - values(1)) / 2;
        last = values(end) + (values(end) - values(end - 1)) / 2;
        extent = sort([first last]);
    end
end

function value = assetTemplate()
    value = struct('id', '', 'filename', '', 'reference', '', ...
                   'width', 0, 'height', 0, 'xExtent', [0 0], ...
                   'yExtent', [0 0], 'rgb', zeros(0, 0, 3, 'uint8'), ...
                   'alpha', zeros(0, 0, 'uint8'));
end
