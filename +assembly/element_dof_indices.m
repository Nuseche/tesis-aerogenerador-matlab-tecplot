function edofs = element_dof_indices(model,elementIndex)
%ELEMENT_DOF_INDICES Return the twelve global DOFs of one beam element.

arguments
    model (1,1) struct
    elementIndex (1,1) double {mustBeInteger,mustBePositive}
end

elements = model.mesh.elements;
nElements = numel(elements.nodeI);
if elementIndex > nElements
    error('assembly:element_dof_indices:IndexOutOfRange', ...
        'Element row %d exceeds the mesh size %d.',elementIndex,nElements);
end
if isfield(model,'dofs') && isfield(model.dofs,'element') && ...
        size(model.dofs.element,1) >= elementIndex
    edofs = double(model.dofs.element(elementIndex,:));
else
    ids = double(model.mesh.nodes.id(:));
    [found,rows] = ismember(double([elements.nodeI(elementIndex), ...
        elements.nodeJ(elementIndex)]),ids);
    if ~all(found)
        error('assembly:element_dof_indices:UnknownNode', ...
            'Element row %d references an unknown node.',elementIndex);
    end
    if isfield(model,'dofs') && isfield(model.dofs,'node')
        nodeMap = double(model.dofs.node);
    else
        nodeMap = reshape(1:6*numel(ids),6,[]).';
    end
    edofs = [nodeMap(rows(1),:) nodeMap(rows(2),:)];
end
if numel(edofs) ~= 12 || any(~isfinite(edofs)) || ...
        any(edofs ~= fix(edofs)) || any(edofs < 1) || numel(unique(edofs)) ~= 12
    error('assembly:element_dof_indices:InvalidMap', ...
        'Element row %d does not map to twelve unique positive DOFs.',elementIndex);
end
edofs = reshape(edofs,1,12);
end
