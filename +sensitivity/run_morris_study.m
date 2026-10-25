function campaign=run_morris_study(folder,budgetStartUTC)
%RUN_MORRIS_STUDY Save approved design, execute and postprocess checkpoints.
s=sensitivity.config_morris();
if nargin>1,s.budgetStartUTC=string(budgetStartUTC);end
if nargin<1,folder=fullfile(s.outputRoot,'morris_20261006');end
[design,vertices,edges]=sensitivity.morris_design(s);
if ~isfolder(folder),mkdir(folder);end
% Design tables can only be written before a new campaign is registered.
if ~isfile(fullfile(folder,'campaign.mat'))
    writetable(vertices,fullfile(folder,'morris_vertices.csv'));
    writetable(edges,fullfile(folder,'morris_edges.csv'));
end
campaign=sensitivity.run_campaign(s,design,folder);
save(fullfile(folder,'morris_design.mat'),'design','vertices','edges','s');
sensitivity.summarize_morris(campaign);
end
