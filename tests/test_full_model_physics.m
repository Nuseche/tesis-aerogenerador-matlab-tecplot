function tests = test_full_model_physics
tests = functiontests(localfunctions);
end

function testFullModelHasExactlySixFreeRigidModes(testCase)
cfg = io.load_configuration(struct('base',struct('type',"free"), ...
    'drivetrain',struct('stiffness',[1e9 1e9 1e9 1e10 1e10 1e10])));
data = io.load_model_data(cfg);
windTurbine = model.build_model(data,cfg);
[M,K] = assembly.assemble_structural_matrices(windTurbine,cfg);
M = rigid.add_body_masses(M,windTurbine,windTurbine.rigidBodies);
Tc = rigid.rigid_constraint_matrix(windTurbine,windTurbine.rigidBodies,cfg);
reduced = rigid.reduce_system(Tc,M,K,windTurbine,cfg);

previous = warning('query','MATLAB:eigs:IllConditionedA');
warning('off','MATLAB:eigs:IllConditionedA');
restore = onCleanup(@() warning(previous.state,previous.identifier)); %#ok<NASGU>
lambda = eigs(reduced.K,reduced.M,12,'smallestabs');
verifyEqual(testCase,nnz(abs(lambda)<1e-4),6);
verifyGreaterThan(testCase,min(real(lambda(abs(lambda)>=1e-4))),1);

probe = sin((1:size(Tc,2)).'/17);
verifyEqual(testCase,probe.'*reduced.M*probe, ...
    (Tc*probe).'*M*(Tc*probe),'RelTol',5e-13);
constraintChecks = validation.check_rigid_constraints( ...
    Tc,windTurbine,windTurbine.rigidBodies,cfg);
verifyTrue(testCase,all([constraintChecks.pass]));
end
