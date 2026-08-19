function summary = generateM21Fixtures(outputDirectory)
%GENERATEM21FIXTURES Export legacy/M2.1 axes and mixed-series comparisons.
    root=fileparts(fileparts(mfilename('fullpath'))); addpath(fullfile(root,'src'));
    if nargin<1, outputDirectory=fullfile(root,'.audit','m2.1'); end
    legacyDir=fullfile(outputDirectory,'tex','legacy'); m21Dir=fullfile(outputDirectory,'tex','m21');
    ensureDirectory(legacyDir); ensureDirectory(m21Dir);
    names=fixtureNames(); rows=cell(numel(names),10); failures=0;
    for k=1:numel(names)
        fig=[];
        try
            fig=createM21Fixture(names{k});
            m21Path=fullfile(m21Dir,[names{k} '.tex']); legacyPath=fullfile(legacyDir,[names{k} '.tex']);
            [ir,m21Tex]=m2t2.export(fig,m21Path,true);
            matlab2tikz(legacyPath,'figurehandle',fig,'standalone',true,'showInfo',false,'externalData',false);
            legacyTex=readText(legacyPath); ax=ir.axes{1};
            m21=signature(m21Tex,ax,names{k},true); legacy=signature(legacyTex,ax,names{k},false);
            expectedSeries=numel(ax.series); expectedPoints=pointCount(ax);
            pass=m21.series==expectedSeries && legacy.series==expectedSeries && ...
                 m21.points==expectedPoints && legacy.points==expectedPoints && ...
                 m21.semantics && legacy.semantics;
            if pass, status='PASS'; detail=''; else, status='FAIL'; detail='semantic mismatch'; failures=failures+1; end
            rows(k,:)={names{k},status,detail,expectedSeries,m21.series,legacy.series, ...
                       expectedPoints,m21.points,legacy.points,'direct paths compared'};
        catch err
            failures=failures+1; rows(k,:)={names{k},'FAIL',errorDetail(err),NaN,NaN,NaN,NaN,NaN,NaN,'exception'};
        end
        if ~isempty(fig)&&ishandle(fig), close(fig); end
    end
    writeRows(fullfile(outputDirectory,'m21-semantic-results.tsv'),rows);
    summary=struct('failures',failures,'fixtures',numel(names));
    if failures, error('M2T2:M21FixtureGenerationFailed','%d M2.1 comparisons failed.',failures); end
end

function result=signature(tex,ax,name,isM21)
    bs=char(92); result.series=numel(regexp(tex,[bs bs 'addplot'],'match'));
    result.points=exportedPoints(tex); checks=[hasOption(tex,'xmin'),hasOption(tex,'xmax'),hasOption(tex,'ymin'),hasOption(tex,'ymax')];
    if strcmp(name,'manual_x_ticks'), checks(end+1)=hasText(tex,'xtick'); checks(end+1)=hasText(tex,'zero'); end
    if strcmp(name,'manual_y_ticks'), checks(end+1)=hasText(tex,'ytick'); checks(end+1)=hasText(tex,'high'); end
    if strcmp(name,'reverse_x'), checks(end+1)=hasText(tex,'x dir=reverse'); end
    if strcmp(name,'reverse_y'), checks(end+1)=hasText(tex,'y dir=reverse'); end
    if strcmp(name,'plain_text'), checks(end+1)=hasText(tex,'plain'); end
    if strcmp(name,'tex_text')
        if isM21, checks(end+1)=hasText(tex,'x_{1}'); else, checks(end+1)=hasText(tex,'ylabel={'); end
    end
    if strcmp(name,'latex_text')
        if isM21, checks(end+1)=hasText(tex,'$x^2$'); else, checks(end+1)=hasText(tex,'title={'); end
    end
    if strcmp(name,'legend_on')||strncmp(name,'mixed_',6)
        checks(end+1)=~isempty(strfind(tex,[bs 'addlegendentry'])); %#ok<STREMP>
    end
    if ~isempty(strfind(name,'errorbar')) %#ok<STREMP>
        if isM21, checks(end+1)=hasText(tex,'error bars'); else, checks(end+1)=hasText(tex,'y error plus'); end
        checks(end+1)=hasText(tex,'y error minus'); checks(end+1)=hasText(tex,'y error plus');
    end
    if strcmp(name,'scatter')||strcmp(name,'mixed_line_scatter')
        checks(end+1)=hasText(tex,'only marks')||hasText(tex,'mark=');
    end
    if isM21
        checks(end+1)=numericOptionEquals(tex,'xmin',ax.xlim(1));
        checks(end+1)=numericOptionEquals(tex,'xmax',ax.xlim(2));
    end
    result.semantics=all(checks);
end

function count=exportedPoints(tex)
    lines=regexp(tex,'\r\n|\n|\r','split'); count=0;
    coordinate='^\s*\([^()]*,[^()]*\)\s*$';
    tableRow='^\s*(?:nan|[-+0-9.eE]+)(?:\s+(?:nan|[-+0-9.eE]+)){1,7}\s*\\\\\s*$';
    for k=1:numel(lines)
        count=count+~isempty(regexp(lines{k},coordinate,'once'))+~isempty(regexp(lines{k},tableRow,'once'));
    end
end

function count=pointCount(ax)
    count=0; for k=1:numel(ax.series), count=count+numel(ax.series{k}.x); end
end
function yes=hasOption(tex,name), yes=~isempty(regexp(tex,[name '\s*='],'once')); end
function yes=hasText(tex,value), yes=~isempty(strfind(tex,value)); end %#ok<STREMP>
function yes=numericOptionEquals(tex,name,expected)
    token=regexp(tex,[name '\s*=\s*([-+0-9.eE]+)'],'tokens','once');
    yes=~isempty(token)&&abs(str2double(token{1})-expected)<=1e-12*max(1,abs(expected));
end
function names=fixtureNames()
    names={'manual_x_ticks','manual_y_ticks','reverse_x','reverse_y','box_on','box_off', ...
           'plain_text','tex_text','latex_text','legend_on','legend_off','scatter', ...
           'errorbar_symmetric','errorbar_asymmetric','mixed_line_scatter','mixed_line_errorbar'};
end
function value=readText(path), fid=fopen(path,'r'); cleanup=onCleanup(@() fclose(fid)); value=fread(fid,Inf,'*char')'; clear cleanup; end
function ensureDirectory(path), if exist(path,'dir')~=7, mkdir(path); end, end
function writeRows(path,rows)
    fid=fopen(path,'w'); cleanup=onCleanup(@() fclose(fid));
    fprintf(fid,'case\tstatus\tdetail\texpected_series\tm21_series\tlegacy_series\texpected_points\tm21_points\tlegacy_points\tnote\n');
    for k=1:size(rows,1), fprintf(fid,'%s\t%s\t%s\t%g\t%g\t%g\t%g\t%g\t%g\t%s\n',rows{k,:}); end; clear cleanup;
end
function value=errorDetail(err)
    value=strrep(strrep(err.message,sprintf('\r'),' '),sprintf('\n'),' ');
    if ~isempty(err.stack), value=sprintf('%s at %s:%d',value,err.stack(1).name,err.stack(1).line); end
end
