function summary=runM70ApiContractTests(outputDirectory)
%RUNM70APICONTRACTTESTS Freeze-candidate public calls with a real compiler.
    root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
    if nargin<1,outputDirectory=fullfile(root,'.audit','m70-api');end
    if exist(outputDirectory,'dir')~=7,mkdir(outputDirectory);end
    f=figure('Visible','off','Color','w');c=onCleanup(@()close(f));
    a=axes('Parent',f);plot(a,[0 1 2],[0 1 .5]);set(a,'Color','w');
    original=jsonencode(m2t2.reader.readFigure(f));
    cases={'defaults',@defaults;'option_failures',@options;'collision',@collision; ...
        'publication',@publication;'rich_auto',@rich;'set_inheritance',@inheritance; ...
        'set_preflight',@preflight;'set_failure_skip',@skipped};
    rows=cell(size(cases,1),3);failures=0;
    for k=1:size(cases,1)
        try,cases{k,2}();state='PASS';detail='';
        catch err,state='FAIL';failures=failures+1;detail=regexprep([err.identifier ' ' err.message],'[\r\n\t]+',' ');end
        rows(k,:)={cases{k,1},state,detail};
    end
    assert(strcmp(original,jsonencode(m2t2.reader.readFigure(f))));
    p=fullfile(outputDirectory,'api-results.tsv');fid=fopen(p,'w');guard=onCleanup(@()fclose(fid));
    fprintf(fid,'case\tstatus\tdetail\n');for k=1:size(rows,1),fprintf(fid,'%s\t%s\t%s\n',rows{k,:});end;clear guard;
    fprintf('%s',fileread(p));assert(failures==0,'M7.0 API contract failed.');
    summary=struct('tests',size(rows,1),'failures',failures);fprintf('M70_API_CONTRACT_PASS: 8/8\n');clear c;
    function defaults()
        r=m2t.export(f,fullfile(outputDirectory,'plot.v1'),'Overwrite',true);shape(r);assert(r.success&&strcmp(r.status,'success'));
        assert(strcmp(r.capability,'supported')&&strcmp(r.profile.name,'none')&&strcmp(r.profile.width,'source'));
        assert(strcmp(r.render.imageBackend.requested,'vector')&&strcmp(r.render.imageBackend.reason,'explicit_vector'));
        assert(strcmp(r.texPath,fullfile(outputDirectory,'plot.v1.tex'))&&isempty(r.logPath)&&isempty(r.render.assets));
    end
    function options()
        pairs={{'Unknown',true},{'Overwrite',1},{'Width','source'},{'Profile','missing'},{'ImageBackend','invalid'}};
        codes={'M2T:E001:InvalidArgument','M2T:E001:InvalidArgument','M2T:PROFILE_WIDTH_INVALID','M2T:PROFILE_UNKNOWN','M2T:IMAGE_BACKEND_UNKNOWN'};
        for j=1:numel(pairs)
            r=m2t.export(f,fullfile(outputDirectory,'invalid'),pairs{j}{:});shape(r);
            assert(~r.success&&strcmp(r.status,'export_failed')&&strcmp(r.diagnostics(1).code,codes{j}));
        end
        assert(exist(fullfile(outputDirectory,'invalid.tex'),'file')~=2);
    end
    function collision()
        base=fullfile(outputDirectory,'plot.v1');before=fileread([base '.tex']);r=m2t.export(f,base);shape(r);
        assert(~r.success&&strcmp(r.diagnostics(1).code,'M2T:E003:OutputExists')&&strcmp(before,fileread([base '.tex'])));
    end
    function publication()
        r=m2t.export(f,fullfile(outputDirectory,'profile'),'pRoFiLe','PUBLICATION','Width','DOUBLE-COLUMN','Overwrite',false,'Overwrite',true);shape(r);
        assert(r.success&&r.profile.widthMillimeters==170&&strcmp(r.profile.width,'double-column'));
    end
    function rich()
        g=figure('Visible','off','Color','w');cg=onCleanup(@()close(g));ax=axes('Parent',g);image('Parent',ax,'CData',cat(3,[1 0;0 1],[0 1;1 0],zeros(2)));set(ax,'Color','w');
        r=m2t.export(g,fullfile(outputDirectory,'forced'));shape(r);assert(~r.success&&strcmp(r.status,'export_failed')&&strcmp(r.capability,'supported'));
        assert(strcmp(r.diagnostics(1).code,'M2T2:E053:UnsupportedVectorRichImage')&&strcmp(r.diagnostics(1).stage,'planning'));
        r=m2t.export(g,fullfile(outputDirectory,'rgb'),'ImageBackend','AUTO','Overwrite',true);shape(r);assert(r.success&&numel(r.render.assets)==1);
        assert(strcmp(r.render.imageBackend.reason,'truecolor_requires_hybrid')&&strcmp(r.render.imageBackend.policy.id,'default-v1'));clear cg;
    end
    function inheritance()
        e=struct('figure',{f,f},'name',{'first','second'},'width',{[],'double-column'});
        r=m2t.exportSet(e,fullfile(outputDirectory,'set'),'Profile','publication','ImageBackend','auto','Overwrite',true);
        assert(r.success&&r.summary.succeeded==2&&isempty(r.diagnostics));
        assert(strcmp(r.entries(1).effective.width,'single-column')&&strcmp(r.entries(2).effective.width,'double-column'));
        for j=1:2,shape(r.entries(j).result);end
        m=jsondecode(fileread(r.manifestPath));assert(m.schemaVersion==1&&m.defaults.continueOnError&&strcmp(m.figures(1).tex,'first.tex'));
        assert(strcmp(m.figures(2).backendReason,'no_image_layer')&&isempty(strfind(fileread(r.manifestPath),outputDirectory)));
    end
    function preflight()
        e=struct('figure',{f,f},'name',{'Same','same'});out=fullfile(outputDirectory,'invalid-set');
        r=m2t.exportSet(e,out);assert(~r.success&&strcmp(r.status,'invalid_set')&&isempty(r.entries));
        assert(strcmp(r.diagnostics(1).code,'M2T:SET_DUPLICATE_NAME')&&exist(out,'dir')~=7);
    end
    function skipped()
        g=figure('Visible','off','Color','w');cg=onCleanup(@()close(g));ax=axes('Parent',g,'Color','w');hggroup('Parent',ax);
        e=struct('figure',{g,f},'name',{'bad','later'});r=m2t.exportSet(e,fullfile(outputDirectory,'stopped'),'ContinueOnError',false,'Overwrite',true);
        assert(~r.success&&strcmp(r.status,'failed')&&r.summary.unsupported==1&&r.summary.skipped==1&&r.summary.failed==0);
        assert(isempty(r.diagnostics)&&strcmp(r.entries(2).result.diagnostics(1).code,'M2T:SET_SKIPPED_AFTER_FAILURE'));
        m=jsondecode(fileread(r.manifestPath));assert(strcmp(m.figures(2).status,'skipped')&&strcmp(m.figures(2).selectedImageBackend,''));clear cg;
    end
end
function shape(r)
    assert(all(isfield(r,{'success','status','capability','texPath','pdfPath','logPath','backend','render','compiler','profile','diagnostics','timings'})));
    assert(islogical(r.success)&&isscalar(r.success)&&strcmp(r.backend,'pgfplots')&&strcmp(r.compiler,'lualatex'));
    assert(all(isfield(r.render,{'requestedImageBackend','effectiveImageBackend','imageBackend','assets'})));
    assert(all(isfield(r.render.imageBackend,{'requested','selected','reason','policy','imageLayerCount','maxImageCells'})));
    assert(all(isfield(r.profile,{'name','width','widthMillimeters','figureSize','figureSizeUnit'})));
    assert(all(isfield(r.timings,{'analysis','export','compile','validation','total'})));
    assert(all(isfield(r.diagnostics,{'severity','code','message','stage'})));
end
