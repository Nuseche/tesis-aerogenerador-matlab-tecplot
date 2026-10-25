function artifacts = export_action03(run,action03)
%EXPORT_ACTION03 Export exact-constraint acceptance tables without re-solving.

arguments
    run (1,1) struct
    action03 (1,1) struct
end

required = {'checkTable','constraintMap','summaryTable'};
for index = 1:numel(required)
    if ~isfield(action03,required{index}) || ~istable(action03.(required{index}))
        error('post:export_action03:MissingTable', ...
            'Action 03 result is missing table %s.',required{index});
    end
end
writetable(action03.checkTable,fullfile(run.folder,'action03_validation.csv'));
writetable(action03.constraintMap,fullfile(run.folder,'action03_constraint_map.csv'));
writetable(action03.summaryTable,fullfile(run.folder,'action03_summary.csv'));
artifacts = struct('validation',action03.checkTable, ...
    'constraintMap',action03.constraintMap,'summary',action03.summaryTable);
end
