function tests=test_action09_seismic_newmark
tests=functiontests(localfunctions);
end

function testSuppliedGroundKinematicsUnitsAndScale(testCase)
t=(0:.1:.5).';source=struct('t',t,'acceleration',[t 2*t], ...
    'velocity',[t.^2 2*t.^2],'displacement',[t.^3 2*t.^3], ...
    'timeUnit',"s",'accelerationUnit',"m/s^2", ...
    'velocityUnit',"m/s",'displacementUnit',"m");
record=io.load_accelerogram(source,struct('baselineCorrection',"none", ...
    'scaleFactor',2));
verifyEqual(testCase,record.acceleration,2*source.acceleration,'AbsTol',1e-14);
verifyEqual(testCase,record.velocity,2*source.velocity,'AbsTol',1e-14);
verifyEqual(testCase,record.displacement,2*source.displacement,'AbsTol',1e-14);
verifyEqual(testCase,record.accelerationUnit,"m/s^2");
verifyEqual(testCase,record.processing.velocitySource,"provided");
verifyEqual(testCase,record.processing.displacementSource,"provided");
end

function testIncompatibleBaselineCorrectionIsRejected(testCase)
source=struct('t',[0;1],'acceleration',[1;2], ...
    'velocity',[0;1.5],'displacement',[0;.5]);
verifyError(testCase,@()io.load_accelerogram(source, ...
    struct('baselineCorrection',"mean")), ...
    'io:Accelerogram:InconsistentProvidedKinematics');
end

function testMassInfluenceDiffersFromKinematicAndProjectsExactly(testCase)
[ops,model,cfg]=coupledSupportSystem();
response=dynamics.run_seismic_analysis(ops,model,cfg);
projected=ops.Tc.'*ops.Mfull*response.GammaFullAbsolute;
verifyGreaterThan(testCase,norm(response.GammaEffective- ...
    response.GammaKinematic),0);
verifyLessThanOrEqual(testCase,norm(ops.M*response.GammaEffective-projected)/ ...
    norm(projected),1e-12);
verifyEqual(testCase,response.baseForce, ...
    -ops.M*response.GammaEffective*response.accelerogram.acceleration.', ...
    'AbsTol',1e-13);
end

function testConditionallyStableNewmarkRejected(testCase)
verifyError(testCase,@()dynamics.newmark_integrate( ...
    1,0,1,[0;.1],zeros(1,2),struct('beta',.1,'gamma',.1)), ...
    'dynamics:Newmark:ConditionallyStableParameters');
end

function testConservativeAndDampedEnergyBalance(testCase)
t=(0:.002:1).';conservative=dynamics.newmark_integrate( ...
    1,0,4,t,zeros(size(t)),struct('q0',1));
damped=dynamics.newmark_integrate( ...
    1,.2,4,t,zeros(size(t)),struct('q0',1));
verifyLessThanOrEqual(testCase,max(conservative.energy.relativeBalanceError),1e-8);
verifyLessThanOrEqual(testCase,max(damped.energy.relativeBalanceError),1e-8);
verifyGreaterThan(testCase,damped.energy.dampingWork(end),0);
end

function testFullDistributionRequiredForAdditionalForce(testCase)
t=(0:.01:.1).';cfg.seismic.record=struct('t',t,'acceleration',ones(size(t)));
cfg.seismic.directions=1;ops=struct('M',1,'D',0,'K',4, ...
    'Mfull',eye(2),'Dfull',zeros(2),'Kfull',diag([5 4]), ...
    'Tc',[0;1],'forceTime',ones(1,numel(t)));
model.fullFixed=1;
verifyError(testCase,@()dynamics.run_seismic_analysis(ops,model,cfg), ...
    'dynamics:Seismic:AmbiguousFullOtherForce');
end

function testConstraintAndSupportRecovery(testCase)
[ops,model,cfg]=coupledSupportSystem();
response=dynamics.run_seismic_analysis(ops,model,cfg);
response=dynamics.recover_full_response(response,ops,model);
verifyEqual(testCase,response.reactions, ...
    response.constraintForcesFull(model.dofs.fixed,:),'AbsTol',1e-13);
verifyLessThanOrEqual(testCase, ...
    response.reactionDiagnostics.relativeProjectedResidual,1e-9);
verifyEqual(testCase,response.absoluteAccelerationFull, ...
    response.qddFull+response.GammaFull*response.accelerogram.acceleration.', ...
    'AbsTol',1e-13);
end

function testElementForceBackwardError(testCase)
model.dofs.number=12;model.dofs.node=1:12;
K=diag(1:12);cache=struct('assembled',true,'id',7,'dofs',(1:12).', ...
    'Te',eye(12),'KeLocal',K,'KeGlobal',K, ...
    'component',"tower",'blade',0);
q=reshape(sin(1:60),12,5);
forces=dynamics.recover_element_forces(model,q,cache);
verifyLessThanOrEqual(testCase,forces.maximumLocalGlobalBackwardError,1e-14);
verifyLessThanOrEqual(testCase,forces.assemblyError,1e-14);
verifySize(testCase,forces.localEndForces,[12 5 1]);
end

function testCanonicalAction09SuiteAndPersistence(testCase)
root=fileparts(fileparts(mfilename('fullpath')));
cfg=io.load_configuration(fullfile(root,'cases', ...
    'config_action09_seismic_newmark.m'));
cfg.output.makeFigures=false;
temporaryRuns=tempname;mkdir(temporaryRuns);
cleanup=onCleanup(@()rmdir(temporaryRuns,'s'));
cfg.output.runsDirectory=string(temporaryRuns);
results=main(cfg);
verifyTrue(testCase,results.action09.passed);
verifyTrue(testCase,all([results.action09.checks.pass]));
verifyLessThanOrEqual(testCase, ...
    results.action09.metrics.fineRelativeDifference,1e-3);
verifyLessThanOrEqual(testCase, ...
    results.action09.metrics.fineMaximumDifference,.01);
verifyGreaterThanOrEqual(testCase,results.action09.metrics.modelTemporalOrder,1.8);
folder=char(results.meta.runFolder);
verifyTrue(testCase,isfile(fullfile(folder,'action09_matrices.mat')));
verifyTrue(testCase,isfile(fullfile(folder,'action09_validation.csv')));
verifyTrue(testCase,isfile(fullfile(folder,'action09_ground_motion.csv')));
verifyTrue(testCase,isfile(fullfile(folder,'action09_time_convergence.csv')));
verifyTrue(testCase,isfile(fullfile(folder,'action09_sdof_benchmark.csv')));
verifyTrue(testCase,isfile(fullfile(folder,'action09_response_extrema.csv')));
verifyTrue(testCase,isfile(fullfile(folder,'action09_reactions.csv')));
verifyTrue(testCase,isfile(fullfile(folder,'action09_element_forces.csv')));
saved=load(fullfile(folder,'action09_matrices.mat'), ...
    'action09Results','GammaEffective','GammaKinematic','Rfull');
verifyTrue(testCase,saved.action09Results.passed);
verifyTrue(testCase,issparse(saved.Rfull));
verifyGreaterThan(testCase, ...
    norm(saved.GammaEffective-saved.GammaKinematic,'fro'),0);
manifest=load(fullfile(folder,'manifest.mat'),'manifest');
verifyTrue(testCase,manifest.manifest.hasAction09);
verifyTrue(testCase,manifest.manifest.action09Passed);
end

function [ops,model,cfg]=coupledSupportSystem()
Tc=[sparse(6,6);speye(6)];Mfull=speye(12);
Mfull(1,7)=.2;Mfull(7,1)=.2;
ops=struct('M',Tc.'*Mfull*Tc,'D',.1*speye(6),'K',4*speye(6), ...
    'Mfull',Mfull,'Dfull',.1*speye(12),'Kfull',4*speye(12), ...
    'Tc',Tc);
model.dofs.node=reshape(1:12,6,2).';model.dofs.fixed=(1:6).';
model.fullFixed=model.dofs.fixed;model.Tc=Tc;model.nDof=6;
model.dofMap=model.dofs.node;
t=(0:.01:.1).';cfg.seismic.record=struct('t',t, ...
    'acceleration',ones(size(t)),'velocity',t,'displacement',.5*t.^2);
cfg.seismic.baselineCorrection="none";cfg.seismic.directions=1;
cfg.newmark.beta=1/4;cfg.newmark.gamma=1/2;
end
