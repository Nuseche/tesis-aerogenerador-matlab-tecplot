function run_connections(campaignFolder)
%RUN_CONNECTIONS Run or inspect the specified local sensitivity campaign.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));addpath(root);addpath(fullfile(root,'cases'));
s=sensitivity.config_local();s.parameters=s.parameters(1,:);
s.parameters.name="drivetrain_stiffness";s.parameters.category="physical";
s.parameters.definition="all six inherited illustrative drivetrain stiffnesses";
s.parameters.source="cases/config_campbell_verification.m";
s.parameters.dependencies="relative connector matrix fixed; geometry/mass unchanged";
s.steps=[0.02 0.01 0.005];
if nargin < 1 || strlength(string(campaignFolder)) == 0
    campaignFolder=fullfile(root,'runs','studies','local_sensitivity');
end
folder=fullfile(campaignFolder,'connections');
c=sensitivity.run_campaign(s,sensitivity.local_design(s),folder);
summary=sensitivity.summarize_local(c);disp(summary.ranking);
end
