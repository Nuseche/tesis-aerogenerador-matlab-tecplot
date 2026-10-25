function [ndof,ne]=model_size(model)
    if isfield(model,"dofs")&&isfield(model.dofs,"number"),ndof=double(model.dofs.number);
    elseif isfield(model,"dofs")&&isfield(model.dofs,"node"),ndof=max(double(model.dofs.node(:)));
    else,ndof=6*numel(model.mesh.nodes.id);end
    el=model.mesh.elements;
    if numel(el)>1,ne=numel(el);else,ne=numel(el.nodeI);end
end
