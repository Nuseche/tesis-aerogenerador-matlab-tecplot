function output=real_seismic_case(csvFile,factors,dt,chunkSize)
% Same operating-point physics as sensitivity.evaluate_case; bounded memory.
% Existing Newmark, influence and physical snapshot recovery are reused.
if nargin<4,chunkSize=500;end
root='/Users/nuseche/Desktop/Tesis_codigos';addpath(root);addpath(fullfile(root,'cases'));
started=tic;study=sensitivity.config_local();cfg=study.nominal;
raw=readmatrix(csvFile);
cfg.seismic=struct('record',struct('t',raw(:,1),'acceleration',raw(:,2), ...
    'timeUnit',"s",'accelerationUnit',"m/s^2"),'directions',2, ...
    'baselineCorrection',"none",'scaleFactor',1,'interpolation',"linear", ...
    'recordStatus',"recorded_processed_unscaled_global_Y_scenario");
cfg.newmark=struct('dt',dt,'beta',1/4,'gamma',1/2);
data=io.load_model_data(cfg);[data,cfg]=sensitivity.apply_parameters(data,cfg,factors);
oldRng=rng;cleanup=onCleanup(@()rng(oldRng));rng(study.seed,'twister');
md=model.build_model(data,cfg);model.validate_model(md,cfg);
[M,Ke]=assembly.assemble_structural_matrices(md,cfg);
M=assembly.apply_mass_formulation(M,cfg,md);
M=rigid.add_body_masses(M,md,md.rigidBodies);
Tc=rigid.rigid_constraint_matrix(md,md.rigidBodies,cfg);
red=rigid.reduce_system(Tc,M,Ke,md,cfg);
sweep=assembly.build_operating_sweep(md,red,cfg);ops=sweep.primaryOps;state=sweep.primaryState;
assert(state.converged&&state.residualRelative<=study.equilibriumTolerance);
am=model.prepare_analysis_model(md,ops.reduced);
record=io.load_accelerogram(cfg.seismic.record,struct('targetDt',dt,'baselineCorrection',"none"));
assert(max(abs(record.acceleration))>0);
channels=[129 1;129 2;129 3;130 1;130 2;130 3;56 1;56 2;56 3;92 3;128 3];
dofs=zeros(size(channels,1),1);
for j=1:numel(dofs)
    row=find(md.mesh.nodes.id==channels(j,1),1);dofs(j)=md.dofs.node(row,channels(j,2));
end
N=numel(record.t);historyQ=zeros(numel(dofs),N);historyA=historyQ;
historyR=zeros(numel(md.dofs.fixed),N);dynamicResidual=0;
lastQ=[];lastV=[];lastA=[];chunkCount=0;
for first=1:chunkSize:N-1
    ix=first:min(first+chunkSize,N);localCfg=cfg;
    localCfg.seismic.record=struct('t',record.t(ix),'acceleration',record.acceleration(ix,:), ...
        'velocity',record.velocity(ix,:),'displacement',record.displacement(ix,:), ...
        'timeUnit',"s",'accelerationUnit',"m/s^2",'velocityUnit',"m/s",'displacementUnit',"m");
    localCfg.newmark=rmfield(localCfg.newmark,'dt'); % already sampled; no repeated resampling
    if ~isempty(lastQ)
        localCfg.newmark.q0=lastQ;localCfg.newmark.qd0=lastV;localCfg.newmark.qdd0=lastA;
    end
    tr=dynamics.run_seismic_analysis(ops,am,localCfg);
    tr=dynamics.recover_full_response(tr,ops.reduced,md);
    historyQ(:,ix)=tr.qFull(dofs,:);historyA(:,ix)=tr.absoluteAccelerationFull(dofs,:);
    historyR(:,ix)=tr.reactionDiagnostics.constraintForcesFull(md.dofs.fixed,:);
    dynamicResidual=max(dynamicResidual,max(tr.relativeResidual));
    dynamicResidual=max(dynamicResidual,tr.reactionDiagnostics.relativeProjectedResidual);
    lastQ=tr.q(:,end);lastV=tr.qd(:,end);lastA=tr.qdd(:,end);chunkCount=chunkCount+1;
end
assert(all(isfinite(historyQ),'all')&&all(isfinite(historyA),'all'));
output=struct('factors',factors,'dt',dt,'t',record.t,'historyQ',historyQ, ...
    'historyA',historyA,'historyR',historyR,'channels',channels, ...
    'peakQ',max(abs(historyQ),[],2),'peakA',max(abs(historyA),[],2), ...
    'peakR',max(abs(historyR),[],2),'dynamicResidual',dynamicResidual, ...
    'equilibriumResidual',state.residualRelative,'configuration',cfg, ...
    'sourceCsv',string(csvFile),'chunkSize',chunkSize,'chunkCount',chunkCount, ...
    'integrationMetadata',tr.integrationMetadata,'elapsedSeconds',toc(started), ...
    'scope',"frozen_snapshot_structural_only_no_aerodynamic_damping", ...
    'rotorAxis',md.rotorAxis,'height',max(md.mesh.nodes.xyz(:,3)));
end
