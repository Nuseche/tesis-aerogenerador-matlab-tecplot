function T=rigid_audit(md,Phi,M,Ke)
%RIGID_AUDIT Rigid motion identification uses shape/support/elastic energy.
xyz=md.mesh.nodes.xyz;B=zeros(size(Phi,1),6);
for k=1:size(xyz,1)
    r=xyz(k,:).';S=[0 -r(3) r(2);r(3) 0 -r(1);-r(2) r(1) 0];
    d=md.dofs.node(k,:);B(d(1:3),:)=[eye(3) -S];B(d(4:6),4:6)=eye(3);
end
H=B'*(M*B);coef=H\(B'*(M*Phi));res=Phi-B*coef;
fit=sqrt(max(real(sum(conj(res).*(M*res),1)),0)./ ...
    max(real(sum(conj(Phi).*(M*Phi),1)),eps));
energy=real(sum(conj(Phi).*(Ke*Phi),1));
scale=norm(Ke,'fro')*sum(abs(Phi).^2,1);erel=abs(energy)./max(scale,eps);
if isempty(md.dofs.fixed),support=zeros(size(fit));
else,support=vecnorm(B(md.dofs.fixed,:)*coef)./max(vecnorm(B*coef),eps);end
rigid=(fit<1e-6)&(support<1e-8)&(erel<1e-10);
T=table((1:size(Phi,2)).',fit.',support.',erel.',rigid.', ...
    'VariableNames',{'mode','rigidShapeResidual','supportResidual','elasticEnergyRatio','rigidCandidate'});
end
