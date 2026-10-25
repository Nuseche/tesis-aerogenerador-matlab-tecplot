function dofs = build_dof_map(mesh, boundaryConditions)
%BUILD_DOF_MAP Create deterministic six-DOF node and element maps.
%   Nodal order is [ux uy uz rx ry rz].

arguments
    mesh (1,1) struct
    boundaryConditions (1,1) struct = struct('fixedNodeIds', [])
end

nodeIds = mesh.nodes.id(:);
nNodes = numel(nodeIds);
nElements = numel(mesh.elements.id);
nodeDofs = reshape(1:(6*nNodes), 6, nNodes).';

[foundI, rowI] = ismember(mesh.elements.nodeI(:), nodeIds);
[foundJ, rowJ] = ismember(mesh.elements.nodeJ(:), nodeIds);
if ~all(foundI & foundJ)
    error('model:build_dof_map:UnknownConnectivity', ...
        'Cannot build element DOFs because a node ID is missing.');
end
elementDofs = [nodeDofs(rowI,:), nodeDofs(rowJ,:)];

if isfield(boundaryConditions, 'fixedNodeIds')
    [foundFixed, fixedRows] = ismember(boundaryConditions.fixedNodeIds(:), nodeIds);
    if ~all(foundFixed)
        error('model:build_dof_map:UnknownFixedNode', ...
            'A fixed node ID is absent from the mesh.');
    end
else
    fixedRows = zeros(0,1);
end
fixed = reshape(nodeDofs(fixedRows,:).', [], 1);
fixed = unique(fixed, 'stable');
allDofs = (1:(6*nNodes)).';
free = setdiff(allDofs, fixed, 'stable');

dofs = struct();
dofs.order = ["ux", "uy", "uz", "rx", "ry", "rz"];
dofs.perNode = 6;
dofs.number = 6*nNodes;
dofs.nodeIds = nodeIds;
dofs.node = nodeDofs;
dofs.element = elementDofs;
dofs.fixed = fixed;
dofs.free = free;
dofs.full = allDofs;
dofs.ndof = dofs.number;
dofs.elementCount = nElements;
end
