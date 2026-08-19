function [ir, tex] = export(figureHandle, outputPath, standalone)
%EXPORT Experimental M2 line-plot export entry point.
%   [IR, TEX] = M2T2.EXPORT(FIGURE, PATH, STANDALONE) reads a figure into
%   the versioned M2 IR and renders it without invoking the legacy exporter.

    if nargin < 3
        standalone = true;
    end
    if nargin < 2 || isempty(outputPath)
        error('M2T2:E002:InvalidArgument', 'M2T2-E002 InvalidArgument: outputPath is required.');
    end
    if ~(islogical(standalone) && isscalar(standalone))
        error('M2T2:E002:InvalidArgument', ...
              'M2T2-E002 InvalidArgument: standalone must be a logical scalar.');
    end

    ir = m2t2.reader.readFigure(figureHandle);
    tex = m2t2.render.renderPgfplots(ir, standalone);

    fid = fopen(outputPath, 'w');
    if fid < 0
        error('M2T2:E005:WriteFailed', ...
              'M2T2-E005 WriteFailed: path=%s', outputPath);
    end
    cleanup = onCleanup(@() fclose(fid));
    fwrite(fid, tex, 'char');
    clear cleanup;
end
