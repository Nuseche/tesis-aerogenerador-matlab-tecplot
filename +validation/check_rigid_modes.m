function report = check_rigid_modes(M, K, baseType, cfg)
%CHECK_RIGID_MODES Count near-zero generalized eigenvalues.

if nargin < 3 || isempty(baseType), baseType = "free"; end
if nargin < 4, cfg = struct(); end
numberToCompute = min(max(12, localCfg(cfg, {'validation','rigidModesToCompute'}, 12)), size(K,1));
tol = localCfg(cfg, {'validation','rigidModeToleranceHz'}, 1e-4);

try
    if size(K,1) <= 40
        lambda = eig(full((K+K.')/2), full((M+M.')/2));
    else
        lambda = eigs((K+K.')/2, (M+M.')/2, numberToCompute, 'smallestabs');
    end
    lambda = real(lambda(isfinite(lambda)));
    frequencies = sqrt(max(lambda,0))/(2*pi);
    count = nnz(abs(lambda) <= (2*pi*tol)^2);
    negativeCount = nnz(lambda < -(2*pi*tol)^2);
catch ME
    report = struct('name', "rigidModes.solve", 'pass', false, 'value', NaN, ...
        'tolerance', tol, 'message', string(ME.message), 'critical', true);
    return
end

if any(strcmpi(string(baseType), ["fixed","fix","flexible","soft","stiff"]))
    expected = 0;
else
    expected = 6;
end
pass = count == expected && negativeCount == 0;
report = struct('name', "rigidModes.count", 'pass', pass, 'value', count, ...
    'tolerance', expected, 'message', sprintf( ...
    'Found %d near-zero and %d materially negative modes (lowest frequencies: %s Hz).', ...
    count, negativeCount, mat2str(sort(frequencies(1:min(end,8))).',4)), 'critical', true);
end

function value = localCfg(cfg, path, fallback)
value = fallback; cursor = cfg;
for i = 1:numel(path)
    if ~isstruct(cursor) || ~isfield(cursor, path{i}), return; end
    cursor = cursor.(path{i});
end
if isnumeric(cursor) && isscalar(cursor), value = cursor; end
end
