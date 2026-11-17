function [Fq,Fv]=force_tangent(forceFcn,q,v,step)
%FORCE_TANGENT Central differences in translation [m], rotation [rad] and rates.
% The caller must compare step sizes; this routine does not fit coefficients.
n=numel(q);Fq=zeros(n);Fv=Fq;
for j=1:n
    d=zeros(n,1);d(j)=step;
    Fq(:,j)=(forceFcn(q+d,v)-forceFcn(q-d,v))/(2*step);
    Fv(:,j)=(forceFcn(q,v+d)-forceFcn(q,v-d))/(2*step);
end
Fq=sparse(Fq);Fv=sparse(Fv);
end
