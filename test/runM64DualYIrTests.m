function summary=runM64DualYIrTests(outputDirectory)
%RUNM64DUALYIRTESTS Handle-free side ownership, overlay and validation contract.
    root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
    if nargin<1,outputDirectory=fullfile(root,'.audit','m64-dual-ir');end
    if exist(outputDirectory,'dir')~=7,mkdir(outputDirectory);end
    ir=fixture();cases={'ordered_coordinates',@renderCase;'json_roundtrip',@jsonCase; ...
        'profile_85',@()profileCase('single-column');'profile_170',@()profileCase('double-column'); ...
        'missing_side',@()badCase('missing');'unknown_side',@()badCase('unknown'); ...
        'orphan_right',@()badCase('orphan');'invalid_limits',@()badCase('limits'); ...
        'negative_log',@()badCase('log');'unsupported_series',@()badCase('series'); ...
        'overlay_owner',@()badCase('overlay');'annotation_owner',@()badCase('annotation'); ...
        'independent_scales',@scaleCase;'old_ir_unchanged',@oldCase; ...
        'scatter_role_isolation',@scatterRoleCase;'colorbar_profile_gutter',@colorbarGutterCase};
    rows=cell(size(cases,1),3);failures=0;
    for k=1:size(cases,1)
        try,cases{k,2}();status='PASS';detail='assertions passed';
        catch err,status='FAIL';failures=failures+1;detail=regexprep([err.identifier ': ' err.message],'[\r\n\t]+',' ');end
        rows(k,:)={cases{k,1},status,detail};
    end
    path=fullfile(outputDirectory,'dual-ir-results.tsv');writeRows(path,rows);
    summary=struct('tests',size(rows,1),'failures',failures,'resultPath',path);
    fprintf('%s',fileread(path));assert(failures==0,'M6.4 portable acceptance failed.');
    function renderCase()
        tex=m2t2.render.renderPgfplots(ir,true);
        assert(strcmp(tex,m2t2.render.renderPgfplots(ir,true)));
        assert(~isempty(strfind(tex,'axis y line*=left'))&&~isempty(strfind(tex,'axis y line*=right')));
        first=strfind(tex,'(1,2)');second=strfind(tex,'(1,100)');third=strfind(tex,'(1,3)');
        assert(numel(first)==1&&numel(second)==1&&numel(third)==1&&first<second&&second<third);
        assert(numel(strfind(tex,'\addlegendentry'))==3);
        save(ir,'dual',m2t2.render.defaultConfig());
    end
    function jsonCase()
        a=m2t2.ir.fromJson(jsonencode(ir));assert(strcmp(jsonencode(a.axes{1}.dualY),jsonencode(ir.axes{1}.dualY)));
        assert(strcmp(m2t2.render.renderPgfplots(a,true),m2t2.render.renderPgfplots(ir,true)));
    end
    function profileCase(width)
        p=m2t.profile.getSelection('publication',width);q=m2t.profile.apply(ir,p.profile,p.width);
        assert(q.success&&isequal(q.ir.axes{1}.series,ir.axes{1}.series));
        assert(isequal(q.ir.layout,ir.layout));
        assert((1-q.ir.axes{1}.placement.x-q.ir.axes{1}.placement.width)*q.ir.size(1)>=38);
        save(q.ir,width,q.renderConfig);
    end
    function scaleCase()
        a=ir;a.axes{1}.dualY.right.scale='log';save(a,'right-log',m2t2.render.defaultConfig());
        a.axes{1}.yscale='log';a.axes{1}.ylim=[1 10];save(a,'both-log',m2t2.render.defaultConfig());
    end
    function scatterRoleCase()
        a=ir;a.axes{1}.series={};a.axes{1}.legend=m2t2.ir.makeLegend();
        for n=1:3
            s=m2t2.ir.makeScatterSeries();s.id=sprintf('scatter-%d',n);s.yAxis='right';
            s.x=[1.25 2 2.75];s.y=[100 200 300]+(n-1)*200;s.markerSize=12;
            s.edgeMode='none';s.faceMode='data';s.colorMode='scalar_mapped';s.colorData=[0 .5 1];
            if n==2,s.colorMode='per_point_rgb';s.colorData=[1 0 0;0 1 0;0 0 1];end
            if n==3,s.edgeMode='data';s.faceMode='none';end
            a.axes{1}.series{n}=s;
        end
        a.axes{1}.colorMapping.limits=[0 1];tex=m2t2.render.renderPgfplots(a,true);
        assert(isempty(strfind(tex,'\addplot+[only marks')));
        assert(~isempty(strfind(tex,'draw opacity=0'))&&~isempty(strfind(tex,'fill opacity=0')));
        save(a,'scatter-roles',m2t2.render.defaultConfig());
    end
    function colorbarGutterCase()
        a=ir;b=m2t2.ir.makeColorbar();b.owner=m2t2.ir.makeOwner('axes',a.axes{1}.id);
        b.associatedAxesIds={a.axes{1}.id};b.placement=m2t2.ir.makePlacement(.85,.2,.04,.65);
        a.elements={b};
        for width={'single-column','double-column'}
            p=m2t.profile.getSelection('publication',width{1});q=m2t.profile.apply(a,p.profile,p.width);
            rect=q.ir.elements{1}.placement;w=q.ir.size(1);
            assert(abs(rect.width*w-8)<1e-9&&(1-rect.x-rect.width)*w>=31);
        end
    end
    function oldCase()
        a=ir;a.axes{1}=rmfield(a.axes{1},'dualY');
        for n=1:3,a.axes{1}.series{n}=rmfield(a.axes{1}.series{n},'yAxis');end
        b=m2t2.ir.fromJson(jsonencode(a));assert(~isfield(b.axes{1},'dualY'));
        assert(numel(strfind(m2t2.render.renderPgfplots(b,true),'\begin{axis}'))==1);
    end
    function badCase(kind)
        a=ir;
        switch kind
            case 'missing',a.axes{1}.series{1}=rmfield(a.axes{1}.series{1},'yAxis');
            case 'unknown',a.axes{1}.series{1}.yAxis='middle';
            case 'orphan',a.axes{1}=rmfield(a.axes{1},'dualY');
            case 'limits',a.axes{1}.dualY.right.limits=[1 1];
            case 'log',a.axes{1}.dualY.right.scale='log';a.axes{1}.series{2}.y(1)=0;
            case 'series',a.axes{1}.series{1}.kind='m2t2.image';
            case 'overlay',a.axes{1}.overlayOf='axes-2';
            case 'annotation',a.annotations={m2t2.ir.makeTextAnnotation()};
        end
        caught=false;try,m2t2.ir.validate(a);catch err,caught=strcmp(err.identifier,'M2T2:E003:InvalidIR');end;assert(caught);
    end
    function save(a,name,config)
        m2t.internal.writeTextFile(fullfile(outputDirectory,[name '.tex']),m2t2.render.renderPgfplots(a,true,config));
        m2t.internal.writeTextFile(fullfile(outputDirectory,[name '.json']),jsonencode(a));
    end
end
function ir=fixture()
    a=m2t2.ir.makeAxes();a.xlim=[1 3];a.ylim=[0 5];a.box='off';
    a.placement=m2t2.ir.makePlacement(.18,.2,.6,.65);
    a.xlabel=m2t2.ir.makeText('Time');a.ylabel=m2t2.ir.makeText('Left');
    a.dualY=struct('leftColor',[0 .3 .7],'right',struct('limits',[10 1000], ...
        'scale','linear','direction','normal','ticks',m2t2.ir.makeTickSpec(), ...
        'label',m2t2.ir.makeText('Right'),'color',[.8 .2 0]));
    for k=1:3
        s=m2t2.ir.makeLineSeries();s.id=sprintf('series-%d',k);s.x=1:3;
        s.y=[k+1 k+2 k+1];s.yAxis='left';s.color=[0 .3 .7];
        if k==2,s.y=[100 200 400];s.yAxis='right';s.color=[.8 .2 0];end
        if k==3,s.y=[3 4 3];s.style='dashed';end
        s.displayName=m2t2.ir.makeText(['Trace ' num2str(k)]);a.series{k}=s;
    end
    a.legend.visible=true;
    for k=[2 1 3],s=a.series{k};a.legend.entries{end+1}=m2t2.ir.makeLegendEntry(s.id,s.displayName);end
    ir=m2t2.ir.makeFigure({a});ir.size=[480 300];
end
function writeRows(path,rows)
    text=sprintf('case\tstatus\tdetail\n');for k=1:size(rows,1),text=[text sprintf('%s\t%s\t%s\n',rows{k,:})];end %#ok<AGROW>
    m2t.internal.writeTextFile(path,text);
end
