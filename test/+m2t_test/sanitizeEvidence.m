function value = sanitizeEvidence(value, roots)
%SANITIZEEVIDENCE Remove machine-specific filesystem roots recursively.
    if nargin < 2
        roots = {pwd, tempdir, getenv('USERPROFILE'), getenv('HOME')};
    end
    roots = roots(~cellfun(@isempty, roots));
    if isstruct(value)
        names = fieldnames(value);
        for index = 1:numel(value)
            for k = 1:numel(names)
                value(index).(names{k}) = m2t_test.sanitizeEvidence(value(index).(names{k}), roots);
            end
        end
    elseif iscell(value)
        for k = 1:numel(value), value{k} = m2t_test.sanitizeEvidence(value{k}, roots); end
    elseif isa(value, 'string')
        for k = 1:numel(value), value(k) = string(sanitizeText(char(value(k)), roots)); end
    elseif ischar(value)
        value = sanitizeText(value, roots);
    end
end

function text = sanitizeText(text, roots)
    for k = 1:numel(roots)
        root = roots{k};
        variants = unique({root, strrep(root, '\', '/'), strrep(root, '/', '\')});
        for v = 1:numel(variants)
            if ~isempty(variants{v}), text = strrep(text, variants{v}, '<machine-path>'); end
        end
    end
    text = regexprep(text, '(?i)[A-Z]:[\\/](Users|Documents and Settings)[\\/][^\\/\s]+', '<user-home>');
    text = regexprep(text, '(?i)/(home|Users)/[^/\s]+', '<user-home>');
end
