function summary=runM64DualYMatlabTests(outputDirectory)
%RUNM64DUALYMATLABTESTS Native side ownership and lifecycle acceptance gate.
    assert(~exist('OCTAVE_VERSION','builtin'),'Native MATLAB required.');
    root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
    if nargin<1,outputDirectory=fullfile(root,'.audit','m64-dual-matlab');end
    if exist(outputDirectory,'dir')~=7,mkdir(outputDirectory);end
    cases={'ownership',@ownershipCase;'legend_reordered',@legendCase;'active_side_lifecycle',@lifecycleCase; ...
        'independent_ticks',@ticksCase;'right_log',@()scaleCase(false,true); ...
        'left_log',@()scaleCase(true,false);'both_log',@()scaleCase(true,true); ...
        'reversed_right',@reverseCase;'colorbar',@colorbarCase; ...
        'tiled',@tiledCase;'profile_85',@()profileCase('single-column',false); ...
        'profile_170',@()profileCase('double-column',false); ...
        'tiled_profile_85',@()profileCase('single-column',true); ...
        'tiled_profile_170',@()profileCase('double-column',true); ...
        'hidden_handle_rejected',@()negativeCase('hidden');'bar_rejected',@()negativeCase('bar'); ...
        'text_rejected',@()negativeCase('text');'minor_ticks_rejected',@()negativeCase('minor'); ...
        'rotated_ticks_rejected',@()negativeCase('rotation');'negative_log_rejected',@()negativeCase('log')};
    rows=cell(size(cases,1),3);failures=0;
    for caseIndex=1:size(cases,1)
        try,cases{caseIndex,2}();status='PASS';detail='assertions passed';
        catch err,status='FAIL';failures=failures+1;detail=regexprep([err.identifier ': ' err.message],'[\r\n\t]+',' ');end
        rows(caseIndex,:)={cases{caseIndex,1},status,detail};
    end
    path=fullfile(outputDirectory,'dual-matlab-results.tsv');report=sprintf('case\tstatus\tdetail\n');
    for reportIndex=1:size(rows,1),report=[report sprintf('%s\t%s\t%s\n',rows{reportIndex,:})];end %#ok<AGROW>
    m2t.internal.writeTextFile(path,report);fprintf('%s',report);
    summary=struct('tests',size(rows,1),'failures',failures,'resultPath',path);
    assert(failures==0,'M6.4 native acceptance failed.');
    function ownershipCase()
        [f,a,h,c]=base(false);ir=m2t2.reader.readFigure(f);n=ir.axes{1};
        assert(numel(n.series)==3&&isequal({n.series{1}.yAxis,n.series{2}.yAxis,n.series{3}.yAxis},{'left','left','right'}));
        order=flipud(allchild(a));
        for k=1:3,assert(isequal(n.series{k}.y,reshape(order(k).YData,1,[])));end
        assert(isequal(n.ylim,a.YAxis(1).Limits)&&isequal(n.dualY.right.limits,a.YAxis(2).Limits));
        saveIR(ir,'ownership');clear c;
    end
    function legendCase()
        [f,a,h,c]=base(false);legend(a,h([2 3 1]),{'Right first','Second left','First left'});
        ir=m2t2.reader.readFigure(f);n=ir.axes{1};
        assert(isequal(cellfun(@(e)e.seriesId,n.legend.entries,'UniformOutput',false), ...
            {n.series{3}.id,n.series{2}.id,n.series{1}.id}));saveIR(ir,'legend');clear c;
    end
    function lifecycleCase()
        [f,a,h,c]=base(false);yyaxis(a,'right');drawnow;
        before=state(a,h);first=m2t2.reader.readFigure(f);assert(isequaln(before,state(a,h)));
        yyaxis(a,'left');drawnow;left=state(a,h);second=m2t2.reader.readFigure(f);
        assert(isequaln(left,state(a,h))&&isequaln(first,second));clear c;
    end
    function ticksCase()
        [f,a,~,c]=base(false);yyaxis(a,'left');yticks(a,[1 3 5]);yticklabels(a,{'low','mid','high'});
        yyaxis(a,'right');yticks(a,[10 100 1000]);yticklabels(a,{'ten','hundred','thousand'});
        ir=m2t2.reader.readFigure(f);assert(isequal(ir.axes{1}.dualY.right.ticks.values,[10 100 1000]));
        assert(strcmp(ir.axes{1}.yticks.labels{1}.value,'low'));saveIR(ir,'ticks');clear c;
    end
    function scaleCase(left,right)
        [f,a,~,c]=base(false);if left,yyaxis(a,'left');set(a,'YScale','log');end
        if right,yyaxis(a,'right');set(a,'YScale','log');end
        drawnow;ir=m2t2.reader.readFigure(f);assert(strcmp(ir.axes{1}.yscale,'log')==left);
        assert(strcmp(ir.axes{1}.dualY.right.scale,'log')==right);saveIR(ir,sprintf('scales-%d-%d',left,right));clear c;
    end
    function reverseCase()
        [f,a,~,c]=base(false);yyaxis(a,'right');set(a,'YDir','reverse');
        ir=m2t2.reader.readFigure(f);assert(strcmp(ir.axes{1}.dualY.right.direction,'reverse'));saveIR(ir,'reverse');clear c;
    end
    function colorbarCase()
        [f,a,~,c]=base(false);colorbar(a);drawnow;ir=m2t2.reader.readFigure(f);
        assert(numel(ir.elements)==1&&strcmp(ir.elements{1}.owner.id,ir.axes{1}.id));saveIR(ir,'colorbar');clear c;
    end
    function tiledCase()
        [f,~,~,c]=base(true);ir=m2t2.reader.readFigure(f);assert(isfield(ir.layout,'tiled')&&numel(ir.axes)==2);
        saveIR(ir,'tiled');clear c;
    end
    function profileCase(width,tiled)
        [f,~,~,c]=base(tiled);ir=m2t2.reader.readFigure(f);p=m2t.profile.getSelection('publication',width);
        q=m2t.profile.apply(ir,p.profile,p.width);assert(q.success&&isequal(ir.axes{1}.series,q.ir.axes{1}.series));
        saveIR(q.ir,sprintf('%s-tiled-%d',width,tiled),q.renderConfig);clear c;
    end
    function negativeCase(kind)
        [f,a,h,c]=base(false);yyaxis(a,'right');
        switch kind
            case 'hidden',h(2).HandleVisibility='off';
            case 'bar',hold(a,'on');bar(a,1:3,[100 200 300]);
            case 'text',text(a,2,100,'Semantic text');
            case 'minor',a.YAxis(2).MinorTick='on';
            case 'rotation',a.YAxis(2).TickLabelRotation=45;
            case 'log',a.YScale='log';h(2).YData=[-1 100 1000];
        end
        drawnow;before=state(a,h);r=m2t.export(f,fullfile(outputDirectory,['rejected-' kind]),'Overwrite',true);
        assert(~r.success&&~isempty(r.diagnostics));assert(isequaln(before,state(a,h)));
        assert(exist(fullfile(outputDirectory,['rejected-' kind '.tex']),'file')~=2);clear c;
    end
    function saveIR(ir,name,config)
        if nargin<3,config=m2t2.render.defaultConfig();end
        m2t.internal.writeTextFile(fullfile(outputDirectory,[name '.tex']),m2t2.render.renderPgfplots(ir,true,config));
        m2t.internal.writeTextFile(fullfile(outputDirectory,[name '.json']),jsonencode(ir));
    end
end
function [f,a,h,c]=base(tiled)
    f=figure('Visible','off','Color','w','Position',[100 100 1000 650]);c=onCleanup(@()close(f));
    if tiled
        f.Position=[100 100 1000 1000];
        t=tiledlayout(f,2,1,'TileSpacing','compact','Padding','compact');a=nexttile(t);
    else,a=axes(f);end
    yyaxis(a,'left');h(1)=plot(a,1:3,[1 3 2],'DisplayName','Left line');ylim(a,[1 5]);ylabel(a,'Left units');
    yyaxis(a,'right');h(2)=scatter(a,1:3,[10 100 1000],[25 49 81],[0;.5;1],'filled','DisplayName','Right scatter');
    ylim(a,[10 1000]);ylabel(a,'Right units');
    yyaxis(a,'left');hold(a,'on');h(3)=plot(a,1:3,[4 2 3],'--','DisplayName','Left later');
    xlabel(a,'Time');title(a,'Dual Y');legend(a,h,{'Left line','Right scatter','Left later'});
    if tiled,b=nexttile(t);plot(b,1:3,[3 2 1]);xlabel(b,'Time');ylabel(b,'Control');title(t,'Shared title');end
    drawnow;
end
function s=state(a,h)
    s={a.YAxisLocation,a.Position,a.Units,a.XLim,a.YAxis(1).Limits,a.YAxis(2).Limits, ...
        a.YAxis(1).Scale,a.YAxis(2).Scale,a.Children};
    for k=1:numel(h),s{end+1}=h(k).XData;s{end+1}=h(k).YData;end
end
