function output = renderText(node)
%RENDERTEXT Render TextIR according to its explicit interpreter semantics.
    switch node.interpreter
        case 'plain'
            output = m2t2.util.escapeTex(node.value);
        case 'tex'
            % MATLAB/Octave accepts math constructs such as x_{1} without
            % delimiters. PGF/TikZ requires an explicit math context, while
            % ordinary legend words must remain ordinary text.
            if any(node.value == '_') || any(node.value == '^') || ...
                    any(node.value == char(92))
                output = ['$' node.value '$'];
            else
                output = m2t2.util.escapeTex(node.value);
            end
        case 'latex'
            % LaTeX-interpreted strings already own their delimiters.
            output = node.value;
        otherwise
            error('M2T2:E008:Schema', ...
                  'Unsupported TextIR interpreter: %s.', node.interpreter);
    end
end
