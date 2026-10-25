function [KOmega,centrifugalAxialForces] = assemble_centrifugal_stiffness(model,state,cfg)
%ASSEMBLE_CENTRIFUGAL_STIFFNESS Explicit centrifugal initial-stress terms.
%   This function only uses forces explicitly identified as centrifugal.
%   build_operating_matrices omits it when state declares that those forces
%   are already included in Kg, preventing double counting.
    if nargin<2||isempty(state),state=struct();end
    if nargin<3,cfg=struct();end %#ok<NASGU>
    [ndof,ne]=model_size(model);centrifugalAxialForces=zeros(ne,1);
    names=["elementCentrifugalAxialForce","elementCentrifugalAxialForces", ...
        "centrifugalAxialForce","centrifugalAxialForces"];
    for name=names
        if isfield(state,name),centrifugalAxialForces=double(state.(name)(:));break,end
    end
    if numel(centrifugalAxialForces)~=ne
        error("assembly:assemble_centrifugal_stiffness:InvalidForces","Expected one centrifugal axial force per element.");
    end
    I=zeros(144*ne,1);J=I;V=I;p=0;
    for e=1:ne
        c=element_context(model,e);if ~c.active,continue,end
        kg=elements.geometric_stiffness(c.xI,c.xJ,c.auxPoint, ...
            centrifugalAxialForces(e),c.section);
        [ii,jj]=ndgrid(c.dofs,c.dofs);idx=p+(1:144);I(idx)=ii(:);J(idx)=jj(:);V(idx)=kg(:);p=p+144;
    end
    KOmega=sparse(I(1:p),J(1:p),V(1:p),ndof,ndof);KOmega=(KOmega+KOmega.')/2;
end
