function result = solve_fixed_root_modes(M, K, rootDofs, numberOfModes)
%SOLVE_FIXED_ROOT_MODES Symmetric generalized modes of a clamped subsystem.

if nargin < 4
    numberOfModes = 12;
end
freeDofs = setdiff((1:size(K,1)).', rootDofs(:), 'stable');
Mf = full(0.5*(M(freeDofs,freeDofs)+M(freeDofs,freeDofs).'));
Kf = full(0.5*(K(freeDofs,freeDofs)+K(freeDofs,freeDofs).'));
[L,p] = chol(Mf,'lower');
if p ~= 0
    error('validation:solve_fixed_root_modes:NonPositiveMass', ...
        'The clamped subsystem mass matrix is not positive definite.');
end
A = L\Kf/L.';
A = 0.5*(A+A.');
[Y,lambda] = eig(A,'vector');
lambda = real(lambda);
negativeTolerance = 1e-10*max(1,max(abs(lambda)));
if any(lambda < -negativeTolerance)
    error('validation:solve_fixed_root_modes:NegativeStiffness', ...
        'The clamped subsystem contains a materially negative eigenvalue.');
end
keep = isfinite(lambda) & lambda > 0;
lambda = lambda(keep);
Y = Y(:,keep);
[lambda,order] = sort(lambda,'ascend');
Y = Y(:,order);
numberOfModes = min(numberOfModes,numel(lambda));
lambda = lambda(1:numberOfModes);
Y = Y(:,1:numberOfModes);
PhiFree = L.'\Y;

for mode = 1:numberOfModes
    modalMass = real(PhiFree(:,mode)'*(Mf*PhiFree(:,mode)));
    PhiFree(:,mode) = PhiFree(:,mode)/sqrt(modalMass);
    [~,pivot] = max(abs(PhiFree(:,mode)));
    if PhiFree(pivot,mode) < 0
        PhiFree(:,mode) = -PhiFree(:,mode);
    end
end
residual = zeros(numberOfModes,1);
for mode = 1:numberOfModes
    r = Kf*PhiFree(:,mode)-lambda(mode)*Mf*PhiFree(:,mode);
    denominator = norm(Kf*PhiFree(:,mode)) + ...
        abs(lambda(mode))*norm(Mf*PhiFree(:,mode));
    residual(mode) = norm(r)/max(denominator,eps);
end

Phi = zeros(size(K,1),numberOfModes);
Phi(freeDofs,:) = PhiFree;
result = struct();
result.frequencyHz = sqrt(lambda)/(2*pi);
result.eigenvalues = lambda;
result.modes = Phi;
result.freeDofs = freeDofs;
result.residual = residual;
result.massNormalized = true;
result.minimumMassEigenvalue = min(eig(Mf));
result.minimumStiffnessEigenvalue = min(eig(Kf));
end
