function MAC = modal_assurance_criterion(PhiA, PhiB, metric)
%MODAL_ASSURANCE_CRITERION Modal assurance criterion between modal bases.
%   MAC = modal.modal_assurance_criterion(PhiA,PhiB) uses the Euclidean
%   inner product.  A positive definite matrix M may be supplied as the
%   third argument to evaluate the mass-weighted MAC.

arguments
    PhiA {mustBeNumeric, mustBeNonempty}
    PhiB {mustBeNumeric, mustBeNonempty}
    metric {mustBeNumeric} = []
end

if size(PhiA,1) ~= size(PhiB,1)
    error('modal:MAC:DimensionMismatch', ...
        'The two modal bases must have the same number of rows.');
end

n = size(PhiA,1);
if isempty(metric)
    metric = speye(n);
elseif ~isequal(size(metric),[n n])
    error('modal:MAC:InvalidMetric', ...
        'The metric must be an n-by-n matrix.');
end

crossProduct = PhiA' * (metric * PhiB);
normA = real(sum(conj(PhiA) .* (metric * PhiA),1));
normB = real(sum(conj(PhiB) .* (metric * PhiB),1));
denominator = normA(:) * normB(:).';

MAC = abs(crossProduct).^2 ./ denominator;
MAC(denominator <= eps(max(1,max(abs(denominator),[],'all')))) = 0;
MAC = min(max(real(MAC),0),1);
end
