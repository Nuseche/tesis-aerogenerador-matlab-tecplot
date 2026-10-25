function summary = generate_comprehensive_evidence(outputFolder)
%GENERATE_COMPREHENSIVE_EVIDENCE Export rigid-mode evidence used by the report.
%   This postprocesses the accepted implementation without creating a run.
%   It evaluates (1) the primitive two-node element, (2) the connected global
%   elastic model with a free base, and (3) the same model with six base DOFs
%   removed. The drivetrain stiffness in the global check is the explicitly
%   labelled numerical benchmark from Action 06, not a calibrated property.

if nargin < 1 || strlength(string(outputFolder)) == 0
    projectRoot = fileparts(fileparts(mfilename('fullpath')));
    outputFolder = fullfile(projectRoot,'docs','resultados_integrales','evidence');
else
    projectRoot = fileparts(fileparts(mfilename('fullpath')));
end
outputFolder = char(string(outputFolder));
if ~isfolder(outputFolder)
    mkdir(outputFolder);
end
addpath(projectRoot);
addpath(fullfile(projectRoot,'cases'));

toleranceHz = 1e-4;

%% Primitive 12-DOF Timoshenko element used by the unit test.
section = struct('id',1,'EA',2.1e9,'GAy',4e8,'GAz',3e8, ...
    'GJ',1.5e8,'EIy',8e7,'EIz',6e7,'m',25,'Jx',2, ...
    'Jy',1.2,'Jz',1.4,'ycg',0,'zcg',0);
[Kprimitive,Mprimitive,primitiveInfo] = ...
    elements.timoshenko3d_matrices(5,section);
lambdaPrimitive = real(eig(full(Kprimitive),full(Mprimitive)));
primitiveSpectrum = spectrumTable(lambdaPrimitive,toleranceHz);
writetable(primitiveSpectrum,fullfile(outputFolder, ...
    'primitive_element_spectrum.csv'));

singularValues = sort(double(primitiveInfo.stiffnessSingularValues(:)), ...
    'descend');
normalizedSingularValue = singularValues/max(singularValues);
singularIndex = (1:numel(singularValues)).';
primitiveSingular = table(singularIndex,singularValues, ...
    normalizedSingularValue);
writetable(primitiveSingular,fullfile(outputFolder, ...
    'primitive_element_singular_values.csv'));

%% Connected global elastic model, free-free and fixed-base views.
cfg = config_action06_equilibrium();
cfg.base.type = "free";
cfg.base.fixedNodeIds = zeros(0,1);
cfg.gravity.enabled = false;
cfg.output.makeFigures = false;
cfg.output.plotGeometry = false;
data = io.load_model_data(cfg);
modelData = model.build_model(data,cfg);
model.validate_model(modelData,cfg);
[Massembled,Ke] = assembly.assemble_structural_matrices(modelData,cfg);
[Mdistributed,~] = assembly.apply_mass_formulation( ...
    Massembled,cfg,modelData);
M = rigid.add_body_masses(Mdistributed,modelData,modelData.rigidBodies);
Tc = rigid.rigid_constraint_matrix(modelData,modelData.rigidBodies,cfg);
reduced = rigid.reduce_system(Tc,M,Ke,modelData,cfg);

numberOfModes = 18;
lambdaFree = smallestGeneralizedEigenvalues( ...
    reduced.Ke,reduced.M,numberOfModes);
globalFreeSpectrum = spectrumTable(lambdaFree,toleranceHz);
writetable(globalFreeSpectrum,fullfile(outputFolder, ...
    'global_free_free_spectrum.csv'));

fixedFull = modelData.dofs.node(1,:).';
fixedReduced = zeros(numel(fixedFull),1);
for index = 1:numel(fixedFull)
    [~,column,value] = find(Tc(fixedFull(index),:));
    if numel(column) ~= 1 || abs(value-1) > 100*eps
        error('tools:generate_comprehensive_evidence:UnexpectedBaseMap', ...
            'Base DOF %d does not map to one unit reduced coordinate.', ...
            fixedFull(index));
    end
    fixedReduced(index) = column;
end
freeReduced = setdiff((1:size(Tc,2)).',fixedReduced,'stable');
lambdaFixed = smallestGeneralizedEigenvalues( ...
    reduced.Ke(freeReduced,freeReduced), ...
    reduced.M(freeReduced,freeReduced),numberOfModes);
globalFixedSpectrum = spectrumTable(lambdaFixed,toleranceHz);
writetable(globalFixedSpectrum,fullfile(outputFolder, ...
    'global_fixed_base_spectrum.csv'));

Qfull = globalRigidMotionMatrix(modelData);
Qreduced = Tc\Qfull;
compatibilityResidual = norm(Tc*Qreduced-Qfull,'fro')/norm(Qfull,'fro');
globalRigidEnergyResidual = norm(reduced.Ke*Qreduced,'fro') / ...
    max(norm(reduced.Ke,'fro')*norm(Qreduced,'fro'),eps);

primitiveZero = primitiveSpectrum.classification == "rigid_numerical_zero";
globalZero = globalFreeSpectrum.classification == "rigid_numerical_zero";
fixedZero = globalFixedSpectrum.classification == "rigid_numerical_zero";
caseName = ["primitive_element";"connected_global_free_free"; ...
    "connected_global_fixed_base"];
coordinateCount = [12;size(Tc,2);numel(freeReduced)];
evaluatedEigenvalues = [height(primitiveSpectrum); ...
    height(globalFreeSpectrum);height(globalFixedSpectrum)];
nearZeroModeCount = [nnz(primitiveZero);nnz(globalZero);nnz(fixedZero)];
materiallyNegativeCount = [sum(primitiveSpectrum.materiallyNegative); ...
    sum(globalFreeSpectrum.materiallyNegative); ...
    sum(globalFixedSpectrum.materiallyNegative)];
maximumAbsoluteNearZeroFrequencyHz = [ ...
    safeMaximum(abs(primitiveSpectrum.frequencyHz(primitiveZero))); ...
    safeMaximum(abs(globalFreeSpectrum.frequencyHz(globalZero))); ...
    safeMaximum(abs(globalFixedSpectrum.frequencyHz(fixedZero)))];
firstFlexibleFrequencyHz = [ ...
    safeMinimum(primitiveSpectrum.frequencyHz(~primitiveZero & ...
        primitiveSpectrum.frequencyHz > 0)); ...
    safeMinimum(globalFreeSpectrum.frequencyHz(~globalZero & ...
        globalFreeSpectrum.frequencyHz > 0)); ...
    safeMinimum(globalFixedSpectrum.frequencyHz(~fixedZero & ...
        globalFixedSpectrum.frequencyHz > 0))];
rigidEnergyResidual = [primitiveInfo.rigidEnergyResidual; ...
    globalRigidEnergyResidual;NaN];
rigidCompatibilityResidual = [0;compatibilityResidual;NaN];
modeToleranceHz = repmat(toleranceHz,3,1);
connectionStatus = ["single_connected_element"; ...
    "drivetrain_benchmark_connects_129_130"; ...
    "same_connected_model_six_base_dofs_removed"];
summary = table(caseName,coordinateCount,evaluatedEigenvalues, ...
    nearZeroModeCount,materiallyNegativeCount, ...
    maximumAbsoluteNearZeroFrequencyHz,firstFlexibleFrequencyHz, ...
    rigidEnergyResidual,rigidCompatibilityResidual,modeToleranceHz, ...
    connectionStatus);
writetable(summary,fullfile(outputFolder,'rigid_mode_summary.csv'));

stage = ["legacy_nodes";"legacy_elements";"removed_type3_connectors"; ...
    "active_flexible_elements";"full_nodal_dofs"; ...
    "independent_after_mpc";"analysis_after_fixed_base"];
count = [138;137;4;133;828;810;804];
description = [ ...
    "Verified Version 0 coordinate rows"; ...
    "Verified Version 0 connectivity rows"; ...
    "Penalty connectors 134:137 excluded"; ...
    "19 tower + 105 blade + 9 transition"; ...
    "138 nodes times 6 DOF"; ...
    "Three six-DOF blade-root MPCs remove 18 dependent DOF"; ...
    "Six independent node-1 support DOF removed"];
meshReduction = table(stage,count,description);
writetable(meshReduction,fullfile(outputFolder, ...
    'mesh_and_dof_reduction.csv'));

%% Sparse-operator structure from the accepted Action 10 artifact.
action10File = fullfile(projectRoot,'runs', ...
    'run_20260831_165045_307_action10_full_acceptance', ...
    'action10_matrices.mat');
stored = load(action10File,'Tanalysis','primaryOperators');
figureFolder = fullfile(fileparts(outputFolder),'figures');
if ~isfolder(figureFolder), mkdir(figureFolder); end
fig = figure('Visible','off','Color','w','Position',[100 100 1200 900]);
layout = tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');
matrixSet = {stored.Tanalysis,stored.primaryOperators.M, ...
    stored.primaryOperators.D,stored.primaryOperators.K};
titles = {sprintf('Tanalysis (%d x %d)',size(stored.Tanalysis)), ...
    sprintf('M (%d x %d)',size(stored.primaryOperators.M)), ...
    sprintf('D=C+G (%d x %d)',size(stored.primaryOperators.D)), ...
    sprintf('K (%d x %d)',size(stored.primaryOperators.K))};
for index = 1:numel(matrixSet)
    ax = nexttile(layout);
    axes(ax); %#ok<LAXES>
    spy(matrixSet{index});
    set(ax,'Color','w','XColor','k','YColor','k');
    title(ax,titles{index},'Color','k');
    xlabel(ax,'Columna');ylabel(ax,'Fila');
end
title(layout,'Estructura dispersa de los operadores aceptados','Color','k');
exportgraphics(fig,fullfile(figureFolder,'31_estructura_matrices.png'), ...
    'Resolution',180);
close(fig);
end

function tableValue = spectrumTable(lambda,toleranceHz)
lambda = real(lambda(:));
[~,order] = sort(abs(lambda),'ascend');
lambda = lambda(order);
frequencyHz = sign(lambda).*sqrt(abs(lambda))/(2*pi);
thresholdLambda = (2*pi*toleranceHz)^2;
classification = repmat("flexible",numel(lambda),1);
classification(abs(lambda) <= thresholdLambda) = "rigid_numerical_zero";
materiallyNegative = lambda < -thresholdLambda;
classification(materiallyNegative) = "materially_negative";
mode = (1:numel(lambda)).';
tableValue = table(mode,lambda,frequencyHz,classification, ...
    materiallyNegative,repmat(toleranceHz,numel(lambda),1), ...
    'VariableNames',{'mode','eigenvalueRad2PerS2','frequencyHz', ...
    'classification','materiallyNegative','zeroToleranceHz'});
end

function lambda = smallestGeneralizedEigenvalues(K,M,numberOfModes)
K = (sparse(K)+sparse(K).')/2;
M = (sparse(M)+sparse(M).')/2;
numberOfModes = min(numberOfModes,size(K,1));
state = warning('query','MATLAB:eigs:IllConditionedA');
cleanup = onCleanup(@() warning(state.state,'MATLAB:eigs:IllConditionedA'));
warning('off','MATLAB:eigs:IllConditionedA');
options = struct('tol',1e-11,'maxit',5000,'isreal',true);
rng(20260831,'twister');
try
    [~,D] = eigs(K,M,numberOfModes,'smallestabs',options);
    lambda = real(diag(D));
catch
    allLambda = eig(full(K),full(M),'vector');
    allLambda = real(allLambda(isfinite(allLambda)));
    [~,order] = sort(abs(allLambda),'ascend');
    lambda = allLambda(order(1:min(numberOfModes,numel(order))));
end
end

function Q = globalRigidMotionMatrix(modelData)
nodeCount = numel(modelData.mesh.nodes.id);
Q = zeros(6*nodeCount,6);
for node = 1:nodeCount
    dofs = modelData.dofs.node(node,:);
    x = modelData.mesh.nodes.xyz(node,:).';
    Q(dofs(1:3),1:3) = eye(3);
    Q(dofs(1:3),4:6) = -skew(x);
    Q(dofs(4:6),4:6) = eye(3);
end
end

function S = skew(x)
S = [0 -x(3) x(2);x(3) 0 -x(1);-x(2) x(1) 0];
end

function value = safeMaximum(values)
if isempty(values), value = 0; else, value = max(values); end
end

function value = safeMinimum(values)
if isempty(values), value = NaN; else, value = min(values); end
end
