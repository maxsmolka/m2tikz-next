function summary=runM73EnvironmentTests(outputDirectory,compile)
%RUNM73ENVIRONMENTTESTS Filesystem, encoding, diagnostics and real-tool checks.
    root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
    if nargin<1,outputDirectory=fullfile(root,'.audit','m73-environment');end
    if nargin<2,compile=false;end
    if exist(outputDirectory,'dir')~=7,mkdir(outputDirectory);end
    umlauts=native2unicode(uint8([195 164 195 182 195 188]),'UTF-8');
    greek=native2unicode(uint8([206 177]),'UTF-8');
    cases={'utf8_bytes',@utf8;'canonical_products',@products;'write_failure',@writeFailure; ...
        'asset_failure',@assetFailure;'missing_compiler',@missingCompiler; ...
        'pdf_diagnostics',@pdfDiagnostics;'unsafe_arguments',@unsafeArguments; ...
        'path_contract',@paths;'numeric_locale',@numbers};
    if compile,cases(end+1:end+3,:)={'real_paths',@realPaths;'real_set',@realSet;'compiler_failure',@compilerFailure};end
    rows=cell(size(cases,1),3);failures=0;
    for k=1:size(cases,1)
        try,cases{k,2}();status='PASS';detail='';
        catch err,status='FAIL';failures=failures+1;detail=regexprep([err.identifier ' ' err.message],'[\r\n\t]+',' ');end
        rows(k,:)={cases{k,1},status,detail};
    end
    report=sprintf('case\tstatus\tdetail\n');for k=1:size(rows,1),report=[report sprintf('%s\t%s\t%s\n',rows{k,:})];end %#ok<AGROW>
    m2t.internal.writeTextFile(fullfile(outputDirectory,'environment-results.tsv'),report);fprintf('%s',report);
    summary=struct('tests',size(rows,1),'failures',failures);
    assert(failures==0,'M7.3 environment contract failed.');fprintf('M73_ENVIRONMENT_PASS: %d/%d compile=%d\n',size(rows,1),size(rows,1),compile);
    function utf8()
        value=[umlauts ' ' greek sprintf('\n')];p=fullfile(outputDirectory,'utf8.txt');
        m2t.internal.writeTextFile(p,value);
        assert(isequal(bytes(p),uint8([195 164 195 182 195 188 32 206 177 10])));
        assert(strcmp(native2unicode(bytes(p),'UTF-8'),value));
    end
    function products()
        s=m2t2.ir.makeLineSeries();s.x=[0 1.25 2];s.y=[0 .5 1];
        a=m2t2.ir.makeAxes();a.xlim=[0 2];a.ylim=[0 1];a.series={s};
        a.xlabel=m2t2.ir.makeText(['literal ' umlauts ' _%&#{}$'],'plain');
        a.ylabel=m2t2.ir.makeText('$\alpha^{2}$','latex');
        ir=m2t2.ir.makeFigure({a});ir.unicodeProbe=greek;
        canonical=m2t2.ir.toJson(ir);assert(strcmp(canonical,m2t2.ir.toJson(m2t2.ir.fromJson(canonical))));
        tex=m2t2.render.renderPgfplots(ir,true);
        assert(isempty(strfind(tex,char(13)))&&~isempty(strfind(tex,'1.25'))); %#ok<STREMP>
        m2t.internal.writeTextFile(fullfile(outputDirectory,'portable.json'),canonical);
        m2t.internal.writeTextFile(fullfile(outputDirectory,'portable.tex'),tex);
        assert(strcmp(native2unicode(bytes(fullfile(outputDirectory,'portable.json')),'UTF-8'),canonical));
        % Reviewed common payload: these bytes match Windows MATLAB and Linux
        % Octave. Hosted CI must reproduce them, not merely repeat itself.
        assert(strcmp(sha256(bytes(fullfile(outputDirectory,'portable.json'))),'52230ae7660109e24dff747b080b104d21e3e133a9d83d7ee06ac739e403b066'));
        assert(strcmp(sha256(bytes(fullfile(outputDirectory,'portable.tex'))),'a421f46af46be2743f970c09c0fd352aac3f4697470dba02d462f11a7d9c2ac1'));
        asset=struct('rgb',uint8(cat(3,[255 0;0 255],[0 255;255 0],zeros(2))), ...
            'alpha',uint8([255 128;64 0]));
        p=fullfile(outputDirectory,'portable.png');m2t2.render.writePngAsset(asset,p);
        [rgb,~,alpha]=imread(p);assert(isequal(rgb,asset.rgb)&&isequal(alpha,asset.alpha));
        if compile
            result=m2t.internal.compileLuaLatex(fullfile(outputDirectory,'portable.tex'),fullfile(outputDirectory,'portable.pdf'),'lualatex');
            assert(result.success);validation=m2t.internal.validatePdf(fullfile(outputDirectory,'portable.pdf'));assert(validation.success);
        end
    end
    function writeFailure()
        p=fullfile(outputDirectory,'parent-is-file');m2t.internal.writeTextFile(p,'preserve');
        expect(@()m2t.internal.writeTextFile(fullfile(p,'child.tex'),'data'),'M2T:E004:WriteFailed');
        assert(strcmp(fileread(p),'preserve'));
    end
    function assetFailure()
        p=fullfile(outputDirectory,'asset-is-directory.png');if exist(p,'dir')~=7,mkdir(p);end
        asset=struct('rgb',zeros(2,2,3,'uint8'),'alpha',255*ones(2,'uint8'));
        expect(@()m2t2.render.writePngAsset(asset,p),'M2T2:E_PNG_WRITE_FAILED');
    end
    function missingCompiler()
        r=m2t.internal.compileLuaLatex(fullfile(outputDirectory,'portable.tex'),fullfile(outputDirectory,'missing.pdf'),'m2tikz_synthetic_missing_compiler_73');
        assert(~r.success&&strcmp(r.diagnostics(1).code,'M2T:C001:CompilerNotFound'));
    end
    function pdfDiagnostics()
        names={'absent.pdf','empty.pdf','invalid.pdf'};codes={'M2T:V001:PdfMissing','M2T:V002:PdfEmpty','M2T:V004:InvalidPdfHeader'};
        m2t.internal.writeTextFile(fullfile(outputDirectory,names{2}),'');m2t.internal.writeTextFile(fullfile(outputDirectory,names{3}),'not-pdf');
        for j=1:3,r=m2t.internal.validatePdf(fullfile(outputDirectory,names{j}));assert(~r.success&&strcmp(r.diagnostics(1).code,codes{j}));end
    end
    function unsafeArguments()
        target=fullfile(outputDirectory,'safe.pdf');
        expect(@()m2t.internal.compileLuaLatex(['unsafe' char(10)],target),'M2T:C005:UnsafeProcessArgument');
        if ispc
            expect(@()m2t.internal.compileLuaLatex('safe.tex',target,'bad%compiler'),'M2T:C005:UnsafeProcessArgument');
        end
    end
    function paths()
        p=m2t.internal.normalizeOutputBase(fullfile(outputDirectory,'output with spaces','nested','figure'));
        assert(~isempty(strfind(p.texPath,fullfile('output with spaces','nested','figure.tex')))); %#ok<STREMP>
        expect(@()m2t.internal.normalizeOutputBase(fullfile(outputDirectory,'unsafe%name')),'M2T:E002:InvalidOutputPath');
        if ispc
            slash=strrep(p.base,char(92),'/');other=m2t.internal.normalizeOutputBase(slash);
            assert(strcmp(strrep(other.base,char(92),'/'),strrep(p.base,char(92),'/')));
        end
    end
    function numbers()
        assert(strcmp(m2t2.util.formatNumber(1.25),'1.25'));
        s=m2t2.ir.makeLineSeries();s.x=[0 1.25];s.y=[.5 1];a=m2t2.ir.makeAxes();a.series={s};
        canonical=m2t2.ir.toJson(m2t2.ir.makeFigure({a}));assert(~isempty(strfind(canonical,'1.25'))); %#ok<STREMP>
    end
    function realPaths()
        [f,c]=source(umlauts);
        folders={'output with spaces',['unicode-' umlauts],fullfile('nested','output','path')};
        for j=1:numel(folders)
            r=m2t.export(f,fullfile(outputDirectory,folders{j},['figure ' umlauts]),'ImageBackend','hybrid','Overwrite',true);
            assert(r.success,['Path export failed: ' folders{j}]);assert(numel(r.render.assets)==1);
            assert(isempty(strfind(native2unicode(bytes(r.texPath),'UTF-8'),char(13)))); %#ok<STREMP>
        end
        clear c;
    end
    function realSet()
        [f,c]=source(umlauts);entries=struct('figure',{f,f},'name',{'first','second'});
        r=m2t.exportSet(entries,fullfile(outputDirectory,['set ' umlauts]),'ImageBackend','auto','Overwrite',true);
        assert(r.success&&r.summary.succeeded==2);manifest=fileread(r.manifestPath);parsed=jsondecode(manifest);
        assert(strcmp(parsed.figures(1).assets{1},'first-assets/image-0001.png'));
        assert(isempty(strfind(manifest,outputDirectory))&&isempty(strfind(manifest,char(92)))); %#ok<STREMP>
        clear c;
    end
    function compilerFailure()
        before={getenv('TEXMFVAR'),getenv('TEXMFCACHE'),getenv('TEXINPUTS')};
        p=fullfile(outputDirectory,'invalid-tex.tex');
        m2t.internal.writeTextFile(p,sprintf('\\documentclass{standalone}\n\\begin{document}\\MSeventyThreeUndefined\\end{document}\n'));
        r=m2t.internal.compileLuaLatex(p,fullfile(outputDirectory,'invalid-tex.pdf'),'lualatex');
        assert(~r.success&&strcmp(r.diagnostics(1).code,'M2T:C003:CompilationFailed')&&exist(r.logPath,'file')==2);
        assert(isequal(before,{getenv('TEXMFVAR'),getenv('TEXMFCACHE'),getenv('TEXINPUTS')}));
    end
end
function [f,c]=source(umlauts)
    f=figure('Visible','off','Color','w');c=onCleanup(@()close(f));a=axes('Parent',f);
    image('Parent',a,'CData',cat(3,[1 0;0 1],[0 1;1 0],zeros(2)),'AlphaData',[1 .5;.25 0]);
    set(a,'Color','w');xlabel(a,['literal ' umlauts ' _%&#{}$'],'Interpreter','none');ylabel(a,'$\alpha^{2}$','Interpreter','latex');
end
function value=bytes(path),f=fopen(path,'rb');assert(f>=0);c=onCleanup(@()fclose(f));value=fread(f,Inf,'*uint8').';clear c;end
function expect(fn,id),try,fn();error('M2T:ExpectedFailure','unsupported input accepted');catch err,assert(strcmp(err.identifier,id),[err.identifier ' ' err.message]);end,end
function value=sha256(data)
    if exist('OCTAVE_VERSION','builtin'),value=hash('sha256',char(data));return;end
    digest=javaMethod('getInstance','java.security.MessageDigest','SHA-256');digest.update(typecast(data,'int8'));
    raw=typecast(digest.digest(),'uint8');value=lower(reshape(dec2hex(raw,2).',1,[]));
end
