function varargout=rotating_constraint_derivatives( ...
        model,bodies,azimuth,omega,options)
%ROTATING_CONSTRAINT_DERIVATIVES Time-dependent rigid root constraints.
%   RESULT = rigid.rotating_constraint_derivatives(MODEL,BODIES,PSI,OMEGA,OPT)
%   returns T, Tdot and Tddot for qFull=T*qIndependent when a rotating
%   master's slave offsets turn about MODEL.rotorAxis. Translational and
%   rotational perturbation components are expressed in inertial axes.
%
%   [T,Tdot,Tddot,INFO] = ... is the equivalent multiple-output API.
%   OMEGA and OPT.angularAcceleration may be signed scalars about the rotor
%   axis or three-vectors parallel to it.

if nargin<2||isempty(bodies)
    if isfield(model,'rigidBodies'),bodies=model.rigidBodies;
    else,bodies=struct();end
end
if nargin<3||isempty(azimuth),azimuth=0;end
if nargin<4||isempty(omega),omega=0;end
if nargin<5||isempty(options),options=struct();end
if ~isscalar(azimuth)||~isnumeric(azimuth)||~isfinite(azimuth)
    error('rigid:rotating_constraint_derivatives:InvalidAzimuth', ...
        'azimuth must be a finite scalar in radians.');
end

[~,staticInfo]=rigid.rigid_constraint_matrix(model,bodies,struct());
[axis,axisPoint]=rotorAxis(model,options,omega);
omegaVector=axisVector(omega,axis,'omega');
alphaValue=option(options,'angularAcceleration',option(options,'alpha',0));
alphaVector=axisVector(alphaValue,axis,'angularAcceleration');
W=skew(omegaVector);Wdot=skew(alphaVector);
R=axisRotation(axis,double(azimuth));

nodeIds=double(model.mesh.nodes.id(:));xyz=double(model.mesh.nodes.xyz);
dofMap=getDofMap(model,numel(nodeIds));ndof=max(dofMap(:));
independent=double(staticInfo.independentDofs(:));nIndependent=numel(independent);
columnOf=double(staticInfo.fullToReduced(:));
T=sparse(ndof,nIndependent);Tdot=sparse(ndof,nIndependent);
Tddot=sparse(ndof,nIndependent);
T(independent,:)=speye(nIndependent);

slaveIds=double(staticInfo.slaveNodeIds(:));
masterIds=double(staticInfo.masterNodeBySlave(:));nSlave=numel(slaveIds);
offsetReference=zeros(nSlave,3);offsetCurrent=zeros(nSlave,3);
offsetVelocity=zeros(nSlave,3);offsetAcceleration=zeros(nSlave,3);
rotating=false(nSlave,1);
for index=1:nSlave
    slaveRow=find(nodeIds==slaveIds(index),1);
    masterRow=find(nodeIds==masterIds(index),1);
    slaveDofs=dofMap(slaveRow,:);masterDofs=dofMap(masterRow,:);
    masterColumns=columnOf(masterDofs);
    if any(masterColumns==0)
        error('rigid:rotating_constraint_derivatives:DependentMaster', ...
            'Master node %d contains dependent DOFs.',masterIds(index));
    end
    r0=(xyz(slaveRow,:)-xyz(masterRow,:)).';
    rotating(index)=isRotatingMaster(bodies,masterIds(index));
    if rotating(index)
        r=R*r0;rdot=W*r;rddot=(Wdot+W*W)*r;
    else
        r=r0;rdot=zeros(3,1);rddot=zeros(3,1);
    end
    B=[eye(3),-skew(r);zeros(3),eye(3)];
    Bdot=[zeros(3),-skew(rdot);zeros(3,6)];
    Bddot=[zeros(3),-skew(rddot);zeros(3,6)];
    T(slaveDofs,masterColumns)=B;
    Tdot(slaveDofs,masterColumns)=Bdot;
    Tddot(slaveDofs,masterColumns)=Bddot;
    offsetReference(index,:)=r0.';offsetCurrent(index,:)=r.';
    offsetVelocity(index,:)=rdot.';offsetAcceleration(index,:)=rddot.';
end

info=struct('T',T,'Tdot',Tdot,'Tddot',Tddot, ...
    'azimuth',double(azimuth),'angularVelocity',omegaVector, ...
    'angularAcceleration',alphaVector,'axis',axis,'point',axisPoint, ...
    'independentDofs',independent,'fullToReduced',columnOf, ...
    'slaveNodeIds',slaveIds,'masterNodeBySlave',masterIds, ...
    'rotatingConstraint',rotating,'offsetReference',offsetReference, ...
    'offsetCurrent',offsetCurrent,'offsetVelocity',offsetVelocity, ...
    'offsetAcceleration',offsetAcceleration, ...
    'coordinateConvention', ...
    "inertial perturbations; rotating nominal slave offsets about rotorAxis");
if nargout<=1
    varargout{1}=info;
else
    varargout{1}=T;
    if nargout>=2,varargout{2}=Tdot;end
    if nargout>=3,varargout{3}=Tddot;end
    if nargout>=4,varargout{4}=info;end
end
end

function [axis,point]=rotorAxis(model,options,omega)
axis=[];point=zeros(3,1);
if isstruct(options)&&isfield(options,'axis')&&~isempty(options.axis)
    axis=double(options.axis(:));
elseif isfield(model,'rotorAxis')&&isfield(model.rotorAxis,'direction')
    axis=double(model.rotorAxis.direction(:));
end
if isstruct(options)&&isfield(options,'point')&&~isempty(options.point)
    point=double(options.point(:));
elseif isfield(model,'rotorAxis')&&isfield(model.rotorAxis,'point')
    point=double(model.rotorAxis.point(:));
end
if isempty(axis)
    candidate=double(omega(:));
    if numel(candidate)==3&&all(isfinite(candidate))&&norm(candidate)>0
        axis=candidate/norm(candidate);
    else
        axis=[1;0;0];
    end
end
if numel(axis)~=3||any(~isfinite(axis))||norm(axis)==0|| ...
        numel(point)~=3||any(~isfinite(point))
    error('rigid:rotating_constraint_derivatives:InvalidAxis', ...
        'A finite nonzero rotor axis and finite axis point are required.');
end
axis=axis/norm(axis);
end

function vector=axisVector(value,axis,label)
value=double(value);
if isscalar(value)
    if ~isfinite(value),invalidVector(label);end
    vector=value*axis;
else
    vector=value(:);
    if numel(vector)~=3||any(~isfinite(vector)),invalidVector(label);end
    transverse=vector-axis*(axis.'*vector);
    if norm(transverse)>1e-10*max(norm(vector),1)
        error('rigid:rotating_constraint_derivatives:NonAxialRate', ...
            '%s must be parallel to the rotor axis.',label);
    end
end
end

function invalidVector(label)
error('rigid:rotating_constraint_derivatives:InvalidRate', ...
    '%s must be a finite scalar or three-vector.',label);
end

function R=axisRotation(axis,angle)
S=skew(axis);R=eye(3)+sin(angle)*S+(1-cos(angle))*(S*S);
end

function tf=isRotatingMaster(bodies,master)
tf=false;list=struct([]);
if isstruct(bodies)&&isfield(bodies,'bodies'),list=bodies.bodies;
elseif isstruct(bodies),list=bodies;end
for index=1:numel(list)
    body=list(index);candidate=NaN;
    if isfield(body,'masterNode'),candidate=double(body.masterNode);
    elseif isfield(body,'node'),candidate=double(body.node);end
    if candidate~=master,continue,end
    if isfield(body,'rotating'),tf=logical(body.rotating);
    else,tf=(master==130);end
    return
end
end

function map=getDofMap(model,n)
if isfield(model,'dofs')&&isfield(model.dofs,'node')
    map=double(model.dofs.node);
else
    map=reshape(1:6*n,6,n).';
end
if ~isequal(size(map),[n 6])
    error('rigid:rotating_constraint_derivatives:InvalidDofMap', ...
        'model.dofs.node must be N-by-6.');
end
end

function value=option(source,name,fallback)
value=fallback;
if isstruct(source)&&isfield(source,name)&&~isempty(source.(name))
    value=source.(name);
end
end

function S=skew(vector)
S=[0 -vector(3) vector(2);vector(3) 0 -vector(1); ...
    -vector(2) vector(1) 0];
end
