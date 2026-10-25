% Reproduce the explicitly approved second stage in its immutable folder.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));addpath(root);addpath(fullfile(root,'cases'));
folder=fullfile(root,'runs','sensitivity','morris_20261006');
campaign=sensitivity.run_morris_study(folder,"2026-10-07 01:48:29");
save(fullfile(root,'docs','sensibilidad_morris_20261006','campaign_result.mat'),'campaign');
