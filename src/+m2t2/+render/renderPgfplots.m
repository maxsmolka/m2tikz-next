function tex = renderPgfplots(ir, standalone, config)
%RENDERPGFPLOTS Render validated, handle-free M2 IR as deterministic TeX.
    if nargin < 2
        standalone = true;
    end
    if nargin < 3, config = m2t2.render.defaultConfig(); end
    m2t2.ir.validate(ir);

    bs = char(92);
    lines = {};
    hasArrows = any(cellfun(@(item) ...
        strcmp(item.kind, 'm2t2.arrowannotation'), ir.annotations));
    hasPatch3 = any(cellfun(@(ax) any(cellfun(@(item) ...
        strcmp(item.kind, 'm2t2.patch3'), ax.series)), ir.axes));
    if standalone
        lines = [lines, {[bs 'documentclass[tikz,border=' ...
                         m2t2.util.formatNumber(config.standaloneBorderPt) ...
                         'pt]{standalone}'], ...
                         [bs 'usepackage{pgfplots}'], ...
                         [bs 'pgfplotsset{compat=1.18}']}];
        if hasArrows, lines{end + 1} = [bs 'usetikzlibrary{arrows.meta}']; end
        if hasPatch3, lines{end + 1} = [bs 'usepgfplotslibrary{patchplots}']; end
        lines{end + 1} = [bs 'begin{document}'];
    elseif hasArrows
        lines{end + 1} = [bs 'usetikzlibrary{arrows.meta}'];
    end
    if ~standalone && hasPatch3
        lines{end + 1} = [bs 'usepgfplotslibrary{patchplots}'];
    end
    lines{end + 1} = [bs 'begin{tikzpicture}'];
    if ~isempty(ir.size)
        lines{end + 1} = [bs 'path[use as bounding box] (0pt,0pt) rectangle (' ...
            m2t2.util.formatNumber(ir.size(1)) 'pt,' ...
            m2t2.util.formatNumber(ir.size(2)) 'pt);'];
    end
    for a = 1:numel(ir.axes)
        axesAnnotations = ir.annotations(cellfun(@(item) ...
            strcmp(item.kind, 'm2t2.textannotation') && ...
            strcmp(item.owner.kind, 'axes') && ...
            strcmp(item.owner.id, ir.axes{a}.id), ir.annotations));
        axesLines = m2t2.render.renderAxes(ir.axes{a}, a, ir.size, config, ...
            axesAnnotations);
        lines = [lines, axesLines]; %#ok<AGROW>
    end
    for e = 1:numel(ir.elements)
        elementLines = m2t2.render.renderFigureElement(ir.elements{e}, ir, e, config);
        lines = [lines, elementLines]; %#ok<AGROW>
    end
    arrowIndex = 0;
    for k = 1:numel(ir.annotations)
        item = ir.annotations{k};
        if ~strcmp(item.kind, 'm2t2.arrowannotation') || ~item.visible, continue; end
        arrowIndex = arrowIndex + 1;
        annotationLines = m2t2.render.renderArrowAnnotation( ...
            item, ir.size, arrowIndex);
        lines = [lines, annotationLines]; %#ok<AGROW>
    end
    lines{end + 1} = [bs 'end{tikzpicture}'];
    if standalone
        lines{end + 1} = [bs 'end{document}'];
    end
    tex = [m2t2.util.joinCell(lines, sprintf('\n')) sprintf('\n')];
end
