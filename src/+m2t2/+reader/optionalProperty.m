function value = optionalProperty(handle, name, default)
%OPTIONALPROPERTY Default only for an absent property, never a failed getter.
    if ~(isscalar(handle) && ishandle(handle))
        error('M2T2:E002:InvalidArgument', ...
            'Optional property %s requires a live scalar graphics handle.', name);
    end
    if isprop(handle, name)
        value = get(handle, name);
    else
        value = default;
    end
end
