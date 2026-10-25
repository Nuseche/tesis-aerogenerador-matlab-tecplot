function output=snapshot_input_case(csvFile,factors,dt,kind,chunkSize,durationLimit,excitationDirection,derivativeScale)
% Structural transfer at the inherited frozen operating point.
% Earthquake input: m/s^2 in global Y. Wind input: measured U in m/s.
% Wind output: per 1 kN MEAN thrust along the prescribed rotor axis.
if nargin<5,chunkSize=1000;end
if nargin<6,durationLimit=Inf;end
if nargin<7,excitationDirection=2;end
if nargin<8,derivativeScale=1;end
assert(ismember(excitationDirection,[1 2]),'Only explicit horizontal X or Y scenarios');
root='/Users/nuseche/Desktop/Tesis_codigos';addpath(root);addpath(fullfile(root,'cases'));
started=tic;study=sensitivity.config_local();cfg=study.nominal;
data=io.load_model_data(cfg);[data,cfg]=sensitivity.apply_parameters(data,cfg,factors);
oldRng=rng;cleanup=onCleanup(@()rng(oldRng));rng(study.seed,'twister');
md=model.build_model(data,cfg);model.validate_model(md,cfg);
[M,Ke]=assembly.assemble_structural_matrices(md,cfg);
M=assembly.apply_mass_formulation(M,cfg,md);M=rigid.add_body_masses(M,md,md.rigidBodies);
Tc=rigid.rigid_constraint_matrix(md,md.rigidBodies,cfg);
red=rigid.reduce_system(Tc,M,Ke,md,cfg);
if derivativeScale<0
    [~,Kzero]=equilibrium.total_lagrangian_internal_force(md,zeros(size(M,1),1),cfg);
    Kextra=red.full.Ke-Kzero;
    cfg.equilibrium.internalForceFcn=@(q,m,c)originalForce(q,m,c,Kextra);
    cfg.equilibrium.tangentFcn=@(q,m,c)diagnosticTangent(q,m,c,Kextra,abs(derivativeScale));
end
sweep=assembly.build_operating_sweep(md,red,cfg);ops=sweep.primaryOps;state=sweep.primaryState;
if derivativeScale>1
    % Numerical verification only: keep the original converged equilibrium
    % and replace ONLY the internal-energy Hessian in its stored tangent.
    [~,Koriginal]=equilibrium.total_lagrangian_internal_force(md,state.qFull,cfg);
    [~,Krefined]=diagnostic_internal_force(md,state.qFull,cfg,derivativeScale);
    state.tangentFull=state.tangentFull-Koriginal+Krefined;
    ops=assembly.build_operating_matrices(md,red,state,cfg);
end
assert(state.converged&&state.residualRelative<=study.equilibriumTolerance);
o=ops.reduced;T=o.Tc;Td=o.Tdot;Tdd=o.Tddot;
raw=readmatrix(csvFile);endTime=min(raw(end,1),raw(1,1)+durationLimit);
t=(raw(1,1):dt:endTime).';
if endTime-t(end)>1e-9,t(end+1)=endTime;end
u=interp1(raw(:,1),raw(:,2),t,'linear');
R=dynamics.influence_vector(md,excitationDirection,size(M,1));
baseFull=ops.full.M*R;baseOperator=T.'*baseFull;
fullUnit=zeros(size(M,1),1);
hub=find(md.mesh.nodes.id==130,1);fullUnit(md.dofs.node(hub,1:3))=1000*md.rotorAxis.direction(:);
windOperator=T.'*fullUnit;
initialQ=zeros(size(o.M,1),1);
if kind=="wind"
    % Interpolate the force shape computed at ORIGINAL measurement times.
    % Keep the 600 s sample-mean thrust parameter identical for every dt.
    shapeRaw=raw(:,2).^2/mean(raw(:,2).^2);
    forceShape=interp1(raw(:,1),shapeRaw,t,'linear');ag=zeros(size(t));
    initialQ=o.K\windOperator; % equilibrium of the SAME frozen linear operator
elseif kind=="earthquake"
    forceShape=zeros(size(t));ag=u;
else,error('inputs:UnknownKind','kind must be wind or earthquake');end
channels=[129 1;129 2;129 3;130 1;130 2;130 3;56 1;56 2;56 3;92 3;128 3];
dofs=zeros(size(channels,1),1);
for j=1:numel(dofs)
    row=find(md.mesh.nodes.id==channels(j,1),1);dofs(j)=md.dofs.node(row,channels(j,2));
end
Ta=T(dofs,:);Tda=Td(dofs,:);Tdda=Tdd(dofs,:);
MA=ops.full.M*T;
DV=2*ops.full.M*Td+ops.full.D*T;
KQ=ops.full.M*Tdd+ops.full.D*Td+ops.full.K*T;
checks=[norm(T.'*MA-o.M,'fro')/norm(o.M,'fro'), ...
    norm(T.'*DV-o.D,'fro')/norm(o.D,'fro'),norm(T.'*KQ-o.K,'fro')/norm(o.K,'fro')];
assert(max(checks)<1e-12,'Full/reduced operator projection mismatch');
fixed=md.dofs.fixed;MA=MA(fixed,:);DV=DV(fixed,:);KQ=KQ(fixed,:);
N=numel(t);historyQ=zeros(numel(dofs),N);historyA=historyQ;historyR=zeros(numel(fixed),N);
v=zeros(size(initialQ));a=[];q=initialQ;dynamicResidual=0;chunkCount=0;
for first=1:chunkSize:N-1
    ix=first:min(first+chunkSize,N);
    F=-baseOperator*ag(ix).'+windOperator*forceShape(ix).';
    opt=struct('beta',1/4,'gamma',1/2,'q0',q,'qd0',v);
    if ~isempty(a),opt.qdd0=a;end
    tr=dynamics.newmark_integrate(o.M,o.D,o.K,t(ix),F,opt);
    historyQ(:,ix)=Ta*tr.q;
    historyA(:,ix)=Ta*tr.qdd+2*Tda*tr.qd+Tdda*tr.q+R(dofs,:)*ag(ix).';
    historyR(:,ix)=MA*tr.qdd+DV*tr.qd+KQ*tr.q+ ...
        baseFull(fixed,:)*ag(ix).'-fullUnit(fixed)*forceShape(ix).';
    dynamicResidual=max(dynamicResidual,max(tr.relativeResidual));
    q=tr.q(:,end);v=tr.qd(:,end);a=tr.qdd(:,end);chunkCount=chunkCount+1;
end
assert(all(isfinite(historyQ),'all')&&all(isfinite(historyA),'all'));
output=struct('factors',factors,'kind',kind,'dt',dt,'t',t,'historyQ',historyQ, ...
    'historyA',historyA,'historyR',historyR,'channels',channels, ...
    'peakQ',max(abs(historyQ),[],2),'peakA',max(abs(historyA),[],2), ...
    'peakR',max(abs(historyR),[],2),'dynamicResidual',dynamicResidual, ...
    'equilibriumResidual',state.residualRelative,'configuration',cfg, ...
    'sourceCsv',string(csvFile),'chunkSize',chunkSize,'chunkCount',chunkCount, ...
    'excitationDirection',excitationDirection,'energyDerivativeScale',derivativeScale, ...
    'elapsedSeconds',toc(started),'projectionErrors',checks, ...
    'scope',"frozen_snapshot_structural_transfer_no_aerodynamic_feedback", ...
    'windUnitMeanThrustN',1000,'windLinearMeanState',initialQ, ...
    'windInitialPolicy',"mean thrust equilibrium; zero perturbation velocity; initial acceleration from equation", ...
    'groundBaselinePolicy',"preserve processed source; no extra correction or scaling", ...
    'rotorAxis',md.rotorAxis,'height',max(md.mesh.nodes.xyz(:,3)));
end
function f=originalForce(q,m,c,extra)
f=equilibrium.total_lagrangian_internal_force(m,q,c)+extra*q;
end
function K=diagnosticTangent(q,m,c,extra,scale)
[~,K]=diagnostic_internal_force(m,q,c,scale);K=K+extra;
end
