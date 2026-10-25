function results = run_all_tests(outputFile)
%RUN_ALL_TESTS Execute every MATLAB unit test in this project.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
suite = testsuite(fullfile(projectRoot,'tests'), 'IncludeSubfolders', true);
results = run(suite);
if nargin < 1 || strlength(string(outputFile)) == 0
    outputFile = fullfile(projectRoot,'tests','latest_results.mat');
end
save(outputFile,'results');
fprintf('\nTest summary: %d passed, %d failed, %d incomplete, %d total.\n', ...
    nnz([results.Passed]), nnz([results.Failed]), nnz([results.Incomplete]), numel(results));
if any([results.Failed] | [results.Incomplete])
    error('tests:run_all_tests:Failure','The automatic validation suite did not pass completely.');
end
end
