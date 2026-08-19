function value = normalizeTextInterpreter(runtimeValue, path)
%NORMALIZETEXTINTERPRETER Canonicalize runtime text interpreter names.
    source = {'none','plain','tex','latex'};
    target = {'plain','plain','tex','latex'};
    index = find(strcmpi(runtimeValue, source), 1);
    if isempty(index)
        error('M2T2:E007:UnsupportedProperty', ...
              'M2T2-E007 UnsupportedProperty: path=%s property=Interpreter value=%s', ...
              path, runtimeValue);
    end
    value = target{index};
end
