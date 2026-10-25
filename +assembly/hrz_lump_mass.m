function [Mlumped,diagnostics]=hrz_lump_mass(Mconsistent,modelOrDofMap)
%HRZ_LUMP_MASS Explicit diagonal scaling of distributed structural mass.
%   Translational diagonal terms are scaled by direction so each rigid
%   translation has the same generalized mass as Mconsistent. Rotational
%   diagonal terms use the mean translational HRZ scale. Concentrated spatial
%   bodies must be added after this operation.

Mconsistent=sparse((Mconsistent+Mconsistent.')/2);
n=size(Mconsistent,1);
if size(Mconsistent,2)~=n||any(~isfinite(nonzeros(Mconsistent)))
    error('assembly:hrz_lump_mass:InvalidMatrix', ...
        'The consistent mass must be a finite square matrix.');
end
dofMap=localDofMap(modelOrDofMap,n);
diagonal=full(diag(Mconsistent));
scale=max(max(diagonal),1);
tolerance=1e-12*scale;
if any(diagonal < -tolerance)
    error('assembly:hrz_lump_mass:NegativeDiagonal', ...
        'HRZ cannot mask a materially negative consistent-mass diagonal.');
end
diagonal(diagonal<0)=0;

directionalTargetMass=zeros(3,1);
directionalInputDiagonal=zeros(3,1);
directionalScale=zeros(3,1);
outputDiagonal=zeros(n,1);
for direction=1:3
    dofs=dofMap(:,direction);
    rigidTranslation=sparse(dofs,1,1,n,1);
    directionalTargetMass(direction)=full( ...
        rigidTranslation.'*Mconsistent*rigidTranslation);
    directionalInputDiagonal(direction)=sum(diagonal(dofs));
    if directionalTargetMass(direction)<=0|| ...
            directionalInputDiagonal(direction)<=0
        error('assembly:hrz_lump_mass:NonPositiveTranslationalMass', ...
            'Each translational direction requires positive generalized mass.');
    end
    directionalScale(direction)=directionalTargetMass(direction)/ ...
        directionalInputDiagonal(direction);
    outputDiagonal(dofs)=directionalScale(direction)*diagonal(dofs);
end
rotationScale=mean(directionalScale);
rotationDofs=reshape(dofMap(:,4:6),[],1);
outputDiagonal(rotationDofs)=rotationScale*diagonal(rotationDofs);
if any(~isfinite(outputDiagonal))||any(outputDiagonal < 0)
    error('assembly:hrz_lump_mass:InvalidOutput', ...
        'HRZ produced a nonfinite or negative diagonal.');
end
Mlumped=spdiags(outputDiagonal,0,n,n);

directionalOutputMass=zeros(3,1);
for direction=1:3
    dofs=dofMap(:,direction);
    rigidTranslation=sparse(dofs,1,1,n,1);
    directionalOutputMass(direction)=full( ...
        rigidTranslation.'*Mlumped*rigidTranslation);
end
relativeError=max(abs(directionalOutputMass-directionalTargetMass)./ ...
    max(directionalTargetMass,1));
diagnostics=struct('method',"hrz",'directionalTargetMass', ...
    directionalTargetMass,'directionalInputDiagonal', ...
    directionalInputDiagonal,'directionalOutputMass', ...
    directionalOutputMass,'directionalScale',directionalScale, ...
    'rotationScale',rotationScale,'minimumOutputDiagonal', ...
    min(outputDiagonal),'zeroDiagonalCount',nnz(outputDiagonal==0), ...
    'translationMassRelativeError',relativeError, ...
    'outputDiagonal',true,'usesAbsoluteValue',false, ...
    'scope',"distributed mass only; add spatial rigid bodies afterward");
end

function dofMap=localDofMap(modelOrDofMap,n)
if isstruct(modelOrDofMap)&&isfield(modelOrDofMap,'dofs')&& ...
        isfield(modelOrDofMap.dofs,'node')
    dofMap=double(modelOrDofMap.dofs.node);
elseif isnumeric(modelOrDofMap)
    dofMap=double(modelOrDofMap);
else
    error('assembly:hrz_lump_mass:MissingDofMap', ...
        'HRZ requires modelData.dofs.node or an explicit N-by-6 map.');
end
values=dofMap(:);
if size(dofMap,2)~=6||numel(values)~=n||any(~isfinite(values))|| ...
        any(values~=fix(values))||~isequal(sort(values),reshape(1:n,[],1))
    error('assembly:hrz_lump_mass:InvalidDofMap', ...
        'The DOF map must be N-by-6 and a permutation of 1:size(M,1).');
end
end
