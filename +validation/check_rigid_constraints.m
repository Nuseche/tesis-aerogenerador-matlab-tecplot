function report = check_rigid_constraints(Tc, modelData, bodies, cfg)
%CHECK_RIGID_CONSTRAINTS Verify rank and exact master/slave kinematics.
%   Node IDs are resolved through mesh.nodes.id; they need not be contiguous
%   or equal to row numbers. Kinematics are checked as matrix identities for
%   every reduced coordinate, rather than with one displacement probe.

if nargin < 4, cfg = struct(); end
tol = localCfg(cfg, {'validation','constraintTolerance'}, 1e-12);
report = repmat(localCheck("", true, 0, 0, "", false), 0, 1);

rankTc = sprank(Tc);
rankPass = rankTc == size(Tc,2);
report(end+1,1) = localCheck("Tc.fullColumnRank", rankPass, rankTc, size(Tc,2), ...
    "The reduction transform must have full column rank.", true);

slavePairs = localSlavePairs(modelData, bodies);
if isempty(slavePairs)
    report(end+1,1) = localCheck("Tc.kinematics", true, NaN, tol, ...
        "No explicit slave map was exposed; rank was checked.", false);
    return
end

nodeIds = double(modelData.mesh.nodes.id(:));
xyz = double(modelData.mesh.nodes.xyz);
dofMap = localDofMap(modelData,numel(nodeIds));
maxResidual = 0;
for i = 1:size(slavePairs,1)
    master = slavePairs(i,1); slave = slavePairs(i,2);
    masterRow = find(nodeIds == master,1);
    slaveRow = find(nodeIds == slave,1);
    if isempty(masterRow) || isempty(slaveRow)
        report(end+1,1) = localCheck("Tc.knownNodes", false, NaN, 0, ...
            "Every reported master and slave must exist in mesh.nodes.id.", true);
        return
    end
    r = (xyz(slaveRow,:) - xyz(masterRow,:)).';
    B = [eye(3),-localSkew(r);zeros(3),eye(3)];
    residual = Tc(dofMap(slaveRow,:),:) - B*Tc(dofMap(masterRow,:),:);
    maxResidual = max(maxResidual, norm(residual,inf));
end
report(end+1,1) = localCheck("Tc.kinematics", maxResidual <= tol, ...
    maxResidual, tol, "Maximum matrix-identity master/slave residual.", true);
end

function dofMap = localDofMap(modelData,nNodes)
if isfield(modelData,'dofs') && isfield(modelData.dofs,'node')
    dofMap = double(modelData.dofs.node);
else
    dofMap = reshape(1:6*nNodes,6,nNodes).';
end
if ~isequal(size(dofMap),[nNodes,6]) || ...
        numel(unique(dofMap(:))) ~= numel(dofMap)
    error('validation:check_rigid_constraints:InvalidDofMap', ...
        'modelData.dofs.node must be an N-by-6 map of unique DOFs.');
end
end

function pairs = localSlavePairs(modelData, bodies)
pairs = zeros(0,2);
if isfield(modelData, 'constraints') && isfield(modelData.constraints, 'slavePairs')
    pairs = modelData.constraints.slavePairs;
    return
end
if isfield(bodies, 'constraints') && isfield(bodies.constraints, 'slavePairs')
    pairs = bodies.constraints.slavePairs;
    return
end
if isfield(bodies, 'constraints') && ...
        all(isfield(bodies.constraints, {'masterNode','slaveNodes'}))
    constraintList = bodies.constraints;
    for constraintIndex = 1:numel(constraintList)
        slaves = constraintList(constraintIndex).slaveNodes(:);
        pairs = [pairs; repmat(constraintList(constraintIndex).masterNode, ...
            numel(slaves),1), slaves]; %#ok<AGROW>
    end
    return
end
if isstruct(bodies)
    for i = 1:numel(bodies)
        if isfield(bodies(i), 'masterNode') && isfield(bodies(i), 'slaveNodes')
            slaves = bodies(i).slaveNodes(:);
            pairs = [pairs; repmat(bodies(i).masterNode, numel(slaves), 1), slaves]; %#ok<AGROW>
        end
    end
end
end

function S = localSkew(r)
S = [0 -r(3) r(2); r(3) 0 -r(1); -r(2) r(1) 0];
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
