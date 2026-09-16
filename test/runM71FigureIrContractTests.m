function summary=runM71FigureIrContractTests(outputDirectory)
%RUNM71FIGUREIRCONTRACTTESTS Stored schema/default/ownership and JSON contract.
    root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
    if nargin<1,outputDirectory=fullfile(root,'.audit','m71-ir');end
    if exist(outputDirectory,'dir')~=7,mkdir(outputDirectory);end
    fixtures=fullfile(root,'test','fixtures','ir','compatibility');
    names={'pre-m61-scatter','rich-scatter','pre-m62-image','rich-image-alpha', ...
        'tiled-layout','dual-y','scientific-3d','bar-background','line-gaps'};
    rows={};
    for k=1:numel(names)
        ir=loadFixture(names{k});checkMeaning(ir,names{k});
        encoded=m2t2.ir.toJson(ir);replay=m2t2.ir.fromJson(encoded);
        assert(strcmp(encoded,strtrim(fileread(fullfile(fixtures,[names{k} '.canonical.json'])))));
        assert(isequaln(ir,replay));
        assert(strcmp(encoded,m2t2.ir.toJson(replay)));
        assert(isequaln(replay,m2t2.ir.fromJson(m2t2.ir.toJson(replay))));
        assert(strcmp(encoded,m2t2.ir.toJson(reverseKeys(ir))));
        first=m2t2.render.makePgfplotsPlan(ir,true,m2t2.render.defaultConfig(),'hybrid','fixture-assets');
        second=m2t2.render.makePgfplotsPlan(replay,true,m2t2.render.defaultConfig(),'hybrid','fixture-assets');
        assert(isequaln(first,second));
        m2t.internal.writeTextFile(fullfile(outputDirectory,[names{k} '.json']),encoded);
        m2t.internal.writeTextFile(fullfile(outputDirectory,[names{k} '.tex']),first.tex);
        rows(end+1,:)={names{k},'PASS'}; %#ok<AGROW>
    end
    cases={'v1_migration',@v1;'unsupported_versions',@versions; ...
        'required_fields',@required;'unknown_fields',@unknown; ...
        'ownership_not_guessed',@ownership;'nan_and_numeric_edges',@numbers; ...
        'singleton_image_shapes',@singletons;'json_errors_and_strings',@syntax; ...
        'order_preserved',@ordering};
    for k=1:size(cases,1),cases{k,2}();rows(end+1,:)={cases{k,1},'PASS'};end %#ok<AGROW>
    p=fullfile(outputDirectory,'m71-ir-results.tsv');fid=fopen(p,'w');guard=onCleanup(@()fclose(fid));
    fprintf(fid,'case\tstatus\n');for k=1:size(rows,1),fprintf(fid,'%s\t%s\n',rows{k,:});end;clear guard;
    summary=struct('tests',size(rows,1),'failures',0);fprintf('M71_IR_CONTRACT_PASS: %d/%d\n',summary.tests,summary.tests);
    function ir=loadFixture(name),ir=m2t2.ir.fromJson(fileread(fullfile(fixtures,[name '.json'])));end
    function v1()
        old=fileread(fullfile(root,'test','fixtures','ir','line-v1.json'));r=m2t2.ir.fromJson(old);
        assert(r.version==2&&strcmp(r.axes{1}.xlabel.interpreter,'plain')&&r.axes{1}.legend.visible);
        assert(strcmp(r.axes{1}.series{1}.id,'axes-1-series-1')&&isequal(r.axes{1}.series{1}.y,[0 .25 1]));
        assert(strcmp(m2t2.ir.toJson(r),m2t2.ir.toJson(m2t2.ir.fromJson(old))));
        reject(strrep(old,'m2t2.line','m2t2.scatter'),'M2T2:E003:InvalidIR');
        d=jsondecode(old);d.axes.extraOwner='unknown';reject(jsonencode(d),'M2T2:E003:InvalidIR');
    end
    function versions()
        for v={3,99,0,-1,2.5,[],[1 2],'2',true}
            ir=loadFixture('rich-scatter');ir.version=v{1};reject(jsonencode(ir),'M2T2:E008:UnsupportedIRVersion');
        end
        ir=loadFixture('rich-scatter');reject(jsonencode(rmfield(ir,'version')),'M2T2:E008:UnsupportedIRVersion');
    end
    function required()
        ir=loadFixture('rich-scatter');a=ir;a=rmfield(a,'axes');reject(jsonencode(a),'M2T2:E003:InvalidIR');
        a=ir;a.axes{1}=rmfield(a.axes{1},'id');reject(jsonencode(a),'M2T2:E003:InvalidIR');
        a=ir;a.axes{1}.series{1}=rmfield(a.axes{1}.series{1},'y');reject(jsonencode(a),'M2T2:E003:InvalidIR');
        a=ir;a.axes{1}.series{1}.x=[0 1;2 3];reject(jsonencode(a),'M2T2:E003:InvalidIR');
        a=ir;a.axes={ir.axes{1},ir.axes{1};ir.axes{1},ir.axes{1}};reject(jsonencode(a),'M2T2:E003:InvalidIR');
        a=ir;a.axes{1}.series{1}=rmfield(a.axes{1}.series{1},'id');r=m2t2.ir.fromJson(jsonencode(a));assert(strcmp(r.axes{1}.series{1}.id,'axes-1-series-1'));
        a=loadFixture('pre-m61-scatter');a.axes{1}.series{1}=rmfield(a.axes{1}.series{1},'edgeMode');a.axes{1}.series{1}.edgeColor=[1 0 0];
        r=m2t2.ir.fromJson(jsonencode(a));assert(isequal(r.axes{1}.series{1}.edgeColor,[1 0 0]));
    end
    function unknown()
        ir=loadFixture('rich-scatter');ir.metadata=struct('label','opaque metadata','revision',7);
        ir.axes{1}.series{1}.extraNote='not interpreted';r=m2t2.ir.fromJson(m2t2.ir.toJson(ir));
        assert(isequal(r.metadata,ir.metadata)&&strcmp(r.axes{1}.series{1}.extraNote,'not interpreted'));
        ir.axes{1}.series{1}.kind='m2t2.future';reject(jsonencode(ir),'M2T2:E008:UnsupportedIRVersion');
    end
    function ownership()
        ir=loadFixture('dual-y');ir.axes{1}.series{2}=rmfield(ir.axes{1}.series{2},'yAxis');reject(jsonencode(ir),'M2T2:E003:InvalidIR');
        ir=loadFixture('scientific-3d');ir.axes{1}=rmfield(ir.axes{1},'sceneOrder');reject(jsonencode(ir),'M2T2:E003:InvalidIR');
        ir=loadFixture('tiled-layout');ir.layout.cells(2)=[];reject(jsonencode(ir),'M2T2:E003:InvalidIR');
        ir=loadFixture('bar-background');ir.axes{1}.series{1}=rmfield(ir.axes{1}.series{1},'owner');reject(jsonencode(ir),'M2T2:E003:InvalidIR');
        ir=loadFixture('tiled-layout');n=m2t2.ir.makeSharedLabel('title',m2t2.ir.makeText('Shared'));n.owner=struct('id','figure');ir.elements={n};reject(jsonencode(ir),'M2T2:E003:InvalidIR');
        n.owner=m2t2.ir.makeOwner();n=rmfield(n,'text');ir.elements={n};reject(jsonencode(ir),'M2T2:E003:InvalidIR');
        ir.elements={};n=m2t2.ir.makeArrowAnnotation();n=rmfield(n,'start');ir.annotations={n};reject(jsonencode(ir),'M2T2:E003:InvalidIR');
        n=m2t2.ir.makeArrowAnnotation();n.owner=struct('kind','figure');ir.annotations={n};reject(jsonencode(ir),'M2T2:E003:InvalidIR');
        n=m2t2.ir.makeArrowAnnotation();n.start=[.1 .3];n.end=[.6 .8];ir.annotations={n};
        r=m2t2.ir.fromJson(m2t2.ir.toJson(ir));assert(isequal(r.annotations{1},n));
        assert(strcmp(m2t2.render.renderPgfplots(ir,true),m2t2.render.renderPgfplots(r,true)));
    end
    function numbers()
        ir=loadFixture('line-gaps');s=ir.axes{1}.series{1};s.x=NaN;s.y=NaN;ir.axes{1}.series={s};
        reject(jsonencode(ir),'M2T2:E003:InvalidIR');r=m2t2.ir.fromJson(m2t2.ir.toJson(ir));assert(isscalar(r.axes{1}.series{1}.x)&&isnan(r.axes{1}.series{1}.x));
        s.x=[0 -0 realmin realmax 1+eps];s.y=s.x;ir.axes{1}.series={s};r=m2t2.ir.fromJson(m2t2.ir.toJson(ir));assert(isequal(r.axes{1}.series{1}.x,s.x));
        s.x=[];s.y=[];ir.axes{1}.series={s};r=m2t2.ir.fromJson(m2t2.ir.toJson(ir));assert(isempty(r.axes{1}.series{1}.x));
    end
    function singletons()
        for dims={[1 1],[1 2],[2 1]}
            ir=loadFixture('rich-image-alpha');s=ir.axes{1}.series{1};sz=dims{1};s.x=1:sz(2);s.y=1:sz(1);s.cdata=reshape(linspace(0,1,prod(sz)*3),[sz 3]);s.alphaData=reshape(linspace(.2,.8,prod(sz)),sz);ir.axes{1}.series={s};
            r=m2t2.ir.fromJson(m2t2.ir.toJson(ir));assert(isequal(r.axes{1}.series{1}.cdata,s.cdata)&&isequal(r.axes{1}.series{1}.alphaData,s.alphaData));
        end
        ir=loadFixture('pre-m62-image');s=ir.axes{1}.series{1};s.x=1;s.y=1;s.cdata=NaN;ir.axes{1}.series={s};r=m2t2.ir.fromJson(m2t2.ir.toJson(ir));assert(isnan(r.axes{1}.series{1}.cdata));
    end
    function syntax()
        for bad={'{','[]','null','{"kind":"m2t2.figure","version":2,"axes":42}'},reject(bad{1},'M2T2:E003:InvalidIR');end
        reject('{"kind":"m2t2.figure","version":2,"axes":[],"bad-key":1}','M2T2:E003:InvalidIR');
        ir=loadFixture('line-gaps');ir.metadata='literal "x":null, braces } and slash \\';j=m2t2.ir.toJson(ir);r=m2t2.ir.fromJson(j);assert(strcmp(r.metadata,ir.metadata));
        if ~exist('OCTAVE_VERSION','builtin'),r=m2t2.ir.fromJson(string(j));assert(strcmp(r.metadata,ir.metadata));end
    end
    function ordering()
        ir=loadFixture('dual-y');ir.axes{1}.series=ir.axes{1}.series([2 1]);r=m2t2.ir.fromJson(m2t2.ir.toJson(ir));assert(strcmp(r.axes{1}.series{1}.id,'right'));
        assert(isequal(r.axes{1}.series{1}.y,[100 200 150]));
    end
end
function checkMeaning(ir,name)
    s=ir.axes{1}.series{1};
    switch name
        case 'pre-m61-scatter',assert(strcmp(s.colorMode,'constant_rgb')&&strcmp(s.sizeMode,'constant')&&strcmp(s.faceMode,'none')&&isequal(s.edgeColor,[.2 .4 .6]));
        case 'rich-scatter',assert(isequal(s.markerSize,[4 6 8])&&isequal(s.colorData,eye(3))&&strcmp(s.faceMode,'data'));
        case 'pre-m62-image',assert(strcmp(s.colorMode,'scalar')&&strcmp(s.alphaMode,'opaque')&&s.directIndexBase==1&&isequal(s.cdata,[0 1;2 3]));
        case 'rich-image-alpha',assert(isequal(s.alphaData,[1 .5;.25 0])&&isequal(squeeze(s.cdata(1,2,:)).',[0 1 0]));
        case 'tiled-layout',assert(numel(ir.axes)==2&&strcmp(ir.layout.cells{2}.axesId,'axes-2')&&strcmp(ir.layout.tiled.indexing,'rowmajor'));
        case 'dual-y',assert(strcmp(ir.axes{1}.series{2}.yAxis,'right')&&isequal(ir.axes{1}.dualY.right.limits,[0 300]));
        case 'scientific-3d',assert(strcmp(s.kind,'m2t2.scatter3')&&isequal(s.z,[0 .5 1])&&strcmp(ir.axes{1}.sceneOrder,'depth'));
        case 'bar-background',assert(strcmp(ir.axes{1}.background,'white')&&isequal(s.xBounds,[-.3 .3;.7 1.3;1.7 2.3]));
        case 'line-gaps',assert(numel(s.x)==3&&isnan(s.x(2))&&isnan(s.y(2)));
    end
end
function value=reverseKeys(value)
    if isstruct(value)
        value=orderfields(value,flipud(fieldnames(value)));
        names=fieldnames(value);for i=1:numel(value),for j=1:numel(names),value(i).(names{j})=reverseKeys(value(i).(names{j}));end,end
    elseif iscell(value),value=cellfun(@reverseKeys,value,'UniformOutput',false);end
end
function reject(text,code)
    try,m2t2.ir.fromJson(text);error('M2T:ExpectedFailure','invalid JSON accepted');catch err,assert(strcmp(err.identifier,code),['unexpected code ' err.identifier]);end
end
