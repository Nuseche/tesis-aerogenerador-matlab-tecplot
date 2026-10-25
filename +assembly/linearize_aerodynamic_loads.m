function [Kaero,Caero,report] = linearize_aerodynamic_loads(model,state,cfg,nDof)
%LINEARIZE_AERODYNAMIC_LOADS Return unsymmetrized LHS force tangents.
%   Kaero=-df_a/dq and Caero=-df_a/dqd. Explicit zero matrices count as an
%   intentional source and are not confused with an absent source.

Kaero=sparse(nDof,nDof);Caero=sparse(nDof,nDof);
report=struct('method',"zero_unprovided",'status',"unprovided", ...
    'evaluations',0,'signConvention', ...
    "Kaero=-df/dq, Caero=-df/dqd",'activeDofs',zeros(0,1), ...
    'coarseFineRelativeK',0,'coarseFineRelativeC',0, ...
    'positionRelativeStep',NaN,'velocityRelativeStep',NaN);
if isfield(cfg,'aerodynamics')&&isfield(cfg.aerodynamics,'status')
    report.status=string(cfg.aerodynamics.status);
end

stateK=isfield(state,'Kaero')&&~isempty(state.Kaero);
stateC=isfield(state,'Caero')&&~isempty(state.Caero);
if stateK||stateC
    if stateK,Kaero=checked(state.Kaero,nDof,'Kaero');end
    if stateC,Caero=checked(state.Caero,nDof,'Caero');end
    report.method="state_matrices";report.status="provided";return
end
if ~isfield(cfg,'aerodynamics')||isempty(cfg.aerodynamics),return,end
aero=cfg.aerodynamics;
cfgK=isfield(aero,'Kaero')&&~isempty(aero.Kaero);
cfgC=isfield(aero,'Caero')&&~isempty(aero.Caero);
if cfgK||cfgC
    if cfgK,Kaero=checked(aero.Kaero,nDof,'Kaero');end
    if cfgC,Caero=checked(aero.Caero,nDof,'Caero');end
    report.method="provided_matrices";report.status="provided";return
end
if isfield(aero,'tangentFcn')&&~isempty(aero.tangentFcn)
    [Kaero,Caero]=aero.tangentFcn(state,model,cfg);
    Kaero=checked(Kaero,nDof,'Kaero');Caero=checked(Caero,nDof,'Caero');
    report.method="analytic_tangent";report.status="provided";
    report.evaluations=1;return
end
if ~isfield(aero,'loadFcn')||isempty(aero.loadFcn),return,end

q=zeros(nDof,1);qd=zeros(nDof,1);
if isfield(state,'qFull'),q=double(state.qFull(:));end
if isfield(state,'qdFull'),qd=double(state.qdFull(:));end
if numel(q)~=nDof||numel(qd)~=nDof|| ...
        any(~isfinite(q))||any(~isfinite(qd))
    error('assembly:linearize_aerodynamic_loads:StateSize', ...
        'Linearization state has invalid size or values.');
end
active=(1:nDof).';
if isfield(aero,'dofIndices')&&~isempty(aero.dofIndices)
    active=unique(double(aero.dofIndices(:)),'stable');
end
if any(active<1|active>nDof|active~=fix(active))
    error('assembly:linearize_aerodynamic_loads:ActiveDofs', ...
        'dofIndices are invalid.');
end
positionStep=option(aero,'positionFiniteDifferenceStep', ...
    option(aero,'finiteDifferenceStep',1e-5));
velocityStep=option(aero,'velocityFiniteDifferenceStep', ...
    option(aero,'finiteDifferenceStep',1e-5));
[Kcoarse,Ccoarse]=finiteDifference(aero.loadFcn,q,qd,state,model,cfg, ...
    nDof,active,positionStep,velocityStep);
[Kfine,Cfine]=finiteDifference(aero.loadFcn,q,qd,state,model,cfg, ...
    nDof,active,positionStep/2,velocityStep/2);
Kaero=sparse(Kfine);Caero=sparse(Cfine);
report.method="central_finite_difference_refined";report.status="provided";
report.evaluations=8*numel(active);report.activeDofs=active;
report.coarseFineRelativeK=norm(Kfine-Kcoarse,'fro')/max(norm(Kfine,'fro'),1);
report.coarseFineRelativeC=norm(Cfine-Ccoarse,'fro')/max(norm(Cfine,'fro'),1);
report.positionRelativeStep=positionStep;
report.velocityRelativeStep=velocityStep;
end

function [K,C]=finiteDifference(fun,q,qd,state,model,cfg,n,active,hqRel,hvRel)
K=zeros(n,n);C=zeros(n,n);
for index=1:numel(active)
    dof=active(index);hq=hqRel*max(1,abs(q(dof)));
    hv=hvRel*max(1,abs(qd(dof)));delta=zeros(n,1);delta(dof)=hq;
    plus=force(fun,q+delta,qd,state,model,cfg,n);
    minus=force(fun,q-delta,qd,state,model,cfg,n);
    K(:,dof)=-(plus-minus)/(2*hq);
    delta=zeros(n,1);delta(dof)=hv;
    plus=force(fun,q,qd+delta,state,model,cfg,n);
    minus=force(fun,q,qd-delta,state,model,cfg,n);
    C(:,dof)=-(plus-minus)/(2*hv);
end
end

function f=force(fun,q,qd,state,model,cfg,n)
f=double(fun(q,qd,state,model,cfg));f=f(:);
if numel(f)~=n||any(~isfinite(f))
    error('assembly:linearize_aerodynamic_loads:Force', ...
        'loadFcn returned invalid force.');
end
end

function A=checked(A,n,name)
A=sparse(A);
if ~isequal(size(A),[n n])||any(~isfinite(nonzeros(A)))
    error('assembly:linearize_aerodynamic_loads:Matrix', ...
        '%s is invalid.',name);
end
end

function value=option(s,name,fallback)
value=fallback;if isfield(s,name)&&~isempty(s.(name)),value=double(s.(name));end
if ~isscalar(value)||~isfinite(value)||value<=0
    error('assembly:linearize_aerodynamic_loads:Step', ...
        '%s must be positive and finite.',name);
end
end
