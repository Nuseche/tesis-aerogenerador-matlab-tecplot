function subsystem = extract_beam_subsystem(modelData, elementSelector, rootNodeId, name)
%EXTRACT_BEAM_SUBSYSTEM Extract and topologically order one unbranched beam.
%   The returned model is compact and contains only the selected elements.
%   Reassembling it avoids the artificial boundary stiffness obtained by
%   taking a principal submatrix of an already assembled connected model.

if nargin < 4 || strlength(string(name)) == 0
    name = "beam";
end

mesh = modelData.mesh;
nElements = numel(mesh.elements.id);
if islogical(elementSelector)
    if numel(elementSelector) ~= nElements
        error('validation:extract_beam_subsystem:InvalidSelector', ...
            'Logical selector length must equal the number of mesh elements.');
    end
    selectedRows = find(elementSelector(:));
else
    selectedRows = double(elementSelector(:));
end
if isempty(selectedRows) || any(selectedRows < 1 | selectedRows > nElements | ...
        selectedRows ~= fix(selectedRows))
    error('validation:extract_beam_subsystem:InvalidSelector', ...
        'The subsystem selector must identify at least one valid element row.');
end

nodeI = double(mesh.elements.nodeI(selectedRows));
nodeJ = double(mesh.elements.nodeJ(selectedRows));
allNodeIds = unique([nodeI;nodeJ], 'stable');
[foundI, localI] = ismember(nodeI, allNodeIds);
[foundJ, localJ] = ismember(nodeJ, allNodeIds);
if ~all(foundI & foundJ)
    error('validation:extract_beam_subsystem:UnknownNode', ...
        'Selected elements reference a node absent from the compact map.');
end

degree = accumarray([localI;localJ], 1, [numel(allNodeIds),1]);
endpoints = allNodeIds(degree == 1);
if numel(endpoints) ~= 2 || any(degree > 2) || ...
        numel(allNodeIds) ~= numel(selectedRows) + 1
    error('validation:extract_beam_subsystem:NotAChain', ...
        ['Subsystem %s is not one connected, unbranched open chain ' ...
         '(%d elements, %d nodes, %d endpoints).'], ...
        string(name), numel(selectedRows), numel(allNodeIds), numel(endpoints));
end
if ~ismember(rootNodeId, endpoints)
    error('validation:extract_beam_subsystem:InvalidRoot', ...
        'Root node %g is not an endpoint of subsystem %s.', rootNodeId, string(name));
end

% Traverse from the prescribed physical root. Element row order and node IDs
% are not assumed to be contiguous or already sorted.
orderedRows = zeros(numel(selectedRows),1);
orderedNodeIds = zeros(numel(allNodeIds),1);
orderedNodeIds(1) = rootNodeId;
used = false(numel(selectedRows),1);
current = rootNodeId;
for station = 1:numel(selectedRows)
    candidates = find(~used & (nodeI == current | nodeJ == current));
    if numel(candidates) ~= 1
        error('validation:extract_beam_subsystem:TraversalFailed', ...
            'Expected one unused continuation at node %g of subsystem %s.', ...
            current, string(name));
    end
    localElement = candidates(1);
    used(localElement) = true;
    orderedRows(station) = selectedRows(localElement);
    if nodeI(localElement) == current
        next = nodeJ(localElement);
    else
        next = nodeI(localElement);
    end
    orderedNodeIds(station+1) = next;
    current = next;
end
if current ~= endpoints(endpoints ~= rootNodeId)
    error('validation:extract_beam_subsystem:TraversalFailed', ...
        'Traversal of subsystem %s did not terminate at its opposite endpoint.', ...
        string(name));
end

[nodesFound, sourceNodeRows] = ismember(orderedNodeIds, mesh.nodes.id(:));
if ~all(nodesFound)
    error('validation:extract_beam_subsystem:UnknownNode', ...
        'Subsystem %s contains a node absent from mesh.nodes.', string(name));
end
[~, compactI] = ismember(double(mesh.elements.nodeI(orderedRows)), orderedNodeIds);
[~, compactJ] = ismember(double(mesh.elements.nodeJ(orderedRows)), orderedNodeIds);

sectionIds = mesh.elements.section(orderedRows);
sections = repmat(modelData.sections(1), numel(orderedRows), 1);
for element = 1:numel(orderedRows)
    sections(element) = findSection(modelData.sections, sectionIds(element));
end

if isfield(mesh.elements, 'auxPoint')
    auxiliaryPoints = double(mesh.elements.auxPoint(orderedRows,:));
else
    auxiliaryPoints = nan(numel(orderedRows),3);
end

subsystem = struct();
subsystem.name = string(name);
subsystem.sourceElementRows = orderedRows;
subsystem.sourceElementIds = mesh.elements.id(orderedRows);
subsystem.sourceNodeIds = orderedNodeIds;
subsystem.sourceNodeRows = sourceNodeRows;
subsystem.rootNodeId = rootNodeId;
subsystem.tipNodeId = orderedNodeIds(end);
subsystem.rootLocalNode = 1;
subsystem.tipLocalNode = numel(orderedNodeIds);
subsystem.xyz = double(mesh.nodes.xyz(sourceNodeRows,:));
subsystem.connectivity = [compactI compactJ];
subsystem.auxiliaryPoints = auxiliaryPoints;
subsystem.sectionIds = sectionIds;
subsystem.sections = sections;
subsystem.numberOfNodes = numel(orderedNodeIds);
subsystem.numberOfElements = numel(orderedRows);
subsystem.dofs = reshape(1:6*subsystem.numberOfNodes, 6, []).';
subsystem.rootDofs = subsystem.dofs(subsystem.rootLocalNode,:);
subsystem.tipDofs = subsystem.dofs(subsystem.tipLocalNode,:);
subsystem.lengths = vecnorm( ...
    subsystem.xyz(compactJ,:) - subsystem.xyz(compactI,:), 2, 2);
subsystem.totalLength = sum(subsystem.lengths);
end

function section = findSection(sections, sectionId)
if isnumeric(sectionId) && isscalar(sectionId) && sectionId >= 1 && ...
        sectionId <= numel(sections) && sectionId == fix(sectionId)
    candidate = sections(sectionId);
    if ~isfield(candidate, 'id') || isequal(double(candidate.id), double(sectionId))
        section = candidate;
        return
    end
end
if isfield(sections, 'id')
    for index = 1:numel(sections)
        if string(sections(index).id) == string(sectionId)
            section = sections(index);
            return
        end
    end
end
error('validation:extract_beam_subsystem:UnknownSection', ...
    'Section %s was not found.', string(sectionId));
end
