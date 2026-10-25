function varargout = solve_quadratic_modes(M, D, K, options)
%SOLVE_QUADRATIC_MODES Solve (lambda^2 M + lambda D + K)phi=0.
%   The companion pencil is solved as a generalized eigenproblem; M is
%   never explicitly inverted. One representative of each physical pair
%   is returned in result.eigenvalues. result.allEigenvalues retains every
%   root computed by the selected solver; for sparse EIGS this is a targeted
%   subset, explicitly identified by result.spectrumComplete=false.

arguments
    M {mustBeNumeric, mustBeNonempty}
    D {mustBeNumeric, mustBeNonempty}
    K {mustBeNumeric, mustBeNonempty}
    options = struct()
end

n = size(M,1);
if size(M,2) ~= n || ~isequal(size(D),[n n]) || ~isequal(size(K),[n n])
    error('modal:Quadratic:InvalidMatrices', ...
        'M, D and K must be square matrices of equal size.');
end
nModes = min(n,getOption(options,{'number','nModes','numModes'},min(20,n)));

I = speye(n);
Z = sparse(n,n);
A = [Z I; -sparse(K) -sparse(D)];
B = [I Z; Z sparse(M)];

solver = 'eig';
requested = min(2*n-1,max(2*nModes+4,2*nModes));
leftStates=[];leftEigenvalues=[];
try
    if 2*n > max(80,3*requested) && requested < 2*n-1
        solver = 'eigs';
        eigsOptions = struct('isreal',isreal(A) && isreal(B), ...
            'tol',getOption(options,{'tolerance','tol'},1e-9), ...
            'maxit',getOption(options,{'maxIterations','maxit'},1500));
        [states,Lambda] = eigs(A,B,requested,getOption(options,{'target','sigma'},0),eigsOptions);
        allEigenvalues = diag(Lambda);
        try
            [leftTranspose,LambdaLeft]=eigs(A.',B.',requested, ...
                getOption(options,{'target','sigma'},0),eigsOptions);
            leftStates=conj(leftTranspose);leftEigenvalues=diag(LambdaLeft);
        catch leftFailure
            warning('modal:Quadratic:LeftEigsUnavailable', ...
                'Sparse left eigensolution failed: %s',leftFailure.message);
        end
    else
        [states,allEigenvalues,leftStates] = eig(full(A),full(B),'vector');
        leftEigenvalues=allEigenvalues;
    end
catch sparseFailure
    warning('modal:Quadratic:EigsFallback', ...
        'Sparse QEP eigensolution failed (%s); using generalized eig.',sparseFailure.message);
    solver = 'eig-fallback';
    [states,allEigenvalues,leftStates] = eig(full(A),full(B),'vector');
    leftEigenvalues=allEigenvalues;
end

finite = isfinite(allEigenvalues);
allEigenvalues = allEigenvalues(finite);
states = states(:,finite);
if ~isempty(leftStates)&&numel(leftEigenvalues)==numel(finite)
    leftStates=leftStates(:,finite);leftEigenvalues=leftEigenvalues(finite);
else
    finiteLeft=isfinite(leftEigenvalues);
    leftEigenvalues=leftEigenvalues(finiteLeft);
    if ~isempty(leftStates),leftStates=leftStates(:,finiteLeft);end
end
allModes = states(1:n,:);

[selected,pairIndex,pairError,pairType,omegaNatural,omegaDamped,dampingRatio] = ...
    selectPhysicalRepresentatives(allEigenvalues,allModes,nModes);
lambda = allEigenvalues(selected);
Phi = allModes(:,selected);

[Phi,generalizedMass] = normalizeModes(Phi,M);
residual = zeros(numel(lambda),1);
normM = norm(M,'fro');
normD = norm(D,'fro');
normK = norm(K,'fro');
for j = 1:numel(lambda)
    R = (lambda(j)^2*M + lambda(j)*D + K)*Phi(:,j);
    denominator = (abs(lambda(j))^2*normM + ...
        abs(lambda(j))*normD + normK)*norm(Phi(:,j));
    residual(j) = norm(R)/max(denominator,eps);
end

[leftModes,leftResidual,biorthogonality,leftDiagnostics]= ...
    recoverLeftModes(leftStates,leftEigenvalues,lambda,Phi,M,D,K);

result = struct('eigenvalues',lambda(:),'modes',Phi, ...
    'dampedFrequencyHz',omegaDamped(:)/(2*pi), ...
    'naturalFrequencyHz',omegaNatural(:)/(2*pi), ...
    'dampingRatio',dampingRatio(:), ...
    'allEigenvalues',allEigenvalues(:), ...
    'computedEigenvalues',allEigenvalues(:), ...
    'spectrumComplete',~strcmp(solver,'eigs'),'allModes',allModes, ...
    'conjugatePartnerIndex',pairIndex(:), ...
    'conjugatePairRelativeError',pairError(:), ...
    'pairType',pairType(:),'pairConsistencyError',pairError(:), ...
    'generalizedMassBeforeScaling',generalizedMass(:), ...
    'residual',residual,'solver',solver,'massNormalized',true, ...
    'leftModes',leftModes,'leftResidual',leftResidual, ...
    'biorthogonality',biorthogonality, ...
    'leftDiagnostics',leftDiagnostics, ...
    'allLeftEigenvalues',leftEigenvalues(:));

if nargout <= 1
    varargout{1} = result;
else
    varargout{1} = lambda(:);
    varargout{2} = Phi;
    if nargout >= 3
        varargout{3} = result;
    end
end


function [Psi,residual,biorthogonality,diagnostics]= ...
        recoverLeftModes(leftStates,leftEigenvalues,lambda,Phi,M,D,K)
n=size(M,1);count=numel(lambda);Psi=complex(zeros(n,0));
residual=zeros(0,1);biorthogonality=complex(zeros(0));
diagnostics=struct('available',false,'matchingError',zeros(0,1), ...
    'maximumResidual',NaN,'maximumOffDiagonal',NaN, ...
    'normalization',"psi'*(2*lambda*M+D)*phi=1");
if isempty(leftStates)||isempty(leftEigenvalues)||count==0,return,end
cost=abs(lambda(:)-leftEigenvalues(:).')./max(1,abs(lambda(:)));
pairs=matchpairs(cost,1e9,'min');
if size(pairs,1)<count,return,end
[~,order]=sort(pairs(:,1));pairs=pairs(order,:);
matched=pairs(:,2);matchingError=cost(sub2ind(size(cost),pairs(:,1),pairs(:,2)));
if max(matchingError)>1e-5,return,end
Psi=leftStates(n+1:end,matched);
for mode=1:count
    diagonal=Psi(:,mode)'*((2*lambda(mode)*M+D)*Phi(:,mode));
    if abs(diagonal)<=eps,continue,end
    Psi(:,mode)=Psi(:,mode)/conj(diagonal);
end
normM=norm(M,'fro');normD=norm(D,'fro');normK=norm(K,'fro');
residual=zeros(count,1);biorthogonality=complex(zeros(count));
for i=1:count
    P=lambda(i)^2*M+lambda(i)*D+K;
    denominator=(abs(lambda(i))^2*normM+abs(lambda(i))*normD+normK)* ...
        norm(Psi(:,i));
    residual(i)=norm(Psi(:,i)'*P)/max(denominator,eps);
    for j=1:count
        biorthogonality(i,j)=Psi(:,i)'* ...
            (((lambda(i)+lambda(j))*M+D)*Phi(:,j));
    end
end
offDiagonal=biorthogonality-diag(diag(biorthogonality));
diagnostics=struct('available',true,'matchingError',matchingError, ...
    'maximumResidual',max(residual), ...
    'maximumOffDiagonal',norm(offDiagonal,'fro')/max(norm(biorthogonality,'fro'),eps), ...
    'normalization',"psi'*(2*lambda*M+D)*phi=1");
end
end

function [selected,partners,errors,pairType,omegaNatural,omegaDamped,dampingRatio] = ...
        selectPhysicalRepresentatives(lambda,modes,nModes)
tol = 1e-9*max(1,max(abs(lambda),[],'omitnan'));
used = false(numel(lambda),1);
selected = zeros(0,1); partners = zeros(0,1); errors = zeros(0,1);
pairType = strings(0,1); omegaNatural = zeros(0,1);
omegaDamped = zeros(0,1); dampingRatio = zeros(0,1);

% Oscillatory physical modes are represented by the positive-imaginary
% member of each conjugate pair.
oscillatory = find(imag(lambda) > tol);
for candidate = oscillatory(:).'
    [distance,partner] = min(abs(lambda-conj(lambda(candidate))));
    used([candidate partner]) = true;
    selected(end+1,1) = candidate; %#ok<AGROW>
    partners(end+1,1) = partner; %#ok<AGROW>
    errors(end+1,1) = distance/max(1,abs(lambda(candidate))); %#ok<AGROW>
    pairType(end+1,1) = "complex-conjugate"; %#ok<AGROW>
    omegaNatural(end+1,1) = abs(lambda(candidate)); %#ok<AGROW>
    omegaDamped(end+1,1) = abs(imag(lambda(candidate))); %#ok<AGROW>
    dampingRatio(end+1,1) = -real(lambda(candidate))/max(abs(lambda(candidate)),eps); %#ok<AGROW>
end

% Overdamped physical modes contribute two real roots. Pair roots by modal
% shape correlation, then derive wn and zeta from their quadratic factors.
realCandidates = find(abs(imag(lambda)) <= tol & ~used);
while numel(realCandidates) >= 2
    basis = modes(:,realCandidates);
    norms = sqrt(sum(abs(basis).^2,1));
    similarity = abs(basis'*basis).^2 ./ max((norms(:).^2)*(norms(:).'.^2),eps);
    similarity(1:size(similarity,1)+1:end) = -inf;
    [best,linear] = max(similarity,[],'all','linear');
    [first,second] = ind2sub(size(similarity),linear);
    pair = realCandidates([first second]);
    roots = lambda(pair);
    [~,representativeLocal] = min(abs(roots));
    representative = pair(representativeLocal);
    partner = pair(3-representativeLocal);
    wn = sqrt(abs(roots(1)*roots(2)));
    selected(end+1,1) = representative; %#ok<AGROW>
    partners(end+1,1) = partner; %#ok<AGROW>
    errors(end+1,1) = max(0,1-best); %#ok<AGROW>
    pairType(end+1,1) = "real-root-pair"; %#ok<AGROW>
    omegaNatural(end+1,1) = wn; %#ok<AGROW>
    omegaDamped(end+1,1) = 0; %#ok<AGROW>
    dampingRatio(end+1,1) = -real(sum(roots))/(2*max(wn,eps)); %#ok<AGROW>
    realCandidates([first second]) = [];
end
if ~isempty(realCandidates)
    candidate = realCandidates(1);
    selected(end+1,1) = candidate;
    partners(end+1,1) = candidate;
    errors(end+1,1) = NaN;
    pairType(end+1,1) = "unpaired-real-root";
    omegaNatural(end+1,1) = abs(lambda(candidate));
    omegaDamped(end+1,1) = 0;
    dampingRatio(end+1,1) = -sign(real(lambda(candidate)));
end

[~,order] = sortrows([omegaNatural abs(lambda(selected))],[1 2]);
order = order(1:min(nModes,numel(order)));
selected = selected(order); partners = partners(order); errors = errors(order);
pairType = pairType(order); omegaNatural = omegaNatural(order);
omegaDamped = omegaDamped(order); dampingRatio = dampingRatio(order);
if numel(selected) < nModes
    warning('modal:Quadratic:FewerPhysicalPairs', ...
        'Only %d physical eigenvalue pairs were recovered for %d requested modes.', ...
        numel(selected),nModes);
end
end

function [Phi,mass] = normalizeModes(Phi,M)
mass = zeros(1,size(Phi,2));
for j = 1:size(Phi,2)
    value = Phi(:,j)'*(M*Phi(:,j));
    mass(j) = real(value);
    scale = sqrt(abs(value));
    if scale <= eps
        scale = norm(Phi(:,j));
    end
    Phi(:,j) = Phi(:,j)/scale;
    [~,pivot] = max(abs(Phi(:,j)));
    Phi(:,j) = Phi(:,j)*exp(-1i*angle(Phi(pivot,j)));
end
end

function value = getOption(options,names,defaultValue)
value = defaultValue;
if isnumeric(options) && isscalar(options)
    if any(strcmp(names,'number')), value = options; end
    return
end
for k = 1:numel(names)
    if isstruct(options) && isfield(options,names{k}) && ~isempty(options.(names{k}))
        value = options.(names{k}); return
    end
end
end
