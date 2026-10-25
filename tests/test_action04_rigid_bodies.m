function tests=test_action04_rigid_bodies
tests=functiontests(localfunctions);
end

function testVersionedDatasetHasExplicitUnits(testCase)
cfg=io.load_configuration();
data=io.load_model_data(cfg);
verifyEqual(testCase,string(data.rigidBodies.datasetId), ...
    "legacy_rigid_bodies_v0");
verifyEqual(testCase,string(data.rigidBodies.orientation.angleUnit),"deg");
verifyEqual(testCase,reshape(double(data.rigidBodies.orientation.angles),1,3), ...
    [90 -5 -90]);
verifyEqual(testCase,[data.rigidBodies.bodies.massKg], ...
    [1.1845e6 1.9600e5]);
end

function testDegreeConversionIsExplicitAndNotLegacyRawRadians(testCase)
cfg=io.load_configuration();data=io.load_model_data(cfg);
modelData=model.build_model(data,cfg);
body=modelData.rigidBodies.bodies(1);
verifyEqual(testCase,body.orientationAnglesRad, ...
    deg2rad(body.orientationAnglesInput),'AbsTol',0);
expected=localPassiveZXZ(deg2rad([90 -5 -90]));
verifyEqual(testCase,body.orientationBodyToGlobal,expected,'AbsTol',2e-15);
legacyRaw=localPassiveZXZ([90 -5 -90]);
verifyGreaterThan(testCase,norm(expected-legacyRaw,'fro'),1e-3);
end

function testOffsetSpatialMassMatchesClosedForm(testCase)
body=struct('mass',12,'cgOffsetBody',[1;-2;.5], ...
    'inertiaBody',[7 .2 -.1;.2 8 .3;-.1 .3 9], ...
    'orientationBodyToGlobal',localPassiveZXZ([.2 -.3 .4]));
[MR,details]=rigid.rigid_body_mass_matrix(body);
r=details.cgOffsetGlobal;
S=[0 -r(3) r(2);r(3) 0 -r(1);-r(2) r(1) 0];
J=body.orientationBodyToGlobal*body.inertiaBody* ...
    body.orientationBodyToGlobal.';
expected=[12*eye(3) -12*S;12*S J-12*S*S];
verifyEqual(testCase,MR,expected,'AbsTol',2e-14);
verifyGreaterThan(testCase,norm(MR(1:3,4:6),'fro'),0);
verifyGreaterThan(testCase,min(eig(MR)),0);
end

function testNonPhysicalInertiaIsRejected(testCase)
body=struct('mass',1,'cgOffsetBody',zeros(3,1), ...
    'inertiaBody',diag([1 1 3]),'orientationBodyToGlobal',eye(3));
verifyError(testCase,@()rigid.rigid_body_mass_matrix(body), ...
    'rigid:rigid_body_mass_matrix:NonPhysicalInertia');
end

function testCanonicalNacelleHasProductsOfInertia(testCase)
cfg=io.load_configuration();data=io.load_model_data(cfg);
modelData=model.build_model(data,cfg);
[~,details]=rigid.rigid_body_mass_matrix(modelData.rigidBodies.bodies(1));
products=details.inertiaGlobalCG-diag(diag(details.inertiaGlobalCG));
verifyGreaterThan(testCase,norm(products,'fro'),1e5);
verifyLessThanOrEqual(testCase,details.inertiaTriangleResidual, ...
    details.inertiaTriangleTolerance);
end

function testCanonicalAction04Suite(testCase)
root=fileparts(fileparts(mfilename('fullpath')));
cfg=io.load_configuration(fullfile(root,'cases','config_action04_rigid_bodies.m'));
data=io.load_model_data(cfg);modelData=model.build_model(data,cfg);
[Md,Ke,~,~]=assembly.assemble_structural_matrices(modelData,cfg);
[Md,massInfo]=assembly.apply_mass_formulation(Md,cfg); %#ok<ASGLU>
[M,bodyInfo]=rigid.add_body_masses(Md,modelData,modelData.rigidBodies);
[Tc,constraintInfo]=rigid.rigid_constraint_matrix( ...
    modelData,modelData.rigidBodies,cfg);
reduced=rigid.reduce_system(Tc,M,Ke,modelData,cfg);
properties=rigid.compute_mass_properties(modelData,M,Tc);
suite=validation.run_rigid_body_mass_suite(modelData,Md,M,Ke,Tc, ...
    reduced,constraintInfo,bodyInfo,properties,cfg);
verifyTrue(testCase,suite.passed);
verifyTrue(testCase,all([suite.checks.pass]));
verifyEqual(testCase,suite.metrics.bodyMassKg,1380500,'AbsTol',0);
verifyLessThanOrEqual(testCase,suite.metrics.constraintConservationError,1e-10);
verifyLessThanOrEqual(testCase,suite.metrics.bodyAdditionError,1e-12);
verifyLessThanOrEqual(testCase,suite.metrics.massEnergyError,1e-12);
end

function R=localPassiveZXZ(angles)
Rz1=[cos(angles(1)) sin(angles(1)) 0; ...
    -sin(angles(1)) cos(angles(1)) 0;0 0 1];
Rx=[1 0 0;0 cos(angles(2)) sin(angles(2)); ...
    0 -sin(angles(2)) cos(angles(2))];
Rz3=[cos(angles(3)) sin(angles(3)) 0; ...
    -sin(angles(3)) cos(angles(3)) 0;0 0 1];
R=Rz3*Rx*Rz1;
end
