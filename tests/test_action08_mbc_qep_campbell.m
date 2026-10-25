function tests=test_action08_mbc_qep_campbell
tests=functiontests(localfunctions);
end

function testHomologousFramePrecedesHarmonicMixing(testCase)
map=reshape(1:18,6,3);referenceR=zeros(3,3,1,3);
for blade=1:3
    angle=2*pi*(blade-1)/3;
    referenceR(:,:,1,blade)=[1 0 0;0 cos(angle) -sin(angle); ...
        0 sin(angle) cos(angle)];
end
frameData=struct('map',map,'referenceR',referenceR, ...
    'rotorAxis',[1;0;0],'nDof',18);
psi=.37;omega=2.1;alpha=-.14;
options=struct('nDof',18,'frameData',frameData, ...
    'angularAcceleration',alpha);
d=rotor.mbc_derivatives(map,psi,omega,options);
verifyLessThanOrEqual(testCase,d.identityError,1e-12);
verifyGreaterThan(testCase,norm(d.frame.Hdot,'fro'),0);
verifyGreaterThan(testCase,norm(d.frame.Hddot,'fro'),0);
h=2e-5;
plus=rotor.mbc_derivatives(map,psi+omega*h+.5*alpha*h^2, ...
    omega+alpha*h,options);
minus=rotor.mbc_derivatives(map,psi-omega*h+.5*alpha*h^2, ...
    omega-alpha*h,options);
finiteDot=(plus.T-minus.T)/(2*h);
finiteDdot=(plus.T-2*d.T+minus.T)/(h^2);
verifyLessThanOrEqual(testCase,norm(finiteDot-d.Tdot,'fro')/ ...
    max(norm(d.Tdot,'fro'),1),2e-8);
verifyLessThanOrEqual(testCase,norm(finiteDdot-d.Tddot,'fro')/ ...
    max(norm(d.Tddot,'fro'),1),2e-6);
for component=1:6
    indices=map(component,:);qHom=zeros(18,1);qHom(indices)=1;
    qGlobal=d.frame.H*qHom;
    harmonicCoordinates=d.harmonic.Tinv*(d.frame.Hinv*qGlobal);
    verifyLessThanOrEqual(testCase, ...
        norm(harmonicCoordinates(indices(2:3))),1e-12);
end
end

function testGlobalAssignmentCounterexample(testCase)
score=[.9 .8;.85 .1];
[assignment,total]=modal.optimal_assignment(score);
verifyEqual(testCase,assignment,[2 1]);
verifyEqual(testCase,total,1.65,'AbsTol',1e-14);
verifyGreaterThan(testCase,total,1.0);
end

function testDegenerateSubspaceIsBasisInvariant(testCase)
rotated=[1 1;-1 1]/sqrt(2);
sub=modal.subspace_mac(eye(2),rotated,eye(2));
individual=modal.modal_assurance_criterion(eye(2),rotated,eye(2));
verifyEqual(testCase,sub.minimumMAC,1,'AbsTol',1e-14);
verifyEqual(testCase,individual,.5*ones(2),'AbsTol',1e-14);
end

function testQuadraticLeftModesAndBiorthogonality(testCase)
M=[2 .1;0 1.4];D=[.3 .8;-.2 .5];K=[8 1.2;-.4 13];
r=modal.solve_quadratic_modes(M,D,K,struct('number',2));
verifyTrue(testCase,r.leftDiagnostics.available);
verifyLessThanOrEqual(testCase,max(r.residual),1e-12);
verifyLessThanOrEqual(testCase,max(r.leftResidual),1e-12);
verifyLessThanOrEqual(testCase,r.leftDiagnostics.maximumOffDiagonal,1e-10);
verifyEqual(testCase,diag(r.biorthogonality),ones(2,1),'AbsTol',1e-10);
end

function testModalSummaryExportsCampbellClassification(testCase)
folder=tempname;mkdir(folder);cleanup=onCleanup(@()rmdir(folder,'s')); %#ok<NASGU>
run=struct('folder',folder);modalResults=struct('speedRPM',[0;6], ...
    'frequencyHz',[1 2;1.1 2.1],'naturalFrequencyHz',[1 2;1.1 2.1], ...
    'dampingRatio',[.01 .02;.01 .02], ...
    'eigenvalues',[-.1+1i -.2+2i;-.1+1.1i -.2+2.1i], ...
    'classification',{{struct('labels',["tower";"blade"]), ...
    struct('labels',["tower";"drivetrain"])}});
tableValue=post.export_modal_summary(run,modalResults);
verifyEqual(testCase,tableValue.classification, ...
    ["tower";"blade";"tower";"drivetrain"]);
reloaded=readtable(fullfile(folder,'modal_summary.csv'), ...
    'TextType','string');
verifyEqual(testCase,reloaded.classification,tableValue.classification);
end

function testCanonicalAction08Suite(testCase)
root=fileparts(fileparts(mfilename('fullpath')));
cfg=io.load_configuration(fullfile(root,'cases', ...
    'config_action08_mbc_qep_campbell.m'));
data=io.load_model_data(cfg);modelData=model.build_model(data,cfg);
[Md,Ke]=assembly.assemble_structural_matrices(modelData,cfg);
Md=assembly.apply_mass_formulation(Md,cfg,modelData);
M=rigid.add_body_masses(Md,modelData,modelData.rigidBodies);
Tc=rigid.rigid_constraint_matrix(modelData,modelData.rigidBodies,cfg);
reduced=rigid.reduce_system(Tc,M,Ke,modelData,cfg);
sweep=assembly.build_operating_sweep(modelData,reduced,cfg);
analysisModel=model.prepare_analysis_model(modelData,sweep.primaryOps.reduced);
modalResults=modal.run_analysis(sweep.ops,analysisModel,cfg);
suite=validation.run_mbc_qep_campbell_suite( ...
    modelData,reduced,sweep,analysisModel,modalResults,cfg);
verifyTrue(testCase,suite.passed);verifyTrue(testCase,all([suite.checks.pass]));
verifyLessThanOrEqual(testCase,suite.metrics.maximumCombinedIdentity,1e-12);
verifyLessThanOrEqual(testCase,suite.metrics.zeroSpeedQepError,1e-6);
verifyLessThanOrEqual(testCase,suite.metrics.maximumQepResidual,1e-8);
verifyGreaterThanOrEqual(testCase, ...
    suite.metrics.minimumEffectiveTrackingMAC,.8);
verifyGreaterThanOrEqual(testCase, ...
    suite.metrics.minimumSubspaceTrackingMAC,.95);
end
