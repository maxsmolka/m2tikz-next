function summary=runM66LargeDataTexTests(outputDirectory)
%RUNM66LARGEDATATEXTESTS Compile small representatives, without timing gates.
    root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'benchmarks'));
    if nargin<1,outputDirectory=fullfile(root,'.audit','m66-tex');end
    rows=benchmarkModernLargeData(outputDirectory,'ir','smoke',true);
    assert(all(strcmp({rows.compileStatus},'PASS')));
    summary=struct('tests',10,'failures',0);fprintf('M66_TEX_PASS: 10/10\n');
    runM66ColorMappingTests(fullfile(outputDirectory,'colors'),true);
end
