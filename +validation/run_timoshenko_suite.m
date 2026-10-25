function results = run_timoshenko_suite( ...
    modelData, M, Ke, elementCache, diagnostics, cfg)
%RUN_TIMOSHENKO_SUITE Action-02 Timoshenko analytical and subsystem suite.
%   This suite deliberately reassembles isolated tower/blade chains. A
%   principal submatrix of the connected turbine would retain artificial
%   stiffness from elements lying outside the selected subsystem.

if nargin < 6 || isempty(cfg)
    cfg = struct();
end
tolerances = validationTolerances(cfg);
numberSubsystemModes = max(2,round(localCfg( ...
    cfg,{'action02','numberSubsystemModes'},6)));
checks = emptyChecks();

checks(end+1,1) = makeCheck("global.M.sparse", issparse(M), ...
    double(~issparse(M)), 0, "Global mass must remain sparse.", true); %#ok<AGROW>
checks(end+1,1) = makeCheck("global.Ke.sparse", issparse(Ke), ...
    double(~issparse(Ke)), 0, "Global elastic stiffness must remain sparse.", true); %#ok<AGROW>
massSymmetry = relativeSymmetry(M);
stiffnessSymmetry = relativeSymmetry(Ke);
checks(end+1,1) = makeCheck("global.M.symmetry", ...
    massSymmetry <= tolerances.matrixSymmetry, massSymmetry, ...
    tolerances.matrixSymmetry, "Relative Frobenius symmetry residual.", true); %#ok<AGROW>
checks(end+1,1) = makeCheck("global.Ke.symmetry", ...
    stiffnessSymmetry <= tolerances.matrixSymmetry, stiffnessSymmetry, ...
    tolerances.matrixSymmetry, "Relative Frobenius symmetry residual.", true); %#ok<AGROW>
checks(end+1,1) = makeCheck("global.matrices.finite", ...
    all(isfinite(nonzeros(M))) && all(isfinite(nonzeros(Ke))), ...
    double(~(all(isfinite(nonzeros(M))) && all(isfinite(nonzeros(Ke))))), ...
    0, "All assembled entries must be finite.", true); %#ok<AGROW>

mesh = modelData.mesh;
towerRows = string(mesh.elements.type(:)) == "tower";
towerRoot = chooseTowerRoot(modelData,towerRows);
tower = validation.extract_beam_subsystem( ...
    modelData,towerRows,towerRoot,"isolated_tower");
[towerM,towerK,towerCache,towerDiagnostics] = ...
    validation.assemble_beam_subsystem(tower,cfg);
towerModes = validation.solve_fixed_root_modes( ...
    towerM,towerK,tower.rootDofs,numberSubsystemModes);
[checks,towerMass] = addSubsystemChecks(checks,tower,towerM,towerK, ...
    towerModes,towerDiagnostics,tolerances);

blade = [];
bladeM = cell(3,1);
bladeK = cell(3,1);
bladeCache = cell(3,1);
bladeDiagnostics = cell(3,1);
bladeModes = cell(3,1);
bladeMass = zeros(3,1);
for bladeNumber = 1:3
    selector = double(mesh.elements.blade(:)) == bladeNumber;
    root = chooseBladeRoot(modelData,selector,bladeNumber);
    extractedBlade = validation.extract_beam_subsystem( ...
        modelData,selector,root,"isolated_blade_"+bladeNumber);
    if bladeNumber == 1
        blade = repmat(extractedBlade,3,1);
    end
    blade(bladeNumber) = extractedBlade;
    [bladeM{bladeNumber},bladeK{bladeNumber},bladeCache{bladeNumber}, ...
        bladeDiagnostics{bladeNumber}] = validation.assemble_beam_subsystem( ...
        blade(bladeNumber),cfg);
    bladeModes{bladeNumber} = validation.solve_fixed_root_modes( ...
        bladeM{bladeNumber},bladeK{bladeNumber}, ...
        blade(bladeNumber).rootDofs,numberSubsystemModes);
    [checks,bladeMass(bladeNumber)] = addSubsystemChecks( ...
        checks,blade(bladeNumber),bladeM{bladeNumber},bladeK{bladeNumber}, ...
        bladeModes{bladeNumber},bladeDiagnostics{bladeNumber},tolerances);
end

[axisSemanticError,axisOrthogonalityError] = bladeAxisSemanticErrors(blade);
checks(end+1,1) = makeCheck("blade.frames.auxiliaryDefinesE3", ...
    axisSemanticError <= tolerances.rotationOrthogonality, ...
    axisSemanticError,tolerances.rotationOrthogonality, ...
    "The auxiliary point must define local e3; e2=e3 cross e1.",true); %#ok<AGROW>
checks(end+1,1) = makeCheck("blade.frames.orthogonality", ...
    axisOrthogonalityError <= tolerances.rotationOrthogonality, ...
    axisOrthogonalityError,tolerances.rotationOrthogonality, ...
    "Maximum local-frame orthogonality/determinant error.",true); %#ok<AGROW>

[synthetic120,syntheticChecks] = exactRotation120Benchmark( ...
    blade(1),bladeM{1},bladeK{1},bladeModes{1},modelData,cfg,tolerances);
checks = [checks(:);syntheticChecks(:)]; %#ok<AGROW>
[bladeEquivalence,equivalenceSummary,equivalenceChecks] = ...
    inheritedBladeEquivalence(blade,bladeModes,modelData,tolerances);
checks = [checks(:);equivalenceChecks(:)]; %#ok<AGROW>

[analytical,analyticalChecks] = analyticalBenchmarks(cfg,tolerances);
checks = [checks(:);analyticalChecks(:)]; %#ok<AGROW>
[meshConvergence,convergenceChecks] = meshConvergenceBenchmark(cfg,tolerances);
checks = [checks(:);convergenceChecks(:)]; %#ok<AGROW>

modalTable = subsystemModalTable(towerModes,bladeModes);
bladeFrequenciesHz = zeros(numberSubsystemModes,3);
for bladeNumber = 1:3
    bladeFrequenciesHz(:,bladeNumber) = ...
        bladeModes{bladeNumber}.frequencyHz(1:numberSubsystemModes);
end
elementDiagnostics = elementDiagnosticsTable(elementCache);
componentSummary = componentSummaryTable(modelData);
checks(end+1,1) = makeCheck("elements.diagnostics.finite", ...
    all(elementDiagnostics.finite),nnz(~elementDiagnostics.finite),0, ...
    "Every assembled element must expose finite scalar diagnostics.",true);
checks(end+1,1) = makeCheck("elements.rigidModeCount", ...
    all(elementDiagnostics.rigidModeCount == 6), ...
    max(abs(elementDiagnostics.rigidModeCount-6)),0, ...
    "Every free two-node beam must retain exactly six rigid modes.",true);
checkTable = struct2table(checks);
passed = all([checks.pass] | ~[checks.critical]);

results = struct();
results.schemaVersion = "1.0.0";
results.action = "02_timoshenko_3d";
results.timestamp = datetime('now','TimeZone','UTC');
results.passed = passed;
results.tolerances = tolerances;
results.checks = checks;
results.checkTable = checkTable;
results.criticalFailures = checks(~[checks.pass] & [checks.critical]);
results.global = struct('massSymmetryError',massSymmetry, ...
    'stiffnessSymmetryError',stiffnessSymmetry,'massNonzeros',nnz(M), ...
    'stiffnessNonzeros',nnz(Ke),'elementCacheCount',numel(elementCache), ...
    'assemblyDiagnosticsProvided',~isempty(diagnostics));
results.tower = subsystemResult(tower,towerModes,towerMass,towerDiagnostics);
firstBladeResult = subsystemResult(blade(1),bladeModes{1}, ...
    bladeMass(1),bladeDiagnostics{1});
results.blades = repmat(firstBladeResult,3,1);
for bladeNumber = 1:3
    results.blades(bladeNumber) = subsystemResult( ...
        blade(bladeNumber),bladeModes{bladeNumber}, ...
        bladeMass(bladeNumber),bladeDiagnostics{bladeNumber});
end
results.modalTable = modalTable;
results.subsystemFrequencies = modalTable(:,{'subsystem','mode','frequencyHz'});
results.bladeFrequenciesHz = bladeFrequenciesHz;
results.elementDiagnostics = elementDiagnostics;
results.componentSummary = componentSummary;
results.synthetic120 = synthetic120;
results.bladeEquivalence = bladeEquivalence;
results.bladeEquivalenceSummary = equivalenceSummary;
results.analytical = analytical;
results.meshConvergence = meshConvergence;
results.cacheSummary = struct('towerElementCount',numel(towerCache), ...
    'bladeElementCounts',cellfun(@numel,bladeCache));

failOnCritical = localCfg(cfg,{'validation','failOnCritical'},true);
if failOnCritical && ~passed
    names = strjoin(string({results.criticalFailures.name}),', ');
    error('validation:run_timoshenko_suite:CriticalFailure', ...
        'Action-02 critical checks failed: %s',names);
end
end

function tolerance = validationTolerances(cfg)
tolerance = struct();
tolerance.rotationOrthogonality = localCfg(cfg, ...
    {'validation','rotationOrthogonality'},1e-12);
tolerance.matrixSymmetry = localCfg(cfg, ...
    {'validation','matrixSymmetry'}, ...
    localCfg(cfg,{'validation','symmetryTolerance'},1e-12));
tolerance.rigidEnergyRelative = localCfg(cfg, ...
    {'validation','rigidEnergyRelative'},1e-10);
tolerance.massConservation = localCfg(cfg, ...
    {'validation','massConservation'}, ...
    localCfg(cfg,{'validation','massConservationTolerance'},1e-10));
tolerance.coordinateInvariance = min(1e-9,localCfg(cfg, ...
    {'validation','coordinateInvariance'},1e-9));
tolerance.analyticalStaticRelative = localCfg(cfg, ...
    {'validation','analyticalStaticRelative'},1e-6);
tolerance.modalBenchmarkRelative = localCfg(cfg, ...
    {'validation','modalBenchmarkRelative'},1e-3);
tolerance.meshConvergenceRelative = localCfg(cfg, ...
    {'validation','meshConvergenceRelative'},1e-3);
tolerance.inheritedBladeEquivalence = 1e-3;
tolerance.modalResidual = min(1e-8,tolerance.modalBenchmarkRelative);
end

function root = chooseTowerRoot(modelData,selector)
nodes = unique([modelData.mesh.elements.nodeI(selector); ...
    modelData.mesh.elements.nodeJ(selector)]);
root = [];
if isfield(modelData,'boundaryConditions') && ...
        isfield(modelData.boundaryConditions,'fixedNodeIds')
    candidates = intersect(nodes,modelData.boundaryConditions.fixedNodeIds(:),'stable');
    if numel(candidates) == 1
        root = candidates;
    end
end
if isempty(root)
    [~,rows] = ismember(nodes,modelData.mesh.nodes.id);
    [~,index] = min(modelData.mesh.nodes.xyz(rows,3));
    root = nodes(index);
end
end

function root = chooseBladeRoot(modelData,selector,bladeNumber)
if isfield(modelData,'bladeDofMap') && ...
        isfield(modelData.bladeDofMap,'rootNodeIds') && ...
        numel(modelData.bladeDofMap.rootNodeIds) >= bladeNumber
    root = modelData.bladeDofMap.rootNodeIds(bladeNumber);
    return
end
nodes = unique([modelData.mesh.elements.nodeI(selector); ...
    modelData.mesh.elements.nodeJ(selector)]);
[~,rows] = ismember(nodes,modelData.mesh.nodes.id);
xyz = modelData.mesh.nodes.xyz(rows,:);
if isfield(modelData,'rotorAxis') && isfield(modelData.rotorAxis,'point')
    point = reshape(modelData.rotorAxis.point,1,3);
    [~,index] = min(vecnorm(xyz-point,2,2));
else
    index = 1;
end
root = nodes(index);
end

function [checks,totalMass] = addSubsystemChecks( ...
    checks,subsystem,M,K,modes,diagnostics,tolerances)
name = subsystem.name;
expectedMass = sum(reshape([subsystem.sections.m],[],1).*subsystem.lengths);
translationMass = zeros(3,1);
for direction = 1:3
    q = zeros(size(M,1),1);
    q(subsystem.dofs(:,direction)) = 1;
    translationMass(direction) = q.'*M*q;
end
massError = max(abs(translationMass-expectedMass))/max(expectedMass,eps);
checks(end+1,1) = makeCheck(name+".massConservation", ...
    massError <= tolerances.massConservation,massError, ...
    tolerances.massConservation, ...
    "Uniform acceleration recovers sum(m_e L_e) in x, y and z.",true); %#ok<AGROW>
checks(end+1,1) = makeCheck(name+".modalResidual", ...
    max(modes.residual) <= tolerances.modalResidual,max(modes.residual), ...
    tolerances.modalResidual,"Maximum generalized eigenpair residual.",true); %#ok<AGROW>
checks(end+1,1) = makeCheck(name+".positiveFrequencies", ...
    all(isfinite(modes.frequencyHz) & modes.frequencyHz > 0), ...
    min(modes.frequencyHz),0,"All requested clamped frequencies are positive.",true); %#ok<AGROW>
checks(end+1,1) = makeCheck(name+".preSymmetry", ...
    max(diagnostics.stiffnessSymmetryErrorBeforeCorrection, ...
    diagnostics.massSymmetryErrorBeforeCorrection) <= tolerances.matrixSymmetry, ...
    max(diagnostics.stiffnessSymmetryErrorBeforeCorrection, ...
    diagnostics.massSymmetryErrorBeforeCorrection),tolerances.matrixSymmetry, ...
    "Symmetry is checked before roundoff correction.",true); %#ok<AGROW>
totalMass = expectedMass;
end

function [semanticError,orthogonalityError] = bladeAxisSemanticErrors(blades)
semanticError = 0;
orthogonalityError = 0;
for bladeNumber = 1:numel(blades)
    subsystem = blades(bladeNumber);
    for element = 1:subsystem.numberOfElements
        ni = subsystem.connectivity(element,1);
        nj = subsystem.connectivity(element,2);
        xI = subsystem.xyz(ni,:);
        xJ = subsystem.xyz(nj,:);
        auxiliary = subsystem.auxiliaryPoints(element,:);
        e1 = (xJ-xI).';
        e1 = e1/norm(e1);
        e3 = auxiliary.'-xI.';
        e3 = e3-e1*(e1.'*e3);
        e3 = e3/norm(e3);
        e2 = cross(e3,e1);
        expected = [e1.';e2.';e3.'];
        R = elements.element_rotation_matrix(xI,xJ,auxiliary);
        semanticError = max(semanticError,norm(R-expected,'fro'));
        orthogonalityError = max(orthogonalityError,max( ...
            norm(R*R.'-eye(3),'fro'),abs(det(R)-1)));
    end
end
end

function [tableValue,checks] = exactRotation120Benchmark( ...
    base,Mbase,Kbase,baseModes,modelData,cfg,tolerances)
axis = reshape(modelData.rotorAxis.direction,3,1);
axis = axis/norm(axis);
origin = reshape(modelData.rotorAxis.point,3,1);
angles = [120;-120];
stiffnessError = zeros(2,1);
massError = zeros(2,1);
energyError = zeros(2,1);
frequencyError = zeros(2,1);
passed = false(2,1);
for index = 1:2
    Q = axisRotation(axis,deg2rad(angles(index)));
    rotated = rotateSubsystem(base,Q,origin);
    [Mr,Kr] = validation.assemble_beam_subsystem(rotated,cfg);
    P = kron(speye(2*base.numberOfNodes),Q);
    stiffnessError(index) = norm(Kr-P*Kbase*P.','fro')/max(norm(Kbase,'fro'),eps);
    massError(index) = norm(Mr-P*Mbase*P.','fro')/max(norm(Mbase,'fro'),eps);
    q = sin((1:size(Kbase,1)).'*sqrt(2));
    qr = P*q;
    energy0 = q.'*Kbase*q;
    energy1 = qr.'*Kr*qr;
    energyError(index) = abs(energy1-energy0)/max(abs(energy0),eps);
    modes = validation.solve_fixed_root_modes(Mr,Kr,rotated.rootDofs, ...
        numel(baseModes.frequencyHz));
    frequencyError(index) = max(abs(modes.frequencyHz-baseModes.frequencyHz)./ ...
        max(baseModes.frequencyHz,eps));
    passed(index) = max([stiffnessError(index),massError(index), ...
        energyError(index),frequencyError(index)]) <= tolerances.coordinateInvariance;
end
tableValue = table(angles,stiffnessError,massError,energyError,frequencyError, ...
    repmat(tolerances.coordinateInvariance,2,1),passed, ...
    'VariableNames',{'angleDeg','stiffnessCongruenceError', ...
    'massCongruenceError','strainEnergyError','maximumFrequencyError', ...
    'tolerance','passed'});
value = max([stiffnessError;massError;energyError;frequencyError]);
checks = makeCheck("blade.synthetic120.exactRotation",all(passed),value, ...
    tolerances.coordinateInvariance, ...
    "Exact +/-120 degree clones must preserve matrices, energy and frequencies.",true);
end

function [tableValue,summary,checks] = inheritedBladeEquivalence( ...
    blades,modes,modelData,tolerances)
numberOfModes = min(cellfun(@(x) numel(x.frequencyHz),modes));
frequencies = zeros(numberOfModes,3);
for bladeNumber = 1:3
    frequencies(:,bladeNumber) = modes{bladeNumber}.frequencyHz(1:numberOfModes);
end
relativeSpread = (max(frequencies,[],2)-min(frequencies,[],2))./ ...
    max(mean(frequencies,2),eps);
passed = relativeSpread <= tolerances.inheritedBladeEquivalence;
mode = (1:numberOfModes).';
tableValue = table(mode,frequencies(:,1),frequencies(:,2),frequencies(:,3), ...
    relativeSpread,repmat(tolerances.inheritedBladeEquivalence,numberOfModes,1), ...
    passed,'VariableNames',{'mode','blade1Hz','blade2Hz','blade3Hz', ...
    'relativeSpread','tolerance','passed'});

axis = reshape(modelData.rotorAxis.direction,3,1);
axis = axis/norm(axis);
origin = reshape(modelData.rotorAxis.point,3,1);
geometryMaximumError = zeros(2,1);
geometryRmsError = zeros(2,1);
auxiliaryMaximumError = zeros(2,1);
angles = [120;-120];
for index = 1:2
    Q = axisRotation(axis,deg2rad(angles(index)));
    rotated = rotateSubsystem(blades(1),Q,origin);
    target = blades(index+1);
    geometryErrors = vecnorm(rotated.xyz-target.xyz,2,2);
    auxiliaryErrors = vecnorm( ...
        rotated.auxiliaryPoints-target.auxiliaryPoints,2,2);
    geometryMaximumError(index) = max(geometryErrors);
    geometryRmsError(index) = sqrt(mean(geometryErrors.^2));
    auxiliaryMaximumError(index) = max(auxiliaryErrors);
end
sameSections = isequal(string(blades(1).sectionIds),string(blades(2).sectionIds)) && ...
    isequal(string(blades(1).sectionIds),string(blades(3).sectionIds));
summary = struct('maximumFrequencySpread',max(relativeSpread), ...
    'geometryAngleDeg',angles,'geometryMaximumErrorM',geometryMaximumError, ...
    'geometryRmsErrorM',geometryRmsError, ...
    'auxiliaryMaximumErrorM',auxiliaryMaximumError, ...
    'sectionSequencesIdentical',sameSections, ...
    'interpretation',["The inherited meshes are only approximately 120-degree rotations; " + ...
    "the 1e-3 test is an engineering-equivalence check, not exact coordinate invariance."]);
checks = [makeCheck("blade.inherited.frequencyEquivalence",all(passed), ...
    max(relativeSpread),tolerances.inheritedBladeEquivalence, ...
    "Sorted isolated frequencies of the three inherited blades.",true), ...
    makeCheck("blade.inherited.sectionSequence",sameSections,double(~sameSections),0, ...
    "Homologous blade stations must use identical section sequences.",true)];
end

function [tableValue,checks] = analyticalBenchmarks(cfg,tolerances)
cfgClosed = closedExactConfiguration(cfg);
section = benchmarkSection();
L = 1;
xI = [0 0 0];
xJ = [L 0 0];
auxiliary = [0 0 1]; % By contract this is +e3, hence +e2 is global +Y.
[K,~,~] = elements.timoshenko3d_matrices( ...
    xI,xJ,auxiliary,section,cfgClosed);
Ktip = K(7:12,7:12);

names = strings(0,1);
observed = zeros(0,1);
expected = zeros(0,1);
caseTolerance = zeros(0,1);

P = 3500;
q = Ktip\[P;0;0;0;0;0];
[names,observed,expected,caseTolerance] = appendAnalytic( ...
    names,observed,expected,caseTolerance,"axial_extension",q(1), ...
    P*L/section.EA,tolerances.analyticalStaticRelative);

T = 800;
q = Ktip\[0;0;0;T;0;0];
[names,observed,expected,caseTolerance] = appendAnalytic( ...
    names,observed,expected,caseTolerance,"saint_venant_torsion",q(4), ...
    T*L/section.GJ,tolerances.analyticalStaticRelative);

Py = 1000;
q = Ktip\[0;Py;0;0;0;0];
expectedY = Py*L^3/(3*section.EIz)+Py*L/section.GAy;
[names,observed,expected,caseTolerance] = appendAnalytic( ...
    names,observed,expected,caseTolerance,"cantilever_local_e2",q(2), ...
    expectedY,tolerances.analyticalStaticRelative);

Pz = 700;
q = Ktip\[0;0;Pz;0;0;0];
expectedZ = Pz*L^3/(3*section.EIy)+Pz*L/section.GAz;
[names,observed,expected,caseTolerance] = appendAnalytic( ...
    names,observed,expected,caseTolerance,"cantilever_local_e3",q(3), ...
    expectedZ,tolerances.analyticalStaticRelative);

short = section;
shortLength = 0.5;
short.EIz = 2e6;
short.GAy = short.EIz/shortLength^2; % delta_shear/delta_bending = 3.
[Kshort,~,~] = elements.timoshenko3d_matrices( ...
    [0 0 0],[shortLength 0 0],[0 0 1],short,cfgClosed);
unitLoad = 1000;
qTotal = Kshort(7:12,7:12)\[0;unitLoad;0;0;0;0];
deltaBending = unitLoad*shortLength^3/(3*short.EIz);
deltaShear = unitLoad*shortLength/short.GAy;
[names,observed,expected,caseTolerance] = appendAnalytic( ...
    names,observed,expected,caseTolerance,"short_beam_total",qTotal(2), ...
    deltaBending+deltaShear,tolerances.analyticalStaticRelative);

nearlyEB = short;
nearlyEB.GAy = 1e7*short.EIz/shortLength^2;
[Keb,~,~] = elements.timoshenko3d_matrices( ...
    [0 0 0],[shortLength 0 0],[0 0 1],nearlyEB,cfgClosed);
qBending = Keb(7:12,7:12)\[0;unitLoad;0;0;0;0];
[names,observed,expected,caseTolerance] = appendAnalytic( ...
    names,observed,expected,caseTolerance,"short_beam_bending_part", ...
    qBending(2),deltaBending,tolerances.analyticalStaticRelative);
[names,observed,expected,caseTolerance] = appendAnalytic( ...
    names,observed,expected,caseTolerance,"short_beam_shear_part", ...
    qTotal(2)-qBending(2),deltaShear,tolerances.analyticalStaticRelative);
[names,observed,expected,caseTolerance] = appendAnalytic( ...
    names,observed,expected,caseTolerance,"euler_bernoulli_limit", ...
    qBending(2),deltaBending,tolerances.analyticalStaticRelative);

% Independent finite-shear modal reference. For a simply supported uniform
% Timoshenko beam, v=sin(kx) and theta=cos(kx) reduce the field equations to
% a quadratic in omega^2 that includes both shear and rotary inertia.
modalSection = section;
modalLength = 4;
modalElements = 32;
[modalM,modalK,modalDofs] = assembleUniformBeam( ...
    modalElements,modalLength,modalSection,cfgClosed);
planeDofs = reshape(modalDofs(:,[2 6]).',[],1);
supported = [planeDofs(1);planeDofs(end-1)];
modalFree = setdiff(planeDofs,supported,'stable');
lambdaFE = symmetricEigenvalues( ...
    modalM(modalFree,modalFree),modalK(modalFree,modalFree));
for modeNumber = 1:2
    expectedFrequency = simplySupportedTimoshenkoFrequency( ...
        modalSection,modalLength,modeNumber);
    [names,observed,expected,caseTolerance] = appendAnalytic( ...
        names,observed,expected,caseTolerance, ...
        "simply_supported_timoshenko_mode_"+modeNumber, ...
        sqrt(lambdaFE(modeNumber))/(2*pi),expectedFrequency, ...
        tolerances.modalBenchmarkRelative);
end

relativeError = abs(observed-expected)./max(abs(expected),eps);
passed = relativeError <= caseTolerance;
tableValue = table(names,observed,expected,relativeError,caseTolerance,passed, ...
    'VariableNames',{'benchmark','observed','expected','relativeError', ...
    'tolerance','passed'});
checks = makeCheck("analytical.static",all(passed), ...
    max(relativeError./caseTolerance),1, ...
    "Axial, torsional, two-plane bending, shear and modal cases.",true);
end

function [tableValue,checks] = meshConvergenceBenchmark(cfg,tolerances)
cfgSelective = selectiveIntegrationConfiguration(cfg);
section = benchmarkSection();
section.Jx = 1e-3;
section.Jy = 1e-3;
section.Jz = 1e-3;
totalLength = 12;
section.GAy = 1e6*max(section.EIy,section.EIz)/totalLength^2;
section.GAz = section.GAy;
elementCount = [1;2;4;8;16;32];
if isfield(cfg,'action02') && isfield(cfg.action02,'meshElementCounts')
    elementCount = unique([elementCount;cfg.action02.meshElementCounts(:)],'sorted');
end
if isfield(cfg,'action02') && isfield(cfg.action02,'referenceElementCount')
    elementCount = unique([elementCount;cfg.action02.referenceElementCount(:)],'sorted');
end
beta = [1.875104068711961;4.694091132974174];
reference = beta.^2/(2*pi).*sqrt(section.EIz/(section.m*totalLength^4));

% Warm up the element/JIT path so the recorded assembly times are useful
% diagnostics. Timing is never an acceptance criterion.
assembleUniformBeam(1,totalLength,section,cfgSelective);
frequency1Hz = zeros(size(elementCount));
frequency2Hz = zeros(size(elementCount));
frequency1RelativeError = zeros(size(elementCount));
frequency2RelativeError = zeros(size(elementCount));
tipDisplacement = zeros(size(elementCount));
tipRelativeError = zeros(size(elementCount));
assemblyTimeSeconds = zeros(size(elementCount));
expectedTip = totalLength^3/(3*section.EIz)+totalLength/section.GAy;
for index = 1:numel(elementCount)
    tic
    [M,K,dofs] = assembleUniformBeam( ...
        elementCount(index),totalLength,section,cfgSelective);
    assemblyTimeSeconds(index) = toc;
    planeDofs = reshape(dofs(:,[2 6]).',[],1); % e2 displacement, e3 rotation
    free = planeDofs(3:end);
    lambda = symmetricEigenvalues(M(free,free),K(free,free));
    frequency1Hz(index) = sqrt(lambda(1))/(2*pi);
    frequency2Hz(index) = sqrt(lambda(2))/(2*pi);
    frequency1RelativeError(index) = abs(frequency1Hz(index)-reference(1))/reference(1);
    frequency2RelativeError(index) = abs(frequency2Hz(index)-reference(2))/reference(2);
    load = zeros(numel(free),1);
    load(end-1) = 1;
    q = K(free,free)\load;
    tipDisplacement(index) = q(end-1);
    tipRelativeError(index) = abs(tipDisplacement(index)-expectedTip)/expectedTip;
end
tableValue = table(elementCount,tipDisplacement,tipRelativeError, ...
    frequency1Hz,frequency2Hz,frequency1RelativeError, ...
    frequency2RelativeError,assemblyTimeSeconds);
tableValue.formulation = repmat("selective_integration",height(tableValue),1);
normalizedFinalError = max([ ...
    frequency1RelativeError(end)/tolerances.meshConvergenceRelative, ...
    frequency2RelativeError(end)/tolerances.meshConvergenceRelative, ...
    tipRelativeError(end)/tolerances.meshConvergenceRelative]);
reduced = frequency1RelativeError(end) < frequency1RelativeError(1) && ...
    frequency2RelativeError(end) < frequency2RelativeError(1);
checks = [makeCheck("meshConvergence.finalError", ...
    normalizedFinalError <= 1,normalizedFinalError,1, ...
    "All final-mesh errors use the base convergence tolerance.",true), ...
    makeCheck("meshConvergence.errorReduction",reduced,double(~reduced),0, ...
    "Both modal errors on the final mesh must be below their one-element errors.",true)];
end

function [M,K,dofs] = assembleUniformBeam(numberOfElements,totalLength,section,cfg)
numberOfNodes = numberOfElements+1;
dofs = reshape(1:6*numberOfNodes,6,[]).';
n = 6*numberOfNodes;
I = zeros(144*numberOfElements,1);
J = I;
VM = I;
VK = I;
elementLength = totalLength/numberOfElements;
for element = 1:numberOfElements
    xI = [(element-1)*elementLength 0 0];
    xJ = [element*elementLength 0 0];
    auxiliary = xI+[0 0 1];
    [ke,me] = elements.timoshenko3d_matrices(xI,xJ,auxiliary,section,cfg);
    edofs = [dofs(element,:) dofs(element+1,:)];
    [ii,jj] = ndgrid(edofs,edofs);
    index = 144*(element-1)+(1:144);
    I(index)=ii(:);J(index)=jj(:);VK(index)=ke(:);VM(index)=me(:);
end
K = sparse(I,J,VK,n,n);
M = sparse(I,J,VM,n,n);
K = 0.5*(K+K.');
M = 0.5*(M+M.');
end

function section = benchmarkSection()
section = struct('id',999001,'EA',2.1e9,'GAy',4e8,'GAz',3e8, ...
    'GJ',1.5e8,'EIy',8e7,'EIz',6e7,'m',25,'Jx',2,'Jy',1.2, ...
    'Jz',1.4,'ycg',0,'zcg',0,'type',"validation");
end

function frequencyHz = simplySupportedTimoshenkoFrequency(section,L,modeNumber)
k = modeNumber*pi/L;
m = double(section.m);
J = double(section.Jz);
S = double(section.GAy);
EI = double(section.EIz);
a = m*J;
b = S*J*k^2+m*S+m*EI*k^2;
c = S*EI*k^4;
discriminant = max(b^2-4*a*c,0);
if a <= eps(max(1,b))
    omegaSquared = c/b;
else
    % Stable expression for the lower (bending-dominated) quadratic root.
    omegaSquared = 2*c/(b+sqrt(discriminant));
end
frequencyHz = sqrt(omegaSquared)/(2*pi);
end

function cfg = selectiveIntegrationConfiguration(cfg)
if ~isstruct(cfg)
    cfg = struct();
end
if ~isfield(cfg,'element') || ~isstruct(cfg.element)
    cfg.element = struct();
end
cfg.element.formulation = "selective_integration";
end

function cfg = closedExactConfiguration(cfg)
if ~isstruct(cfg)
    cfg = struct();
end
if ~isfield(cfg,'element') || ~isstruct(cfg.element)
    cfg.element = struct();
end
cfg.element.formulation = "closed_exact";
end

function lambda = symmetricEigenvalues(M,K)
M = full(0.5*(M+M.'));
K = full(0.5*(K+K.'));
[L,p] = chol(M,'lower');
if p ~= 0
    error('validation:run_timoshenko_suite:NonPositiveBenchmarkMass', ...
        'A benchmark mass matrix is not positive definite after its SPCs.');
end
A = L\K/L.';
A = 0.5*(A+A.');
lambda = eig(A);
negativeTolerance = 1e-10*max(1,max(abs(lambda)));
if any(lambda < -negativeTolerance)
    error('validation:run_timoshenko_suite:NegativeBenchmarkMode', ...
        'A benchmark contains a materially negative eigenvalue.');
end
lambda = sort(real(lambda(isfinite(lambda) & real(lambda)>0)));
end

function [names,observed,expected,tolerance] = appendAnalytic( ...
    names,observed,expected,tolerance,name,newObserved,newExpected,newTolerance)
names(end+1,1) = string(name);
observed(end+1,1) = newObserved;
expected(end+1,1) = newExpected;
tolerance(end+1,1) = newTolerance;
end

function tableValue = subsystemModalTable(towerModes,bladeModes)
subsystem = strings(0,1);
mode = zeros(0,1);
frequencyHz = zeros(0,1);
residual = zeros(0,1);
[subsystem,mode,frequencyHz,residual] = appendModes( ...
    subsystem,mode,frequencyHz,residual,"tower",towerModes);
for bladeNumber = 1:3
    [subsystem,mode,frequencyHz,residual] = appendModes( ...
        subsystem,mode,frequencyHz,residual,"blade_"+bladeNumber, ...
        bladeModes{bladeNumber});
end
tableValue = table(subsystem,mode,frequencyHz,residual);
end

function [labels,mode,frequency,residual] = appendModes( ...
    labels,mode,frequency,residual,label,result)
n = numel(result.frequencyHz);
labels = [labels;repmat(string(label),n,1)]; %#ok<AGROW>
mode = [mode;(1:n).']; %#ok<AGROW>
frequency = [frequency;result.frequencyHz(:)]; %#ok<AGROW>
residual = [residual;result.residual(:)]; %#ok<AGROW>
end

function result = subsystemResult(subsystem,modes,mass,diagnostics)
result = struct('name',subsystem.name,'sourceElementRows', ...
    subsystem.sourceElementRows,'sourceElementIds',subsystem.sourceElementIds, ...
    'sourceNodeIds',subsystem.sourceNodeIds,'rootNodeId',subsystem.rootNodeId, ...
    'tipNodeId',subsystem.tipNodeId,'numberOfElements',subsystem.numberOfElements, ...
    'numberOfNodes',subsystem.numberOfNodes,'totalLengthM',subsystem.totalLength, ...
    'distributedMassKg',mass,'frequencyHz',modes.frequencyHz, ...
    'eigenvalues',modes.eigenvalues,'modalResidual',modes.residual, ...
    'diagnostics',diagnostics);
end

function tableValue = elementDiagnosticsTable(cache)
if isempty(cache)
    tableValue = table([],[],[],[],strings(0,1),[],[],true(0,1), ...
        true(0,1),strings(0,1),[],[],[],[],[],[], ...
        'VariableNames',{'elementId','nodeI','nodeJ','sectionId','component', ...
        'blade','lengthM','assembled','finite','formulation','symmetryErrorK', ...
        'symmetryErrorM','minimumMassEigenvalue','rigidModeCount', ...
        'frameOrthogonalityError','determinantR'});
    return
end
if iscell(cache)
    cache = [cache{:}];
end
if ~isstruct(cache)
    error('validation:run_timoshenko_suite:InvalidElementCache', ...
        'elementCache must be a struct array or cell array of structs.');
end
assembled = true(size(cache));
if isfield(cache,'assembled')
    assembled = logical([cache.assembled]);
end
cache = cache(assembled);
n = numel(cache);
assembled = true(n,1);
elementId = numericCacheField(cache,'id',NaN);
nodeI = numericCacheField(cache,'nodeI',NaN);
nodeJ = numericCacheField(cache,'nodeJ',NaN);
sectionId = numericCacheField(cache,'sectionId',NaN);
component = stringCacheField(cache,'component',"");
blade = numericCacheField(cache,'blade',0);
lengthM = numericCacheField(cache,'L',NaN);
formulation = stringCacheField(cache,'formulation',"unspecified");
symmetryErrorK = numericCacheField(cache,'symmetryErrorK',NaN);
symmetryErrorM = numericCacheField(cache,'symmetryErrorM',NaN);
minimumMassEigenvalue = numericCacheField(cache,'minMassEigenvalue',NaN);
rigidModeCount = numericCacheField(cache,'rigidModeCount',NaN);
frameOrthogonalityError = nan(n,1);
determinantR = nan(n,1);
for index = 1:n
    if isfield(cache(index),'R') && isequal(size(cache(index).R),[3 3])
        R = double(cache(index).R);
        frameOrthogonalityError(index) = max( ...
            norm(R*R.'-eye(3),'fro'),abs(det(R)-1));
        determinantR(index) = det(R);
    end
end
finite = isfinite(lengthM) & isfinite(symmetryErrorK) & ...
    isfinite(symmetryErrorM) & isfinite(minimumMassEigenvalue) & ...
    isfinite(rigidModeCount) & isfinite(frameOrthogonalityError) & ...
    isfinite(determinantR);
tableValue = table(elementId,nodeI,nodeJ,sectionId,component,blade,lengthM, ...
    assembled,finite,formulation,symmetryErrorK,symmetryErrorM, ...
    minimumMassEigenvalue,rigidModeCount,frameOrthogonalityError,determinantR);
end

function values = numericCacheField(cache,name,fallback)
values = repmat(double(fallback),numel(cache),1);
for index = 1:numel(cache)
    if isfield(cache(index),name) && ~isempty(cache(index).(name)) && ...
            isnumeric(cache(index).(name)) && isscalar(cache(index).(name))
        values(index) = double(cache(index).(name));
    end
end
end

function values = stringCacheField(cache,name,fallback)
values = repmat(string(fallback),numel(cache),1);
for index = 1:numel(cache)
    if isfield(cache(index),name) && ~isempty(cache(index).(name))
        values(index) = string(cache(index).(name));
    end
end
end

function summary = componentSummaryTable(modelData)
mesh = modelData.mesh;
elements = mesh.elements;
nodeIds = double(mesh.nodes.id(:));
[foundI,rowI] = ismember(double(elements.nodeI(:)),nodeIds);
[foundJ,rowJ] = ismember(double(elements.nodeJ(:)),nodeIds);
if ~all(foundI & foundJ)
    error('validation:run_timoshenko_suite:InvalidConnectivity', ...
        'Component summary cannot be formed with missing nodes.');
end
lengths = vecnorm(mesh.nodes.xyz(rowJ,:)-mesh.nodes.xyz(rowI,:),2,2);
sectionIds = elements.section(:);
massPerLength = zeros(numel(sectionIds),1);
for element = 1:numel(sectionIds)
    section = findModelSection(modelData.sections,sectionIds(element));
    massPerLength(element) = section.m;
end
labels = string(elements.type(:));
bladeNumber = double(elements.blade(:));
bladeRows = labels == "blade";
labels(bladeRows) = "blade_"+string(bladeNumber(bladeRows));
component = unique(labels,'stable');
elementCount = zeros(numel(component),1);
totalLengthM = zeros(numel(component),1);
distributedMassKg = zeros(numel(component),1);
for index = 1:numel(component)
    selected = labels == component(index);
    elementCount(index) = nnz(selected);
    totalLengthM(index) = sum(lengths(selected));
    distributedMassKg(index) = sum(massPerLength(selected).*lengths(selected));
end
summary = table(component,elementCount,totalLengthM,distributedMassKg);
end

function section = findModelSection(sections,sectionId)
if isnumeric(sectionId) && isscalar(sectionId) && sectionId >= 1 && ...
        sectionId <= numel(sections) && sectionId == fix(sectionId)
    candidate = sections(sectionId);
    if ~isfield(candidate,'id') || isequal(double(candidate.id),double(sectionId))
        section = candidate;
        return
    end
end
for index = 1:numel(sections)
    if isfield(sections(index),'id') && ...
            string(sections(index).id) == string(sectionId)
        section = sections(index);
        return
    end
end
error('validation:run_timoshenko_suite:UnknownSection', ...
    'Section %s is absent from modelData.sections.',string(sectionId));
end

function rotated = rotateSubsystem(base,Q,origin)
rotated = base;
rotated.name = base.name+"_rotated";
rotated.xyz = rotatePoints(base.xyz,Q,origin);
rotated.auxiliaryPoints = rotatePoints(base.auxiliaryPoints,Q,origin);
end

function points = rotatePoints(points,Q,origin)
points = (Q*(points.'-origin)+origin).';
end

function Q = axisRotation(axis,angle)
S = [0 -axis(3) axis(2);axis(3) 0 -axis(1);-axis(2) axis(1) 0];
Q = eye(3)+sin(angle)*S+(1-cos(angle))*(S*S);
end

function value = relativeSymmetry(A)
value = norm(A-A.','fro')/max(norm(A,'fro'),eps);
end

function checks = emptyChecks()
checks = repmat(makeCheck("",true,0,0,"",false),0,1);
end

function check = makeCheck(name,pass,value,tolerance,message,critical)
check = struct('name',string(name),'pass',logical(pass),'value',double(value), ...
    'tolerance',double(tolerance),'message',string(message), ...
    'critical',logical(critical));
end

function value = localCfg(cfg,path,fallback)
value = fallback;
cursor = cfg;
for index = 1:numel(path)
    if ~isstruct(cursor) || ~isfield(cursor,path{index})
        return
    end
    cursor = cursor.(path{index});
end
if (isnumeric(cursor) || islogical(cursor)) && isscalar(cursor) && isfinite(cursor)
    value = double(cursor);
end
end
