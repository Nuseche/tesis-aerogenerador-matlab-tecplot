function artifacts=export_action04(run,action04)
%EXPORT_ACTION04 Export stored rigid-body mass acceptance tables.
arguments
    run (1,1) struct
    action04 (1,1) struct
end
required={'checkTable','bodyTable','massPropertiesTable'};
for index=1:numel(required)
    if ~isfield(action04,required{index})||~istable(action04.(required{index}))
        error('post:export_action04:MissingTable', ...
            'Action 04 result is missing table %s.',required{index});
    end
end
writetable(action04.checkTable,fullfile(run.folder,'action04_validation.csv'));
writetable(action04.bodyTable,fullfile(run.folder,'action04_body_matrices.csv'));
writetable(action04.massPropertiesTable, ...
    fullfile(run.folder,'action04_mass_properties.csv'));
artifacts=struct('validation',action04.checkTable,'bodies',action04.bodyTable, ...
    'massProperties',action04.massPropertiesTable);
end
