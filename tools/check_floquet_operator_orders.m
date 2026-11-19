function relativeTail=check_floquet_operator_orders(F)
% Confirm that the cached Fourier operators used by both Floquet integrators
% vanish beyond +/-2 at the original sampling tolerance.
keys={'M','D0','D1','K0','K1','K2'};
relativeTail=zeros(numel(keys),1);
for j=1:numel(keys)
    coeff=F.(keys{j});
    norms=cellfun(@(A)norm(A,'fro'),coeff);
    relativeTail(j)=max(norms(abs(-F.L:F.L)>2))/max(max(norms),eps);
end
assert(max(relativeTail)<1e-12,'Nonnegligible coefficients outside the integrated bandwidth.');
end
