function [M,Ke,cache,diagnostics] = assemble_structural_matrices(model,cfg)
%ASSEMBLE_STRUCTURAL_MATRICES Sparse global consistent mass and stiffness.
%   The triplet pass visits only active flexible elements.  Foundation and
%   drivetrain operators belong to later actions and are excluded whenever
%   cfg.assembly.flexibleOnly is true or analysis.type is Action 02.
if nargin<2,cfg=struct();end
[ndof,ne]=model_size(model);
maxTerms=144*ne;I=zeros(maxTerms,1);J=I;VM=I;VK=I;p=0;
lengths=zeros(ne,1);assembled=false(ne,1);
cache=repmat(cacheTemplate(),ne,1);
for e=1:ne
    c=element_context(model,e);
    if ~c.active,continue,end
    [ke,me,info]=elements.timoshenko3d_matrices( ...
        c.xI,c.xJ,c.auxPoint,c.section,cfg);
    [ii,jj]=ndgrid(c.dofs,c.dofs);idx=p+(1:144);
    I(idx)=ii(:);J(idx)=jj(:);VM(idx)=me(:);VK(idx)=ke(:);p=p+144;
    lengths(e)=localInfo(info,{'L','length'},norm(c.xJ-c.xI));
    assembled(e)=true;cache(e)=makeCache(c,ke,me,info);
end
M=sparse(I(1:p),J(1:p),VM(1:p),ndof,ndof);
Ke=sparse(I(1:p),J(1:p),VK(1:p),ndof,ndof);

flexibleOnly=isFlexibleOnly(cfg);
if flexibleOnly
    Mfoundation=sparse(ndof,ndof);Kfoundation=sparse(ndof,ndof);
    Kdrivetrain=sparse(ndof,ndof);
    foundationInfo=struct('enabled',false,'type',"excluded_action02", ...
        'nodeId',NaN,'massProvided',false,'stiffnessProvided',false);
    drivetrainInfo=struct('enabled',false,'nodeI',129,'nodeJ',130, ...
        'stiffnessProvided',false,'status',"excluded_action02");
else
    [Mfoundation,Kfoundation,foundationInfo]=foundationOperators(model,cfg,ndof);
    [Kdrivetrain,drivetrainInfo]=drivetrainOperator(model,cfg,ndof);
end
M=M+Mfoundation;Ke=Ke+Kfoundation+Kdrivetrain;

massSymmetryError=relativeSymmetry(M);
stiffnessSymmetryError=relativeSymmetry(Ke);
symmetryTolerance=cfgValue(cfg,{'validation','matrixSymmetry'}, ...
    cfgValue(cfg,{'validation','symmetryTolerance'},1e-10));
if massSymmetryError>symmetryTolerance || stiffnessSymmetryError>symmetryTolerance
    error('assembly:assemble_structural_matrices:SymmetryFailure', ...
        ['Pre-symmetrization errors exceed tolerance %.3e: ' ...
         'M %.3e, Ke %.3e.'],symmetryTolerance, ...
         massSymmetryError,stiffnessSymmetryError);
end
M=(M+M.')/2;Ke=(Ke+Ke.')/2;

disconnected=find(full(sum(spones(M)+spones(Ke),2))==0);
expected=expectedDetachedDofs(model);
unexpected=setdiff(disconnected,expected);
if ~isempty(unexpected)
    error('assembly:assemble_structural_matrices:DisconnectedDofs', ...
        'Unexpected disconnected global DOFs: %s.', ...
        char(strjoin(string(unexpected.'),', ')));
end
diagnostics=struct("elementLengths",lengths,"assembled",assembled, ...
    "massSymmetryError",massSymmetryError, ...
    "stiffnessSymmetryError",stiffnessSymmetryError, ...
    "symmetryTolerance",symmetryTolerance, ...
    "massNonzeros",nnz(M),"stiffnessNonzeros",nnz(Ke), ...
    "flexibleOnly",flexibleOnly,"disconnectedDofs",disconnected, ...
    "expectedDisconnectedDofs",intersect(disconnected,expected), ...
    "unexpectedDisconnectedDofs",unexpected, ...
    "foundation",foundationInfo,"drivetrain",drivetrainInfo, ...
    "components",struct("Mfoundation",Mfoundation, ...
    "Kfoundation",Kfoundation,"Kdrivetrain",Kdrivetrain));
end

function value=cfgValue(cfg,path,fallback)
value=fallback;cursor=cfg;
for k=1:numel(path)
    if ~isstruct(cursor)||~isfield(cursor,path{k}),return,end
    cursor=cursor.(path{k});
end
if isnumeric(cursor)&&isscalar(cursor)&&isfinite(cursor),value=double(cursor);end
end
function tf=isFlexibleOnly(cfg)
tf=false;
if isfield(cfg,'assembly')&&isfield(cfg.assembly,'flexibleOnly')
    tf=logical(cfg.assembly.flexibleOnly);
end
if isfield(cfg,'analysis')&&isfield(cfg.analysis,'type')
    tf=tf||any(lower(string(cfg.analysis.type))== ...
        ["action02","action_02","timoshenko_action02"]);
end
end
function value=relativeSymmetry(A)
value=norm(A-A.',"fro")/max(norm(A,"fro"),eps);
end
function expected=expectedDetachedDofs(model)
expected=zeros(0,1);
if ~isfield(model,'rigidBodies')||~isfield(model.rigidBodies,'masters'),return,end
ids=double(model.mesh.nodes.id(:));
for id=double(model.rigidBodies.masters(:)).'
    row=find(ids==id,1);
    if isempty(row),continue,end
    if isfield(model,'dofs')&&isfield(model.dofs,'node')
        expected=[expected;double(model.dofs.node(row,:)).']; %#ok<AGROW>
    else
        expected=[expected;(6*(row-1)+(1:6)).']; %#ok<AGROW>
    end
end
expected=unique(expected);
end
function t=cacheTemplate()
t=struct('assembled',false,'id',NaN,'nodeI',NaN,'nodeJ',NaN, ...
    'sectionId',NaN,'component',"",'blade',0,'dofs',zeros(1,12), ...
    'L',NaN,'R',eye(3),'Te',eye(12),'KeLocal',zeros(12), ...
    'MeLocal',zeros(12),'KeGlobal',zeros(12),'MeGlobal',zeros(12), ...
    'gauss',struct(),'symmetryErrorK',NaN,'symmetryErrorM',NaN, ...
    'minMassEigenvalue',NaN,'rigidModeCount',NaN,'formulation',"");
end
function entry=makeCache(c,ke,me,info)
entry=cacheTemplate();entry.assembled=true;entry.id=c.id;
entry.nodeI=c.nodeI;entry.nodeJ=c.nodeJ;entry.sectionId=c.sectionId;
entry.component=c.type;entry.blade=c.blade;entry.dofs=c.dofs;
entry.L=localInfo(info,{'L','length'},norm(c.xJ-c.xI));
entry.R=localInfo(info,{'R'},eye(3));
entry.Te=localInfo(info,{'Te','transformation'},eye(12));
entry.KeLocal=localInfo(info,{'KeLocal','Klocal'},entry.Te*ke*entry.Te.');
entry.MeLocal=localInfo(info,{'MeLocal','Mlocal'},entry.Te*me*entry.Te.');
entry.KeGlobal=ke;entry.MeGlobal=me;
entry.gauss=localInfo(info,{'gauss'},struct());
entry.symmetryErrorK=localInfo(info,{'symmetryErrorK'},relativeSymmetry(ke));
entry.symmetryErrorM=localInfo(info,{'symmetryErrorM'},relativeSymmetry(me));
entry.minMassEigenvalue=localInfo(info,{'minMassEigenvalue'}, ...
    min(eig((full(me)+full(me).')/2)));
entry.rigidModeCount=localInfo(info,{'rigidModeCount'},NaN);
entry.formulation=string(localInfo(info,{'formulation'},"unspecified"));
end
function value=localInfo(info,names,fallback)
value=fallback;
for k=1:numel(names)
    if isstruct(info)&&isfield(info,names{k})&&~isempty(info.(names{k}))
        value=info.(names{k});return
    end
end
end

function [Mf,Kf,info]=foundationOperators(model,cfg,n)
    Mf=sparse(n,n);Kf=sparse(n,n);type="fixed";
    if isfield(cfg,"base")&&isfield(cfg.base,"type"),type=lower(string(cfg.base.type));end
    enabled=any(type==["flexible","soft","stiff"]);
    info=struct("enabled",enabled,"type",type,"nodeId",NaN,"massProvided",false,"stiffnessProvided",false);
    if ~enabled,return,end
    if ~isfield(cfg,"foundation"),return,end
    nodeId=baseNode(model,cfg);dofs=nodeDofs(model,nodeId);info.nodeId=nodeId;
    if isfield(cfg.foundation,"M")&&~isempty(cfg.foundation.M)
        A=smallOperator(cfg.foundation.M,n,dofs,"foundation mass");Mf=A;info.massProvided=true;
    end
    if isfield(cfg.foundation,"K")&&~isempty(cfg.foundation.K)
        A=smallOperator(cfg.foundation.K,n,dofs,"foundation stiffness");Kf=A;info.stiffnessProvided=true;
    end
end
function [Kd,info]=drivetrainOperator(model,cfg,n)
    Kd=sparse(n,n);info=struct("enabled",false,"nodeI",129,"nodeJ",130,"stiffnessProvided",false);
    if ~isfield(cfg,"drivetrain")||~isfield(cfg.drivetrain,"stiffness")||isempty(cfg.drivetrain.stiffness),return,end
    ids=double(model.mesh.nodes.id(:));if ~all(ismember([129;130],ids)),return,end
    values=double(cfg.drivetrain.stiffness);
    if isvector(values)&&numel(values)==6,K6=diag(values);elseif isequal(size(values),[6 6]),K6=values;else,error("assembly:assemble_structural_matrices:InvalidDrivetrain","cfg.drivetrain.stiffness must have six entries or be 6-by-6.");end
    if any(~isfinite(K6(:)))||min(eig((K6+K6.')/2))<0,error("assembly:assemble_structural_matrices:InvalidDrivetrain","Drivetrain stiffness must be finite, symmetric and positive semidefinite.");end
    if isfield(cfg.drivetrain,"orientation")&&~isempty(cfg.drivetrain.orientation)
        R=double(cfg.drivetrain.orientation);if ~isequal(size(R),[3 3])||norm(R*R.'-eye(3),"fro")>1e-10,error("assembly:assemble_structural_matrices:InvalidDrivetrainFrame","Drivetrain orientation must be orthonormal.");end
        Q=blkdiag(R,R);K6=Q.'*K6*Q;
    end
    [B,dofs,kinematics]=assembly.drivetrain_relative_kinematics(model,129,130);
    K12=B.'*K6*B;
    Kd(dofs,dofs)=sparse(K12);info.enabled=nnz(K6)>0;
    info.stiffnessProvided=true;info.matrix=K12;
    info.offsetGlobal=kinematics.offsetGlobal;
    info.objectivity=kinematics;
    info.relativeKinematicMatrix=B;
end
function A=smallOperator(value,n,dofs,label)
    value=sparse(value);if isequal(size(value),[n n]),A=value;return,end
    if ~isequal(size(value),[6 6])||any(~isfinite(nonzeros(value))),error("assembly:assemble_structural_matrices:InvalidFoundation","%s must be global or 6-by-6.",label);end
    A=sparse(n,n);A(dofs,dofs)=value;
end
function id=baseNode(model,cfg)
    if isfield(cfg,"foundation")&&isfield(cfg.foundation,"nodeId"),id=double(cfg.foundation.nodeId);
    elseif isfield(model,"boundaryConditions")&&isfield(model.boundaryConditions,"fixedNodeIds"),id=double(model.boundaryConditions.fixedNodeIds(1));
    else,id=double(model.mesh.nodes.id(1));end
end
function dofs=nodeDofs(model,id)
    row=find(double(model.mesh.nodes.id(:))==id,1);if isempty(row),error("assembly:assemble_structural_matrices:UnknownNode","Node %g does not exist.",id);end
    if isfield(model,"dofs")&&isfield(model.dofs,"node"),dofs=double(model.dofs.node(row,:));else,dofs=6*(row-1)+(1:6);end
end
