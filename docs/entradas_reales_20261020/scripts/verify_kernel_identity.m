root='/Users/nuseche/Desktop/Tesis_codigos';addpath(root);addpath(fullfile(root,'cases'));
docs=fullfile(root,'docs/entradas_reales_20261020');addpath(fullfile(docs,'scripts'));
cfg=config_action08_mbc_qep_campbell();data=io.load_model_data(cfg);md=model.build_model(data,cfg);
rng(6720,'twister');n=md.dofs.number;states=[zeros(n,1),1e-5*randn(n,1),1e-4*randn(n,1)];
checks=zeros(3,4);
for j=1:3
    q=states(:,j);[f,K,d]=equilibrium.total_lagrangian_internal_force(md,q,cfg);
    [f1,K1,d1]=diagnostic_internal_force(md,q,cfg,1);
    [~,~,d20]=diagnostic_internal_force(md,q,cfg,20);
    checks(j,:)=[norm(f-f1)/max(norm(f),eps),norm(K-K1,'fro')/max(norm(K,'fro'),eps), ...
        abs(d.totalStrainEnergy-d1.totalStrainEnergy),abs(d.totalStrainEnergy-d20.totalStrainEnergy)];
end
assert(max(checks,[],'all')<1e-13,'Diagnostic copy changes original kernel/energy');
result=struct('states',3,'checks',checks,'columnNames', ...
    ["relativeForceScale1" "relativeHessianScale1" "energyDifferenceScale1" "energyDifferenceScale20"], ...
    'physicalEnergyIdentical',true,'productionSourcesChanged',false);
fid=fopen(fullfile(docs,'kernel_identity_verification.json'),'w');fprintf(fid,'%s',jsonencode(result,PrettyPrint=true));fclose(fid);
