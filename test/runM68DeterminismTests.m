function summary=runM68DeterminismTests(outputDirectory)
%RUNM68DETERMINISMTESTS Stable semantics/bytes, never timing thresholds.
    root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
    if nargin<1,outputDirectory=fullfile(root,'.audit','m68-determinism');end
    if exist(outputDirectory,'dir')~=7,mkdir(outputDirectory);end
    cases={'numeric_buffer',@numericBuffer;'precision_boundary',@precisionBoundary; ...
        'vector_image_reference',@imageReference;'planner_order',@plannerOrder; ...
        'ir_json_tex',@irJsonTex;'png_encoder',@pngEncoder; ...
        'diagnostic_order',@diagnosticOrder;'native_repeat',@nativeRepeat};
    rows=cell(size(cases,1),3);failures=0;
    for k=1:size(cases,1)
        try,cases{k,2}();status='PASS';detail='';
        catch err,status='FAIL';detail=regexprep([err.identifier ' ' err.message],'[\r\n\t]+',' ');failures=failures+1;end
        rows(k,:)={cases{k,1},status,detail};
    end
    report=sprintf('case\tstatus\tdetail\n');for k=1:size(rows,1),report=[report sprintf('%s\t%s\t%s\n',rows{k,:})];end %#ok<AGROW>
    m2t.internal.writeTextFile(fullfile(outputDirectory,'m68-results.tsv'),report);fprintf('%s',report);
    summary=struct('tests',size(rows,1),'failures',failures);assert(failures==0,'M6.8 determinism suite failed.');
    fprintf('M68_DETERMINISM_PASS: %d/%d\n',size(rows,1),size(rows,1));
    function numericBuffer()
        numbers=[0 -0 pi -pi 1+eps 1e-300 -1e300 realmin realmax NaN];
        for width=1:4
            values=repmat(numbers,width,1);expected=cell(1,numel(numbers));
            for q=1:numel(numbers),parts=arrayfun(@m2t2.util.formatNumber,values(:,q),'UniformOutput',false);expected{q}=m2t2.util.joinCell(parts,' ');end
            assert(strcmp(m2t2.render.formatNumericRows(values),m2t2.util.joinCell(expected,sprintf('\n'))));
        end
        assert(isempty(m2t2.render.formatNumericRows([])));
        if exist('OCTAVE_VERSION','builtin'),assert(strcmp(m2t2.render.formatNumericRows([NA;1]),'nan 1'));end
        try,m2t2.render.formatNumericRows([1 Inf]);error('M2T:ExpectedFailure','accepted Inf');catch err,assert(strcmp(err.identifier,'M2T2:E003:InvalidIR'));end
        old=getenv('LC_NUMERIC');c=onCleanup(@()setenv('LC_NUMERIC',old));setenv('LC_NUMERIC','de_DE.UTF-8');
        assert(strcmp(m2t2.render.formatNumericRows([1.5;2.25]),'1.5 2.25'));clear c;
    end
    function precisionBoundary()
        assert(strcmp(m2t2.util.formatNumber(1+eps),'1')); % Text is not a binary-double archive.
        values=[pi -pi realmin 1e-200 1e200 1e300];
        for v=values,decoded=str2double(m2t2.util.formatNumber(v));assert(abs(decoded/v-1)<5e-15);end
        % At the finite-double boundary the existing rounded decimal can
        % parse as Inf. Document this limit; do not claim archival round-trip.
        assert(strcmp(m2t2.util.formatNumber(realmax),'1.79769313486232e+308'));
        assert(isinf(str2double(m2t2.util.formatNumber(realmax))));
        ir=fixture();ir.axes{1}.series{1}.cdata(1)=1+eps;
        copy=ir;m2t2.render.renderPgfplots(ir,true);assert(isequaln(copy,ir)&&ir.axes{1}.series{1}.cdata(1)~=1);
    end
    function imageReference()
        ir=fixture();s=ir.axes{1}.series{1};s.x=[-0 .125 pi];s.y=[-2 4];s.cdata=[NaN -0 .25;1+eps .75 1];
        map=ir.axes{1}.colorMapping;
        for variant=1:2
            if variant==2,s.cdata=uint8([0 1 2;3 4 5]);s.mapping='direct';s.directIndexBase=0;end
            indices=m2t2.render.imageColorIndices(s.cdata,map,s.mapping,s.directIndexBase);
            expected={};for r=1:numel(s.y),for c=1:numel(s.x)
                values={s.x(c),s.y(r),s.cdata(r,c),indices(r,c)};parts=cellfun(@m2t2.util.formatNumber,values,'UniformOutput',false);expected{end+1}=m2t2.util.joinCell(parts,' '); %#ok<AGROW>
            end,end
            actual=m2t2.render.renderImage(s,'map',map);body=m2t2.util.joinCell(actual(3:end-1),sprintf('\n'));
            assert(strcmp(body,m2t2.util.joinCell(expected,sprintf('\n'))));
        end
    end
    function plannerOrder()
        ir=fixture();s=ir.axes{1}.series{1};s.id='rgb';s.colorMode='rgb';s.mapping='none';s.cdata=cat(3,ones(2,3),zeros(2,3),ones(2,3));
        s.alphaMode='constant';s.alphaData=.5;ir.axes{1}.series{2}=s;
        d=m2t.planning.selectImageBackend(ir,'auto');assert(strcmp(d.reason,'alpha_requires_hybrid'));
        again=m2t.planning.selectImageBackend(ir,'auto');assert(isequal(d,again));
        a=m2t2.render.makePgfplotsPlan(ir,true,m2t2.render.defaultConfig(),d.selected,'owned-assets');
        b=m2t2.render.makePgfplotsPlan(ir,true,m2t2.render.defaultConfig(),d.selected,'owned-assets');
        assert(isequaln(a,b)&&strcmp(a.assets(1).filename,'image-0001.png')&&strcmp(a.assets(2).filename,'image-0002.png'));
        assert(isempty(strfind(a.tex,outputDirectory))&&isempty(strfind(a.tex,tempdir)));
    end
    function irJsonTex()
        ir=fixture();before=jsonencode(ir);first=m2t2.render.renderPgfplots(ir,true);
        restored=m2t2.ir.fromJson(before);after=m2t2.ir.fromJson(jsonencode(restored));
        assert(isequaln(restored,after)&&strcmp(first,m2t2.render.renderPgfplots(restored,true)));
        assert(strcmp(before,jsonencode(ir))&&strcmp(first,m2t2.render.renderPgfplots(ir,true)));
        m2t.internal.writeTextFile(fullfile(outputDirectory,'canonical-fixture.tex'),first);
    end
    function pngEncoder()
        ir=fixture();s=ir.axes{1}.series{1};s.alphaMode='per_pixel';s.alphaData=[0 .5 1;1 .5 0];ir.axes{1}.series{1}=s;
        plan=m2t2.render.makePgfplotsPlan(ir,true,m2t2.render.defaultConfig(),'hybrid','assets');asset=plan.assets(1);
        a=fullfile(outputDirectory,'first.png');b=fullfile(outputDirectory,'second.png');
        m2t2.render.writePngAsset(asset,a);pause(1.1);m2t2.render.writePngAsset(asset,b);
        assert(isequal(bytes(a),bytes(b)));raw=bytes(a);offset=9;
        while offset<=numel(raw),n=double(raw(offset:offset+3))*[16777216;65536;256;1];kind=char(raw(offset+4:offset+7));assert(~strcmp(kind,'tIME'));offset=offset+12+n;end
        [rgb,map,alpha]=imread(a);assert(isempty(map)&&isequal(rgb,asset.rgb)&&isequal(alpha,asset.alpha));
    end
    function diagnosticOrder()
        f=figure('Visible','off','Color','w');c=onCleanup(@()close(f));a=axes('Parent',f,'Color','w');hggroup('Parent',a);hggroup('Parent',a,'HandleVisibility','off');
        one=m2t.internal.analyzeFigure(f);two=m2t.internal.analyzeFigure(f);assert(isequal(one.diagnostics,two.diagnostics));
        assert(strcmp(one.diagnostics(1).code,'M2T2:E001:UnsupportedObject'));clear c;
    end
    function nativeRepeat()
        f=figure('Visible','off','Color','w');c=onCleanup(@()close(f));a=axes('Parent',f);plot(a,[0 0 .5 1],[1 1 NaN 2]);set(a,'Color','w');
        one=m2t2.reader.readFigure(f);two=m2t2.reader.readFigure(f);assert(isequaln(one,two)&&strcmp(jsonencode(one),jsonencode(two)));
        assert(strcmp(m2t2.render.renderPgfplots(one,true),m2t2.render.renderPgfplots(two,true)));clear c;
    end
end
function ir=fixture()
    a=m2t2.ir.makeAxes();a.xlim=[.5 3.5];a.ylim=[.5 2.5];a.ydirection='reverse';a.background='white';
    s=m2t2.ir.makeImageSeries();s.x=1:3;s.y=1:2;s.cdata=[0 .25 .5;.75 1 .5];a.series={s};
    ir=m2t2.ir.makeFigure({a});ir.size=[320 200];
end
function value=bytes(path),f=fopen(path,'rb');c=onCleanup(@()fclose(f));value=fread(f,Inf,'*uint8').';clear c;end
