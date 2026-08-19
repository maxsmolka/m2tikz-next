function evidence=auditM53BoxplotRuntime(outputPath)
%AUDITM53BOXPLOTRUNTIME Capture privacy-safe resolved boxplot HG evidence.
    root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
    if nargin<1,outputPath=fullfile(root,'.audit','m53-evidence','matlab-r2026a-boxplot.json');end
    f=figure('Visible','off');cleanup=onCleanup(@()close(f));a=axes('Parent',f);
    values=[(1:20)';100;(11:30)';200];groups=[ones(21,1);2*ones(21,1)];
    boxplot(a,values,groups,'Color',[.2 .4 .8],'PlotStyle','traditional', ...
        'BoxStyle','filled','MedianStyle','line','Symbol','xk','OutlierSize',2);
    h=allchild(a);stats=getappdata(h,'boxvalplot');children=allchild(h);
    roles=cell(1,numel(children));types=roles;
    for k=1:numel(children),roles{k}=get(children(k),'Tag');types{k}=get(children(k),'Type');end
    runtime=m2t_test.runtimeInfo();evidence=struct('runtime',runtime,'toolboxLicense',logical(license('test','Statistics_Toolbox')), ...
        'containerClass',class(h),'containerType',get(h,'Type'),'containerTag',get(h,'Tag'), ...
        'plotType',getappdata(h,'plottype'),'positions',reshape(getappdata(h,'gpos'),1,[]), ...
        'notched',getappdata(h,'notchon'),'statisticFields',{stats.Properties.VariableNames}, ...
        'resolvedStatistics',[stats.wlo stats.q1 stats.q2 stats.q3 stats.whi], ...
        'outlierCounts',cellfun(@numel,stats.outliers)','childTypes',{types},'childRoles',{roles});
    folder=fileparts(outputPath);if exist(folder,'dir')~=7,mkdir(folder);end
    m2t.internal.writeTextFile(outputPath,[jsonencode(evidence,'PrettyPrint',true) newline]);clear cleanup;
end
