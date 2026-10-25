function artifacts=export_action06(run,action06)
%EXPORT_ACTION06 Export stored equilibrium and axial-force tables.
arguments
    run (1,1) struct
    action06 (1,1) struct
end
mapping={'checkTable','action06_validation.csv'; ...
    'equilibriumTable','action06_equilibrium.csv'; ...
    'axialTable','action06_axial_forces.csv'; ...
    'continuationTable','action06_continuation.csv'};
for index=1:size(mapping,1)
    field=mapping{index,1};file=mapping{index,2};
    if ~isfield(action06,field)||~istable(action06.(field))
        error('post:export_action06:MissingTable', ...
            'Action 06 result is missing table %s.',field);
    end
    writetable(action06.(field),fullfile(run.folder,file));
end
artifacts=struct('validation',action06.checkTable, ...
    'equilibrium',action06.equilibriumTable,'axial',action06.axialTable, ...
    'continuation',action06.continuationTable);
end
