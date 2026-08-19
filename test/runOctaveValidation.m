function result = runOctaveValidation(outputDirectory)
%RUNOCTAVEVALIDATION Exercise the shared evidence harness with GNU Octave.
    repositoryRoot=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(repositoryRoot,'test'));
    if nargin<1,outputDirectory=fullfile(repositoryRoot,'build','octave-validation');end
    result=m2t_test.runValidation('octave',outputDirectory);
end
