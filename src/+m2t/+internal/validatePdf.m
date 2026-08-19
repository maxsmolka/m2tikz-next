function validation = validatePdf(pdfPath)
%VALIDATEPDF Perform dependency-free structural checks on the compiled PDF.
    validation = struct('success', false, ...
                        'diagnostics', m2t.internal.emptyDiagnostics());
    if exist(pdfPath, 'file') ~= 2
        validation.diagnostics(end + 1) = m2t.internal.makeDiagnostic( ...
            'error', 'M2T:V001:PdfMissing', ...
            sprintf('LuaLaTeX completed but no PDF was produced: %s', pdfPath), ...
            'validation');
        return
    end
    fid = fopen(pdfPath, 'rb');
    if fid < 0
        validation.diagnostics(end + 1) = m2t.internal.makeDiagnostic( ...
            'error', 'M2T:V003:PdfUnreadable', ...
            sprintf('The generated PDF cannot be read: %s', pdfPath), 'validation');
        return
    end
    cleanup = onCleanup(@() fclose(fid));
    fseek(fid, 0, 'eof');
    byteCount = ftell(fid);
    fseek(fid, 0, 'bof');
    if byteCount <= 0
        validation.diagnostics(end + 1) = m2t.internal.makeDiagnostic( ...
            'error', 'M2T:V002:PdfEmpty', ...
            sprintf('The generated PDF is empty: %s', pdfPath), 'validation');
        return
    end
    header = fread(fid, 4, '*char')';
    clear cleanup;
    if ~strcmp(header, '%PDF')
        validation.diagnostics(end + 1) = m2t.internal.makeDiagnostic( ...
            'error', 'M2T:V004:InvalidPdfHeader', ...
            sprintf('The generated file does not have a PDF header: %s', pdfPath), ...
            'validation');
        return
    end
    validation.success = true;
end
