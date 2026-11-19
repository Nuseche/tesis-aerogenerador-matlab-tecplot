function replay_case00_pulse()
% Six generalized pulse components, small-deformation stationary reference.
% Use the maintained model body-to-global convention for load moments;
% include the transposed convention as a sensitivity check.
% Also export sensitivity of tower X to arbitrary constant moment direction.
root=fileparts(fileparts(mfilename('fullpath')));addpath(root,fullfile(root,'cases'));
out=fullfile(root,'runs','case00_decay');if ~isfolder(out),mkdir(out);end
maxNumCompThreads(1);cfg=config_seismic_verification();cfg.gravity.enabled=false;
cfg.rotor.speedRPM=0;md=model.build_model(io.load_model_data(cfg),cfg);
[M,K]=assembly.assemble_structural_matrices(md,cfg);M=rigid.add_body_masses(M,md,md.rigidBodies);
C=assembly.assemble_damping_matrix(md,M,K,struct(),cfg);
constraint=rigid.rigid_constraint_matrix(md,md.rigidBodies,cfg);
red=rigid.reduce_system(constraint,M,K,md,cfg);T=constraint(:,red.free);
Mr=T'*M*T;Kr=T'*K*T;Cr=T'*C*T;
[V,L]=eig(full(Kr),full(Mr),'chol');[lam,ix]=sort(diag(L));V=V(:,ix);
V=V./sqrt(diag(V'*Mr*V)).';D=V'*Cr*V;c=diag(D);
assert(min(lam)>0 && norm(D-diag(c),'fro')/norm(D,'fro')<1e-7);
n=md.dofs.node(129,:);idx=md.dofs.node(20,1:3);base=md.dofs.node(1,5);
shaft=md.mesh.nodes.xyz(130,:)'-md.mesh.nodes.xyz(129,:)';shaft=shaft/norm(shaft);
R=md.rigidBodies.bodies([md.rigidBodies.bodies.masterNode]==129).orientationBodyToGlobal;
% The four columns give the combined global forces and three unit-scaled
% global moment cases. Their linear combination reconstructs the trial.
B=sparse(size(K,1),4);B(n(1:3),1)=1e7;B(n(4:6),2:4)=1e7*eye(3);
physical=T*V;F=physical'*B;coef=[1;R*ones(3,1)];
U=physical(idx,:);m=M(base,:)*physical;d=C(base,:)*physical;k=K(base,:)*physical;
% Exact step solution via the two stable roots of each mass-normalized mode.
r1=-c/2+sqrt(complex((c/2).^2-lam));r2=-c/2-sqrt(complex((c/2).^2-lam));
assert(all(abs(r1-r2)>1e-7));t=(20:.02:1100)';y=zeros(numel(t),8);
% Replay the source orientation from prepare_case00_replay.py. Midpoint
% couples act over 0.01 s, the nominal resolution of the archived history.
% All forces act at the nacelle reference point in the undeformed model.
inputs=readmatrix(fullfile(out,'replay_moment_inputs.csv'));dt=.01;
assert(size(inputs,1)==100 && max(abs(inputs(:,1)-(20.005:dt:20.995)'))<1e-8);
follower=zeros(numel(t),4);Q=zeros(size(lam));Vdot=Q;
for j=1:100
 f=F*[1;inputs(j,2:4)'];[Q,Vdot]=advance(dt,r1,r2,lam,Q,Vdot,f);
 if mod(j,2)==0
   a=f-lam.*Q-c.*Vdot;
   follower(j/2+1,:)=[U*Q;k*Q+d*Vdot+m*a]';
 end
end
for start=51:256:numel(t)
 i=start:min(start+255,numel(t));
 [qq,vv]=advance(t(i)'-21,r1,r2,lam,Q,Vdot,zeros(size(lam)));
 aa=-lam.*qq-c.*vv;follower(i,:)=[U*qq;k*qq+d*vv+m*aa]';
end
for start=1:256:numel(t)
 i=start:min(start+255,numel(t));tau=t(i)'-20;
 [q,v]=step(tau,r1,r2,lam);past=tau>=1;
 [qoff,voff]=step(tau(past)-1,r1,r2,lam);q(:,past)=q(:,past)-qoff;v(:,past)=v(:,past)-voff;
 a=(tau<1)-lam.*q-c.*v;
 tower=U*((F*coef).*q);moment=k*((F*coef).*q)+d*((F*coef).*v)+m*((F*coef).*a);
 towerInputs=(U(1,:)'.*F)'*q;
 worst=sqrt(3)*vecnorm(towerInputs(2:4,:),2,1);
 y(i,:)=[tower;moment;towerInputs(1,:);towerInputs(1,:)-worst;towerInputs(1,:)+worst;[1;(R')*ones(3,1)]'*towerInputs]';
end
writetable(array2table([t follower y],'VariableNames',{'t','towerX','towerY','towerZ','baseMy','towerXnominal','towerYnominal','towerZnominal','baseMynominal','towerXforces','towerXminOrientation','towerXmaxOrientation','towerXtranspose'}),fullfile(out,'linear_replay.csv'));
fprintf('n %d, f1 %.8g Hz, shaft axis %g %g %g, towerX peak %g My peak %g\n',numel(lam),sqrt(lam(1))/(2*pi),shaft,max(abs(follower(:,1))),max(abs(follower(:,4))));
end
function [q,v]=step(t,r1,r2,lam)
% Normalized modal response to a unit step, zero initial state.
q=real((1+(r2.*exp(r1*t)-r1.*exp(r2*t))./(r1-r2))./lam);
v=real((exp(r1*t)-exp(r2*t))./(r1-r2));
end

function [q,v]=advance(t,r1,r2,lam,q0,v0,f)
a=exp(r1*t);b=exp(r2*t);
h=real((a-b)./(r1-r2));hd=real((r1.*a-r2.*b)./(r1-r2));
j=real((r1.*b-r2.*a)./(r1-r2));
q=j.*q0+h.*v0+((1-j)./lam).*f;
v=-lam.*h.*q0+hd.*v0+h.*f;
end
