function [Kg,axialForces] = assemble_geometric_stiffness(model,state,cfg)
%ASSEMBLE_GEOMETRIC_STIFFNESS Assemble initial-stress beam-column terms.
%   Axial force is positive in tension. It is read from state or recovered
%   from state.qFull/state.q using the elastic axial deformation.
    if nargin<2||isempty(state),state=struct();end
    if nargin<3,cfg=struct();end %#ok<NASGU>
    [ndof,ne]=model_size(model);axialForces=getAxialForces(model,state,ne);
    I=zeros(144*ne,1);J=I;V=I;p=0;
    for e=1:ne
        c=element_context(model,e);if ~c.active,continue,end
        kg=elements.geometric_stiffness(c.xI,c.xJ,c.auxPoint, ...
            axialForces(e),c.section);
        [ii,jj]=ndgrid(c.dofs,c.dofs);idx=p+(1:144);
        I(idx)=ii(:);J(idx)=jj(:);V(idx)=kg(:);p=p+144;
    end
    Kg=sparse(I(1:p),J(1:p),V(1:p),ndof,ndof);Kg=(Kg+Kg.')/2;
end

function N=getAxialForces(model,state,ne)
    names=["elementAxialForce","elementAxialForces","axialForce","axialForces"];
    for name=names
        if isfield(state,name),N=double(state.(name)(:));break,end
    end
    if ~exist("N","var"),N=zeros(ne,1);end
    if numel(N)~=ne,error("assembly:assemble_geometric_stiffness:InvalidAxialForces","Expected one axial force per element.");end
    if all(N==0)
        q=[];
        if isfield(state,"qFull"),q=state.qFull;elseif isfield(state,"q"),q=state.q;end
        if ~isempty(q)
            for e=1:ne
                c=element_context(model,e);if ~c.active,continue,end
                [~,T,L]=elements.element_rotation_matrix(c.xI,c.xJ,c.auxPoint);
                ql=T*double(q(c.dofs));N(e)=c.section.EA*(ql(7)-ql(1))/L;
            end
        end
    end
end
