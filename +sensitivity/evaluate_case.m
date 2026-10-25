function result=evaluate_case(study,factors,options)
%EVALUATE_CASE Existing physical routines, re-equilibrated for each case.
if nargin<3,options=struct();end
started=tic;cfg=study.nominal;
if isfield(options,'seismic')&&options.seismic
    timeCfg=config_action09_seismic_newmark();
    cfg.seismic=timeCfg.seismic;cfg.newmark=timeCfg.newmark;
    if isfield(options,'dt'),cfg.newmark.dt=options.dt;end
end
data=io.load_model_data(cfg);
[data,cfg]=sensitivity.apply_parameters(data,cfg,factors);
if isfield(options,'strict')&&options.strict
    % Tighten QEP only: equilibrium Hessian has an observed numerical floor.
    cfg.modal.tolerance=1e-12;cfg.modes.tolerance=1e-12;
end
oldRng=rng;cleanup=onCleanup(@()rng(oldRng));rng(study.seed,'twister');
md=model.build_model(data,cfg);inputReport=model.validate_model(md,cfg);
refinement=1;
if isfield(options,'refinement'),refinement=options.refinement;end
if refinement>1
    if cfg.rotor.speedRPM~=0||cfg.rotor.mbc.enabled
        error('sensitivity:RefinementScope', ...
            'Initial mesh verification requires stopped rotor and MBC disabled.');
    end
    md=sensitivity.refine_model(md,refinement);
end
[M,Ke,~,assemblyReport]=assembly.assemble_structural_matrices(md,cfg);
[M,massReport]=assembly.apply_mass_formulation(M,cfg,md);
[M,bodyReport]=rigid.add_body_masses(M,md,md.rigidBodies);
[Tc,constraintReport]=rigid.rigid_constraint_matrix(md,md.rigidBodies,cfg);
reduced=rigid.reduce_system(Tc,M,Ke,md,cfg);
sweepCfg=cfg;
if isfield(options,'continuationGrid')
    sweepCfg.rotor.speedRPMGrid=options.continuationGrid;
end
sweep=assembly.build_operating_sweep(md,reduced,sweepCfg);
ops=sweep.primaryOps;state=sweep.primaryState;
am=model.prepare_analysis_model(md,ops.reduced);
mr=modal.run_analysis(ops,am,cfg);sol=mr.solutions{1};
[~,cholFlag]=chol(ops.reduced.M);
if cholFlag~=0,error('sensitivity:MassNotPositive','Reduced mass is not positive definite.');end
if ~state.converged||state.residualRelative>study.equilibriumTolerance
    error('sensitivity:EquilibriumResidual','Equilibrium residual %.3g.',state.residualRelative);
end
if max(sol.residual)>study.qepTolerance||any(~isfinite(sol.eigenvaluesQEP))
    error('sensitivity:QEPResidual','QEP solution failed the residual gate.');
end
if isempty(sol.leftResidual)||max(sol.leftResidual)>study.qepTolerance
    error('sensitivity:LeftResidual','Missing or inaccurate left QEP modes.');
end
rigidAudit=sensitivity.rigid_audit(md,sol.fullModes,M,Ke);
channels=[129 2;130 2;56 3;92 3;128 3];
staticQ=zeros(size(channels,1),1);
for k=1:size(channels,1)
    row=find(md.mesh.nodes.id==channels(k,1),1);
    staticQ(k)=state.qFull(md.dofs.node(row,channels(k,2)));
end
result=struct('configuration',cfg,'factors',factors,'options',options, ...
    'solution',sol,'fullMass',M,'state',state,'staticQ',staticQ, ...
    'channels',channels,'modelSummary',md.summary, ...
    'diagnostics',struct('input',inputReport,'assembly',assemblyReport, ...
    'mass',massReport,'bodies',bodyReport,'constraints',constraintReport, ...
    'rigid',rigidAudit,'equilibriumResidual',state.residualRelative, ...
    'qepResidual',max(sol.residual),'leftResidual',max(sol.leftResidual), ...
    'spectrumComplete',sol.spectrumComplete,'refinement',refinement), ...
    'units',struct('frequency',"Hz",'growth',"s^-1",'staticQ',"m"), ...
    'scope',"frozen_azimuth_partial_spectrum_total_equilibrium_sensitivity");
if isfield(options,'seismic')&&options.seismic
    tr=dynamics.run_seismic_analysis(ops,am,cfg);
    tr=dynamics.recover_full_response(tr,ops.reduced,md);
    peakQ=zeros(size(channels,1),1);peakA=peakQ;historyQ=zeros(size(channels,1),numel(tr.t));
    for k=1:size(channels,1)
        row=find(md.mesh.nodes.id==channels(k,1),1);dof=md.dofs.node(row,channels(k,2));
        historyQ(k,:)=tr.qFull(dof,:);
        peakQ(k)=max(abs(tr.qFull(dof,:)));
        peakA(k)=max(abs(tr.absoluteAccelerationFull(dof,:)));
    end
    result.time=struct('t',tr.t,'peakQ',peakQ,'peakAbsoluteA',peakA, ...
        'historyQ',historyQ,'window',[tr.t(1) tr.t(end)], ...
        'recordStatus',cfg.seismic.recordStatus,'dt',cfg.newmark.dt, ...
        'dynamicResidual',tr.reactionDiagnostics.relativeProjectedResidual, ...
        'integrationMetadata',tr.integrationMetadata);
    result.configuration=cfg;
end
result.elapsedSeconds=toc(started);
end
