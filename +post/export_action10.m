function artifacts=export_action10(run,action10)
%EXPORT_ACTION10 Persist Action-10 audit tables without reassembly.
arguments
    run (1,1) struct
    action10 (1,1) struct
end

mapping={ ...
    'requirementTable','action10_requirement_matrix.csv','requirements'; ...
    'matrixTable','action10_matrix_properties.csv','matrices'; ...
    'evidenceTable','action10_evidence.csv','evidence'; ...
    'artifactTable','action10_artifacts.csv','artifacts'};
artifacts=struct();
for index=1:size(mapping,1)
    field=mapping{index,1};fileName=mapping{index,2};output=mapping{index,3};
    if ~isfield(action10,field)||~istable(action10.(field))
        error('post:export_action10:MissingTable', ...
            'Action 10 result is missing required table %s.',field);
    end
    tableValue=action10.(field);
    writetable(tableValue,fullfile(run.folder,fileName));
    artifacts.(output)=tableValue;
end
end
