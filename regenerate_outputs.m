function artifacts = regenerate_outputs(runFolder)
%REGENERATE_OUTPUTS Rebuild tables/figures from saved data, without analysis.

arguments
    runFolder (1,1) string
end
required = ["configuration.mat","model_snapshot.mat","results.mat"];
for name = required
    if ~isfile(fullfile(runFolder,name))
        error('regenerate_outputs:MissingFile','Missing %s in %s.',name,runFolder);
    end
end
c = load(fullfile(runFolder,'configuration.mat'),'configuration');
m = load(fullfile(runFolder,'model_snapshot.mat'),'modelSnapshot');
r = load(fullfile(runFolder,'results.mat'),'results');
run.folder = char(runFolder);
run.figuresFolder = fullfile(run.folder,'figures');
if ~isfolder(run.figuresFolder), mkdir(run.figuresFolder); end
artifacts = post.export_all(run,c.configuration,m.modelSnapshot,r.results);
end
