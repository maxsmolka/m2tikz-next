function summary=runM66LargeDataContractTests(outputDirectory)
%RUNM66LARGEDATACONTRACTTESTS Count/pixel assertions, not timing thresholds.
    root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'benchmarks'));addpath(fullfile(root,'src'));
    if nargin<1,outputDirectory=fullfile(root,'.audit','m66-contract');end
    rows=benchmarkModernLargeData(outputDirectory,'ir','smoke',false);
    defaults=m2t.internal.parseExportOptions();assert(strcmp(defaults.imageBackend,'vector'));
    assert(numel(rows)==10&&all([rows.texBytes]>0));
    assert(all([rows(6:9).assetBytes]>0)&&all([rows([1:5 10]).assetBytes]==0));
    assert(all(isnan([rows.readerSeconds]))); % Portable fixtures are not native reader evidence.
    assert(all(strcmp({rows.compileStatus},'NOT_REQUESTED')));
    summary=struct('tests',10,'failures',0);fprintf('M66_CONTRACT_PASS: 10/10\n');
    runM66ColorMappingTests(fullfile(outputDirectory,'colors'));
end
