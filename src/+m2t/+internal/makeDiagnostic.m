function diagnostic = makeDiagnostic(severity, code, message, stage)
%MAKEDIAGNOSTIC Construct one stable workflow diagnostic.
    diagnostic = struct('severity', severity, 'code', code, ...
                        'message', message, 'stage', stage);
end
