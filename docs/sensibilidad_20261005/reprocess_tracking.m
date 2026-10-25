% Postprocessing revision: reject groups touching the selected spectral cut.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));addpath(root);addpath(fullfile(root,'cases'));
folder=fullfile(root,'runs','sensitivity','initial_20261005');
for phase=["local" "foundation" "connections"]
    saved=load(fullfile(folder,phase,'campaign.mat'),'campaign');
    summary=sensitivity.summarize_local(saved.campaign);disp(summary.ranking);
end
loaded=load(fullfile(folder,'local','summary.mat'),'summary');
cc=load(fullfile(folder,'interactions','campaign.mat'),'campaign');
sensitivity.summarize_interactions(loaded.summary,cc.campaign,["blade_density";"blade_stiffness"],0.01);
p=sensitivity.provenance(root);writetable(p.files,fullfile(folder,'postprocessing_source_hashes.csv'));
postprocessing=struct('fingerprint',p.fingerprint,'rawSource',"source_snapshot_20261005.tar.gz", ...
    'revisionReason',"spectral boundary groups excluded; finite rankings first; explicit paper figure styles", ...
    'rawCasesRecomputed',false,'rawInputsAndSolversChanged',false);
save(fullfile(folder,'postprocessing_provenance.mat'),'postprocessing');
