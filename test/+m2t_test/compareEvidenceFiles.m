function result = compareEvidenceFiles(candidatePath, referencePath, expectedDifferencePaths)
%COMPAREEVIDENCEFILES Compare sanitized normalized JSON evidence files.
    if nargin<3,expectedDifferencePaths={};end
    candidate=jsondecode(fileread(candidatePath));reference=jsondecode(fileread(referencePath));
    result=m2t_test.compareSemantic(candidate,reference,expectedDifferencePaths);
end
