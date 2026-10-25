% Reproduce the attempted stricter equilibrium separately; retain failure.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));addpath(root);addpath(fullfile(root,'cases'));
study=sensitivity.config_local();study.nominal.equilibrium.tolerance=1e-10;
study.nominal.equilibrium.relativeTolerance=1e-10;
study.nominal.modal.tolerance=1e-12;study.nominal.modes.tolerance=1e-12;
design=struct('id',"equilibrium_floor",'factors',struct(),'options',struct());
sensitivity.run_campaign(study,design); % creates a new timestamped folder
