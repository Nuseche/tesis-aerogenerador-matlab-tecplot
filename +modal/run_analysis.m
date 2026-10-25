function results = run_analysis(ops, modelData, cfg)
%RUN_ANALYSIS Run one modal solution or a MAC-tracked Campbell sweep.
%   ops may be a matrix structure, a structure array/cell indexed by
%   speed, or a function handle ops(speedRPM). Matrix aliases accepted are
%   M/mass, D/Ctotal/C (+ optional G), and Kt/Ktotal/K.

arguments
    ops
    modelData = struct()
    cfg = struct()
end

% cfg.modes is the plan-level contract. cfg.modal keeps solver switches;
% when both define the same field, the explicit cfg.modes value wins.
modalCfg = mergeStruct(nestedStruct(cfg,'modal'),nestedStruct(cfg,'modes'));
rotorCfg = nestedStruct(cfg,'rotor');
nModes = getOption(modalCfg,{'number','nModes','numModes'},20);
speedGrid = getOption(rotorCfg,{'speedRPMGrid','speedsRPM'},[]);
if isempty(speedGrid), speedGrid = getOption(modalCfg,{'speedRPMGrid','speedsRPM'},[]); end
if isempty(speedGrid), speedGrid = getOption(rotorCfg,{'speedRPM'},0); end
speedGrid = speedGrid(:);

nSpeed = numel(speedGrid);
solutions = cell(nSpeed,1);
frequencies = nan(nSpeed,nModes);
naturalFrequencies = nan(nSpeed,nModes);
damping = nan(nSpeed,nModes);
eigenvalues = complex(nan(nSpeed,nModes));
trackingMAC = nan(nSpeed,nModes);
individualTrackingMAC = nan(nSpeed,nModes);
subspaceTrackingMAC = nan(nSpeed,nModes);
trackingFrequencyChange = nan(nSpeed,nModes);
trackingAssignment = nan(nSpeed,nModes);
trackingClusterId = nan(nSpeed,nModes);
classifications = cell(nSpeed,1);

previousSolution = [];
previousM = [];
for i = 1:nSpeed
    currentOps = resolveOps(ops,speedGrid(i),i,nSpeed,cfg,modelData);
    [M,D,K] = extractMatrices(currentOps);

    % Optional MBC conversion at the current rotor speed.
    mbcCfg = nestedStruct(rotorCfg,'mbc');
    if getOption(mbcCfg,{'enabled'},false)
        map = getBladeMap(modelData,mbcCfg);
        if ~isfield(mbcCfg,'frameData')&&isfield(modelData,'mbc')&& ...
                isfield(modelData.mbc,'frameData')
            mbcCfg.frameData=modelData.mbc.frameData;
        end
        psi = getOption(mbcCfg,{'azimuth','azimuthRad','referenceAzimuth'}, ...
            getOption(rotorCfg,{'azimuthRad','azimuth'},0));
        omega = speedGrid(i)*2*pi/60;
        transformed = rotor.transform_rotating_system(M,D,K,map,psi,omega,mbcCfg);
        M = transformed.M; D = transformed.D; K = transformed.K;
        currentOps.mbc = transformed;
    end

    solverChoice = lower(string(getOption(modalCfg,{'solver','formulation'},'auto')));
    conservative = solverChoice == "conservative" || ...
        (solverChoice == "auto" && norm(D,'fro') <= ...
        1e-12*max([1,norm(M,'fro'),norm(K,'fro')]));
    solveOptions = modalCfg;
    solveOptions.number = nModes;
    if conservative
        solution = modal.solve_conservative_modes(M,K,solveOptions);
        solution.naturalFrequencyHz = solution.frequencyHz;
        solution.dampedFrequencyHz = solution.frequencyHz;
        solution.dampingRatio = zeros(size(solution.frequencyHz));
        solution.eigenvaluesQEP = 1i*solution.omegaRadPerSec;
    else
        solution = modal.solve_quadratic_modes(M,D,K,solveOptions);
        solution.frequencyHz = solution.dampedFrequencyHz;
        solution.eigenvaluesQEP = solution.eigenvalues;
    end

    Phi = solution.modes;
    count = min(nModes,size(Phi,2));
    if ~isempty(previousSolution) && count > 0
        trackingMetric=(previousM+M)/2;
        tracking=modal.track_campbell_branches( ...
            previousSolution,solution,trackingMetric,modalCfg);
        reorder=tracking.assignment;
        remaining = setdiff(1:size(Phi,2),reorder,'stable');
        reorder = [reorder remaining];
        solution = reorderSolution(solution,reorder);
        Phi = solution.modes;
        trackingMAC(i,1:numel(tracking.effectiveMAC))=tracking.effectiveMAC;
        individualTrackingMAC(i,1:numel(tracking.individualMAC))=tracking.individualMAC;
        subspaceTrackingMAC(i,1:numel(tracking.subspaceMAC))=tracking.subspaceMAC;
        trackingFrequencyChange(i,1:numel(tracking.relativeFrequencyChange))= ...
            tracking.relativeFrequencyChange;
        trackingAssignment(i,1:numel(tracking.assignment))=tracking.assignment;
        trackingClusterId(i,1:numel(tracking.clusterId))=tracking.clusterId;
        solution.tracking=tracking;
    elseif count > 0
        trackingMAC(i,1:count) = 1;
        individualTrackingMAC(i,1:count)=1;
        trackingFrequencyChange(i,1:count)=0;
        trackingAssignment(i,1:count)=1:count;
        trackingClusterId(i,1:count)=1:count;
    end

    solution.transformedOperators=struct('M',M,'D',D,'K',K);
    if isfield(currentOps,'mbc'),solution.mbc=currentOps.mbc;end
    previousSolution=solution;previousSolution.modes=Phi(:,1:count);
    previousM=M;
    recovery = getRecoveryMatrix(currentOps,size(Phi,1));
    if ~isempty(recovery)
        if isfield(currentOps,'mbc')
            recovery = recovery*currentOps.mbc.transformation.T;
        end
        solution.fullModes = recovery*solution.modes;
    end
    frequencies(i,1:count) = solution.frequencyHz(1:count);
    naturalFrequencies(i,1:count) = solution.naturalFrequencyHz(1:count);
    damping(i,1:count) = solution.dampingRatio(1:count);
    eigenvalues(i,1:count) = solution.eigenvaluesQEP(1:count);

    classOptions = modalCfg;
    classificationInput = solution;
    classOptions.M = M;
    if isfield(solution,'fullModes')
        classificationInput.modes = solution.fullModes;
        fullMass = getFullMass(currentOps,size(solution.fullModes,1));
        if ~isempty(fullMass), classOptions.M = fullMass; end
    end
    classifications{i} = modal.classify_modes(classificationInput,modelData,classOptions);
    solution.classification = classifications{i}.labels;
    solutions{i} = solution;
end

campbell = struct('speedRPM',speedGrid,'frequencyHz',frequencies, ...
    'naturalFrequencyHz',naturalFrequencies,'dampingRatio',damping, ...
    'eigenvalues',eigenvalues,'trackingMAC',trackingMAC, ...
    'individualTrackingMAC',individualTrackingMAC, ...
    'subspaceTrackingMAC',subspaceTrackingMAC, ...
    'trackingFrequencyChange',trackingFrequencyChange, ...
    'trackingAssignment',trackingAssignment, ...
    'trackingClusterId',trackingClusterId, ...
    'classification',{classifications},'branchNumber',1:nModes);
results = struct('speedRPMGrid',speedGrid,'solutions',{solutions}, ...
    'classification',{classifications},'campbell',campbell, ...
    'speedRPM',speedGrid,'frequencyHz',frequencies, ...
    'naturalFrequencyHz',naturalFrequencies,'dampingRatio',damping, ...
    'eigenvalues',eigenvalues,'trackingMAC',trackingMAC, ...
    'individualTrackingMAC',individualTrackingMAC, ...
    'subspaceTrackingMAC',subspaceTrackingMAC, ...
    'trackingFrequencyChange',trackingFrequencyChange, ...
    'trackingAssignment',trackingAssignment, ...
    'trackingClusterId',trackingClusterId, ...
    'referenceSolution',solutions{1});
if nSpeed == 1
    fields = fieldnames(solutions{1});
    for k = 1:numel(fields), results.(fields{k}) = solutions{1}.(fields{k}); end
end
end

function current = resolveOps(ops,speed,index,nSpeed,cfg,modelData)
if isa(ops,'function_handle')
    current = ops(speed);
elseif iscell(ops)
    if numel(ops) ~= 1 && numel(ops) ~= nSpeed
        error('modal:Run:SpeedCountMismatch', ...
            'The ops cell must have one entry or one entry per rotor speed.');
    end
    current = ops{min(index,numel(ops))};
elseif isstruct(ops) && numel(ops) == nSpeed && nSpeed > 1
    current = ops(index);
elseif isstruct(ops) && isfield(ops,'atSpeed') && isa(ops.atSpeed,'function_handle')
    current = ops.atSpeed(speed);
elseif isstruct(ops) && isfield(ops,'speedFactory') && isa(ops.speedFactory,'function_handle')
    current = ops.speedFactory(speed,modelData,cfg);
else
    current = sliceMatrixPages(ops,index,nSpeed);
end
end

function s = sliceMatrixPages(s,index,nSpeed)
if ~isstruct(s), error('modal:Run:InvalidOps','ops must provide operating matrices.'); end
names = fieldnames(s);
for k = 1:numel(names)
    value = s.(names{k});
    if isnumeric(value) && ndims(value) == 3 && size(value,3) == nSpeed
        s.(names{k}) = value(:,:,index);
    elseif iscell(value) && numel(value) == nSpeed
        s.(names{k}) = value{index};
    end
end
end

function [M,D,K] = extractMatrices(ops)
if isfield(ops,'reduced') && isstruct(ops.reduced), ops = ops.reduced; end
M = pickField(ops,{'M','mass'});
K = pickField(ops,{'Kt','Ktotal','K'});
D = pickField(ops,{'D','Ctotal'});
if isempty(D)
    D = pickField(ops,{'C'});
    if isempty(D), D = sparse(size(M,1),size(M,1)); end
    G = pickField(ops,{'G'});
    if ~isempty(G), D = D + G; end
end
if isempty(M) || isempty(K)
    error('modal:Run:MissingMatrices','ops must contain M and K/Kt.');
end
end

function recovery = getRecoveryMatrix(ops,nReduced)
recovery = [];
if isfield(ops,'reduced') && isstruct(ops.reduced) && isfield(ops.reduced,'Tc')
    recovery = ops.reduced.Tc;
elseif isfield(ops,'Tc')
    recovery = ops.Tc;
end
if ~isempty(recovery) && size(recovery,2) ~= nReduced, recovery = []; end
end

function Mfull = getFullMass(ops,nFull)
Mfull = [];
if isfield(ops,'full') && isstruct(ops.full), Mfull = pickField(ops.full,{'M','mass'}); end
if isempty(Mfull), Mfull = pickField(ops,{'Mfull'}); end
if ~isempty(Mfull) && ~isequal(size(Mfull),[nFull nFull]), Mfull = []; end
end

function value = pickField(s,names)
value = [];
for k = 1:numel(names)
    if isfield(s,names{k}) && ~isempty(s.(names{k})), value = s.(names{k}); return; end
end
end

function solution = reorderSolution(solution,order)
vectorFields = {'eigenvalues','omegaRadPerSec','frequencyHz', ...
    'naturalFrequencyHz','dampedFrequencyHz','dampingRatio', ...
    'eigenvaluesQEP','residual','conjugatePartnerIndex', ...
    'conjugatePairRelativeError','generalizedMassBeforeScaling', ...
    'massNormBeforeScaling','pairType','pairConsistencyError','leftResidual', ...
    'signedFrequencyHz','classification','normwiseResidual'};
solution.modes = solution.modes(:,order);
if isfield(solution,'leftModes')&&size(solution.leftModes,2)>=numel(order)
    solution.leftModes=solution.leftModes(:,order);
end
for k = 1:numel(vectorFields)
    name = vectorFields{k};
    if isfield(solution,name) && numel(solution.(name)) >= numel(order)
        value = solution.(name);
        solution.(name) = value(order);
    end
end
if isfield(solution,'biorthogonality')&& ...
        size(solution.biorthogonality,1)>=numel(order)
    solution.biorthogonality=solution.biorthogonality(order,order);
end
end

function map = getBladeMap(modelData,mbcCfg)
if isfield(mbcCfg,'bladeDofMap'), map = mbcCfg.bladeDofMap;
elseif isfield(modelData,'bladeDofMap'), map = modelData.bladeDofMap;
elseif isfield(modelData,'mbcMap'), map = modelData.mbcMap;
else, error('modal:Run:MissingMBCMap','MBC enabled but no blade DOF map was supplied.');
end
end

function value = getOption(s,names,defaultValue)
if ischar(names) || isstring(names), names = cellstr(names); end
value = defaultValue;
for k = 1:numel(names)
    if isstruct(s) && isfield(s,names{k}) && ~isempty(s.(names{k}))
        value = s.(names{k}); return
    end
end
end

function out = nestedStruct(s,name)
out = struct();
if isstruct(s) && isfield(s,name) && isstruct(s.(name)), out = s.(name); end
end

function out = mergeStruct(base,overlay)
out = base;
names = fieldnames(overlay);
for k = 1:numel(names), out.(names{k}) = overlay.(names{k}); end
end
