function [B,dofs,diagnostics] = drivetrain_relative_kinematics(model,nodeI,nodeJ)
%DRIVETRAIN_RELATIVE_KINEMATICS Offset-aware relative 6-DOF motion.
%   delta=B*[qI;qJ] compares node J with the frame at I transported across
%   their geometric offset. It is objective for infinitesimal rigid motion.

if nargin<2,nodeI=129;end
if nargin<3,nodeJ=130;end
ids=double(model.mesh.nodes.id(:));xyz=double(model.mesh.nodes.xyz);
rowI=find(ids==nodeI,1);rowJ=find(ids==nodeJ,1);
if isempty(rowI)||isempty(rowJ)
    error('assembly:drivetrain_relative_kinematics:UnknownNode', ...
        'Both drivetrain nodes must exist in the mesh.');
end
dofsI=nodeDofs(model,rowI);dofsJ=nodeDofs(model,rowJ);dofs=[dofsI dofsJ];
offset=(xyz(rowJ,:)-xyz(rowI,:)).';S=skew(offset);
B=zeros(6,12);
B(1:3,1:3)=-eye(3);B(1:3,4:6)=S;B(1:3,7:9)=eye(3);
B(4:6,4:6)=-eye(3);B(4:6,10:12)=eye(3);
rigidTranslation=[ones(3,1);zeros(3,1);ones(3,1);zeros(3,1)];
translationResidual=norm(B*rigidTranslation);
rotationResidual=0;
for axisIndex=1:3
    theta=zeros(3,1);theta(axisIndex)=1;
    rigidRotation=[zeros(3,1);theta;cross(theta,offset);theta];
    rotationResidual=max(rotationResidual,norm(B*rigidRotation));
end
diagnostics=struct('nodeI',nodeI,'nodeJ',nodeJ,'offsetGlobal',offset, ...
    'translationObjectivityResidual',translationResidual, ...
    'rotationObjectivityResidual',rotationResidual);
end

function dofs=nodeDofs(model,row)
if isfield(model,'dofs')&&isfield(model.dofs,'node')
    dofs=double(model.dofs.node(row,:));
else
    dofs=6*(row-1)+(1:6);
end
end

function S=skew(v)
S=[0 -v(3) v(2);v(3) 0 -v(1);-v(2) v(1) 0];
end
