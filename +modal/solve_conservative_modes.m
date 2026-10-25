function varargout = solve_conservative_modes(M, K, options)
%SOLVE_CONSERVATIVE_MODES Solve K*phi=lambda*M*phi and mass-normalize.
%   result = modal.solve_conservative_modes(M,K,options)
%   [Phi,frequencyHz,result] = ... is also supported.
%   Eigenvalues are returned without zero-clipping. Near-zero classification
%   does not establish that a mode is rigid: use a known rigid-motion basis.
%   The default classification threshold is rigidToleranceHz=1e-4 Hz.
%   An explicitly supplied rigidTolerance/zeroTolerance retains the legacy
%   spectrum-relative threshold, but no longer overwrites eigenvalues.
%   frequencyHz retains its oscillatory-frequency convention; inspect
%   signedFrequencyHz, omegaRadPerSec and classification for negative roots.

arguments
    M {mustBeNumeric, mustBeNonempty}
    K {mustBeNumeric, mustBeNonempty}
    options = struct()
end

validateSquarePair(M,K);
n = size(M,1);
nModes = min(n,getOption(options,{'number','nModes','numModes'},min(20,n)));
includeRigid = logical(getOption(options,{'includeRigidModes','includeRigid'},true));
rigidTolerance = getOption(options,{'rigidTolerance','zeroTolerance'},[]);
rigidToleranceHz = getOption(options, ...
    {'rigidToleranceHz','rigidFrequencyToleranceHz','zeroToleranceHz'},1e-4);
if ~isscalar(rigidToleranceHz) || ~isfinite(rigidToleranceHz) || rigidToleranceHz < 0
    error('modal:Conservative:InvalidRigidTolerance', ...
        'rigidToleranceHz must be a finite nonnegative scalar.');
end

% The generalized formulation is deliberate: no inverse of M is formed.
useSparse = n > max(40,2*nModes) && nModes < n-1;
requestedModes = nModes;
if ~includeRigid
    requestedModes = min(n-1,max(2*nModes,nModes+12));
end
solver = 'eig';
try
    if useSparse
        solver = 'eigs';
        eigsOptions = struct('isreal',isreal(M) && isreal(K), ...
            'tol',getOption(options,{'tolerance','tol'},1e-10), ...
            'maxit',getOption(options,{'maxIterations','maxit'},1000));
        % A nearly singular K is expected when rigid modes are requested.
        % Residuals and rigid-mode counts are checked explicitly below, so
        % suppress only this known diagnostic during the sparse solve.
        previousWarning = warning('query','MATLAB:eigs:IllConditionedA');
        warningCleanup = onCleanup(@() warning(previousWarning.state, ...
            previousWarning.identifier));
        warning('off','MATLAB:eigs:IllConditionedA');
        [Phi,Lambda] = eigs(K,M,requestedModes,'smallestabs',eigsOptions);
        clear warningCleanup
        eigenvalues = diag(Lambda);
    else
        [Phi,Lambda] = eig(full(K),full(M),'vector');
        eigenvalues = Lambda;
    end
catch sparseFailure
    warning('modal:Conservative:EigsFallback', ...
        'Sparse eigensolution failed (%s); using generalized eig.',sparseFailure.message);
    solver = 'eig-fallback';
    [Phi,Lambda] = eig(full(K),full(M),'vector');
    eigenvalues = Lambda;
end

allRawEigenvalues = eigenvalues(:);
[eigenvalues,Phi,thresholdLambda,classificationPolicy] = ...
    filterSpectrum(eigenvalues,Phi,includeRigid,rigidTolerance,rigidToleranceHz);
if numel(eigenvalues) < nModes && startsWith(solver,'eigs')
    warning('modal:Conservative:FilteredEigsFallback', ...
        ['Only %d requested flexible modes remained after filtering the sparse ' ...
        'spectrum; using generalized eig to complete %d modes.'],numel(eigenvalues),nModes);
    solver = 'eig-filter-fallback';
    [Phi,Lambda] = eig(full(K),full(M),'vector');
    allRawEigenvalues = Lambda(:);
    [eigenvalues,Phi,thresholdLambda,classificationPolicy] = ...
        filterSpectrum(Lambda,Phi,includeRigid,rigidTolerance,rigidToleranceHz);
end

[eigenvalues,order] = sort(eigenvalues,'ascend');
Phi = Phi(:,order);
if numel(eigenvalues) > nModes
    eigenvalues = eigenvalues(1:nModes);
    Phi = Phi(:,1:nModes);
end

[Phi,massNorm] = massNormalize(Phi,M);
omega = sqrt(complex(eigenvalues,0));
frequencyHz = real(omega)/(2*pi);
residual = columnResiduals(K*Phi - M*Phi*diag(eigenvalues),K,M,Phi,eigenvalues);
normwiseResidual = normwiseColumnResiduals( ...
    K*Phi - M*Phi*diag(eigenvalues),K,M,Phi,eigenvalues);
classification = repmat("positive",numel(eigenvalues),1);
classification(abs(eigenvalues) <= thresholdLambda) = "near_zero_numerical";
classification(eigenvalues < -thresholdLambda) = "negative";
if any(real(allRawEigenvalues) < -thresholdLambda & ...
        abs(imag(allRawEigenvalues)) <= 1e-8*max(1,abs(real(allRawEigenvalues))))
    warning('modal:Conservative:NegativeEigenvalues', ...
        ['The computed conservative spectrum contains eigenvalues below ' ...
        '-%.6g rad^2/s^2. Negative eigenvalues are not clipped or hidden; ' ...
        'inspect allRawEigenvalues and classification.'],thresholdLambda);
end

result = struct('eigenvalues',eigenvalues(:), ...
    'omegaRadPerSec',omega(:),'frequencyHz',frequencyHz(:), ...
    'modes',Phi,'massNormBeforeScaling',massNorm(:), ...
    'residual',residual(:),'solver',solver, ...
    'massNormalized',true, ...
    'allRawEigenvalues',allRawEigenvalues, ...
    'signedFrequencyHz',sign(eigenvalues(:)).*sqrt(abs(eigenvalues(:)))/(2*pi), ...
    'classification',classification, ...
    'classificationThresholdEigenvalue',thresholdLambda, ...
    'classificationPolicy',classificationPolicy, ...
    'normwiseResidual',normwiseResidual(:), ...
    'normwiseResidualDefinition', ...
        '||K*phi-lambda*M*phi||_2/((||K||_F+|lambda|*||M||_F)*||phi||_2)');

if nargout <= 1
    varargout{1} = result;
else
    varargout{1} = Phi;
    varargout{2} = frequencyHz(:);
    if nargout >= 3
        varargout{3} = result;
    end
end
end

function validateSquarePair(A,B)
if size(A,1) ~= size(A,2) || ~isequal(size(A),size(B))
    error('modal:Conservative:InvalidMatrices', ...
        'M and K must be square matrices of equal size.');
end
end

function [eigenvalues,Phi,threshold,policy] = ...
        filterSpectrum(eigenvalues,Phi,includeRigid,rigidTolerance,rigidToleranceHz)
finite = isfinite(eigenvalues) & abs(imag(eigenvalues)) <= ...
    1e-8*max(1,abs(real(eigenvalues)));
eigenvalues = real(eigenvalues(finite));
Phi = Phi(:,finite);
if isempty(rigidTolerance)
    threshold = (2*pi*rigidToleranceHz)^2;
    policy = "absolute_frequency_threshold_not_a_rigidity_proof";
else
    if ~isscalar(rigidTolerance) || ~isfinite(rigidTolerance) || rigidTolerance < 0
        error('modal:Conservative:InvalidRigidTolerance', ...
            'rigidTolerance must be a finite nonnegative scalar.');
    end
    scale = max([1;abs(eigenvalues)]);
    threshold = rigidTolerance*scale;
    policy = "explicit_legacy_relative_spectrum_threshold_not_a_rigidity_proof";
end
if includeRigid
    keep = true(size(eigenvalues));
else
    % Remove only the near-zero class, never a materially negative root.
    keep = abs(eigenvalues) > threshold;
end
eigenvalues = eigenvalues(keep);
Phi = Phi(:,keep);
end

function [Phi,normBefore] = massNormalize(Phi,M)
normBefore = zeros(1,size(Phi,2));
for j = 1:size(Phi,2)
    value = Phi(:,j)'*(M*Phi(:,j));
    normBefore(j) = real(value);
    if abs(value) <= eps(max(1,norm(M,'fro')))
        error('modal:Conservative:ZeroMassMode', ...
            'Mode %d has zero generalized mass.',j);
    end
    Phi(:,j) = Phi(:,j)/sqrt(value);
    [~,pivot] = max(abs(Phi(:,j)));
    Phi(:,j) = Phi(:,j)*exp(-1i*angle(Phi(pivot,j)));
    if isreal(M) && norm(imag(Phi(:,j))) <= 1e-12*max(1,norm(real(Phi(:,j))))
        Phi(:,j) = real(Phi(:,j));
    end
end
end

function r = columnResiduals(R,K,M,Phi,lambda)
r = zeros(size(lambda));
for j = 1:numel(lambda)
    denominator = norm(K*Phi(:,j)) + abs(lambda(j))*norm(M*Phi(:,j));
    r(j) = norm(R(:,j))/max(denominator,eps);
end
end

function r = normwiseColumnResiduals(R,K,M,Phi,lambda)
% This scale does not collapse when both K*phi and lambda are almost zero.
r = zeros(size(lambda));
normK = norm(K,'fro');
normM = norm(M,'fro');
for j = 1:numel(lambda)
    denominator = (normK + abs(lambda(j))*normM)*norm(Phi(:,j));
    r(j) = norm(R(:,j))/max(denominator,realmin);
end
end

function value = getOption(options,names,defaultValue)
value = defaultValue;
if isnumeric(options) && isscalar(options)
    if any(strcmp(names,'number'))
        value = options;
    end
    return
end
for k = 1:numel(names)
    if isstruct(options) && isfield(options,names{k}) && ~isempty(options.(names{k}))
        value = options.(names{k});
        return
    end
end
end
