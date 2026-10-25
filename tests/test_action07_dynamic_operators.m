function tests=test_action07_dynamic_operators
tests=functiontests(localfunctions);
end

function testRigidDiskCorotatingEnergyAndInertialAngularMomentum(testCase)
m=10;Jp=4;Jd=3;omega=7;
body=struct('mass',m,'cgOffsetBody',zeros(3,1), ...
    'inertiaBody',diag([Jp Jd Jd]),'orientationBodyToGlobal',eye(3));
M=rigid.rigid_body_mass_matrix(body);
[G,d]=assembly.rotating_mass_gyroscopic_matrix(M,[omega;0;0]);
verifyEqual(testCase,full(G(1:3,1:3)), ...
    2*m*[0 0 0;0 0 -omega;0 omega 0],'AbsTol',1e-13);
verifyEqual(testCase,full(G(4:6,4:6)), ...
    [0 0 0;0 0 -(2*Jd-Jp)*omega;0 (2*Jd-Jp)*omega 0],'AbsTol',1e-13);
transport=assembly.transport_rotating_operators(M,G,[omega;0;0]);
verifyEqual(testCase,full(transport.G(1:3,1:3)),zeros(3),'AbsTol',1e-13);
verifyEqual(testCase,full(transport.G(4:6,4:6)), ...
    [0 0 0;0 0 Jp*omega;0 -Jp*omega 0],'AbsTol',1e-13);
verifyEqual(testCase,d.angularMomentum,[Jp*omega;0;0],'AbsTol',1e-13);
verifyEqual(testCase,norm(G+G.','fro'),0,'AbsTol',0);
end

function testDistributedSelectiveElementMatchesAnalyticCoriolis(testCase)
L=5;m=12;omega=3;section=localSection();section.m=m;
section.Jx=2;section.Jy=1;section.Jz=1;
cfg.elements.formulation="selective_integration";
G=elements.timoshenko_gyroscopic_matrix( ...
    [0 0 0],[L 0 0],[0 0 1],section,[omega;0;0],cfg);
M2=m*L/6*[2 1;1 2];expected=2*omega*kron(M2,[0 -1;1 0]);
verifyEqual(testCase,full(G([2 3 8 9],[2 3 8 9])),expected, ...
    'RelTol',2e-15);
verifyEqual(testCase,norm(G+G.','fro'),0,'AbsTol',0);
end

function testRayleighTargetsAndConnectorObjectivity(testCase)
model.mesh.nodes=struct('id',[129;130],'xyz',[1 2 3;3 2.5 2.7]);
model.dofs.node=reshape(1:12,6,2).';
cfg.damping.rayleigh.targetFrequenciesHz=[.2;2];
cfg.damping.rayleigh.targetDampingRatios=[.01;.01];
cfg.drivetrain.damping=1:6;
[C,parts]=assembly.assemble_damping_matrix( ...
    model,speye(12),2*speye(12),struct(),cfg);
verifyEqual(testCase,parts.rayleigh.recoveredDampingRatios, ...
    [.01;.01],'AbsTol',2e-15);
theta=[.2;-.1;.3];translation=[1;-2;.5];q=zeros(12,1);
for node=1:2
    x=model.mesh.nodes.xyz(node,:).';
    q(model.dofs.node(node,1:3))=translation+cross(theta,x);
    q(model.dofs.node(node,4:6))=theta;
end
B=parts.drivetrainKinematics.relativeKinematicMatrix;
verifyEqual(testCase,B*q,zeros(6,1),'AbsTol',1e-14);
verifyEqual(testCase,q.'*parts.drivetrain*q,0,'AbsTol',1e-12);
verifyGreaterThan(testCase,q.'*C*q,0);
end

function testAerodynamicRefinementAndExplicitZeroSource(testCase)
state.qFull=[.2;-.1];state.qdFull=[.3;.4];
cfg.aerodynamics.loadFcn=@aeroLoad;
cfg.aerodynamics.dofIndices=[1 2];
cfg.aerodynamics.finiteDifferenceStep=1e-4;
[K,C,report]=assembly.linearize_aerodynamic_loads(struct(),state,cfg,2);
verifyEqual(testCase,full(K),-[2 3;-1 4],'AbsTol',2e-10);
verifyEqual(testCase,full(C),-[.5 -.2;.7 .9],'AbsTol',2e-10);
verifyEqual(testCase,report.method,"central_finite_difference_refined");
cfg.aerodynamics=struct('Kaero',sparse(2,2),'Caero',sparse(2,2));
[K,C,report]=assembly.linearize_aerodynamic_loads(struct(),state,cfg,2);
verifyEqual(testCase,nnz(K)+nnz(C),0);
verifyEqual(testCase,report.method,"provided_matrices");
end

function testAerodynamicForceAndStaticTangentShareSource(testCase)
model.mesh.nodes=struct('id',1,'xyz',[0 0 0]);
model.mesh.elements=struct('id',zeros(0,1),'nodeI',zeros(0,1), ...
    'nodeJ',zeros(0,1),'section',zeros(0,1),'blade',zeros(0,1));
model.sections=struct([]);model.dofs.node=1:6;model.dofs.number=6;
state.qFull=[.2;zeros(5,1)];state.qdFull=zeros(6,1);
cfg.gravity=struct('enabled',false,'vector',[0;0;0]);cfg.rotor.speedRPM=0;
cfg.aerodynamics.loadFcn=@staticAeroLoad;
cfg.aerodynamics.tangentFcn=@staticAeroTangent;
[f,parts,Kexternal]=assembly.assemble_load_vector(model,cfg,state);
verifyEqual(testCase,full(f(1)),96,'AbsTol',1e-13);
verifyEqual(testCase,full(parts.aerodynamic(1)),96,'AbsTol',1e-13);
verifyEqual(testCase,full(Kexternal(1,1)),-20,'AbsTol',1e-13);
verifyEqual(testCase,full(parts.aerodynamicStiffness(1,1)),20,'AbsTol',1e-13);
end

function testExternalGyroValidationRejectsNonSkew(testCase)
model.mesh.nodes=struct('id',1,'xyz',[0 0 0]);
model.mesh.elements=struct('id',zeros(0,1),'nodeI',zeros(0,1), ...
    'nodeJ',zeros(0,1),'section',zeros(0,1),'blade',zeros(0,1));
model.sections=struct([]);model.dofs.node=1:6;model.dofs.number=6;
model.rotorAxis.direction=[1;0;0];state.Gexternal=speye(6);
verifyError(testCase,@()assembly.assemble_gyroscopic_matrix( ...
    model,state,struct()),'assembly:assemble_gyroscopic_matrix:NonSkew');
end

function testCanonicalAction07Suite(testCase)
root=fileparts(fileparts(mfilename('fullpath')));
cfg=io.load_configuration(fullfile(root,'cases', ...
    'config_action07_dynamic_operators.m'));
data=io.load_model_data(cfg);modelData=model.build_model(data,cfg);
[Md,Ke]=assembly.assemble_structural_matrices(modelData,cfg);
Md=assembly.apply_mass_formulation(Md,cfg,modelData);
M=rigid.add_body_masses(Md,modelData,modelData.rigidBodies);
Tc=rigid.rigid_constraint_matrix(modelData,modelData.rigidBodies,cfg);
reduced=rigid.reduce_system(Tc,M,Ke,modelData,cfg);
sweep=assembly.build_operating_sweep(modelData,reduced,cfg);
suite=validation.run_dynamic_operator_suite(modelData,reduced,sweep,cfg);
verifyTrue(testCase,suite.passed);verifyTrue(testCase,all([suite.checks.pass]));
verifyLessThanOrEqual(testCase,suite.metrics.maximumGyroSkewError,1e-12);
verifyLessThanOrEqual(testCase,suite.metrics.bladeNormDispersion,1e-3);
verifyLessThanOrEqual(testCase,suite.metrics.distributedElementError,1e-10);
verifyLessThanOrEqual(testCase,suite.metrics.aerodynamicPositionError,1e-6);
end

function f=aeroLoad(q,qd,~,~,~)
f=[2 3;-1 4]*q+[.5 -.2;.7 .9]*qd;
end

function f=staticAeroLoad(q,~,~,~,~)
f=zeros(6,1);f(1)=100-20*q(1);
end

function [K,C]=staticAeroTangent(~,~,~)
K=sparse(6,6);K(1,1)=20;C=sparse(6,6);
end

function section=localSection()
section=struct('id',1,'EA',2.1e9,'GAy',4e8,'GAz',3e8,'GJ',1.5e8, ...
    'EIy',8e7,'EIz',6e7,'m',25,'Jx',2,'Jy',1.2,'Jz',1.4, ...
    'xcg',0,'ycg',0,'zcg',0);
end
