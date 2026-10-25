function artifacts=export_action08(run,action08)
%EXPORT_ACTION08 Persist human-readable Action-08 acceptance evidence.

artifacts=struct();
artifacts.validation=write(action08,'checkTable', ...
    fullfile(run.folder,'action08_validation.csv'));
artifacts.campbell=write(action08,'campbellTable', ...
    fullfile(run.folder,'action08_campbell.csv'));
artifacts.qep=write(action08,'qepTable', ...
    fullfile(run.folder,'action08_qep.csv'));
artifacts.tracking=write(action08,'trackingTable', ...
    fullfile(run.folder,'action08_tracking.csv'));
artifacts.transforms=write(action08,'transformTable', ...
    fullfile(run.folder,'action08_mbc_transforms.csv'));
artifacts.homology=write(action08,'homologyTable', ...
    fullfile(run.folder,'action08_homology.csv'));
artifacts.zeroSpeed=write(action08,'zeroSpeedTable', ...
    fullfile(run.folder,'action08_zero_speed.csv'));
artifacts.assignment=write(action08,'assignmentTable', ...
    fullfile(run.folder,'action08_assignment.csv'));
artifacts.storage=write(action08,'storageTable', ...
    fullfile(run.folder,'action08_storage.csv'));
end

function tableValue=write(source,field,fileName)
tableValue=table();
if isfield(source,field)&&istable(source.(field))
    tableValue=source.(field);
    writetable(tableValue,fileName);
end
end
