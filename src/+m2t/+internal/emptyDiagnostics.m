function diagnostics = emptyDiagnostics()
%EMPTYDIAGNOSTICS Return a typed empty user-facing diagnostic array.
    diagnostics = struct('severity', {}, 'code', {}, 'message', {}, 'stage', {});
end
