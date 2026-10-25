function tests=test_seismic_rotating_constraints
tests=functiontests(localfunctions);
end

function testProjectedReactionsUseMovingConstraintDerivatives(testCase)
[ops,model,cfg]=movingSnapshotSystem();
response=dynamics.run_seismic_analysis(ops,model,cfg);
T=ops.reduced.Tc;Td=ops.reduced.Tdot;Tdd=ops.reduced.Tddot;
q=T*response.q;v=T*response.qd+Td*response.q;
a=T*response.qdd+2*Td*response.qd+Tdd*response.q;
verifyEqual(testCase,response.fullRelative.q,q,'AbsTol',1e-14);
verifyEqual(testCase,response.fullRelative.qd,v,'AbsTol',1e-14);
verifyEqual(testCase,response.fullRelative.qdd,a,'AbsTol',1e-14);
fullForce=-ops.full.M*response.GammaFullAbsolute*response.accelerogram.acceleration.';
expected=ops.full.M*a+ops.full.D*v+ops.full.K*q-fullForce;
verifyEqual(testCase,response.reactions,expected,'AbsTol',2e-13);
verifyLessThan(testCase,response.reactionDiagnostics.relativeProjectedResidual,1e-10);
verifyEqual(testCase,T.'*response.reactions,response.equilibriumResidual,'AbsTol',5e-13);
% Omitting the derivatives is measurably wrong even though Newmark solves
% its frozen reduced equation accurately.
constantMapResidual=ops.full.M*(T*response.qdd)+ ...
    ops.full.D*(T*response.qd)+ops.full.K*q-fullForce;
verifyGreaterThan(testCase,norm(T.'*constantMapResidual,'fro'),1e-2);
verifyFalse(testCase,response.integrationMetadata.isLTVIntegration);
verifyEqual(testCase,response.integrationMetadata.operatorPolicy,"frozen_operating_point");
end

function testRecoveredAccelerationIsDerivativeOfLocalMovingMap(testCase)
[ops,model,cfg,transformation]=movingSnapshotSystem();
response=dynamics.run_seismic_analysis(ops,model,cfg);
response=dynamics.recover_full_response(response,fullRecoveryOps(ops),model);
k=4;q=response.q(:,k);v=response.qd(:,k);a=response.qdd(:,k);
localTrajectory=@(tau)transformation(tau)*(q+tau*v+tau^2*a/2);
h=1e-4;center=localTrajectory(0);plus=localTrajectory(h);minus=localTrajectory(-h);
velocity=(plus-minus)/(2*h);acceleration=(plus-2*center+minus)/h^2;
verifyEqual(testCase,response.qdFull(:,k),velocity,'AbsTol',2e-8);
verifyEqual(testCase,response.qddFull(:,k),acceleration,'AbsTol',2e-7);
verifyTrue(testCase,response.kinematicRecovery.hasMovingConstraintDerivatives);
verifyEqual(testCase,response.kinematicRecovery.transformationPolicy, ...
    "single_operating_point_snapshot");
% This is a derivative at the local snapshot, not a finite difference of
% an LTV trajectory over the complete frozen-operator Newmark history.
end

function testFullRecoveryPreservesAbsoluteMotionAndSupportRows(testCase)
[ops,model,cfg]=movingSnapshotSystem();
response=dynamics.run_seismic_analysis(ops,model,cfg);
fullConstraintForce=response.reactions;
response=dynamics.recover_full_response(response,fullRecoveryOps(ops),model);
verifyEqual(testCase,response.reactions,fullConstraintForce(model.dofs.fixed,:), ...
    'AbsTol',1e-14);
verifyEqual(testCase,response.constraintForcesFull,fullConstraintForce,'AbsTol',1e-14);
verifyEqual(testCase,response.qddFull,response.fullRelative.qdd,'AbsTol',0);
verifyEqual(testCase,response.absoluteDisplacementFull, ...
    response.qFull+response.GammaFull*response.accelerogram.displacement.', ...
    'AbsTol',1e-14);
verifyEqual(testCase,response.absoluteVelocityFull, ...
    response.qdFull+response.GammaFull*response.accelerogram.velocity.', ...
    'AbsTol',1e-14);
verifyEqual(testCase,response.absoluteAccelerationFull, ...
    response.qddFull+response.GammaFull*response.accelerogram.acceleration.', ...
    'AbsTol',1e-14);
verifyEqual(testCase,response.GammaFull,response.GammaFullAbsolute,'AbsTol',0);
end

function testConstantTransformationRemainsBackwardCompatible(testCase)
T=[zeros(2);eye(2)];response=struct('t',[0;1;2], ...
    'q',[1 2 3;4 5 6],'qd',[.2 .4 .6;.1 .3 .5], ...
    'qdd',[.02 .04 .06;.01 .03 .05]);
result=dynamics.recover_full_response(response,struct('Tc',T),struct());
verifyEqual(testCase,result.qFull,T*response.q,'AbsTol',0);
verifyEqual(testCase,result.qdFull,T*response.qd,'AbsTol',0);
verifyEqual(testCase,result.qddFull,T*response.qdd,'AbsTol',0);
verifyFalse(testCase,result.kinematicRecovery.hasMovingConstraintDerivatives);
end

function testInvalidDerivativeDimensionsAreRejected(testCase)
response=struct('t',[0;1],'q',zeros(2),'qd',zeros(2),'qdd',zeros(2));
ops=struct('Tc',eye(2),'Tdot',ones(3,2));
verifyError(testCase,@()dynamics.recover_full_response(response,ops,struct()), ...
    'dynamics:RecoverFull:InvalidTransformationDerivative');
end

function [ops,model,cfg,transformation]=movingSnapshotSystem()
W=skew([.4;-.2;.7]);W6=blkdiag(W,W);
R=expm(skew([.2;-.1;.3]));R6=blkdiag(R,R);
transformation=@(tau)[zeros(6);expm(tau*W6)*R6];
T=sparse(transformation(0));Td=sparse([zeros(6);W6*R6]);
Tdd=sparse([zeros(6);W6*W6*R6]);
M=spdiags((1:.1:2.1).',0,12,12);M(1,7)=.12;M(7,1)=.12;
D=.08*speye(12);K=spdiags((30:41).',0,12,12);
K(1,7)=-2;K(7,1)=-2;
ops.full=struct('M',M,'D',D,'K',K);
ops.reduced=struct('M',T.'*M*T,'D',T.'*(D*T+2*M*Td), ...
    'K',T.'*(K*T+D*Td+M*Tdd),'Tc',T,'Tdot',Td,'Tddot',Tdd);
model.dofs.node=reshape(1:12,6,2).';model.dofs.fixed=(1:6).';
model.fullFixed=model.dofs.fixed;model.Tc=T;model.nDof=6;
model.dofMap=model.dofs.node;
t=(0:.01:.1).';cfg.seismic.record=struct('t',t, ...
    'acceleration',ones(size(t)),'velocity',t,'displacement',t.^2/2);
cfg.seismic.directions=1;cfg.seismic.baselineCorrection="none";
cfg.newmark=struct('q0',.01*(1:6).','qd0',.02*(6:-1:1).');
end

function recovery=fullRecoveryOps(ops)
recovery=ops.reduced;recovery.Mfull=ops.full.M;
recovery.Dfull=ops.full.D;recovery.Kfull=ops.full.K;
end

function S=skew(v)
S=[0 -v(3) v(2);v(3) 0 -v(1);-v(2) v(1) 0];
end
