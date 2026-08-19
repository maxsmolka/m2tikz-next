function paths = writeValidationReports(report, outputDirectory)
%WRITEVALIDATIONREPORTS Emit sanitized schema-1 JSON and Markdown evidence.
    if exist(outputDirectory,'dir')~=7,mkdir(outputDirectory);end
    report=m2t_test.sanitizeEvidence(report);
    jsonPath=fullfile(outputDirectory,'report.json');markdownPath=fullfile(outputDirectory,'report.md');
    writeText(jsonPath,[jsonencode(report) sprintf('\n')]);
    runtimeLabel=[upper(report.runtime.kind) ' ' report.runtime.version];
    if ~isempty(report.runtime.release),runtimeLabel=[runtimeLabel ' (' report.runtime.release ')'];end
    lines={ '# MATLAB Validation'; ''; ['Runtime: ' runtimeLabel]; ...
        ['Architecture: ' report.runtime.architecture]; ['Operating system: ' report.runtime.os]; ''; ...
        '## Summary'; ''; ['- Fixtures: ' num2str(report.summary.totalFixtures)]; ...
        ['- Passed: ' num2str(report.summary.passed)]; ['- Failed: ' num2str(report.summary.failed)]; ...
        ['- Environment failures: ' num2str(report.summary.environmentFailures)]; ...
        ['- Semantic mismatches: ' num2str(report.summary.semanticMismatches)]; ''; ...
        '## Validation layers'; ''; '| Layer | Category | Status |'; '| --- | --- | --- |'};
    lines=lines(:)';
    for k=1:numel(report.layers),lines{end+1}=sprintf('| %s %s | %s | %s |',report.layers(k).id,report.layers(k).name,report.layers(k).category,report.layers(k).status);end
    lines=[lines {'' '## Fixtures' '' '| ID | Name | Status | Category | Evidence |' '| --- | --- | --- | --- | --- |'}];
    for k=1:numel(report.fixtures)
        item=report.fixtures(k);lines{end+1}=sprintf('| %s | %s | %s | %s | %s |',item.id,item.name,item.status,item.failureCategory,item.evidence);
    end
    lines=[lines {'' 'Legacy status is reported separately from the modern support decision.'}];
    writeText(markdownPath,[joinLines(lines) sprintf('\n')]);
    paths=struct('json',jsonPath,'markdown',markdownPath);
end
function text=joinLines(lines),text='';for k=1:numel(lines),if k>1,text=[text sprintf('\n')];end;text=[text lines{k}];end,end %#ok<AGROW>
function writeText(path,text),fid=fopen(path,'wb');if fid<0,error('M2T_TEST:REPORT_WRITE','Cannot write %s.',path);end;cleanup=onCleanup(@()fclose(fid));fwrite(fid,text,'char');clear cleanup;end
