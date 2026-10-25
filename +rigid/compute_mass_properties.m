function properties = compute_mass_properties(modelData,Mfull,Tc)
%COMPUTE_MASS_PROPERTIES Recover total mass, CG and inertia from M and Tc.
%   Properties are evaluated about the global origin using six rigid-body
%   velocity fields. Congruence through Tc must preserve the spatial mass.

xyz=double(modelData.mesh.nodes.xyz);nNodes=size(xyz,1);
if isfield(modelData,'dofs')&&isfield(modelData.dofs,'node')
    dofMap=double(modelData.dofs.node);ndof=max(dofMap(:));
else
    dofMap=reshape(1:6*nNodes,6,nNodes).';ndof=6*nNodes;
end
if ~isequal(size(dofMap),[nNodes 6])|| ...
        ~isequal(sort(dofMap(:)),reshape(1:ndof,[],1))
    error('rigid:compute_mass_properties:DofMap', ...
        'The nodal DOF map must be a permutation of 1:ndof.');
end
if ~isequal(size(Mfull),[ndof ndof])||size(Tc,1)~=ndof
    error('rigid:compute_mass_properties:Size','Mfull/Tc dimensions do not match the nodal mesh.');
end
P=sparse(ndof,6);
for node=1:nNodes
    r=xyz(node,:);S=[0 -r(3) r(2);r(3) 0 -r(1);-r(2) r(1) 0];
    P(dofMap(node,:),:)=[eye(3) -S;zeros(3) eye(3)];
end
spatialFull=full(P.'*Mfull*P);
Pr=Tc\P;
compatibility=norm(Tc*Pr-P,'fro')/max(norm(P,'fro'),eps);
Mreduced=Tc.'*Mfull*Tc;
spatialReduced=full(Pr.'*Mreduced*Pr);
conservation=norm(spatialReduced-spatialFull,'fro')/max(norm(spatialFull,'fro'),eps);

mass=trace(spatialFull(1:3,1:3))/3;
S=-spatialFull(1:3,4:6)/mass;
center=[S(3,2);S(1,3);S(2,1)];
properties=struct('totalMassKg',mass,'centerOfMassGlobalM',center, ...
    'inertiaAboutOriginKgM2',spatialFull(4:6,4:6), ...
    'spatialMassFull',spatialFull,'spatialMassReduced',spatialReduced, ...
    'constraintCompatibilityError',compatibility, ...
    'constraintConservationError',conservation, ...
    'definition',"Rigid velocity-field projection about global origin");
end
