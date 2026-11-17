function result=weak_coupling_integrate(operatorFcn,forceFcn,time,options)
%WEAK_COUPLING_INTEGRATE One aerodynamic evaluation per step; predicted feedback.
% The mechanical solve is implicit average-acceleration Newmark. No claim of
% unconditional stability is made for the explicitly exchanged aeroelastic load.
t=time(:);dt=diff(t);
if numel(t)<2||any(~isfinite(t))||any(dt<=0),error('dynamics:CouplingTime','Time must be finite and increasing.');end
meanStep=mean(dt);uniformStep=max(abs(dt-meanStep))<=1e-10*max(1,meanStep);
op=operatorFcn(t(1));n=size(op.M,1);q=zeros(n,1);v=q;
if isfield(options,'q0'),q=options.q0;end
if isfield(options,'v0'),v=options.v0;end
q=q(:);v=v(:);
if numel(q)~=n||numel(v)~=n||any(~isfinite([q;v]))
    error('dynamics:CouplingInitialState','Initial displacement and velocity must be finite n-vectors.');
end
stride=options.outputStride;keep=unique([1:stride:numel(t),numel(t)]);ns=numel(keep);
Q=zeros(n,ns);V=Q;A=Q;F=Q;rotation=zeros(1,ns);alphaMin=rotation;alphaMax=rotation;
[fa,report]=forceFcn(t(1),q,v,op);f=op.baseForce+fa;a=op.M\(f-op.D*v-op.K*q);
Q(:,1)=q;V(:,1)=v;A(:,1)=a;F(:,1)=fa;rotation(1)=report.maxElasticRotation;
alphaMin(1)=min(report.alphaRad);alphaMax(1)=max(report.alphaRad);cursor=2;
maxResidual=0;cached=[];previous=[];clock=tic;
status="completed";terminationTime=t(end);acceptedSteps=0;evaluations=1;
maximumRotation=report.maxElasticRotation;attemptedRotation=maximumRotation;
returnPartial=isfield(options,'returnPartialOnDomainExit')&&options.returnPartialOnDomainExit;
for k=1:numel(t)-1
    h=meanStep;if ~uniformStep,h=dt(k);end
    op=operatorFcn(t(k+1));
    qPredict=q+h*v+.5*h*h*a;vPredict=v+h*a;
    [fa,report]=forceFcn(t(k+1),qPredict,vPredict,op);evaluations=evaluations+1;
    % Solve for acceleration to avoid recovering it from nearly equal q values.
    % This is algebraically the same average-acceleration Newmark step.
    f=op.baseForce+fa;qBar=q+h*v+h*h/4*a;vBar=v+h/2*a;
    Keff=op.M+h/2*op.D+h*h/4*op.K;
    rhs=f-op.D*vBar-op.K*qBar;
    if isempty(cached)||~isequal(Keff,previous),cached=decomposition(Keff,'lu');previous=Keff;end
    aNew=cached\rhs;qNew=qBar+h*h/4*aNew;vNew=vBar+h/2*aNew;
    residual=op.M*aNew+op.D*vNew+op.K*qNew-f;
    relative=norm(residual)/max(norm(f)+norm(op.M*aNew)+norm(op.D*vNew)+norm(op.K*qNew),eps);
    maxResidual=max(maxResidual,relative);
    actualRotation=report.maxElasticRotation;
    if isfield(options,'rotationMap')
        actualRotation=max(actualRotation,max(vecnorm(reshape(options.rotationMap*qNew,3,[]),2,1)));
    end
    if any(~isfinite([qNew;vNew;aNew]))
        error('dynamics:CouplingRange','Nonfinite response at t=%.6g s.',t(k+1));
    end
    attemptedRotation=actualRotation;
    if actualRotation>options.maxElasticRotation
        if returnPartial
            status="rotation_limit";terminationTime=t(k+1);break
        end
        error('dynamics:CouplingRange','Elastic rotation exceeds configured domain at t=%.6g s.',t(k+1));
    end
    maximumRotation=max(maximumRotation,actualRotation);acceptedSteps=k;
    q=qNew;v=vNew;a=aNew;
    if cursor<=ns&&k+1==keep(cursor)
        Q(:,cursor)=q;V(:,cursor)=v;A(:,cursor)=a;F(:,cursor)=fa;
        rotation(cursor)=actualRotation;alphaMin(cursor)=min(report.alphaRad);alphaMax(cursor)=max(report.alphaRad);cursor=cursor+1;
    end
end
stored=1:cursor-1;
result=struct('t',t(keep(stored)),'q',Q(:,stored),'qd',V(:,stored),'qdd',A(:,stored),'aerodynamicForce',F(:,stored), ...
    'maximumMechanicalResidual',maxResidual,'maxElasticRotation',rotation(stored), ...
    'maximumAcceptedRotation',maximumRotation,'attemptedRotation',attemptedRotation, ...
    'status',status,'terminationTime',terminationTime,'lastAcceptedTime',t(acceptedSteps+1), ...
    'alphaMinRad',alphaMin(stored),'alphaMaxRad',alphaMax(stored),'elapsedSeconds',toc(clock), ...
    'aerodynamicEvaluations',evaluations,'integrationSteps',acceptedSteps, ...
    'method',"partitioned_weak_predictor_Newmark",'subiterations',0, ...
    'unconditionalCoupledStabilityClaimed',false,'loadState',"second_order_displacement_first_order_velocity_predictor");
end
