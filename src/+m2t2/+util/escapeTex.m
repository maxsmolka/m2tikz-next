function output = escapeTex(input)
%ESCAPETEX Escape normalized literal text for PGFPlots labels and legends.
    output = input;
    bs = char(92);
    replacements = {bs,[bs 'textbackslash{}']; '{',[bs '{']; '}',[bs '}']; ...
                    '%',[bs '%']; '$',[bs '$']; '#',[bs '#']; '&',[bs '&']; ...
                    '_',[bs '_']; '^',[bs 'textasciicircum{}']; '~',[bs 'textasciitilde{}']};
    placeholder = char(1);
    output = strrep(output, bs, placeholder);
    for k = 2:size(replacements, 1)
        output = strrep(output, replacements{k, 1}, replacements{k, 2});
    end
    output = strrep(output, placeholder, replacements{1, 2});
end
