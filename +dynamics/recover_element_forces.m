function result=recover_element_forces(modelData,qFull,elementCache)
%RECOVER_ELEMENT_FORCES Incremental elastic Timoshenko end forces.
%   Forces are recovered about the accepted operating equilibrium. Static
%   prestress is not added again. Local ordering is
%   [N V2 V3 T M2 M3] at node I followed by the same at node J.

arguments
    modelData (1,1) struct
    qFull {mustBeNumeric,mustBeNonempty}
    elementCache struct
end
nFull=double(modelData.dofs.number);
if size(qFull,1)~=nFull&&size(qFull,2)==nFull,qFull=qFull.';end
if size(qFull,1)~=nFull
    error('dynamics:ElementForces:DimensionMismatch', ...
        'qFull must have one row per full model DOF.');
end
active=find([elementCache.assembled]);nElement=numel(active);nt=size(qFull,2);
elementId=zeros(nElement,1);component=strings(nElement,1);blade=zeros(nElement,1);
localEndForces=zeros(12,nt,nElement);globalEndForces=zeros(12,nt,nElement);
axial=zeros(nElement,nt);shear2=axial;shear3=axial;torsion=axial;
moment2=axial;moment3=axial;localGlobalError=zeros(nElement,1);
localGlobalBackwardError=zeros(nElement,1);
assembledGlobalForce=zeros(nFull,nt);Kbeam=sparse(nFull,nFull);
for row=1:nElement
    cache=elementCache(active(row));dofs=double(cache.dofs(:));
    qe=qFull(dofs,:);qLocal=cache.Te*qe;
    fLocal=cache.KeLocal*qLocal;fGlobal=cache.Te.'*fLocal;
    expected=cache.KeGlobal*qe;
    localGlobalError(row)=norm(fGlobal-expected,'fro')/max(norm(expected,'fro'),eps);
    localGlobalBackwardError(row)=norm(fGlobal-expected,'fro')/ ...
        max(norm(cache.KeGlobal,'fro')*norm(qe,'fro'),eps);
    localEndForces(:,:,row)=fLocal;globalEndForces(:,:,row)=fGlobal;
    assembledGlobalForce(dofs,:)=assembledGlobalForce(dofs,:)+fGlobal;
    Kbeam(dofs,dofs)=Kbeam(dofs,dofs)+sparse(cache.KeGlobal);
    elementId(row)=double(cache.id);component(row)=string(cache.component);
    blade(row)=double(cache.blade);
    axial(row,:)=(fLocal(7,:)-fLocal(1,:))/2;
    shear2(row,:)=(fLocal(8,:)-fLocal(2,:))/2;
    shear3(row,:)=(fLocal(9,:)-fLocal(3,:))/2;
    torsion(row,:)=(fLocal(10,:)-fLocal(4,:))/2;
    moment2(row,:)=(fLocal(11,:)-fLocal(5,:))/2;
    moment3(row,:)=(fLocal(12,:)-fLocal(6,:))/2;
end
reference=Kbeam*qFull;
assemblyError=norm(assembledGlobalForce-reference,'fro')/ ...
    max(norm(reference,'fro'),eps);
result=struct('schemaVersion',"1.0.0",'elementId',elementId, ...
    'component',component,'blade',blade,'localEndForces',localEndForces, ...
    'globalEndForces',globalEndForces,'axialForce',axial, ...
    'shearLocal2',shear2,'shearLocal3',shear3,'torsionalMoment',torsion, ...
    'bendingMomentLocal2',moment2,'bendingMomentLocal3',moment3, ...
    'assembledGlobalForce',assembledGlobalForce,'Kbeam',Kbeam, ...
    'maximumLocalGlobalError',max(localGlobalError,[],'omitnan'), ...
    'localGlobalError',localGlobalError, ...
    'maximumLocalGlobalBackwardError', ...
    max(localGlobalBackwardError,[],'omitnan'), ...
    'localGlobalBackwardError',localGlobalBackwardError, ...
    'assemblyError',assemblyError, ...
    'forceConvention', ...
    "local nodal resisting forces [N,V2,V3,T,M2,M3] at I then J", ...
    'interpretation', ...
    "incremental linear-elastic forces about operating equilibrium; prestress excluded");
end
