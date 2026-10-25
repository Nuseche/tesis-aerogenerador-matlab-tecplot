function result = subspace_mac(PhiA,PhiB,metric)
%SUBSPACE_MAC Principal-angle MAC between two modal subspaces.

if size(PhiA,1)~=size(PhiB,1)||size(PhiA,2)~=size(PhiB,2)||isempty(PhiA)
    error('modal:SubspaceMAC:DimensionMismatch', ...
        'Subspaces must have equal nonzero row and column dimensions.');
end
n=size(PhiA,1);if nargin<3||isempty(metric),metric=speye(n);end
if ~isequal(size(metric),[n n])
    error('modal:SubspaceMAC:InvalidMetric','Metric dimension is invalid.');
end
GA=PhiA'*(metric*PhiA);GB=PhiB'*(metric*PhiB);
[VA,DA]=eig((GA+GA')/2,'vector');[VB,DB]=eig((GB+GB')/2,'vector');
tol=1e-12*max([1;abs(DA(:));abs(DB(:))]);
if min(real(DA))<=tol||min(real(DB))<=tol
    error('modal:SubspaceMAC:SingularBasis', ...
        'Modal bases must be independent under the supplied metric.');
end
invA=VA*diag(1./sqrt(real(DA)))*VA';
invB=VB*diag(1./sqrt(real(DB)))*VB';
cross=invA*(PhiA'*(metric*PhiB))*invB;
singularValues=min(max(real(svd(cross)),0),1);
mac=singularValues.^2;
result=struct('principalCosines',singularValues, ...
    'principalAnglesRad',acos(singularValues), ...
    'principalMAC',mac,'minimumMAC',min(mac), ...
    'meanMAC',mean(mac),'maximumAngleRad',max(acos(singularValues)));
end
