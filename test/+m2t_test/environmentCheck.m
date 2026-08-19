function environment = environmentCheck(outputDirectory)
%ENVIRONMENTCHECK Classify prerequisites without treating them as product bugs.
    environment=struct('writableOutput',false,'writableTemp',false, ...
        'luaLatexAvailable',false,'pdfInfoAvailable',false,'pngAvailable',false,'pgfplotsValidatedByCompile',false, ...
        'failures',{{}});
    if exist(outputDirectory,'dir')~=7,[ok,message]=mkdir(outputDirectory);if ~ok,environment.failures{end+1}=['output: ' message];end,end
    environment.writableOutput=writeProbe(outputDirectory);
    environment.writableTemp=writeProbe(tempdir);
    [code,~]=system('lualatex --version');environment.luaLatexAvailable=code==0;
    [code,~]=system('pdfinfo -v');environment.pdfInfoAvailable=code==0;
    environment.pngAvailable=exist('imwrite','file')==2||exist('imwrite','builtin')==5;
    if ~environment.writableOutput,environment.failures{end+1}='output directory is not writable';end
    if ~environment.writableTemp,environment.failures{end+1}='temporary directory is not writable';end
    if ~environment.luaLatexAvailable,environment.failures{end+1}='lualatex is not available on PATH';end
    if ~environment.pdfInfoAvailable,environment.failures{end+1}='pdfinfo is not available on PATH';end
    if ~environment.pngAvailable,environment.failures{end+1}='imwrite is unavailable';end
end
function ok=writeProbe(directory)
    ok=false;path=fullfile(directory,'m2t-validation-write-probe.tmp');fid=fopen(path,'wb');
    if fid<0,return;end;fwrite(fid,'ok','char');fclose(fid);ok=exist(path,'file')==2;
    if ok
        if exist('unlink','builtin')==5||exist('unlink','file')==2,unlink(path);else,delete(path);end
    end
end
