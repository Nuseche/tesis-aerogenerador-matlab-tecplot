function export_nominal_properties(study,folder)
%EXPORT_NOMINAL_PROPERTIES Actual input values by section/body/connection.
cfg=study.nominal;data=io.load_model_data(cfg);md=model.build_model(data,cfg);
s=md.sections;id=(1:numel(s)).';type=string({s.type}).';
T=table(id,type,[s.EA].',[s.GAy].',[s.GAz].',[s.GJ].',[s.EIy].',[s.EIz].', ...
    [s.m].',[s.Jx].',[s.Jy].',[s.Jz].','VariableNames', ...
    {'sectionId','type','EA_N','GAy_N','GAz_N','GJ_Nm2','EIy_Nm2','EIz_Nm2', ...
    'massPerLength_kg_m','Jx_kg_m','Jy_kg_m','Jz_kg_m'});
writetable(T,fullfile(folder,'nominal_sections.csv'));
b=md.rigidBodies.bodies;rows=cell(0,6);
for k=1:numel(b)
    rows(end+1,:)={b(k).name,b(k).masterNode,b(k).mass, ...
        string(mat2str(b(k).inertiaBody,16)),string(mat2str(b(k).cgOffsetBody,16)),b(k).source}; %#ok<AGROW>
end
writetable(cell2table(rows,'VariableNames',{'body','masterNode','massKg','inertiaKgM2','offsetM','source'}), ...
    fullfile(folder,'nominal_bodies.csv'));
comp=["ux";"uy";"uz";"rx";"ry";"rz"];unit=[repmat("N/m",3,1);repmat("N m/rad",3,1)];
writetable(table(comp,cfg.drivetrain.stiffness(:),unit,'VariableNames', ...
    {'component','drivetrainStiffness','unit'}),fullfile(folder,'nominal_drivetrain.csv'));
if string(cfg.base.type)=="flexible"
    writetable(table(comp,diag(cfg.foundation.K),diag(cfg.foundation.M),diag(cfg.foundation.C), ...
        'VariableNames',{'component','foundationK','foundationM','foundationC'}),fullfile(folder,'nominal_foundation.csv'));
end
end
