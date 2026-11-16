% Numerical diagnostic copy; original solver remains unchanged. Only derivative step is varied.
function [fInternal,Kt,details]=diagnostic_internal_force(model,qFull,cfg,scale)
%TOTAL_LAGRANGIAN_INTERNAL_FORCE Corotational Timoshenko internal operator.
%   A current element frame removes rigid translation/rotation. The accepted
%   local Timoshenko stiffness acts on deformational corotated coordinates.
%   Force and tangent are numerical first/second derivatives of one scalar
%   energy, preserving a consistent solver contract for large rotations and
%   small strains.

if nargin<3,cfg=struct();end
qFull=double(qFull(:));
[dofMap,ndof]=localDofMap(model);
if numel(qFull)~=ndof||any(~isfinite(qFull))
    error('equilibrium:total_lagrangian_internal_force:InvalidState', ...
        'qFull must be a finite full-DOF vector.');
end
elementSet=model.mesh.elements;ne=localElementCount(elementSet);
fInternal=zeros(ndof,1);I=zeros(144*ne,1);J=I;V=I;p=0;
axialForce=zeros(ne,1);greenStrain=zeros(ne,1);
strainEnergy=zeros(ne,1);active=false(ne,1);
for element=1:ne
    context=localContext(model,elementSet,element,dofMap);
    if ~context.active,continue,end
    [KeGlobal,~,info]=elements.timoshenko3d_matrices( ...
        context.xI,context.xJ,context.auxPoint,context.section,cfg);
    qe=qFull(context.dofs);L=info.L;
    energyFcn=@(value)localCorotationalEnergy(value,context.xI, ...
        context.xJ,info.R,info.KeLocal,L);
    if norm(qe,inf)<=1e-14
        fElement=KeGlobal*qe;Kglobal=KeGlobal;energy=0;
    else
        [fElement,Kglobal,energy]=localEnergyDerivatives(energyFcn,qe,L,scale);
    end
    fInternal(context.dofs)=fInternal(context.dofs)+fElement;
    [ii,jj]=ndgrid(context.dofs,context.dofs);index=p+(1:144);
    I(index)=ii(:);J(index)=jj(:);V(index)=Kglobal(:);p=p+144;

    currentChord=(context.xJ(:)+qe(7:9))- ...
        (context.xI(:)+qe(1:3));
    currentLength=norm(currentChord);
    extension=currentLength-L;
    axialForce(element)=double(context.section.EA)*extension/L;
    greenStrain(element)=.5*((currentLength/L)^2-1);
    strainEnergy(element)=energy;active(element)=true;
end
Kt=sparse(I(1:p),J(1:p),V(1:p),ndof,ndof);Kt=(Kt+Kt.')/2;
details=struct('elementAxialForces',axialForce, ...
    'elementGreenStrain',greenStrain,'elementStrainEnergy',strainEnergy, ...
    'totalStrainEnergy',sum(strainEnergy),'activeElements',active, ...
    'formulation',"numerically differentiated corotational Timoshenko energy", ...
    'rotationRange',"large rigid rotation, small deformational strain", ...
    'derivativeMethod',"central finite differences of scalar element energy");
end

function [gradient,hessian,energy0]=localEnergyDerivatives(energyFcn,q,L,scale)
n=numel(q);energy0=energyFcn(q);gradient=zeros(n,1);hessian=zeros(n);
translationStep=scale*2e-6*max(L,1);rotationStep=scale*2e-6;
step=rotationStep*ones(n,1);step([1:3 7:9])=translationStep;
plus=zeros(n,1);minus=zeros(n,1);
for i=1:n
    qp=q;qm=q;qp(i)=qp(i)+step(i);qm(i)=qm(i)-step(i);
    plus(i)=energyFcn(qp);minus(i)=energyFcn(qm);
    gradient(i)=(plus(i)-minus(i))/(2*step(i));
    hessian(i,i)=(plus(i)-2*energy0+minus(i))/step(i)^2;
end
for i=1:n-1
    for j=i+1:n
        qpp=q;qpm=q;qmp=q;qmm=q;
        qpp([i j])=qpp([i j])+[step(i);step(j)];
        qpm(i)=qpm(i)+step(i);qpm(j)=qpm(j)-step(j);
        qmp(i)=qmp(i)-step(i);qmp(j)=qmp(j)+step(j);
        qmm([i j])=qmm([i j])-[step(i);step(j)];
        value=(energyFcn(qpp)-energyFcn(qpm)-energyFcn(qmp)+ ...
            energyFcn(qmm))/(4*step(i)*step(j));
        hessian(i,j)=value;hessian(j,i)=value;
    end
end
hessian=(hessian+hessian.')/2;
end

function energy=localCorotationalEnergy(q,xI,xJ,R0,Klocal,L)
uI=q(1:3);thetaI=q(4:6);uJ=q(7:9);thetaJ=q(10:12);
currentI=xI(:)+uI;currentJ=xJ(:)+uJ;
chord=currentJ-currentI;currentLength=norm(chord);
if currentLength<=1e-9*L
    error('equilibrium:total_lagrangian_internal_force:CollapsedElement', ...
        'Corotational element length collapsed.');
end
e1=chord/currentLength;
averageRotation=.5*(thetaI+thetaJ);
Qaverage=localRotationExponential(averageRotation);
e3Candidate=Qaverage*R0(3,:).';
e3=e3Candidate-e1*(e1.'*e3Candidate);
if norm(e3)<=1e-10
    e3Candidate=Qaverage*R0(2,:).';
    e3=e3Candidate-e1*(e1.'*e3Candidate);
end
e3=e3/norm(e3);e2=cross(e3,e1);e2=e2/norm(e2);e3=cross(e1,e2);
Rcurrent=[e1.';e2.';e3.'];
Qreference=R0.';Qcurrent=Rcurrent.';
frameRotation=localRotationVector(Qcurrent*Qreference.');
thetaIDeformation=Rcurrent*(thetaI-frameRotation);
thetaJDeformation=Rcurrent*(thetaJ-frameRotation);
qDeformation=zeros(12,1);
qDeformation(4:6)=thetaIDeformation;
qDeformation(7)=currentLength-L;
qDeformation(10:12)=thetaJDeformation;
energy=.5*qDeformation.'*Klocal*qDeformation;
end

function Q=localRotationExponential(vector)
angle=norm(vector);
if angle<1e-10
    S=localSkew(vector);Q=eye(3)+S+.5*S*S;return
end
axis=vector/angle;S=localSkew(axis);
Q=eye(3)+sin(angle)*S+(1-cos(angle))*(S*S);
end

function vector=localRotationVector(Q)
cosine=max(-1,min(1,(trace(Q)-1)/2));angle=acos(cosine);
if angle<1e-8
    vector=.5*[Q(3,2)-Q(2,3);Q(1,3)-Q(3,1);Q(2,1)-Q(1,2)];
elseif pi-angle<1e-6
    [V,D]=eig((Q+eye(3))/2);[~,index]=max(real(diag(D)));
    axis=real(V(:,index));axis=axis/norm(axis);vector=angle*axis;
else
    axis=[Q(3,2)-Q(2,3);Q(1,3)-Q(3,1);Q(2,1)-Q(1,2)]/(2*sin(angle));
    vector=angle*axis;
end
end

function S=localSkew(vector)
S=[0 -vector(3) vector(2);vector(3) 0 -vector(1); ...
    -vector(2) vector(1) 0];
end

function context=localContext(model,elementData,element,dofMap)
ids=double(model.mesh.nodes.id(:));xyz=double(model.mesh.nodes.xyz);
nodeI=double(localAt(elementData,'nodeI',element));
nodeJ=double(localAt(elementData,'nodeJ',element));
rowI=find(ids==nodeI,1);rowJ=find(ids==nodeJ,1);
if isempty(rowI)||isempty(rowJ)
    error('equilibrium:total_lagrangian_internal_force:UnknownNode', ...
        'Element %d references an unknown node.',element);
end
aux=[NaN NaN NaN];
if isfield(elementData,'auxPoint')
    if numel(elementData)>1,aux=double(elementData(element).auxPoint);
    else,aux=double(elementData.auxPoint(element,:));end
end
if any(~isfinite(aux)),aux=localDefaultAux(xyz(rowI,:),xyz(rowJ,:));end
section=localSection(model.sections,localAt(elementData,'section',element));
if isfield(model,'dofs')&&isfield(model.dofs,'element')
    dofs=double(model.dofs.element(element,:));
else
    dofs=[dofMap(rowI,:) dofMap(rowJ,:)];
end
active=true;
if isfield(elementData,'active'),active=logical(localAt(elementData,'active',element));end
context=struct('xI',xyz(rowI,:),'xJ',xyz(rowJ,:),'auxPoint',aux, ...
    'section',section,'dofs',dofs,'active',active);
end

function section=localSection(sections,id)
if isnumeric(id)&&isscalar(id)&&id>=1&&id<=numel(sections)&&id==fix(id)
    section=sections(id);return
end
for index=1:numel(sections)
    if isfield(sections(index),'id')&&string(sections(index).id)==string(id)
        section=sections(index);return
    end
end
error('equilibrium:total_lagrangian_internal_force:UnknownSection', ...
    'Unknown section %s.',string(id));
end

function value=localAt(s,name,index)
field=s.(name);
if iscell(field),value=field{index};
elseif numel(s)>1,value=s(index).(name);
else,value=field(index);end
end

function count=localElementCount(elementData)
if numel(elementData)>1,count=numel(elementData);else,count=numel(elementData.nodeI);end
end

function aux=localDefaultAux(xI,xJ)
direction=(xJ-xI).';direction=direction/norm(direction);
basis=eye(3);[~,index]=min((basis.'*direction).^2);
aux=xI+basis(:,index).';
end

function [map,ndof]=localDofMap(model)
n=numel(model.mesh.nodes.id);
if isfield(model,'dofs')&&isfield(model.dofs,'node')
    map=double(model.dofs.node);
else
    map=reshape(1:6*n,6,n).';
end
ndof=max(map(:));
end
