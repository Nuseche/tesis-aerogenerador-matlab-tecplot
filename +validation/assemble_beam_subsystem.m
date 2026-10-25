function [M, K, cache, diagnostics] = assemble_beam_subsystem(subsystem, cfg)
%ASSEMBLE_BEAM_SUBSYSTEM Assemble one compact beam using sparse triplets.

if nargin < 2
    cfg = struct();
end
n = 6*subsystem.numberOfNodes;
ne = subsystem.numberOfElements;
I = zeros(144*ne,1);
J = zeros(144*ne,1);
VK = zeros(144*ne,1);
VM = zeros(144*ne,1);
cache = cell(ne,1);

for element = 1:ne
    nodeI = subsystem.connectivity(element,1);
    nodeJ = subsystem.connectivity(element,2);
    xI = subsystem.xyz(nodeI,:);
    xJ = subsystem.xyz(nodeJ,:);
    auxiliaryPoint = subsystem.auxiliaryPoints(element,:);
    section = subsystem.sections(element);
    [ke, me, info] = elements.timoshenko3d_matrices( ...
        xI, xJ, auxiliaryPoint, section, cfg);
    elementDofs = [subsystem.dofs(nodeI,:) subsystem.dofs(nodeJ,:)];
    [ii,jj] = ndgrid(elementDofs, elementDofs);
    index = 144*(element-1) + (1:144);
    I(index) = ii(:);
    J(index) = jj(:);
    VK(index) = ke(:);
    VM(index) = me(:);
    cache{element} = info;
end

Kraw = sparse(I,J,VK,n,n);
Mraw = sparse(I,J,VM,n,n);
diagnostics = struct();
diagnostics.stiffnessSymmetryErrorBeforeCorrection = relativeSymmetry(Kraw);
diagnostics.massSymmetryErrorBeforeCorrection = relativeSymmetry(Mraw);
diagnostics.stiffnessNonzeros = nnz(Kraw);
diagnostics.massNonzeros = nnz(Mraw);
diagnostics.numberOfNodes = subsystem.numberOfNodes;
diagnostics.numberOfElements = ne;
diagnostics.totalLength = subsystem.totalLength;

tolerance = localCfg(cfg, {'validation','matrixSymmetry'}, ...
    localCfg(cfg, {'validation','symmetryTolerance'}, 1e-12));
if diagnostics.stiffnessSymmetryErrorBeforeCorrection > tolerance || ...
        diagnostics.massSymmetryErrorBeforeCorrection > tolerance
    error('validation:assemble_beam_subsystem:SymmetryFailure', ...
        ['Subsystem %s exceeds the pre-correction symmetry tolerance: ' ...
         'K %.3e, M %.3e, tolerance %.3e.'], subsystem.name, ...
        diagnostics.stiffnessSymmetryErrorBeforeCorrection, ...
        diagnostics.massSymmetryErrorBeforeCorrection, tolerance);
end
K = 0.5*(Kraw + Kraw.');
M = 0.5*(Mraw + Mraw.');
end

function value = relativeSymmetry(A)
value = norm(A-A.','fro')/max(norm(A,'fro'),eps);
end

function value = localCfg(cfg, path, fallback)
value = fallback;
cursor = cfg;
for index = 1:numel(path)
    if ~isstruct(cursor) || ~isfield(cursor,path{index})
        return
    end
    cursor = cursor.(path{index});
end
if isnumeric(cursor) && isscalar(cursor) && isfinite(cursor)
    value = double(cursor);
end
end
