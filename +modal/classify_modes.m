function classification = classify_modes(modes, modelData, options)
%CLASSIFY_MODES Classify modes from user/model supplied DOF groups.
%   Groups may be supplied as modelData.modalGroups, modelData.dofGroups,
%   or options.groups. Each field contains global DOF indices.

arguments
    modes
    modelData = struct()
    options = struct()
end

if isstruct(modes)
    if isfield(modes,'modes'), Phi = modes.modes;
    elseif isfield(modes,'Phi'), Phi = modes.Phi;
    else, error('modal:Classify:MissingModes','Modal structure has no modes field.');
    end
else
    Phi = modes;
end

groups = struct();
groupSource = "none";
if isstruct(options) && isfield(options,'groups'), groups = options.groups;
elseif isstruct(modelData) && isfield(modelData,'modalGroups'), groups = modelData.modalGroups;
elseif isstruct(modelData) && isfield(modelData,'dofGroups'), groups = modelData.dofGroups;
end
if ~isempty(fieldnames(groups))
    groupSource = "provided";
else
    groups = inferPhysicalGroups(modelData,size(Phi,1));
    if ~isempty(fieldnames(groups)), groupSource = "inferred-from-mesh"; end
end

M = speye(size(Phi,1));
if isstruct(options) && isfield(options,'M') && ~isempty(options.M), M = options.M;
elseif isstruct(modelData) && isfield(modelData,'M') && ~isempty(modelData.M), M = modelData.M;
end
names = fieldnames(groups);
nModes = size(Phi,2);
if isempty(names)
    classification = struct('labels',repmat("unclassified",nModes,1), ...
        'groupNames',strings(0,1),'participation',zeros(nModes,0), ...
        'dominantParticipation',zeros(nModes,1),'groupSource',groupSource, ...
        'metricUsed',"none");
    return
end
metricUsed = "supplied";
if ~isequal(size(M),[size(Phi,1) size(Phi,1)])
    M = speye(size(Phi,1));
    metricUsed = "identity-dimension-fallback";
end

participation = zeros(nModes,numel(names));
membershipCount = zeros(size(Phi,1),1);
groupIndices = cell(numel(names),1);
for g = 1:numel(names)
    idx = unique(groups.(names{g})(:));
    idx = idx(idx >= 1 & idx <= size(Phi,1));
    groupIndices{g} = idx;
    membershipCount(idx) = membershipCount(idx)+1;
end
covered = membershipCount>0;
for g = 1:numel(names)
    idx = groupIndices{g};
    for j = 1:nModes
        modalMomentum = M*Phi(:,j);
        allContribution = abs(conj(Phi(:,j)).*modalMomentum);
        % Overlapping groups share a coordinate's contribution equally;
        % therefore the reported participations form a true partition of
        % the covered modal contribution instead of double-counting it.
        localContribution = allContribution(idx)./membershipCount(idx);
        participation(j,g) = sum(localContribution)/ ...
            max(sum(allContribution(covered)),eps);
    end
end
[dominant,index] = max(participation,[],2);
labels = string(names(index));
threshold = getOption(options,'minimumParticipation',0);
labels(dominant < threshold) = "mixed";
classification = struct('labels',labels,'groupNames',string(names), ...
    'participation',participation,'dominantParticipation',dominant, ...
    'groupSource',groupSource,'metricUsed',metricUsed, ...
    'overlapPolicy',"equal-share partition", ...
    'torsionInterpretation',"rotational-DOF proxy; inspect mode shapes for local-axis torsion");
end

function groups = inferPhysicalGroups(modelData,nDof)
groups = struct();
if ~isstruct(modelData) || ~isfield(modelData,'mesh') || ...
        ~isfield(modelData,'dofs') || ~isfield(modelData.dofs,'node')
    return
end
nodeMap = double(modelData.dofs.node);
nodeIds = double(modelData.mesh.nodes.id(:));
elements = modelData.mesh.elements;
if size(nodeMap,1) ~= numel(nodeIds), return; end

if isfield(elements,'type')
    type = lower(string(elements.type));
    towerNodes = connectedNodes(elements,type == "tower");
    towerRows = rowsForNodeIds(nodeIds,towerNodes);
    groups.tower = validDofs(nodeMap(towerRows,:),nDof);
end
if isfield(elements,'blade')
    blade = double(elements.blade(:));
    bladeNodes = connectedNodes(elements,blade > 0);
    bladeRows = rowsForNodeIds(nodeIds,bladeNodes);
    groups.blades = validDofs(nodeMap(bladeRows,:),nDof);
end

% Torsional participation is a DOF-type group, intentionally overlapping
% spatial groups; this permits a torsion label when rotations dominate.
if size(nodeMap,2) >= 6
    groups.torsion = validDofs(nodeMap(:,4:6),nDof);
end

masterIds = [];
if isfield(modelData,'rigidBodies') && isstruct(modelData.rigidBodies) && ...
        isfield(modelData.rigidBodies,'masters')
    masterIds = modelData.rigidBodies.masters;
end
masterRows = rowsForNodeIds(nodeIds,masterIds);
if ~isempty(masterRows)
    groups.drivetrain = validDofs(nodeMap(masterRows,:),nDof);
end

names = fieldnames(groups);
for k = numel(names):-1:1
    if isempty(groups.(names{k})), groups = rmfield(groups,names{k}); end
end
end

function nodes = connectedNodes(elements,mask)
nodes = unique([double(elements.nodeI(mask));double(elements.nodeJ(mask))]);
end

function rows = rowsForNodeIds(allIds,selectedIds)
[found,rows] = ismember(double(selectedIds(:)),allIds);
rows = unique(rows(found));
end

function idx = validDofs(values,nDof)
idx = unique(double(values(:)));
idx = idx(idx >= 1 & idx <= nDof);
end

function value = getOption(s,name,defaultValue)
value = defaultValue;
if isstruct(s) && isfield(s,name) && ~isempty(s.(name)), value = s.(name); end
end
