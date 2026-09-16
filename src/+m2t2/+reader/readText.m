function node = readText(textHandle, path)
%READTEXT Normalize a graphics text handle to TextIR.
    value = m2t2.util.textValue(get(textHandle, 'String'), [path '.value']);
    if strcmp(get(textHandle,'Visible'),'off'),value='';end
    interpreter = m2t2.util.normalizeTextInterpreter(get(textHandle, 'Interpreter'), path);
    node = m2t2.ir.makeText(value, interpreter);
end
