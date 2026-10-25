function tests = test_action03_constraints
tests = functiontests(localfunctions);
end

function testEmptyConstraintListProducesIdentity(testCase)
modelData = localModel();
modelData = rmfield(modelData,'rigidBodies');
[Tc,info] = rigid.rigid_constraint_matrix(modelData,struct(),struct());
verifyEqual(testCase,Tc,speye(18));
verifyEmpty(testCase,info.slaveNodeIds);
verifyEqual(testCase,info.reducedToFull,(1:18).');
end

function testReorderedNoncontiguousNodeIds(testCase)
modelData = localModel();
bodies.constraints = struct('masterNode',10,'slaveNodes',500);
[Tc,~] = rigid.rigid_constraint_matrix(modelData,bodies,struct());
cfg.validation.constraintTolerance = 1e-12;
checks = validation.check_rigid_constraints(Tc,modelData,bodies,cfg);
verifyTrue(testCase,all([checks.pass]));
verifyLessThanOrEqual(testCase,checks(end).value,1e-12);
end

function testSixPureMasterMotionsAndMixedMotion(testCase)
modelData = localModel();
bodies.constraints = struct('masterNode',10,'slaveNodes',500);
[Tc,info] = rigid.rigid_constraint_matrix(modelData,bodies,struct());
ids = modelData.mesh.nodes.id;
masterRow = find(ids==10,1); slaveRow = find(ids==500,1);
masterDofs = modelData.dofs.node(masterRow,:);
slaveDofs = modelData.dofs.node(slaveRow,:);
r = (modelData.mesh.nodes.xyz(slaveRow,:)- ...
    modelData.mesh.nodes.xyz(masterRow,:)).';
S = [0 -r(3) r(2);r(3) 0 -r(1);-r(2) r(1) 0];
B = [eye(3) -S;zeros(3) eye(3)];
motions = [eye(6),[1;2;3;.1;-.2;.3]];
for column = 1:size(motions,2)
    qReduced = zeros(size(Tc,2),1);
    qReduced(info.fullToReduced(masterDofs)) = motions(:,column);
    qFull = Tc*qReduced;
    verifyEqual(testCase,qFull(slaveDofs),B*motions(:,column),'AbsTol',2e-15);
end
end

function testInvalidConstraintDefinitionsAreRejected(testCase)
modelData = localModel();
bodies.constraints = struct('masterNode',10,'slaveNodes',10);
verifyError(testCase,@()rigid.rigid_constraint_matrix(modelData,bodies,struct()), ...
    'rigid:rigid_constraint_matrix:SelfConstraint');

bodies.constraints = [struct('masterNode',10,'slaveNodes',500), ...
    struct('masterNode',77,'slaveNodes',500)];
verifyError(testCase,@()rigid.rigid_constraint_matrix(modelData,bodies,struct()), ...
    'rigid:rigid_constraint_matrix:DuplicateSlave');

bodies.constraints = [struct('masterNode',10,'slaveNodes',500), ...
    struct('masterNode',77,'slaveNodes',10)];
verifyError(testCase,@()rigid.rigid_constraint_matrix(modelData,bodies,struct()), ...
    'rigid:rigid_constraint_matrix:ConstraintChain');

bodies.constraints = struct('masterNode',10.5,'slaveNodes',500);
verifyError(testCase,@()rigid.rigid_constraint_matrix(modelData,bodies,struct()), ...
    'rigid:rigid_constraint_matrix:InvalidNodeId');

bodies.constraints = struct('masterNode',10,'slaveNodes',999);
verifyError(testCase,@()rigid.rigid_constraint_matrix(modelData,bodies,struct()), ...
    'rigid:rigid_constraint_matrix:UnknownNode');
end

function testNacelleRotorDirectTieIsRejected(testCase)
modelData = localDriveModel();
bodies.constraints = struct('masterNode',130,'slaveNodes',129);
verifyError(testCase,@()rigid.rigid_constraint_matrix(modelData,bodies,struct()), ...
    'rigid:rigid_constraint_matrix:DriveTrainMustRemainFlexible');
end

function testCoupledSpcOnSlaveIsRejectedExplicitly(testCase)
modelData = localModel();
bodies.constraints = struct('masterNode',10,'slaveNodes',500);
[Tc,~] = rigid.rigid_constraint_matrix(modelData,bodies,struct());
slaveRow = find(modelData.mesh.nodes.id==500,1);
modelData.dofs.fixed = modelData.dofs.node(slaveRow,1);
verifyError(testCase,@()rigid.reduce_system( ...
    Tc,speye(18),speye(18),modelData,struct()), ...
    'rigid:reduce_system:DependentSPCNotSupported');
end

function testCanonicalAction03Suite(testCase)
projectRoot = fileparts(fileparts(mfilename('fullpath')));
cfg = io.load_configuration(fullfile(projectRoot,'cases', ...
    'config_action03_rigid_constraints.m'));
data = io.load_model_data(cfg);
modelData = model.build_model(data,cfg);
[M,Ke,~,diagnostics] = assembly.assemble_structural_matrices(modelData,cfg);
[Tc,info] = rigid.rigid_constraint_matrix(modelData,modelData.rigidBodies,cfg);
reduced = rigid.reduce_system(Tc,M,Ke,modelData,cfg);
suite = validation.run_rigid_constraint_suite( ...
    modelData,M,Ke,Tc,reduced,info,diagnostics,cfg);
verifyTrue(testCase,suite.passed);
verifyTrue(testCase,all([suite.checks.pass]));
verifyEqual(testCase,size(Tc),[828 810]);
verifyEqual(testCase,numel(reduced.free),804);
verifyEqual(testCase,sprank(Tc),810);
verifyLessThanOrEqual(testCase,suite.metrics.massCongruenceError,1e-12);
verifyLessThanOrEqual(testCase,suite.metrics.stiffnessCongruenceError,1e-12);
verifyLessThanOrEqual(testCase,suite.metrics.virtualWorkError,1e-12);
end

function modelData = localModel()
ids = [500;10;77];
xyz = [0 2 0;0 0 0;1 0 0];
modelData.mesh.nodes = struct('id',ids,'xyz',xyz);
modelData.mesh.elements = struct('nodeI',[],'nodeJ',[]);
modelData.dofs.node = reshape(1:18,6,3).';
modelData.dofs.number = 18;
modelData.dofs.fixed = zeros(0,1);
modelData.rigidBodies = struct();
end

function modelData = localDriveModel()
modelData = localModel();
modelData.mesh.nodes.id = [129;130;21];
end
