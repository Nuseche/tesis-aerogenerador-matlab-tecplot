function tests=test_action06_equilibrium
tests=functiontests(localfunctions);
end

function testCorotationalRigidMotionHasZeroEnergy(testCase)
modelData=localBeamModel();angle=.2;
Q=[cos(angle) -sin(angle) 0;sin(angle) cos(angle) 0;0 0 1];
q=zeros(12,1);q(7:9)=Q*[4;0;0]-[4;0;0];
q(4:6)=[0;0;angle];q(10:12)=[0;0;angle];
[force,tangent,details]= ...
    equilibrium.total_lagrangian_internal_force(modelData,q,struct());
verifyLessThanOrEqual(testCase,details.totalStrainEnergy,1e-12);
verifyEqual(testCase,details.elementAxialForces,0,'AbsTol',1e-8);
verifyLessThan(testCase,norm(force)/(norm(tangent,'fro')*max(norm(q),1)),1e-10);
end

function testCorotationalTangentMatchesDirectionalDerivative(testCase)
modelData=localBeamModel();q=zeros(12,1);q(8)=.05;q(12)=.01;
[~,tangent]=equilibrium.total_lagrangian_internal_force(modelData,q,struct());
direction=sin((1:12).');direction=direction/norm(direction);h=1e-5;
plus=equilibrium.total_lagrangian_internal_force( ...
    modelData,q+h*direction,struct());
minus=equilibrium.total_lagrangian_internal_force( ...
    modelData,q-h*direction,struct());
finiteDifference=(plus-minus)/(2*h);
errorValue=norm(finiteDifference-tangent*direction)/norm(finiteDifference);
verifyLessThanOrEqual(testCase,errorValue,2e-6);
end

function testCentrifugalLoadAndJacobianScaleWithOmegaSquared(testCase)
modelData=localBeamModel();modelData.mesh.nodes.xyz=[0 1 0;0 5 0];
modelData.mesh.elements.auxPoint=[1 1 0];
modelData.rotorAxis=struct('point',[0;0;0],'direction',[1;0;0]);
state.qFull=zeros(12,1);cfg6.rotor.speedRPM=6;cfg12.rotor.speedRPM=12;
[f6,~,K6]=equilibrium.centrifugal_loads(modelData,cfg6,state);
[f12,~,K12]=equilibrium.centrifugal_loads(modelData,cfg12,state);
verifyEqual(testCase,f12,4*f6,'RelTol',2e-14);
verifyEqual(testCase,K12,4*K6,'RelTol',2e-14);
direction=cos((1:12).');direction=direction/norm(direction);h=1e-5;
plus=state;minus=state;plus.qFull=h*direction;minus.qFull=-h*direction;
fp=equilibrium.centrifugal_loads(modelData,cfg12,plus);
fm=equilibrium.centrifugal_loads(modelData,cfg12,minus);
verifyEqual(testCase,full((fp-fm)/(2*h)),full(K12*direction),'RelTol',2e-9);
end

function testOffsetAwareDrivetrainIsRigidMotionObjective(testCase)
modelData=localThreeNodeModel();cfg.base.type="fixed";
cfg.foundation.M=[];cfg.foundation.K=[];
cfg.drivetrain.stiffness=[1e4 2e4 3e4 4e4 5e4 6e4];
[~,~,~,diagnostics]=assembly.assemble_structural_matrices(modelData,cfg);
theta=[.01;-.02;.03];translation=[1;2;3];q=zeros(18,1);
for node=1:3
    x=modelData.mesh.nodes.xyz(node,:).';
    q(modelData.dofs.node(node,1:3))=translation+cross(theta,x);
    q(modelData.dofs.node(node,4:6))=theta;
end
energy=q.'*diagnostics.components.Kdrivetrain*q;
verifyEqual(testCase,energy,0,'AbsTol',2e-10);
verifyEqual(testCase,diagnostics.drivetrain.offsetGlobal,[1;0;0]);
end

function testTimoshenkoGeometricMatrixUsesShearFlexibility(testCase)
section=localSection();L=4;N=1e5;
Keb=elements.geometric_stiffness(L,N);
Ktim=elements.geometric_stiffness([0 0 0],[L 0 0],[0 1 0],N,section);
verifyLessThan(testCase,norm(Ktim-Ktim.','fro'),1e-10);
verifyGreaterThan(testCase,norm(Ktim-Keb,'fro'),0);
section.GAy=1e30;section.GAz=1e30;
Klimit=elements.geometric_stiffness([0 0 0],[L 0 0],[0 1 0],N,section);
verifyEqual(testCase,Klimit,Keb,'RelTol',1e-12);
end

function testCanonicalAction06Suite(testCase)
root=fileparts(fileparts(mfilename('fullpath')));
cfg=io.load_configuration(fullfile(root,'cases','config_action06_equilibrium.m'));
data=io.load_model_data(cfg);modelData=model.build_model(data,cfg);
[Md,Ke]=assembly.assemble_structural_matrices(modelData,cfg);
Md=assembly.apply_mass_formulation(Md,cfg,modelData);
M=rigid.add_body_masses(Md,modelData,modelData.rigidBodies);
Tc=rigid.rigid_constraint_matrix(modelData,modelData.rigidBodies,cfg);
reduced=rigid.reduce_system(Tc,M,Ke,modelData,cfg);
sweep=assembly.build_operating_sweep(modelData,reduced,cfg);
suite=validation.run_equilibrium_suite(modelData,reduced,sweep,cfg);
verifyTrue(testCase,suite.passed);
verifyTrue(testCase,all([suite.checks.pass]));
verifyLessThanOrEqual(testCase,suite.metrics.maximumResidual,1e-8);
verifyLessThanOrEqual(testCase,suite.metrics.maximumGlobalBalanceError,2e-3);
verifyLessThanOrEqual(testCase,suite.metrics.internalTangentError,2e-6);
verifyLessThanOrEqual(testCase,suite.metrics.centrifugalTangentError,2e-6);
verifyEqual(testCase,suite.metrics.maximumKOmegaNorm,0,'AbsTol',0);
end

function modelData=localBeamModel()
modelData.mesh.nodes=struct('id',[1;2],'xyz',[0 0 0;4 0 0]);
modelData.mesh.elements=struct('id',1,'nodeI',1,'nodeJ',2,'section',1, ...
    'blade',1,'type',"blade",'auxPoint',[0 1 0]);
modelData.sections=localSection();
modelData.dofs.node=reshape(1:12,6,2).';modelData.dofs.element=1:12;
modelData.dofs.number=12;modelData.dofs.fixed=zeros(0,1);
modelData.rotorAxis=struct('point',[0;0;0],'direction',[1;0;0]);
end

function modelData=localThreeNodeModel()
modelData.mesh.nodes=struct('id',[1;129;130], ...
    'xyz',[0 0 0;2 0 0;3 0 0]);
modelData.mesh.elements=struct('id',[1;2],'nodeI',[1;129], ...
    'nodeJ',[129;130],'section',[1;1],'blade',[0;0], ...
    'type',["tower";"transition"],'auxPoint',[0 1 0;2 1 0]);
modelData.sections=localSection();
modelData.dofs.node=reshape(1:18,6,3).';
modelData.dofs.element=[modelData.dofs.node(1,:) modelData.dofs.node(2,:); ...
    modelData.dofs.node(2,:) modelData.dofs.node(3,:)];
modelData.dofs.number=18;modelData.dofs.fixed=(1:6).';
modelData.boundaryConditions.fixedNodeIds=1;
modelData.boundaryConditions.fixedDofs=(1:6).';
modelData.rigidBodies.masters=[129;130];
end

function section=localSection()
section=struct('id',1,'EA',2.1e9,'GAy',4e8,'GAz',3e8,'GJ',1.5e8, ...
    'EIy',8e7,'EIz',6e7,'m',25,'Jx',2,'Jy',1.2,'Jz',1.4, ...
    'ycg',0,'zcg',0);
end
