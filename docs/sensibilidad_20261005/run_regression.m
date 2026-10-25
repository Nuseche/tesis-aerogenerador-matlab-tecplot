root='/Users/nuseche/Desktop/Tesis_codigos';addpath(root);addpath(fullfile(root,'cases'));addpath(fullfile(root,'tests'));
diary(fullfile(root,'docs','sensibilidad_20261005','regression.log'));
results=run_all_tests(fullfile(root,'docs','sensibilidad_20261005','regression_results.mat'));
diary off
