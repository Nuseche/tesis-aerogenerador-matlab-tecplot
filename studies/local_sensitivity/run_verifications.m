function run_verifications(campaignFolder)
%RUN_VERIFICATIONS Run or inspect the specified local sensitivity campaign.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));addpath(root);addpath(fullfile(root,'cases'));
if nargin < 1 || strlength(string(campaignFolder)) == 0
    campaignFolder=fullfile(root,'runs','studies','local_sensitivity');
end
folder=fullfile(campaignFolder);
diary(fullfile(folder,'verification_execution.log'));
for phase=["verification" "seismic" "foundation"]
    try
        sensitivity.run_initial_study(folder,phase);
    catch ME
        fprintf('PHASE %s FAILED: %s\n%s\n',phase,ME.message,getReport(ME,'extended','hyperlinks','off'));
    end
end
diary off
end
