function result = newmark_integrate(M, D, K, t, force, options)
%NEWMARK_INTEGRATE Integrate M*qdd+D*qd+K*q=f with Newmark beta-gamma.
%   No symmetry of D or K is assumed and no matrix inverse is formed.

arguments
    M {mustBeNumeric, mustBeNonempty}
    D {mustBeNumeric, mustBeNonempty}
    K {mustBeNumeric, mustBeNonempty}
    t (:,1) double {mustBeFinite}
    force
    options = struct()
end

n = size(M,1); nt = numel(t);
if size(M,2) ~= n || ~isequal(size(D),[n n]) || ~isequal(size(K),[n n])
    error('dynamics:Newmark:InvalidMatrices','M, D, and K must be square and equally sized.');
end
if nt < 2 || any(diff(t) <= 0)
    error('dynamics:Newmark:InvalidTime','t must be strictly increasing and contain at least two samples.');
end
F = evaluateForce(force,t,n);
beta = getOption(options,{'beta'},1/4);
gamma = getOption(options,{'gamma'},1/2);
if beta <= 0 || gamma < 0
    error('dynamics:Newmark:InvalidParameters','beta must be positive and gamma nonnegative.');
end
requireStable=logical(getOption(options, ...
    {'requireUnconditionalStability','enforceUnconditionalStability'},true));
stabilityLimit=.25*(gamma+.5)^2;
unconditionallyStable=gamma>=.5&&beta>=stabilityLimit-10*eps(stabilityLimit);
if requireStable&&~unconditionallyStable
    error('dynamics:Newmark:ConditionallyStableParameters', ...
        ['Unconditionally stable linear Newmark integration requires ' ...
         'gamma>=0.5 and beta>=0.25*(gamma+0.5)^2.']);
end

q = zeros(n,nt,'like',full(M(1))); qd = q; qdd = q;
q(:,1) = initialVector(options,{'q0','initialDisplacement'},n);
qd(:,1) = initialVector(options,{'qd0','v0','initialVelocity'},n);
if isstruct(options) && (isfield(options,'qdd0') || isfield(options,'a0'))
    qdd(:,1) = initialVector(options,{'qdd0','a0','initialAcceleration'},n);
else
    qdd(:,1) = M \ (F(:,1)-D*qd(:,1)-K*q(:,1));
end

constantStep = max(abs(diff(t)-mean(diff(t)))) <= 1e-10*max(1,mean(diff(t)));
constantDt=mean(diff(t));
cachedSolver = [];hasCachedSolver=false;
for i = 1:nt-1
    dt = t(i+1)-t(i);
    if constantStep,dt=constantDt;end
    a0 = 1/(beta*dt^2); a1 = gamma/(beta*dt);
    a2 = 1/(beta*dt); a3 = 1/(2*beta)-1;
    a4 = gamma/beta-1; a5 = dt*(gamma/(2*beta)-1);
    Keffective = K + a0*M + a1*D;
    effectiveForce = F(:,i+1) + M*(a0*q(:,i)+a2*qd(:,i)+a3*qdd(:,i)) + ...
        D*(a1*q(:,i)+a4*qd(:,i)+a5*qdd(:,i));
    if ~constantStep || ~hasCachedSolver
        cachedSolver = factorizeGeneral(Keffective);
        hasCachedSolver=true;
    end
    q(:,i+1) = solveFactorized(cachedSolver,Keffective,effectiveForce);
    qdd(:,i+1) = a0*(q(:,i+1)-q(:,i))-a2*qd(:,i)-a3*qdd(:,i);
    qd(:,i+1) = qd(:,i) + dt*((1-gamma)*qdd(:,i)+gamma*qdd(:,i+1));
end

energy = calculateEnergy(M,D,K,t,q,qd,F);
residual = M*qdd + D*qd + K*q - F;
columnNorm = @(A)sqrt(sum(abs(A).^2,1));
denominator = columnNorm(F) + columnNorm(M*qdd) + ...
    columnNorm(D*qd) + columnNorm(K*q);
relativeResidual = columnNorm(residual)./max(denominator,eps);
result = struct('t',t,'q',q,'qd',qd,'qdd',qdd,'force',F, ...
    'energy',energy,'equilibriumResidual',residual, ...
    'relativeResidual',relativeResidual,'beta',beta,'gamma',gamma, ...
    'unconditionallyStable',unconditionallyStable, ...
    'stabilityBetaLimit',stabilityLimit,'constantTimeStep',constantStep);
end

function F = evaluateForce(force,t,n)
if isa(force,'function_handle')
    F = zeros(n,numel(t));
    for k = 1:numel(t), F(:,k) = force(t(k)); end
elseif isnumeric(force)
    if isequal(size(force),[n numel(t)]), F = force;
    elseif isequal(size(force),[numel(t) n]), F = force.';
    elseif isvector(force) && numel(force) == n, F = repmat(force(:),1,numel(t));
    else, error('dynamics:Newmark:InvalidForce','force must be n-by-nt, nt-by-n, n-vector, or function handle.');
    end
else
    error('dynamics:Newmark:InvalidForce','Unsupported force representation.');
end
end

function factor = factorizeGeneral(A)
try
    factor = decomposition(A,'auto');
catch
    factor = [];
end
end

function x = solveFactorized(factor,A,b)
if isempty(factor), x = A \ b; else, x = factor \ b; end
end

function v = initialVector(s,names,n)
v = zeros(n,1);
for k = 1:numel(names)
    if isstruct(s) && isfield(s,names{k}) && ~isempty(s.(names{k}))
        v = s.(names{k})(:); break
    end
end
if numel(v) ~= n, error('dynamics:Newmark:InvalidInitialState','Initial state vectors must have n entries.'); end
end

function energy = calculateEnergy(M,D,K,t,q,qd,F)
nt = numel(t); kinetic = zeros(nt,1); strain = zeros(nt,1);
inputPower = zeros(nt,1); dampingPower = zeros(nt,1); nonconservativePower = zeros(nt,1);
Ms=(M+M')/2;Ks = (K+K')/2; Ka = (K-K')/2;
for k = 1:nt
    kinetic(k) = real(0.5*qd(:,k)'*Ms*qd(:,k));
    strain(k) = real(0.5*q(:,k)'*Ks*q(:,k));
    inputPower(k) = real(qd(:,k)'*F(:,k));
    dampingPower(k) = real(qd(:,k)'*D*qd(:,k));
    nonconservativePower(k) = real(qd(:,k)'*Ka*q(:,k));
end
externalWork=zeros(nt,1);dampingWork=zeros(nt,1);
nonconservativeWork=zeros(nt,1);
for k=1:nt-1
    dt=t(k+1)-t(k);dq=q(:,k+1)-q(:,k);
    velocityMid=(qd(:,k+1)+qd(:,k))/2;
    displacementMid=(q(:,k+1)+q(:,k))/2;
    forceMid=(F(:,k+1)+F(:,k))/2;
    externalWork(k+1)=externalWork(k)+real(dq'*forceMid);
    dampingWork(k+1)=dampingWork(k)+ ...
        real(dt*velocityMid'*D*velocityMid);
    nonconservativeWork(k+1)=nonconservativeWork(k)+ ...
        real(dq'*Ka*displacementMid);
end
initialMechanical = kinetic(1)+strain(1);
balanceResidual = kinetic+strain+dampingWork+nonconservativeWork- ...
    initialMechanical-externalWork;
referenceEnergy = max([abs(kinetic),abs(strain),abs(dampingWork), ...
    abs(nonconservativeWork),abs(externalWork), ...
    repmat(abs(initialMechanical),nt,1)],[],2);
relativeBalanceError = abs(balanceResidual)./max(referenceEnergy,eps);
energy = struct('kinetic',kinetic,'strain',strain, ...
    'mechanical',kinetic+strain,'inputPower',inputPower, ...
    'externalWork',externalWork,'dampingPower',dampingPower, ...
    'dampingWork',dampingWork,'nonconservativeWork',nonconservativeWork, ...
    'balanceResidual',balanceResidual, ...
    'relativeBalanceError',relativeBalanceError, ...
    'workIntegration',"Newmark-compatible midpoint increments");
end

function value = getOption(s,names,defaultValue)
value = defaultValue;
for k = 1:numel(names)
    if isstruct(s) && isfield(s,names{k}) && ~isempty(s.(names{k})), value = s.(names{k}); return; end
end
end
