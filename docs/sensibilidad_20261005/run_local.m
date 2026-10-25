root=fileparts(fileparts(fileparts(mfilename('fullpath'))));addpath(root);addpath(fullfile(root,'cases'));
folder=fullfile(root,'runs','sensitivity','initial_20261005');
if ~isfolder(folder),mkdir(folder);end
diary(fullfile(folder,'local_execution.log'));
summary=sensitivity.run_initial_study(folder,'local');
s=sensitivity.config_local();
r=sensitivity.read_case(fullfile(folder,'local'),'continuation');
sensitivity.verify_historical_nominal(s,r,fullfile(folder,'local'));
disp(summary.ranking);
fprintf('Accepted smallest-step rows: %d / %d\n',nnz(summary.table.step==min(s.steps)&summary.table.trackingValid&summary.table.signalResolved&summary.table.stepConverged),height(summary.table));
diary off
