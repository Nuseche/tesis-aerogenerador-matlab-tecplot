function suite = run_rigid_constraint_suite(modelData,M,Ke,Tc,reduced,info,assemblyDiagnostics,cfg)
%RUN_RIGID_CONSTRAINT_SUITE Specialized acceptance checks for Action 03.
%   This suite validates only exact rigid kinematics and congruence. It does
%   not add or assess concentrated rigid-body mass, gravity, rotation or a
%   drivetrain constitutive law.

arguments
    modelData (1,1) struct
    M
    Ke
    Tc
    reduced (1,1) struct
    info (1,1) struct
    assemblyDiagnostics (1,1) struct
    cfg (1,1) struct
end

tol = localCfg(cfg,{'validation','constraintTolerance'},1e-12);
matrixTol = localCfg(cfg,{'validation','matrixSymmetry'},1e-12);
checks = repmat(localCheck("",true,0,0,"",false),0,1);

nodeIds = double(modelData.mesh.nodes.id(:));
dofMap = double(modelData.dofs.node);
ndof = max(dofMap(:));
slaves = double(info.slaveNodeIds(:));
masters = double(info.masterNodeBySlave(:));
expectedReduced = ndof-6*numel(slaves);

checks(end+1,1) = localCheck("scope.fullDofCount",size(Tc,1)==ndof, ...
    size(Tc,1),ndof,"Tc has one row per complete DOF.",true);
checks(end+1,1) = localCheck("scope.reducedDofCount",size(Tc,2)==expectedReduced, ...
    size(Tc,2),expectedReduced,"Only six DOFs per declared slave are eliminated.",true);
expectedFullRegression = localCfg(cfg,{'action03','expectedFullDofs'},ndof);
expectedReducedRegression = localCfg(cfg,{'action03','expectedReducedDofs'},expectedReduced);
checks(end+1,1) = localCheck("regression.fullDofCount",ndof==expectedFullRegression, ...
    ndof,expectedFullRegression,"Canonical inherited-mesh full DOF count.",true);
checks(end+1,1) = localCheck("regression.reducedDofCount", ...
    size(Tc,2)==expectedReducedRegression,size(Tc,2),expectedReducedRegression, ...
    "Canonical inherited-mesh reduced DOF count.",true);
checks(end+1,1) = localCheck("Tc.sparse",issparse(Tc),double(~issparse(Tc)),0, ...
    "The kinematic transformation must remain sparse.",true);
checks(end+1,1) = localCheck("Tc.rank",sprank(Tc)==size(Tc,2),sprank(Tc), ...
    size(Tc,2),"Tc must have full structural column rank.",true);

expectedSlaves = localVectorCfg(cfg,{'action03','expectedSlaveNodeIds'},[21;57;93]);
expectedMaster = localCfg(cfg,{'action03','expectedMasterNodeId'},130);
checks(end+1,1) = localCheck("topology.slaveNodes", ...
    isequal(sort(slaves),sort(expectedSlaves(:))), ...
    numel(slaves),numel(expectedSlaves),"Declared blade-root slaves.",true);
checks(end+1,1) = localCheck("topology.masterNodes", ...
    numel(masters)==numel(slaves) && all(masters==expectedMaster), ...
    nnz(masters==expectedMaster),numel(slaves), ...
    "Every blade root is tied to rotor master 130.",true);

masterRows = arrayfun(@(id)find(nodeIds==id,1),[129;130]);
masterColumns = info.fullToReduced(reshape(dofMap(masterRows,:).',[],1));
mastersIndependent = all(masterColumns>0) && numel(unique(masterColumns))==12;
checks(end+1,1) = localCheck("topology.masters129And130Independent", ...
    mastersIndependent,numel(unique(masterColumns)),12, ...
    "Nacelle and rotor masters retain twelve distinct independent DOFs.",true);

legacyType = double(modelData.mesh.elements.legacyType(:));
legacyId = double(modelData.mesh.elements.legacyId(:));
checks(end+1,1) = localCheck("topology.legacyType3Removed", ...
    nnz(legacyType==3)==0,nnz(legacyType==3),0, ...
    "No penalty connector of inherited type 3 may remain.",true);
removedExpected = localVectorCfg(cfg,{'action03','expectedRemovedLegacyIds'},(134:137).');
removedActual = double(modelData.meta.removedLegacyType3Ids(:));
checks(end+1,1) = localCheck("topology.removedLegacyIds", ...
    isequal(sort(removedActual),sort(removedExpected)),numel(removedActual), ...
    numel(removedExpected),"Removed connector IDs are traceable.",true);
preservedExpected = localVectorCfg(cfg,{'action03','expectedTransitionLegacyIds'},(125:133).');
preservedActual = sort(legacyId(legacyType==4));
checks(end+1,1) = localCheck("topology.type4TransitionHypothesis", ...
    isequal(preservedActual,sort(preservedExpected)),numel(preservedActual), ...
    numel(preservedExpected), ...
    "Type-4 members are retained as an explicit flexible-transition hypothesis.",true);

checks = [checks; localMatrixChecks(M,"full.M",matrixTol); ...
    localMatrixChecks(Ke,"full.Ke",matrixTol); ...
    localMatrixChecks(reduced.M,"reduced.M",matrixTol); ...
    localMatrixChecks(reduced.Ke,"reduced.Ke",matrixTol)]; %#ok<AGROW>
checks = [checks; validation.check_rigid_constraints( ...
    Tc,modelData,modelData.rigidBodies,cfg)]; %#ok<AGROW>

[massError,stiffnessError] = localCongruenceErrors(Tc,M,Ke,reduced);
checks(end+1,1) = localCheck("congruence.massEnergy",massError<=tol, ...
    massError,tol,"Maximum deterministic quadratic-form mass error.",true);
checks(end+1,1) = localCheck("congruence.stiffnessEnergy",stiffnessError<=tol, ...
    stiffnessError,tol,"Maximum deterministic quadratic-form stiffness error.",true);

z = localProbe(size(Tc,2),7);
f = localProbe(size(Tc,1),11);
fullWork = (Tc*z).'*f;
reducedWork = z.'*(Tc.'*f);
workError = localRelative(fullWork,reducedWork);
checks(end+1,1) = localCheck("congruence.virtualWork",workError<=tol, ...
    workError,tol,"Full and reduced external virtual work must agree.",true);
recoverError = norm(reduced.recover(z)-Tc*z,inf)/max(norm(Tc*z,inf),1);
checks(end+1,1) = localCheck("mapping.recover",recoverError<=tol, ...
    recoverError,tol,"The recovery operator implements q=Tc*qReduced.",true);
loadError = norm(reduced.reduceLoad(f)-Tc.'*f,inf)/max(norm(Tc.'*f,inf),1);
checks(end+1,1) = localCheck("mapping.reduceLoad",loadError<=tol, ...
    loadError,tol,"The load operator implements fReduced=Tc'*fFull.",true);

expectedFree = localCfg(cfg,{'action03','expectedFreeDofs'},size(Tc,2)-numel(reduced.fixed));
checks(end+1,1) = localCheck("boundary.fixedBaseFreeDofs", ...
    numel(reduced.free)==expectedFree,numel(reduced.free),expectedFree, ...
    "The canonical fixed base removes exactly six independent DOFs.",true);
connected = full(sum(spones(reduced.M)+spones(reduced.Ke),2))>0;
checks(end+1,1) = localCheck("reduced.noDisconnectedRows",all(connected), ...
    nnz(~connected),0,"Every reduced coordinate participates in M or Ke.",true);
checks(end+1,1) = localCheck("assembly.noUnexpectedDisconnectedFullDofs", ...
    isempty(assemblyDiagnostics.unexpectedDisconnectedDofs), ...
    numel(assemblyDiagnostics.unexpectedDisconnectedDofs),0, ...
    "Only explicitly expected detached master rows are permitted before Tc.",true);

constraintMap = localConstraintMap(modelData,slaves,masters);
transitionMassKg = localTransitionMass(modelData);
summaryTable = table( ...
    ["full_dofs";"reduced_dofs";"fixed_base_free_dofs";"Tc_rank"; ...
     "Tc_nonzeros";"slave_nodes";"transition_mass_kg"; ...
     "mass_congruence_error";"stiffness_congruence_error";"virtual_work_error"], ...
    [string(size(Tc,1));string(size(Tc,2));string(numel(reduced.free)); ...
     string(sprank(Tc));string(nnz(Tc));string(numel(slaves)); ...
     string(sprintf('%.12g',transitionMassKg)); ...
     string(sprintf('%.12g',massError)); ...
     string(sprintf('%.12g',stiffnessError)); ...
     string(sprintf('%.12g',workError))], ...
    VariableNames={'metric','value'});

suite = struct();
suite.schemaVersion = "1.0.0";
suite.scope = "exact_rigid_constraints_without_concentrated_body_masses";
suite.checks = checks;
suite.checkTable = struct2table(checks);
suite.constraintMap = constraintMap;
suite.summaryTable = summaryTable;
suite.constraintInfo = info;
suite.transitionHypothesis = struct( ...
    'legacyIds',preservedActual,'distributedMassKg',transitionMassKg, ...
    'status',"retained provisionally; physical calibration pending");
suite.metrics = struct('massCongruenceError',massError, ...
    'stiffnessCongruenceError',stiffnessError, ...
    'virtualWorkError',workError,'kinematicTolerance',tol);
suite.passed = all([checks.pass] | ~[checks.critical]);
suite.criticalFailures = checks(~[checks.pass] & [checks.critical]);

failOnCritical = logical(localCfg(cfg,{'validation','failOnCritical'},1));
if failOnCritical && ~suite.passed
    names = strjoin(string({suite.criticalFailures.name}),', ');
    error('validation:run_rigid_constraint_suite:CriticalFailure', ...
        'Action 03 critical checks failed: %s',names);
end
end

function checks = localMatrixChecks(A,label,tol)
checks = repmat(localCheck("",true,0,0,"",false),0,1);
checks(end+1,1) = localCheck(label+".sparse",issparse(A),double(~issparse(A)),0, ...
    "Matrix must remain sparse.",true);
finite = all(isfinite(nonzeros(A)));
checks(end+1,1) = localCheck(label+".finite",finite,double(~finite),0, ...
    "Every stored coefficient must be finite.",true);
errorValue = norm(A-A.','fro')/max(norm(A,'fro'),eps);
checks(end+1,1) = localCheck(label+".symmetry",errorValue<=tol,errorValue,tol, ...
    "Relative Frobenius symmetry residual.",true);
end

function [massError,stiffnessError] = localCongruenceErrors(Tc,M,Ke,reduced)
massError = 0;
stiffnessError = 0;
for seed = 1:4
    z = localProbe(size(Tc,2),seed);
    q = Tc*z;
    massError = max(massError,localRelative(z.'*reduced.M*z,q.'*M*q));
    stiffnessError = max(stiffnessError, ...
        localRelative(z.'*reduced.Ke*z,q.'*Ke*q));
end
end

function value = localRelative(a,b)
value = abs(a-b)/max([abs(a),abs(b),1]);
end

function vector = localProbe(n,seed)
index = (1:n).';
vector = sin((seed+1)*index/17)+cos((seed+3)*index/29)+index/(n+1);
end

function map = localConstraintMap(modelData,slaves,masters)
ids = double(modelData.mesh.nodes.id(:));
xyz = double(modelData.mesh.nodes.xyz);
count = numel(slaves);
dx = zeros(count,1); dy = dx; dz = dx;
for index = 1:count
    slaveRow = find(ids==slaves(index),1);
    masterRow = find(ids==masters(index),1);
    offset = xyz(slaveRow,:)-xyz(masterRow,:);
    dx(index)=offset(1); dy(index)=offset(2); dz(index)=offset(3);
end
slaveNode = slaves;
masterNode = masters;
map = table(masterNode,slaveNode,dx,dy,dz);
end

function massKg = localTransitionMass(modelData)
elements = modelData.mesh.elements;
mask = double(elements.legacyType(:))==4;
ids = double(modelData.mesh.nodes.id(:));
[~,rowI] = ismember(double(elements.nodeI(mask)),ids);
[~,rowJ] = ismember(double(elements.nodeJ(mask)),ids);
lengths = vecnorm(modelData.mesh.nodes.xyz(rowJ,:)-modelData.mesh.nodes.xyz(rowI,:),2,2);
sectionIds = double(elements.section(mask));
massPerLength = reshape([modelData.sections(sectionIds).m],[],1);
massKg = sum(lengths.*massPerLength);
end

function check = localCheck(name,pass,value,tolerance,message,critical)
check = struct('name',string(name),'pass',logical(pass),'value',value, ...
    'tolerance',tolerance,'message',string(message),'critical',logical(critical));
end

function value = localCfg(cfg,path,fallback)
value = fallback; cursor = cfg;
for index = 1:numel(path)
    if ~isstruct(cursor) || ~isfield(cursor,path{index}), return; end
    cursor = cursor.(path{index});
end
if isnumeric(cursor) && isscalar(cursor) && isfinite(cursor)
    value = double(cursor);
end
end

function value = localVectorCfg(cfg,path,fallback)
value = fallback; cursor = cfg;
for index = 1:numel(path)
    if ~isstruct(cursor) || ~isfield(cursor,path{index}), return; end
    cursor = cursor.(path{index});
end
if isnumeric(cursor) && isvector(cursor) && all(isfinite(cursor))
    value = double(cursor(:));
end
end
