function marker = normalizeMarker(value, path)
%NORMALIZEMARKER Map MATLAB/Octave markers to the M2 IR vocabulary.
    source = {'none','o','+','*','.','x','s','square','d','diamond','^','v','>','<','p','pentagram','h','hexagram'};
    target = {'none','circle','plus','asterisk','point','x','square','square','diamond','diamond', ...
              'triangle_up','triangle_down','triangle_right','triangle_left', ...
              'pentagram','pentagram','hexagram','hexagram'};
    index = find(strcmpi(value, source), 1);
    if isempty(index)
        error('M2T2:E004:NormalizationFailed', ...
              'M2T2-E004 NormalizationFailed: path=%s reason=unsupported marker %s', ...
              path, value);
    end
    marker = target{index};
end
