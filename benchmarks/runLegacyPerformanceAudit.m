% Performance baseline. Writes only below .audit/runtime-baseline.
audit_root = fileparts(fileparts(mfilename('fullpath')));
baseline = fullfile(audit_root,'.audit','runtime-baseline');
inline_dir = fullfile(baseline,'tex','performance','inline');
external_dir = fullfile(baseline,'tex','performance','external');
data_dir = fullfile(baseline,'data','performance','external');
results_dir = fullfile(baseline,'results');
for p={inline_dir,external_dir,data_dir,results_dir}
    if ~exist(p{1},'dir'), mkdir(p{1}); end
end
addpath(fullfile(audit_root,'src'));
counts = [100,10000,100000,1000000];
fid=fopen(fullfile(results_dir,'performance-export.tsv'),'w');
cleanup_fid=onCleanup(@()fclose(fid));
fprintf(fid,'points\tmode\texport_seconds\ttex_bytes\tdata_bytes\tstatus\terror\n');
for n=counts
    close all; fig=figure('visible','off'); x=linspace(0,100,n); plot(x,sin(x));
    for mode={'inline','external'}
        error_message=''; status='PASS'; data_bytes=0;
        if strcmp(mode{1},'inline')
            target=fullfile(inline_dir,sprintf('line-%d.tex',n));
        else
            target=fullfile(external_dir,sprintf('line-%d.tex',n));
        end
        started=tic;
        try
            if strcmp(mode{1},'inline')
                matlab2tikz(target,'figurehandle',fig,'standalone',true,'showInfo',false);
            else
                matlab2tikz(target,'figurehandle',fig,'standalone',true,'showInfo',false, ...
                    'externalData',true,'dataPath',data_dir, ...
                    'relativeDataPath','../../../data/performance/external');
            end
        catch err
            status='FAIL'; error_message=err.message;
        end
        elapsed=toc(started); tex_bytes=0;
        d=dir(target); if ~isempty(d), tex_bytes=d(1).bytes; end
        if strcmp(mode{1},'external')
            [dummy,name]=fileparts(target);
            d=dir(fullfile(data_dir,[name '-*.tsv']));
            if ~isempty(d), data_bytes=sum([d.bytes]); end
        end
        error_message=strrep(strrep(error_message,sprintf('\r'),' '),sprintf('\n'),' ');
        fprintf(fid,'%d\t%s\t%.6f\t%d\t%d\t%s\t%s\n',n,mode{1},elapsed, ...
            tex_bytes,data_bytes,status,error_message);
        fprintf('PERF_EXPORT|%d|%s|%.6f|%d|%d|%s\n',n,mode{1},elapsed, ...
            tex_bytes,data_bytes,status);
    end
end
