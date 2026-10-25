function [Gamma,diagnostics] = influence_vector(modelData, directions, nDof)
%INFLUENCE_VECTOR Build base-motion influence vectors.
%   Gamma = dynamics.influence_vector(modelData,directions,nDof)
%   directions accepts [1 2 3], "x"/"y"/"z", or a cell/string array.
%   The nodal convention is [ux uy uz rx ry rz]. Existing modelData.Gamma
%   is returned when compatible.

arguments
    modelData = struct()
    directions = [1 2 3]
    nDof = []
end

if isstruct(directions)
    cfg = directions;
    directions = getOption(cfg,{'directions','components','direction'},[1 2 3]);
end
component = parseDirections(directions);

if isempty(nDof)
    nDof = inferDofCount(modelData);
end
if isempty(nDof) || nDof < 1
    error('dynamics:Influence:UnknownDimension', ...
        'nDof could not be inferred; supply it explicitly.');
end

if isstruct(modelData) && isfield(modelData,'Gamma') && ...
        size(modelData.Gamma,1) == nDof
    existing = modelData.Gamma;
    if size(existing,2) >= max(component)
        Gamma = existing(:,component);
        diagnostics=struct('source',"provided",'absoluteFull',sparse(0,0), ...
            'compatibleFull',sparse(0,0),'kinematicReduced',Gamma, ...
            'compatibilityResidual',sparse(0,0), ...
            'relativeCompatibilityError',NaN,'fixedDofs',zeros(0,1));
        return
    end
end

hasReduction = isstruct(modelData) && isfield(modelData,'Tc') && ...
    size(modelData.Tc,2) == nDof && size(modelData.Tc,1) > nDof;
if hasReduction
    constructionDofCount = size(modelData.Tc,1);
else
    constructionDofCount = nDof;
end
dofMap = extractDofMap(modelData,constructionDofCount);
absoluteFull = sparse(constructionDofCount,numel(component));
for j = 1:numel(component)
    indices = dofMap(:,component(j));
    indices = indices(indices >= 1 & indices <= constructionDofCount);
    absoluteFull(indices,j) = 1;
end

fixed=zeros(0,1);compatibleFull=absoluteFull;residual=sparse(0,0);
relativeError=0;
% The relative-coordinate compatible field has zero support rows. The
% absolute field deliberately retains support motion and is used by the
% mass-consistent force projection in run_seismic_analysis.
if hasReduction
    fixed = extractFixedDofs(modelData,constructionDofCount);
    compatibleFull(fixed,:) = 0;
    Gamma = modelData.Tc \ compatibleFull;
    residual=modelData.Tc*Gamma-compatibleFull;
    relativeError=norm(residual,'fro')/max(norm(compatibleFull,'fro'),eps);
    if relativeError>1e-10
        error('dynamics:Influence:IncompatibleReduction', ...
            'Relative influence is incompatible with Tc (error %.3e).',relativeError);
    end
else
    Gamma=absoluteFull;
end
diagnostics=struct('source',"constructed",'absoluteFull',absoluteFull, ...
    'compatibleFull',compatibleFull,'kinematicReduced',Gamma, ...
    'compatibilityResidual',residual, ...
    'relativeCompatibilityError',relativeError,'fixedDofs',fixed, ...
    'directions',component(:).','convention', ...
    "absoluteFull includes support motion; compatibleFull has zero fixed rows");
end

function map = extractDofMap(modelData,nDof)
map = [];
if isstruct(modelData) && isfield(modelData,'dofMap')
    value = modelData.dofMap;
    if isnumeric(value), map = value;
    elseif isstruct(value)
        candidates = {'nodeDofs','nodeDOFs','dofs'};
        for k = 1:numel(candidates)
            if isfield(value,candidates{k}) && isnumeric(value.(candidates{k}))
                map = value.(candidates{k}); break
            end
        end
    end
end
if isempty(map) && isstruct(modelData) && isfield(modelData,'dofs') && ...
        isstruct(modelData.dofs)
    candidates = {'node','nodeDofs','nodeDOFs'};
    for k = 1:numel(candidates)
        if isfield(modelData.dofs,candidates{k}) && isnumeric(modelData.dofs.(candidates{k}))
            map = modelData.dofs.(candidates{k}); break
        end
    end
end
if isempty(map)
    if mod(nDof,6) == 0
        map = reshape(1:nDof,6,[]).';
    else
        % A reduced translational test/model may contain only x-like DOFs.
        map = zeros(nDof,6); map(:,1) = (1:nDof).';
    end
end
if size(map,2) < 3
    error('dynamics:Influence:InvalidDofMap','The DOF map needs at least three translational columns.');
end
end

function count = inferDofCount(modelData)
count = [];
names = {'nDof','nDOF','numberOfDofs'};
for k = 1:numel(names)
    if isstruct(modelData) && isfield(modelData,names{k}), count = modelData.(names{k}); return; end
end
if isstruct(modelData) && isfield(modelData,'dofMap') && isnumeric(modelData.dofMap)
    count = max(modelData.dofMap,[],'all');
end
if isempty(count) && isstruct(modelData) && isfield(modelData,'dofs') && isstruct(modelData.dofs)
    count = getOption(modelData.dofs,{'number','ndof','nDof'},[]);
    if isempty(count) && isfield(modelData.dofs,'node')
        count = max(modelData.dofs.node,[],'all');
    end
end
end

function fixed = extractFixedDofs(modelData,nDof)
fixed = [];
if isfield(modelData,'fullFixed'), fixed = modelData.fullFixed;
elseif isfield(modelData,'dofs') && isstruct(modelData.dofs) && isfield(modelData.dofs,'fixed')
    fixed = modelData.dofs.fixed;
elseif isfield(modelData,'fixedDofs'), fixed = modelData.fixedDofs;
end
fixed = unique(double(fixed(:)));
fixed = fixed(fixed >= 1 & fixed <= nDof);
end

function component = parseDirections(value)
if isnumeric(value)
    component = value(:).';
else
    labels = lower(string(value)); component = zeros(size(labels));
    for k = 1:numel(labels)
        switch labels(k)
            case {"x","ux","1"}, component(k) = 1;
            case {"y","uy","2"}, component(k) = 2;
            case {"z","uz","3"}, component(k) = 3;
            otherwise, error('dynamics:Influence:InvalidDirection','Unknown direction %s.',labels(k));
        end
    end
end
if isempty(component) || any(~ismember(component,1:3))
    error('dynamics:Influence:InvalidDirection','Directions must be x, y, z or 1, 2, 3.');
end
end

function value = getOption(s,names,defaultValue)
value = defaultValue;
for k = 1:numel(names)
    if isfield(s,names{k}) && ~isempty(s.(names{k})), value = s.(names{k}); return; end
end
end
