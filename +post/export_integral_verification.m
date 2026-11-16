function artifacts=export_integral_verification(run,action10)
%EXPORT_INTEGRAL_VERIFICATION Persist Integral verification audit tables without reassembly.
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
        error('post:export_integral_verification:MissingTable', ...
            'Action 10 result is missing required table %s.',field);
    end
    tableValue=action10.(field);
    writetable(tableValue,fullfile(run.folder,fileName));
    artifacts.(output)=tableValue;
end
end
