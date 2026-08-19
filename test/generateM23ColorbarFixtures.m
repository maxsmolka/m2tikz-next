function summary = generateM23ColorbarFixtures(outputDirectory)
%GENERATEM23COLORBARFIXTURES Export Legacy/M2.3 pairs and semantic evidence.
    root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));addpath(fullfile(root,'test','private'));
    if nargin<1,outputDirectory=fullfile(root,'.audit','m2.3');end
    legacyDir=fullfile(outputDirectory,'tex','legacy');m23Dir=fullfile(outputDirectory,'tex','m23');
    ensureDirectory(legacyDir);ensureDirectory(m23Dir);
    names={'default','eastoutside','westoutside','horizontal','manual','ticks','label','first_only','separate','overlap'};
    rows=cell(numel(names),8);failures=0;
    for k=1:numel(names)
        fig=[];
        try
            [fig,expected]=createM23ColorbarFixture(names{k});
            legacyPath=fullfile(legacyDir,[names{k} '.tex']);m23Path=fullfile(m23Dir,[names{k} '.tex']);
            [ir,tex]=m2t2.export(fig,m23Path,true);
            matlab2tikz(legacyPath,'figurehandle',fig,'standalone',true,'showInfo',false,'externalData',false);
            count=numel(ir.elements); owners=cellfun(@(item)item.owner.id,ir.elements,'UniformOutput',false);
            valid=count==expected.count && all(cellfun(@(item)strcmp(item.kind,'m2t2.colorbar'),ir.elements));
            for e=1:count
                cb=ir.elements{e};a=find(cellfun(@(item)strcmp(item.id,cb.owner.id),ir.axes),1);
                valid=valid && ~isempty(a) && isequal(cb.limits,ir.axes{a}.colorMapping.limits) && ...
                    cb.placement.width>0 && cb.placement.height>0 && ...
                    ~isempty(strfind(tex,'colorbar style={')); %#ok<STREMP>
            end
            if valid,status='PASS';detail='';else,status='FAIL';detail='semantic mismatch';failures=failures+1;end
            rows(k,:)={names{k},status,detail,numel(ir.axes),count,strjoin(owners,','), ...
                strjoin(cellfun(@(item)item.orientation,ir.elements,'UniformOutput',false),','), ...
                strjoin(cellfun(@(item)item.location,ir.elements,'UniformOutput',false),',')};
        catch err
            failures=failures+1;rows(k,:)={names{k},'FAIL',oneLine(err.message),NaN,NaN,'','',''};
        end
        if ~isempty(fig)&&ishandle(fig),close(fig);end
    end
    writeRows(fullfile(outputDirectory,'m23-semantic-results.tsv'),rows);
    summary=struct('failures',failures,'fixtures',numel(names));
    if failures,error('M2T2:M23FixtureGenerationFailed','%d M2.3 fixture exports failed.',failures);end
end
function ensureDirectory(path),if exist(path,'dir')~=7,mkdir(path);end,end
function writeRows(path,rows),fid=fopen(path,'w');cleanup=onCleanup(@()fclose(fid));fprintf(fid,'case\tstatus\tdetail\taxes\tcolorbars\towners\torientations\tlocations\n');for k=1:size(rows,1),fprintf(fid,'%s\t%s\t%s\t%g\t%g\t%s\t%s\t%s\n',rows{k,:});end,end
function value=oneLine(value),value=strrep(value,sprintf('\r'),' ');value=strrep(value,sprintf('\n'),' ');end
