function summary = run_validation_suite(modelData, ops, results, cfg, phase)
%RUN_VALIDATION_SUITE Execute phased global acceptance checks.
%   phase="preflight" checks model/operator properties, phase="postflight"
%   checks solved results, and the backward-compatible default "all" runs
%   both. A caller can therefore stop before an expensive solve when a
%   preflight critical gate fails.

if nargin < 5 || strlength(string(phase)) == 0, phase = "all"; end
phase = lower(string(phase));
if ~isscalar(phase) || ~any(phase == ["all","preflight","postflight"])
    error('validation:run_validation_suite:InvalidPhase', ...
        'phase must be all, preflight or postflight.');
end

checks = repmat(localCheck("",true,0,0,"",false),0,1);
if phase ~= "postflight"
    checks = validation.check_matrix_properties(ops,cfg);

    if isfield(ops,'reduced'), red = ops.reduced; else, red = ops; end
    M = localGet(red,{'M'});
    K = localGet(red,{'K','Kt','Ktotal','Ke'});
    if ~isempty(M) && ~isempty(K) && ~localSkipRigidModes(cfg)
        baseType = "free";
        if isfield(cfg,'base') && isfield(cfg.base,'type')
            baseType = cfg.base.type;
        end
        checks = [checks; validation.check_rigid_modes( ...
            M,K,baseType,cfg)]; %#ok<AGROW>
    end

    Tc = localGet(red,{'Tc'});
    if isempty(Tc) && isfield(ops,'full')
        Tc = localGet(ops.full,{'Tc'});
    end
    if ~isempty(Tc)
        bodies = struct([]);
        if isfield(modelData,'rigidBodies'), bodies = modelData.rigidBodies; end
        checks = [checks; validation.check_rigid_constraints( ...
            Tc,modelData,bodies,cfg)]; %#ok<AGROW>
    end
end

if phase ~= "preflight"
    checks = [checks; localResultChecks(results,cfg)]; %#ok<AGROW>
end
summary = struct();
summary.timestamp = datetime('now', 'TimeZone', 'local');
summary.phase = phase;
summary.checks = checks;
summary.passed = all([checks.pass] | ~[checks.critical]);
summary.criticalFailures = checks(~[checks.pass] & [checks.critical]);
summary.warningCount = nnz(~[checks.pass] & ~[checks.critical]);

failOnCritical = true;
if isfield(cfg, 'validation') && isfield(cfg.validation, 'failOnCritical')
    failOnCritical = logical(cfg.validation.failOnCritical);
end
if failOnCritical && ~summary.passed
    names = strjoin(string({summary.criticalFailures.name}), ', ');
    error('validation:run_validation_suite:CriticalFailure', ...
        'Critical validation checks failed: %s', names);
end
end

function tf = localSkipRigidModes(cfg)
tf = false;
if isfield(cfg,'analysis') && isfield(cfg.analysis,'type')
    tf = any(lower(string(cfg.analysis.type)) == ...
        ["action03","action03_rigid_constraints", ...
         "rigid_constraint_validation","action04", ...
         "action04_rigid_bodies","rigid_body_mass_validation", ...
         "action05","action05_mass_formulation", ...
         "mass_formulation_validation"]);
end
end

function checks = localResultChecks(results, cfg)
checks = repmat(localCheck("", true, 0, 0, "", false), 0, 1);
if isfield(results,'massProperties')
    value=results.massProperties.constraintConservationError;
    tolerance=localCfg(cfg,{'validation','massConservationTolerance'},1e-10);
    checks(end+1,1)=localCheck("mass.constraintConservation",value<=tolerance, ...
        value,tolerance,"Spatial mass before and after Tc congruence.",true); %#ok<AGROW>
end
if isfield(results, 'modal') && ~isempty(results.modal)
    eigenvalues = localFindRecursive(results.modal, {'eigenvalues','lambda'});
    if ~isempty(eigenvalues)
        finite = all(isfinite(eigenvalues),'all');
        checks(end+1,1) = localCheck("modal.eigenvalues.finite", finite, ...
            double(~finite), 0, "All requested modal eigenvalues must be finite.", true); %#ok<AGROW>
    end
end
if isfield(results, 'time') && ~isempty(results.time)
    stateNames = {'q','qd','qdd'};
    for index = 1:numel(stateNames)
        state = localFindRecursive(results.time,stateNames(index));
        if ~isempty(state)
            finite = isnumeric(state) && all(isfinite(state(:)));
            checks(end+1,1) = localCheck( ...
                "time."+stateNames{index}+".finite",finite, ...
                double(~finite),0, ...
                "All time-response state entries must be finite.",true); %#ok<AGROW>
        end
    end
    recoveredNames = {'absoluteDisplacement','absoluteVelocity', ...
        'absoluteAcceleration','constraintForcesFull','reactions', ...
        'elementForces'};
    for index = 1:numel(recoveredNames)
        recovered = localFindRecursive(results.time,recoveredNames(index));
        if ~isempty(recovered) && isnumeric(recovered)
            finite = all(isfinite(recovered(:)));
            checks(end+1,1) = localCheck( ...
                "time."+recoveredNames{index}+".finite",finite, ...
                double(~finite),0, ...
                "Recovered time-history evidence must be finite.",true); %#ok<AGROW>
        end
    end
    energyTol = localCfg(cfg,{'validation','energyTolerance'},1e-6);
    energyCritical = localLogicalCfg(cfg, ...
        {'validation','requireEnergyBalance'},false);
    energy = localFindRecursive(results.time, {'energy'});
    if isstruct(energy) && isfield(energy, 'relativeBalanceError')
        value = max(abs(energy.relativeBalanceError), [], 'all');
        checks(end+1,1) = localCheck("time.energy.balance", value <= energyTol, value, ...
            energyTol, "Maximum relative algorithmic energy-balance residual.", ...
            energyCritical); %#ok<AGROW>
    elseif energyCritical
        checks(end+1,1) = localCheck("time.energy.balance",false,NaN, ...
            energyTol,"Required energy-balance evidence was not found.",true); %#ok<AGROW>
    end
end
end

function value = localFindRecursive(s, names)
value = [];
if ~isstruct(s), return; end
for i = 1:numel(names)
    if isfield(s, names{i}), value = s.(names{i}); return; end
end
fields = fieldnames(s);
for i = 1:numel(fields)
    candidate = s.(fields{i});
    if isstruct(candidate)
        value = localFindRecursive(candidate, names);
        if ~isempty(value), return; end
    end
end
end

function value = localGet(s, names)
value = [];
for i = 1:numel(names)
    if isstruct(s) && isfield(s, names{i}) && ~isempty(s.(names{i}))
        value = s.(names{i}); return
    end
end
end

function check = localCheck(name, pass, value, tolerance, message, critical)
check = struct('name', string(name), 'pass', logical(pass), 'value', value, ...
    'tolerance', tolerance, 'message', string(message), 'critical', logical(critical));
end

function value = localCfg(cfg, path, fallback)
value = fallback; cursor = cfg;
for i = 1:numel(path)
    if ~isstruct(cursor) || ~isfield(cursor, path{i}), return; end
    cursor = cursor.(path{i});
end
if isnumeric(cursor) && isscalar(cursor), value = cursor; end
end

function value = localLogicalCfg(cfg,path,fallback)
value=fallback;cursor=cfg;
for index=1:numel(path)
    if ~isstruct(cursor)||~isfield(cursor,path{index}),return;end
    cursor=cursor.(path{index});
end
if (islogical(cursor)||isnumeric(cursor))&&isscalar(cursor)
    value=logical(cursor);
end
end
