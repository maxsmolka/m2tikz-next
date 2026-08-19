function result = runMatlabValidation(outputDirectory)
%RUNMATLABVALIDATION One-command noninteractive MATLAB evidence entry point.
    repositoryRoot=fileparts(fileparts(mfilename('fullpath')));
    addpath(fullfile(repositoryRoot,'test'));
    if nargin<1,outputDirectory=fullfile(repositoryRoot,'build','matlab-validation');end
    runtime=m2t_test.runtimeInfo();
    if ~strcmp(runtime.kind,'matlab')
        error('M2T_TEST:MATLAB_REQUIRED','runMatlabValidation requires MATLAB; detected %s.',runtime.kind);
    end
    result=m2t_test.runValidation('matlab',outputDirectory);
    fprintf('MATLAB Validation\nRuntime: MATLAB %s %s\nFixtures: %d\nPassed: %d\nFailed: %d\nEnvironment failures: %d\nSemantic mismatches: %d\n', ...
        result.runtime.version,result.runtime.release,result.summary.totalFixtures,result.summary.passed, ...
        result.summary.failed,result.summary.environmentFailures,result.summary.semanticMismatches);
    assert(result.success,'M2T_TEST:MATLAB_VALIDATION_FAILED','MATLAB validation failed; inspect %s.',result.paths.markdown);
end
