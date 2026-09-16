function summary=runM72RuntimeCompatibilityTests(outputDirectory,compile)
%RUNM72RUNTIMECOMPATIBILITYTESTS Synthetic native/portable evidence, separately.
    root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
    if nargin<1,outputDirectory=fullfile(root,'.audit','m72-runtime');end
    if nargin<2,compile=false;end
    if exist(outputDirectory,'dir')~=7,mkdir(outputDirectory);end
    native=~exist('OCTAVE_VERSION','builtin');rows=cell(15,4);failures=0;
    for k=1:15
        layer='native-reader';detail='';
        try
            [f,ir,layer]=fixture(k);guard=onCleanup(@()close(f));
            m2t2.ir.validate(ir);canonical=m2t2.ir.toJson(ir);
            assert(strcmp(canonical,m2t2.ir.toJson(m2t2.ir.fromJson(canonical))));
            if strcmp(layer,'native-reader')
                assert(strcmp(canonical,m2t2.ir.toJson(m2t2.reader.readFigure(f))));
            end
            name=sprintf('R%02d',k);assets=[name '-assets'];
            plan=m2t2.render.makePgfplotsPlan(ir,true,m2t2.render.defaultConfig(),'hybrid',assets);
            replay=m2t2.render.makePgfplotsPlan(m2t2.ir.fromJson(canonical),true,m2t2.render.defaultConfig(),'hybrid',assets);
            assert(strcmp(plan.tex,replay.tex));
            m2t.internal.writeTextFile(fullfile(outputDirectory,[name '.json']),canonical);
            m2t.internal.writeTextFile(fullfile(outputDirectory,[name '.tex']),plan.tex);
            if compile
                folder=fullfile(outputDirectory,assets);if exist(folder,'dir')~=7,mkdir(folder);end
                for j=1:numel(plan.assets),m2t2.render.writePngAsset(plan.assets(j),fullfile(folder,plan.assets(j).filename));end
                pdf=fullfile(outputDirectory,[name '.pdf']);
                result=m2t.internal.compileLuaLatex(fullfile(outputDirectory,[name '.tex']),pdf,'lualatex');
                assert(result.success,['Compiler failed for ' name]);pdfResult=m2t.internal.validatePdf(pdf);assert(pdfResult.success);
                if k==14
                    result=m2t.export(f,fullfile(outputDirectory,'profile'),'Profile','publication','Overwrite',true);
                    assert(result.success&&result.profile.widthMillimeters==85);
                elseif k==15
                    entries=struct('figure',{f,f},'name',{'first','second'});
                    result=m2t.exportSet(entries,fullfile(outputDirectory,'set'),'Overwrite',true);
                    assert(result.success&&result.summary.succeeded==2);
                end
            end
            state='PASS';clear guard;
        catch err
            state='FAIL';failures=failures+1;detail=regexprep([err.identifier ' ' err.message],'[\r\n\t]+',' ');
        end
        rows(k,:)={sprintf('R%02d',k),state,layer,detail};
    end
    propertyAndTextTests(native);
    report=sprintf('case\tstatus\tevidence\tdetail\n');
    for k=1:15,report=[report sprintf('%s\t%s\t%s\t%s\n',rows{k,:})];end %#ok<AGROW>
    m2t.internal.writeTextFile(fullfile(outputDirectory,'runtime-results.tsv'),report);fprintf('%s',report);
    summary=struct('tests',15,'failures',failures,'compile',compile);
    assert(failures==0,'M7.2 runtime matrix failed.');fprintf('M72_RUNTIME_PASS: 15/15 compile=%d nativeMatlab=%d\n',compile,native);
    function [f,ir,layer]=fixture(k)
        f=figure('Visible','off','Color','w');a=axes('Parent',f,'Color','w');layer='native-reader';
        if ~native&&any(k==[5 6 7])
            layer='portable-only (native supported constructor unavailable)';
            if k==5
                s=m2t2.ir.makeBoxplotSeries();s.positions=1;s.lowerWhisker=0;s.q1=1;s.median=2;s.q3=3;s.upperWhisker=4;
                ax=m2t2.ir.makeAxes();ax.xlim=[0 2];ax.ylim=[0 4];ax.series={s};ir=m2t2.ir.makeFigure({ax});
            else
                names={'tiled-layout','dual-y'};
                ir=m2t2.ir.fromJson(fileread(fullfile(root,'test','fixtures','ir','compatibility',[names{k-5} '.json'])));
            end
            return;
        end
        switch k
            case 1
                h=plot(a,single([1 2 3]),single([2 1 3]));hold(a,'on');e=errorbar(a,1:3,[3 2 4],[.1 .2 .3]);
                legend(a,[e h],{'errors','line'});
            case 2
                plot(a,[1 10 100],[2 3 4]);set(a,'XScale','log','XDir','reverse','XTick',[1 10 100],'XTickLabel',{'one','ten','hundred'});
            case 3
                scatter(a,1:4,[2 1 4 3],[16 25 36 49],[1 0 0;0 1 0;0 0 1;1 0 1],'filled');
            case 4,bar(a,[1 2;3 4;2 1],'grouped');
            case 5,boxplot(a,[(1:20)';80],'PlotStyle','traditional','BoxStyle','filled','MedianStyle','line','Symbol','xk');
            case 6
                delete(a);t=tiledlayout(f,1,2);a=nexttile(t);plot(a,1:3);set(a,'Color','w');
                a=nexttile(t);plot(a,[3 1 2]);title(t,'Shared title');xlabel(t,'Shared X');
            case 7
                yyaxis(a,'left');plot(a,1:3,[1 2 3]);yyaxis(a,'right');plot(a,1:3,[10 20 30]);
            case 8,imagesc(a,uint16([0 2;3 1]));colorbar(a);
            case 9
                rgb=cat(3,uint8([255 0;0 255]),uint8([0 255;255 0]),zeros(2,'uint8'));
                alpha=[1 .5;.25 0];if native,alpha=single(alpha);end
                image('Parent',a,'CData',rgb,'AlphaData',alpha,'AlphaDataMapping','none');
            case 10
                plot(a,1:3);text(2,2,'note','Parent',a,'Color','k');xlabel(a,{'two','parts'});
                if native,annotation(f,'arrow',[.2 .4],[.3 .5],'Color','k');end
            case 11
                [x,y]=meshgrid(-1:1);surf(a,x,y,x.*y,'FaceColor','interp','EdgeColor','none');hold(a,'on');plot3(a,[-1 1],[0 0],[.5 .5]);
                if isprop(a,'SortMethod'),set(a,'SortMethod','childorder');end;view(a,30,25);
            case 12
                scatter3(a,[-.8 0 .8],[.4 -.4 .6],[-.5 .5 0],144,[.2 .4 .8],'filled');view(a,30,25);
            case 13
                delete(a);a=subplot(1,2,1,'Parent',f);plot(a,1:3);set(a,'Color','w');a=subplot(1,2,2,'Parent',f);bar(a,[1 2 3]);
            otherwise,plot(a,1:3,[2 1 3]);
        end
        set(a,'Color','w');drawnow;
        ir=m2t2.reader.readFigure(f);
        switch k
            case 1
                assert(isequal(ir.axes{1}.series{1}.y,[2 1 3]));
                assert(strcmp(ir.axes{1}.legend.entries{1}.seriesId,ir.axes{1}.series{2}.id));
            case 2,assert(strcmp(ir.axes{1}.xscale,'log')&&strcmp(ir.axes{1}.xdirection,'reverse'));
            case 3,assert(isequal(ir.axes{1}.series{1}.markerSize,[4 5 6 7])&&size(ir.axes{1}.series{1}.colorData,1)==4);
            case 4,assert(numel(ir.axes{1}.series)==2);
            case 5,assert(isequal(ir.axes{1}.series{1}.outlierValues,80));
            case {6 13},assert(numel(ir.axes)==2);
            case 7,assert(strcmp(ir.axes{1}.series{2}.yAxis,'right'));
            case 8,assert(isequal(ir.axes{1}.series{1}.cdata,[0 2;3 1])&&numel(ir.elements)==1);
            case 9,assert(isequal(ir.axes{1}.series{1}.alphaData,[1 .5;.25 0]));
            case 10,assert(~isempty(ir.annotations));
            case 11,assert(numel(ir.axes{1}.series)==2);
            case 12,assert(isequal(ir.axes{1}.series{1}.z,[-.5 .5 0]));
        end
    end
end
function propertyAndTextTests(native)
    f=figure('Visible','off','Color','w');c=onCleanup(@()close(f));a=axes('Parent',f);h=plot(a,1:3);set(a,'Color','w');
    assert(isequal(m2t2.reader.optionalProperty(h,'XData',99),[1 2 3]));
    assert(m2t2.reader.optionalProperty(h,'AbsentSyntheticProperty',99)==99);
    assert(isempty(m2t2.reader.optionalProperty(h,'ZData',99)));
    l=legend(a,h,'line');set(l,'Orientation','horizontal');
    try,m2t2.reader.readFigure(f);error('M2T:ExpectedFailure','horizontal legend accepted');
    catch err,assert(strcmp(err.identifier,'M2T2:E007:UnsupportedProperty'));end
    set(l,'Orientation','vertical');
    if isprop(l,'NumColumns')
        set(l,'NumColumns',2);
        try,m2t2.reader.readFigure(f);error('M2T:ExpectedFailure','multicolumn legend accepted');
        catch err,assert(strcmp(err.identifier,'M2T2:E007:UnsupportedProperty'));end
    end
    delete(l);
    g=hggroup('Parent',a);
    try,m2t2.reader.readScatter(g,'synthetic.required');error('M2T:ExpectedFailure','missing data accepted');
    catch err,assert(strcmp(err.identifier,'M2T2:E040:MalformedScatterData'));end
    delete(h);
    try,m2t2.reader.optionalProperty(h,'XData',99);error('M2T:ExpectedFailure','invalid handle accepted');
    catch err,assert(strcmp(err.identifier,'M2T2:E002:InvalidArgument'));end
    assert(strcmp(m2t2.util.textValue({'alpha','beta'}),'alpha beta'));
    if native
        delete(a);a=axes('Parent',f);b=bar(a,[1 2 3]);set(a,'Color','w');set(b,'FaceAlpha',.5);
        try,m2t2.reader.readFigure(f);error('M2T:ExpectedFailure','bar alpha accepted');
        catch err,assert(strcmp(err.identifier,'M2T2:E021:UnsupportedBarColorMode'));end
        assert(strcmp(m2t2.util.textValue(string('alpha')),'alpha'));
        for value={string(missing),["alpha" "beta"]}
            try,m2t2.util.textValue(value{1});error('M2T:ExpectedFailure','invalid text accepted');
            catch err,assert(strcmp(err.identifier,'M2T2:E004:NormalizationFailed'));end
        end
    end
    clear c;
end
