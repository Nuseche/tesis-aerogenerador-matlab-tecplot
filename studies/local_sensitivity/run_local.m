function run_local(campaignFolder)
%RUN_LOCAL Run or inspect the specified local sensitivity campaign.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));addpath(root);addpath(fullfile(root,'cases'));
if nargin < 1 || strlength(string(campaignFolder)) == 0
    campaignFolder=fullfile(root,'runs','studies','local_sensitivity');
end
folder=fullfile(campaignFolder);
if ~isfolder(folder),mkdir(folder);end
diary(fullfile(folder,'local_execution.log'));
summary=sensitivity.run_initial_study(folder,'local');
s=sensitivity.config_local();
r=sensitivity.read_case(fullfile(folder,'local'),'continuation');
sensitivity.verify_historical_nominal(s,r,fullfile(folder,'local'));
disp(summary.ranking);
fprintf('Accepted smallest-step rows: %d / %d\n',nnz(summary.table.step==min(s.steps)&summary.table.trackingValid&summary.table.signalResolved&summary.table.stepConverged),height(summary.table));
diary off
end
