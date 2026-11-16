function run_morris(campaignFolder)
%RUN_MORRIS Run or inspect the specified morris campaign.
% Use the documented exploratory domain in a new or matching campaign.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));addpath(root);addpath(fullfile(root,'cases'));
if nargin < 1 || strlength(string(campaignFolder)) == 0
    campaignFolder=fullfile(root,'runs','studies','morris');
end
folder=fullfile(campaignFolder);
campaign=sensitivity.run_morris_study(folder);
save(fullfile(folder,'campaign_result.mat'),'campaign');
end
