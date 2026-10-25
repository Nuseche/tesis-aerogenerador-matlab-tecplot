function [f,details,Kload] = centrifugal_loads(model,cfg,state)
%CENTRIFUGAL_LOADS Consistent loads for mass rotating at constant velocity.
%   Uses the quadratic expansion of the prescribed-spin kinetic potential
%   T0, including centroidal rotary inertia and offset curvature. The force
%   is grad(T0)|0 + Hess(T0)|0*q (small perturbations about the nominal spin).
%   Four-point quadrature matches consistent mass. Kload=dfCentrifugal/dq.
    if nargin<2,cfg=struct();end
    if nargin<3,state=struct();end
    [omega,axisPoint]=rotation(model,cfg,state);
    ndof=numberDofs(model);f=zeros(ndof,1);q=stateVector(state,ndof);
    Aomega=norm(omega)^2*eye(3)-omega*omega.';
    elementSet=model.mesh.elements;ne=elementCount(elementSet);
    eqLoads=zeros(ne,12);active=false(ne,1);
    I=zeros(144*ne+72,1);J=I;V=I;p=0;
    for e=1:ne
        if ~isRotatingElement(elementSet,e),continue,end
        [ni,nj,sid,aux]=elementData(elementSet,e);
        ids=double(model.mesh.nodes.id(:));ri=find(ids==ni,1);rj=find(ids==nj,1);
        if isempty(ri)||isempty(rj),error("equilibrium:centrifugal_loads:UnknownNode","Rotating element references an unknown node.");end
        xi=double(model.mesh.nodes.xyz(ri,:)).';xj=double(model.mesh.nodes.xyz(rj,:)).';
        section=findSection(model.sections,sid);
        if any(~isfinite(aux)),chord=xj-xi;basis=eye(3);[~,k]=min((basis.'*(chord/norm(chord))).^2);aux=(xi+basis(:,k)).';end
        [~,~,elementInfo]=elements.timoshenko3d_matrices( ...
            xi.',xj.',reshape(aux,1,3),section,cfg);
        dofs=elementDofs(model,e,ri,rj);
        [fe,ke]=consistentLineLoad(xi,xj,axisPoint,omega, ...
            elementInfo,section,q(dofs),cfg);
        f(dofs)=f(dofs)+fe;eqLoads(e,:)=fe.';active(e)=true;
        [ii,jj]=ndgrid(dofs,dofs);index=p+(1:144);
        I(index)=ii(:);J(index)=jj(:);V(index)=ke(:);p=p+144;
    end
    bodyReport=repmat(struct("name","","masterNode",NaN,"force",zeros(3,1),"moment",zeros(3,1)),0,1);
    for b=bodyList(model).'
        master=getMaster(b);if ~isRotatingBody(b,master),continue,end
        [~,d]=rigid.rigid_body_mass_matrix(b);row=find(double(model.mesh.nodes.id(:))==master,1);
        dofs=nodeDofs(model,row);
        position=double(model.mesh.nodes.xyz(row,:)).'-axisPoint;
        spin=elements.rotating_section_operators(d.mass,d.inertiaGlobalCG, ...
            d.cgOffsetGlobal,omega,position);
        kb=-spin.Kcentrifugal;
        generalized=spin.forceCentrifugal+kb*q(dofs);F=generalized(1:3);
        moment=generalized(4:6);f(dofs)=f(dofs)+generalized;
        [ii,jj]=ndgrid(dofs,dofs);index=p+(1:36);
        I(index)=ii(:);J(index)=jj(:);V(index)=kb(:);p=p+36;
        bodyReport(end+1,1)=struct("name",string(optional(b,"name","body")), ...
            "masterNode",master,"force",F,"moment",moment); %#ok<AGROW>
    end
    f=sparse(f);Kload=sparse(I(1:p),J(1:p),V(1:p),ndof,ndof);
    Kload=(Kload+Kload.')/2;
    details=struct("omega",omega,"axisPoint",axisPoint, ...
        "accelerationGradient",Aomega,"elementEquivalentLoads",eqLoads, ...
        "rotatingElements",active,"bodies",bodyReport, ...
        "loadNorm",norm(f),"tangentNorm",norm(Kload,'fro'), ...
        "configurationDependent",true,'quadratureOrder',4, ...
        'potential',"quadratic Taylor expansion of physical prescribed-spin T0", ...
        'rotaryInertiaIncluded',true,'offsetCurvatureIncluded',true, ...
        'coordinateFrame',"nominal_corotating_equilibrium_snapshot");
end

function [feGlobal,keGlobal]=consistentLineLoad(xi,xj,p,omega,info,section,qElement,cfg)
    [~,mass]=elements.section_mass(section,cfg);
    R=info.R;T=info.Te;L=info.L;
    feLocal=zeros(12,1);keLocal=zeros(12);
    [points,weights]=elements.gauss_rule(4);
    for k=1:numel(points)
        s=(points(k)+1)/2;
        N=elements.timoshenko_kinematic_matrix(points(k),L, ...
            info.formulation,info.phiY,info.phiZ);
        position=R*((1-s)*xi+s*xj-p);
        spin=elements.rotating_section_operators(mass.massPerLength, ...
            mass.centroidalInertia,mass.offset,R*omega,position);
        factor=weights(k)*L/2;
        feLocal=feLocal+factor*N.'*spin.forceCentrifugal;
        keLocal=keLocal-factor*N.'*spin.Kcentrifugal*N;
    end
    keGlobal=T.'*keLocal*T;
    feGlobal=T.'*feLocal+keGlobal*qElement;
    keGlobal=(keGlobal+keGlobal.')/2;
end
function [omega,p]=rotation(model,cfg,state)
    if isfield(state,"angularVelocity"),value=state.angularVelocity;
    elseif isfield(state,"omega"),value=state.omega;
    elseif isfield(cfg,"rotor")&&isfield(cfg.rotor,"speedRadPerSec"),value=cfg.rotor.speedRadPerSec;
    elseif isfield(cfg,"rotor")&&isfield(cfg.rotor,"speedRPM"),value=cfg.rotor.speedRPM*2*pi/60;
    else,value=0;end
    direction=[1;0;0];p=zeros(3,1);
    if isfield(model,"rotorAxis")
        if isfield(model.rotorAxis,"direction"),direction=double(model.rotorAxis.direction(:));end
        if isfield(model.rotorAxis,"point"),p=double(model.rotorAxis.point(:));end
    end
    if norm(direction)<=eps,error("equilibrium:centrifugal_loads:InvalidAxis","Rotor axis direction cannot be zero.");end
    direction=direction/norm(direction);
    if isscalar(value),omega=double(value)*direction;else,omega=double(value(:));end
    if numel(omega)~=3||any(~isfinite(omega)),error("equilibrium:centrifugal_loads:InvalidSpeed","Angular velocity must be finite.");end
end
function tf=isRotatingElement(el,e)
    tf=false;
    if isfield(el,"rotating"),tf=logical(at(el,"rotating",e));return,end
    if isfield(el,"blade"),tf=double(at(el,"blade",e))>0;return,end
    if isfield(el,"type"),type=lower(string(at(el,"type",e)));tf=contains(type,"blade")||contains(type,"rotor");end
end
function tf=isRotatingBody(b,master)
    if isfield(b,"rotating"),tf=logical(b.rotating);else,tf=(master==130);end
end
function [ni,nj,sid,aux]=elementData(el,e)
    ni=double(at(el,"nodeI",e));nj=double(at(el,"nodeJ",e));sid=at(el,"section",e);
    if isfield(el,"auxPoint"),f=el.auxPoint;if numel(el)>1,aux=double(el(e).auxPoint);else,aux=double(f(e,:));end
    else,aux=[NaN NaN NaN];end
end
function section=findSection(sections,sid)
    if isnumeric(sid)&&sid>=1&&sid<=numel(sections)&&sid==floor(sid),section=sections(sid);return,end
    for k=1:numel(sections),if isfield(sections(k),"id")&&string(sections(k).id)==string(sid),section=sections(k);return,end,end
    error("equilibrium:centrifugal_loads:UnknownSection","Unknown section %s.",string(sid));
end
function d=elementDofs(model,e,ri,rj)
    if isfield(model,"dofs")&&isfield(model.dofs,"element"),d=double(model.dofs.element(e,:));else,map=getMap(model);d=[map(ri,:) map(rj,:)];end
end
function d=nodeDofs(model,row)
    map=getMap(model);d=double(map(row,:));
end
function map=getMap(model)
    n=numel(model.mesh.nodes.id);if isfield(model,"dofs")&&isfield(model.dofs,"node"),map=model.dofs.node;else,map=reshape(1:6*n,6,n).';end
end
function n=numberDofs(model)
    if isfield(model,"dofs")&&isfield(model.dofs,"number"),n=double(model.dofs.number);else,map=getMap(model);n=max(map(:));end
end
function n=elementCount(el)
    if numel(el)>1,n=numel(el);else,n=numel(el.nodeI);end
end
function value=at(s,name,e)
    f=s.(name);if iscell(f),value=f{e};elseif numel(s)>1,value=s(e).(name);else,value=f(e);end
end
function list=bodyList(model)
    list=struct([]);if ~isfield(model,"rigidBodies"),return,end;rb=model.rigidBodies;if isfield(rb,"bodies"),list=rb.bodies;else,list=rb;end;list=list(:);
end
function master=getMaster(b)
    if isfield(b,"masterNode"),master=double(b.masterNode);elseif isfield(b,"node"),master=double(b.node);else,error("equilibrium:centrifugal_loads:MissingMaster","Body requires masterNode.");end
end
function x=optional(s,name,defaultValue)
    if isfield(s,name)&&~isempty(s.(name)),x=s.(name);else,x=defaultValue;end
end
function q=stateVector(state,n)
    q=zeros(n,1);
    if isfield(state,'qFull'),q=double(state.qFull(:));
    elseif isfield(state,'q')&&numel(state.q)==n,q=double(state.q(:));end
    if numel(q)~=n||any(~isfinite(q)),error('equilibrium:centrifugal_loads:InvalidState','State displacement must be a finite full vector.');end
end
function S=skew(r)
    r=double(r(:));S=[0 -r(3) r(2);r(3) 0 -r(1);-r(2) r(1) 0];
end
