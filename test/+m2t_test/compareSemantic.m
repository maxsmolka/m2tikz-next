function result = compareSemantic(actual, expected, expectedDifferencePaths)
%COMPARESEMANTIC Compare normalized evidence with field-specific tolerances.
    if nargin < 3, expectedDifferencePaths = {}; end
    differences = compareValue(actual, expected, '', expectedDifferencePaths);
    if isempty(differences)
        unexpected=differences;classification='exact';
    else
        unexpected=differences(~[differences.expected]);
        if isempty(unexpected),classification='expected_runtime_difference';else,classification='semantic_mismatch';end
    end
    result=struct('equal',isempty(unexpected),'classification',classification, ...
                  'differences',differences);
end

function differences = compareValue(actual,expected,path,expectedPaths)
    differences=repmat(diffTemplate(),1,0);
    if isstruct(actual)&&isstruct(expected)&&isequal(size(actual),size(expected))
        namesA=sort(fieldnames(actual));namesE=sort(fieldnames(expected));
        if ~isequal(namesA,namesE),differences=addDiff(differences,path,'field_set',actual,expected,expectedPaths);return;end
        for index=1:numel(actual)
            for k=1:numel(namesA)
                child=joinPath(path,namesA{k});
                differences=[differences compareValue(actual(index).(namesA{k}),expected(index).(namesA{k}),child,expectedPaths)]; %#ok<AGROW>
            end
        end
    elseif iscell(actual)&&iscell(expected)&&isequal(size(actual),size(expected))
        for k=1:numel(actual)
            differences=[differences compareValue(actual{k},expected{k},sprintf('%s{%d}',path,k),expectedPaths)]; %#ok<AGROW>
        end
    elseif isnumeric(actual)&&isnumeric(expected)&&isequal(size(actual),size(expected))
        tolerance=toleranceFor(path);
        if ~(all((isnan(actual(:))&isnan(expected(:))) | abs(actual(:)-expected(:))<=tolerance))
            differences=addDiff(differences,path,sprintf('numeric_tolerance_%g',tolerance),actual,expected,expectedPaths);
        end
    elseif ~isequal(actual,expected)
        differences=addDiff(differences,path,'exact',actual,expected,expectedPaths);
    end
end

function tolerance=toleranceFor(path)
    lowerPath=lower(path);
    if ~isempty(regexp(lowerPath,'placement|position|size|widthmillimeters','once'))
        tolerance=1e-8;
    elseif ~isempty(regexp(lowerPath,'color|colormap','once'))
        tolerance=1e-12;
    elseif ~isempty(regexp(lowerPath,'x|y|data|limit|tick','once'))
        tolerance=1e-12;
    else
        tolerance=0;
    end
end

function differences=addDiff(differences,path,rule,actual,expected,expectedPaths)
    isExpected=any(strcmp(path,expectedPaths)); item=diffTemplate();
    item.path=path;item.rule=rule;item.expected=isExpected;
    item.actual=actual;item.reference=expected;differences(end+1)=item;
end
function value=diffTemplate(),value=struct('path','','rule','','expected',false,'actual',[],'reference',[]);end
function value=joinPath(parent,name),if isempty(parent),value=name;else,value=[parent '.' name];end,end
