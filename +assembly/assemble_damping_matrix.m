function [C,parts] = assemble_damping_matrix(model,M,Ke,state,cfg)
%ASSEMBLE_DAMPING_MATRIX Traced structural, foundation and connector damping.
%   Rayleigh damping uses the elastic reference Ke. Aerodynamic damping is
%   carried separately and may be nonsymmetric; passive mechanical parts
%   are never silently symmetrized.

if nargin<4||isempty(state),state=struct();end
if nargin<5,cfg=struct();end
ndof=size(M,1);M=sparse(M);Ke=sparse(Ke);
Cstruct=sparse(ndof,ndof);Cfoundation=sparse(ndof,ndof);
Caero=sparse(ndof,ndof);calibration=struct('method',"coefficients", ...
    'alpha',0,'beta',0,'targetFrequenciesHz',zeros(0,1), ...
    'targetDampingRatios',zeros(0,1),'recoveredDampingRatios',zeros(0,1));

damping=struct();if isfield(cfg,'damping'),damping=cfg.damping;end
if isfield(damping,'matrix')&&~isempty(damping.matrix)
    Cstruct=checkedMatrix(damping.matrix,ndof,'structural damping');
    calibration.method="direct_matrix";
else
    [alpha,beta,calibration]=rayleighCoefficients(damping);
    Cstruct=alpha*M+beta*Ke;
end

if isfield(state,'Cfoundation')&&~isempty(state.Cfoundation)
    Cfoundation=checkedMatrix(state.Cfoundation,ndof,'foundation damping');
elseif isfield(model,'foundation')&&isfield(model.foundation,'C')&& ...
        ~isempty(model.foundation.C)
    Cfoundation=embedFoundation(model,model.foundation.C,ndof);
elseif isfield(cfg,'foundation')&&isfield(cfg.foundation,'C')&& ...
        ~isempty(cfg.foundation.C)
    Cfoundation=embedFoundation(model,cfg.foundation.C,ndof);
end
if isfield(state,'Caero')&&~isempty(state.Caero)
    Caero=checkedMatrix(state.Caero,ndof,'aerodynamic damping');
elseif isfield(cfg,'aerodynamics')&&isfield(cfg.aerodynamics,'Caero')&& ...
        ~isempty(cfg.aerodynamics.Caero)
    Caero=checkedMatrix(cfg.aerodynamics.Caero,ndof,'aerodynamic damping');
end
[Cdrivetrain,drivetrainInfo]=drivetrainDamping(model,cfg,ndof);
C=Cstruct+Cfoundation+Caero+Cdrivetrain;
parts=struct('structural',Cstruct,'foundation',Cfoundation, ...
    'aerodynamic',Caero,'drivetrain',Cdrivetrain, ...
    'rayleigh',calibration,'drivetrainKinematics',drivetrainInfo, ...
    'componentIdentityError',norm(C-(Cstruct+Cfoundation+Caero+Cdrivetrain),'fro'));
end

function [alpha,beta,info]=rayleighCoefficients(damping)
alpha=readScalar(damping,["alpha","rayleighAlpha"],0);
beta=readScalar(damping,["beta","rayleighBeta"],0);
rayleigh=struct();if isfield(damping,'rayleigh'),rayleigh=damping.rayleigh;end
alpha=readScalar(rayleigh,"alpha",alpha);beta=readScalar(rayleigh,"beta",beta);
frequencies=[];zetas=[];
if isfield(rayleigh,'targetFrequenciesHz')
    frequencies=double(rayleigh.targetFrequenciesHz(:));
elseif isfield(damping,'targetFrequenciesHz')
    frequencies=double(damping.targetFrequenciesHz(:));
end
if isfield(rayleigh,'targetDampingRatios')
    zetas=double(rayleigh.targetDampingRatios(:));
elseif isfield(damping,'targetDampingRatios')
    zetas=double(damping.targetDampingRatios(:));
end
method="coefficients";recovered=zeros(0,1);
if ~isempty(frequencies)||~isempty(zetas)
    if numel(frequencies)~=2||numel(zetas)~=2|| ...
            any(~isfinite(frequencies))||any(frequencies<=0)|| ...
            frequencies(1)==frequencies(2)||any(~isfinite(zetas))||any(zetas<0)
        error('assembly:assemble_damping_matrix:InvalidRayleighTargets', ...
            'Rayleigh calibration requires two distinct positive frequencies and two nonnegative damping ratios.');
    end
    omega=2*pi*frequencies;
    coefficients=[1./(2*omega),omega/2]\zetas;
    alpha=coefficients(1);beta=coefficients(2);
    if any(~isfinite(coefficients))||any(coefficients<-1e-14)
        error('assembly:assemble_damping_matrix:NonPassiveRayleighFit', ...
            'Requested targets produce negative Rayleigh coefficients.');
    end
    alpha=max(alpha,0);beta=max(beta,0);
    recovered=alpha./(2*omega)+beta*omega/2;method="two_target_fit";
end
info=struct('method',method,'alpha',alpha,'beta',beta, ...
    'targetFrequenciesHz',frequencies,'targetDampingRatios',zetas, ...
    'recoveredDampingRatios',recovered);
end

function [Cd,info]=drivetrainDamping(model,cfg,n)
Cd=sparse(n,n);info=struct('enabled',false,'offsetGlobal',zeros(3,1), ...
    'relativeKinematicMatrix',zeros(6,12), ...
    'translationObjectivityResidual',0,'rotationObjectivityResidual',0);
if ~isfield(cfg,'drivetrain')||~isfield(cfg.drivetrain,'damping')|| ...
        isempty(cfg.drivetrain.damping),return,end
ids=double(model.mesh.nodes.id(:));if ~all(ismember([129;130],ids)),return,end
value=double(cfg.drivetrain.damping);
if isvector(value)&&numel(value)==6,C6=diag(value);
elseif isequal(size(value),[6 6]),C6=value;
else,error('assembly:assemble_damping_matrix:InvalidDrivetrain', ...
        'Drivetrain damping must have six entries or be 6-by-6.');end
if any(~isfinite(C6(:)))||norm(C6-C6.','fro')>1e-11*max(norm(C6,'fro'),1)|| ...
        min(eig((C6+C6.')/2))<-1e-12*max(norm(C6,'fro'),1)
    error('assembly:assemble_damping_matrix:InvalidDrivetrain', ...
        'Drivetrain damping must be finite, symmetric and positive semidefinite.');
end
if isfield(cfg.drivetrain,'orientation')&&~isempty(cfg.drivetrain.orientation)
    R=double(cfg.drivetrain.orientation);
    if ~isequal(size(R),[3 3])||norm(R*R.'-eye(3),'fro')>1e-10||det(R)<=0
        error('assembly:assemble_damping_matrix:InvalidDrivetrainFrame', ...
            'Drivetrain orientation must be right-handed and orthonormal.');
    end
    Q=blkdiag(R,R);C6=Q.'*C6*Q;
end
[B,dofs,kinematics]=assembly.drivetrain_relative_kinematics(model,129,130);
Cd(dofs,dofs)=sparse(B.'*C6*B);info=kinematics;
info.enabled=nnz(C6)>0;info.relativeKinematicMatrix=B;
end

function A=checkedMatrix(A,n,label)
A=sparse(A);
if ~isequal(size(A),[n n])||any(~isfinite(nonzeros(A)))
    error('assembly:assemble_damping_matrix:InvalidMatrix', ...
        '%s matrix has invalid size or values.',label);
end
end

function value=readScalar(s,names,fallback)
value=fallback;
for name=string(names)
    if isstruct(s)&&isfield(s,name)&&~isempty(s.(name))
        value=double(s.(name));break
    end
end
if ~isscalar(value)||~isfinite(value)||value<0
    error('assembly:assemble_damping_matrix:InvalidRayleigh', ...
        'Rayleigh coefficients must be finite and nonnegative.');
end
end

function Cf=embedFoundation(model,Csmall,n)
Csmall=sparse(Csmall);if isequal(size(Csmall),[n n]),Cf=Csmall;return,end
node=1;
if isfield(model,'foundation')&&isfield(model.foundation,'nodeId')
    node=model.foundation.nodeId;
end
row=find(double(model.mesh.nodes.id(:))==node,1);
if isempty(row),error('assembly:assemble_damping_matrix:UnknownFoundationNode', ...
        'Foundation node does not exist.');end
if isfield(model,'dofs')&&isfield(model.dofs,'node')
    dofs=double(model.dofs.node(row,:));
else,dofs=6*(row-1)+(1:6);end
if ~isequal(size(Csmall),[6 6])||any(~isfinite(nonzeros(Csmall)))
    error('assembly:assemble_damping_matrix:InvalidFoundation', ...
        'Foundation C must be global or a finite 6-by-6 matrix.');
end
Cf=sparse(n,n);Cf(dofs,dofs)=Csmall;
end
