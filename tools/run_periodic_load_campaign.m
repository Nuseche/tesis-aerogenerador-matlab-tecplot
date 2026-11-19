function results=run_periodic_load_campaign(mode)
% Controlled periodic/averaged, full/reduced comparison, no SIMPACT.
if nargin<1,mode="pilot";end
root=fileparts(fileparts(mfilename('fullpath')));addpath(root,fullfile(root,'cases'));
out=fullfile(root,'runs','periodic_loads_20261118');if ~isfolder(out),mkdir(out);end
rng(20261118);maxNumCompThreads(1);
cache=fullfile(out,'operators64.mat');
if ~isfile(cache)
 cfg=config_aeroelastic_snl100();cfg.gravity.enabled=false;
 z=.005;wa=2*pi*.17;wb=2*pi;cfg.damping.alpha=2*z*wa*wb/(wa+wb);cfg.damping.beta=2*z/(wa+wb);
 md=model.build_model(io.load_model_data(cfg),cfg);s=aero.prepare_structure(md,cfg);
 [~,~,ec]=assembly.assemble_structural_matrices(md,cfg);
 [F,checks]=sampleFourier(s,ec,64,12);
 [V,L]=eigs(F.M{13},F.K0{13},194,'largestabs'); % inverted generalized eigenproblem
 lam=1./real(diag(L));[lam,ix]=sort(lam);V=real(V(:,ix));
 for j=1:size(V,2),V(:,j)=V(:,j)/sqrt(real(V(:,j)'*F.M{13}*V(:,j)));end
 save(cache,'F','checks','V','lam','cfg','-v7.3');
 fprintf('Sampled operators; n=%d, Fourier tail=%g\n',size(V,1),checks.tailRelative);
else,load(cache,'F','checks','V','lam','cfg');end
if mode=="pilot"
 cases=[3.4445,6;3.4445,9];rows={};
 for j=1:size(cases,1)
  clock=tic;[Y,meta]=solveCase(F,[],cases(j,1)*pi/30,cases(j,2),false);
  rows(end+1,:)={cases(j,1),cases(j,2),meta.dimension,meta.residual,toc(clock),abs(2*Y(1,25+3,1)),abs(2*Y(4,25+3,1))};
  save(fullfile(out,sprintf('pilot_H%d.mat',cases(j,2))),'Y','meta');disp(rows(end,:));
 end
 results=cell2table(rows,'VariableNames',{'rpm','H','dimension','residual','seconds','hub3P','baseMy3P'});writetable(results,fullfile(out,'pilot.csv'));return
end
if mode=="sweep"
 rows={};
 for rpm=unique([2.8:0.025:3.9,3.32:0.002:3.49,3.4445,4])
  w=rpm*pi/30;[yp,~]=solveCase(F,[],w,6,false);[ya,~]=solveCase(F,[],w,0,true);
  for c=[1,4,6],for b=1:2
   a=2*ya(c,28,b);p=2*yp(c,28,b);
   rows(end+1,:)={rpm,c,b,abs(a),angle(a)*180/pi,abs(p),angle(p)*180/pi};
  end,end
 end
 results=cell2table(rows,'VariableNames',{'rpm','channel','load','averageAbs','averagePhase','periodicAbs','periodicPhase'});writetable(results,fullfile(out,'speed_sweep.csv'));return
end
if mode=="angular"
 md=model.build_model(io.load_model_data(cfg),cfg);s=aero.prepare_structure(md,cfg);[~,~,ec]=assembly.assemble_structural_matrices(md,cfg);
 [F96,checks96]=sampleFourier(s,ec,96,12);rows={};
 for rpm=[2.8,3.4445,4]
  [a,ma]=solveCase(F,[],rpm*pi/30,12,false);[b,mb]=solveCase(F96,[],rpm*pi/30,12,false);
  for c=1:size(a,1),for bidx=1:2
   er=100*norm(squeeze(a(c,:,bidx)-b(c,:,bidx)))/max(norm(squeeze(b(c,:,bidx))),1e-30);
   rows(end+1,:)={rpm,c,bidx,er,ma.residual,mb.residual};
  end,end
 end
 results=cell2table(rows,'VariableNames',{'rpm','channel','load','errorPercent','residual64','residual96'});writetable(results,fullfile(out,'angular_check.csv'));save(fullfile(out,'operators96.mat'),'F96','checks96','-v7.3');return
end
rpms=[2.8 3.35 3.4445 3.55 4];counts=[12 24 48 96];rows={};convergence={};costs={};raw=cell(numel(rpms),1);
for j=1:numel(rpms)
 rpm=rpms(j);w=rpm*pi/30;
 clock=tic;[Yref,mref]=solveCase(F,[],w,12,false);refSeconds=toc(clock);
 [Y9,m9]=solveCase(F,[],w,9,false);[Y6,m6]=solveCase(F,[],w,6,false);
 [Yavg,mavg]=solveCase(F,[],w,0,true);
 for c=1:size(Yref,1),for b=1:2
  ref=squeeze(Yref(c,:,b));den=max(norm(ref),1e-30);
  convergence(end+1,:)={rpm,c,b,100*norm(squeeze(Y9(c,:,b))-ref)/den,100*norm(squeeze(Y6(c,:,b))-ref)/den,den,mref.residual,m9.residual,m6.residual};
 end,end
 rows=appendMetrics(rows,rpm,"full_average",804,0,Yavg,Yref,Yavg,Yavg);
 costs(end+1,:)={rpm,"full_periodic",804,12,0,refSeconds,mref.solveSeconds,mref.recoverySeconds,mref.residual};
 costs(end+1,:)={rpm,"full_average",804,0,0,mavg.totalSeconds,mavg.solveSeconds,mavg.recoverySeconds,mavg.residual};
 models={};
 for count=counts
  for kind=["modal","ritz","equal_order"]
   prep=tic;Q=V(:,1:count);
   if kind=="ritz"
    M=F.M{13};K=F.K0{13};B=F.B{13};R=K\B;R=R-Q*(Q'*M*R);
    % SVD of whitened residual Gram avoids dependent enrichment columns.
    G=(R'*M*R);[U,S]=eig((G+G')/2);d=real(diag(S));keep=d>max(d)*1e-10;
    Q=[Q,R*U(:,keep)*diag(1./sqrt(d(keep)))];
   elseif kind=="equal_order",Q=V(:,1:count+2);end
   Fq=project(F,Q);preptime=toc(prep);
   [Yr,mr]=solveCase(Fq,[],w,9,false);[Ya,ma]=solveCase(Fq,[],w,0,true);
   label=kind+string(count);rows=appendMetrics(rows,rpm,label,size(Q,2),9,Yr,Yref,Ya,Yavg);
   rows=appendMetrics(rows,rpm,label+"_average",size(Q,2),0,Ya,Yref,Ya,Yavg);
   costs(end+1,:)={rpm,label,size(Q,2),9,preptime,mr.totalSeconds,mr.solveSeconds,mr.recoverySeconds,mr.residual};
   costs(end+1,:)={rpm,label+"_average",size(Q,2),0,preptime,ma.totalSeconds,ma.solveSeconds,ma.recoverySeconds,ma.residual};
   models{end+1}=struct('label',label,'Yperiodic',Yr,'Yaverage',Ya,'meta',mr,'basis',Q);
  end
 end
 raw{j}=struct('rpm',rpm,'reference',Yref,'H9',Y9,'H6',Y6,'average',Yavg,'models',{models});
 results=cell2table(rows,'VariableNames',{'rpm','model','dimension','H','channel','load','historyErrorPercent','primaryComplexErrorPercent','primaryAmplitudeErrorPercent','primaryPhaseErrorDeg','referencePrimaryAbs','referenceHistoryNorm','periodicVersusAveragePercent','averagedROMErrorPercent'});
 conv=cell2table(convergence,'VariableNames',{'rpm','channel','load','H9to12Percent','H6to12Percent','referenceNorm','residual12','residual9','residual6'});
 timing=cell2table(costs,'VariableNames',{'rpm','model','dimension','H','projectionSeconds','totalSeconds','solveSeconds','recoverySeconds','residual'});
 writetable(results,fullfile(out,'errors.csv'));writetable(conv,fullfile(out,'harmonic_convergence.csv'));writetable(timing,fullfile(out,'costs.csv'));
 save(fullfile(out,'campaign.mat'),'raw','results','conv','timing','checks','cfg','lam','-v7.3');
 fprintf('Completed rpm %.6g (%d/%d); full reference %.3gs\n',rpm,j,numel(rpms),refSeconds);
end
end

function [F,checks]=sampleFourier(s,ec,N,L)
n=s.n;nd=s.ndof;names={'M','D0','D1','K0','K1','K2','O2','O10','O11','O00','O01','O02','B'};
F=struct('L',L,'N',N,'outputH',24,'channels',["hub_axial_m","nacelle_axial_m","blade1_tip_axial_m","base_My_Nm","base_Mx_Nm","blade1_root_elastic_M2_Nm","blade1_root_elastic_M3_Nm"]);
for name=names,F.(name{1})=cell(1,2*L+1);end
load=zeros(nd,2);axis=s.model.rotorAxis.direction;hub=s.model.dofs.node(130,1:3);load(hub,1)=axis;load(hub(2),2)=1;
root=find([ec.blade]==1 & [ec.assembled],1);er=ec(root);base=s.model.dofs.node(1,[5 4]);
S=sparse(3,nd);S(1,hub)=axis';S(2,s.model.dofs.node(129,1:3))=axis';S(3,s.model.dofs.node(56,1:3))=axis';
checks=struct('baseRowInvariance',0,'forceVariation',0,'reconstruction',0,'tailRelative',0);
for j=1:N
 psi=2*pi*(j-1)/N;a=aero.turbine_mbc_operators(s,psi,0);p=aero.turbine_mbc_operators(s,psi,1);m=aero.turbine_mbc_operators(s,psi,-1);
 R=a.recovery;P=p.transformation;ct=rigid.rotating_constraint_derivatives(s.model,s.model.rigidBodies,psi,1,struct('angularAcceleration',0));
 T=ct.T(:,s.free);Td=ct.Tdot(:,s.free);Tdd=ct.Tddot(:,s.free);
 Rd=Td*P.T+T*P.Tdot;Rdd=Tdd*P.T+2*Td*P.Tdot+T*P.Tddot;
 O00=sparse(7,n);O01=O00;O02=O00;O10=O00;O11=O00;O2=O00;
 O00(1:3,:)=S*R;O00(4:5,:)=s.Ke(base,:)*R;O01(4:5,:)=s.C(base,:)*Rd;O02(4:5,:)=s.M(base,:)*Rdd;
 O10(4:5,:)=s.C(base,:)*R;O11(4:5,:)=2*s.M(base,:)*Rd;O2(4:5,:)=s.M(base,:)*R;
 O00(6:7,:)=er.KeLocal([5 6],:)*er.Te*p.physicalOperators.Q(er.dofs,er.dofs)'*R(er.dofs,:);
 z=struct('M',a.M,'D0',a.D,'D1',(p.D-m.D)/2,'K0',a.K,'K1',(p.K-m.K)/2,'K2',(p.K+m.K)/2-a.K, ...
 'O2',O2,'O10',O10,'O11',O11,'O00',O00,'O01',O01,'O02',O02,'B',R'*load);
 for name=names
  key=name{1};for l=-L:L
   v=z.(key)*exp(-1i*l*psi)/N;
   if j==1,F.(key){l+L+1}=v;else,F.(key){l+L+1}=F.(key){l+L+1}+v;end
  end
 end
 if mod(j,16)==0,fprintf('Operator samples %d/%d\n',j,N);end
end
for name=names
 key=name{1};sc=max(cellfun(@(x)norm(x,'fro'),F.(key)));tail=0;
 for l=-L:L
  v=F.(key){l+L+1};nv=norm(v,'fro');if abs(l)>=L-1,tail=tail+nv;end
  if nv<1e-12*max(sc,eps),F.(key){l+L+1}=sparse(size(v,1),size(v,2));end
 end
 checks.tailRelative=max(checks.tailRelative,tail/max(sc,eps));
end
% Off-grid Fourier reconstruction check, independent of quadrature nodes.
psi=.1234567;w=.36;o=aero.turbine_mbc_operators(s,psi,w);ma=0;da=0;ka=0;
for l=-L:L,ix=l+L+1;z=exp(1i*l*psi);ma=ma+F.M{ix}*z;da=da+(F.D0{ix}+w*F.D1{ix})*z;ka=ka+(F.K0{ix}+w*F.K1{ix}+w*w*F.K2{ix})*z;end
checks.reconstruction=max([norm(ma-o.M,'fro')/norm(o.M,'fro'),norm(da-o.D,'fro')/norm(o.D,'fro'),norm(ka-o.K,'fro')/norm(o.K,'fro')]);
checks.rootElement=er.id;checks.N=N;checks.L=L;checks.scope='prescribed structural rotation; elastic perturbation; no gravity/aero; root elastic end moments exclude prestress and inertia';
end

function G=project(F,Q)
G=F;for key={'M','D0','D1','K0','K1','K2'}
 for j=1:numel(F.(key{1})),G.(key{1}){j}=Q'*F.(key{1}){j}*Q;end
end
for key={'O2','O10','O11','O00','O01','O02'}
 for j=1:numel(F.(key{1})),G.(key{1}){j}=F.(key{1}){j}*Q;end
end
for j=1:numel(F.B),G.B{j}=Q'*F.B{j};end
end

function [Y,meta]=solveCase(F,Q,w,H,averaged)
clock=tic;if ~isempty(Q),F=project(F,Q);end
n=size(F.M{F.L+1},1);L=F.L;
if averaged,hs=[-3 3];else,hs=-H:H;end
nh=numel(hs);blocks=cell(nh);rhs=zeros(n*nh,2);
for ih=1:nh
 h=hs(ih);rr=(ih-1)*n+(1:n);
 for l=[h-3 h+3],if abs(l)<=L&&(~averaged||l==0),rhs(rr,:)=rhs(rr,:)+.5*F.B{l+L+1};end,end
 for ik=1:nh
  k=hs(ik);l=h-k;
  if abs(l)>L||(averaged&&l~=0),blocks{ih,ik}=sparse(n,n);continue,end
  ix=l+L+1;blocks{ih,ik}=sparse(F.K0{ix}+w*F.K1{ix}+w*w*F.K2{ix}+1i*k*w*(F.D0{ix}+w*F.D1{ix})-(k*w)^2*F.M{ix});
 end
end
A=cell2mat(blocks);clear blocks;tt=tic;X=A\rhs;solveSeconds=toc(tt);residual=norm(A*X-rhs,'fro')/max(norm(rhs,'fro'),eps);
X=reshape(X,n,nh,2);tt=tic;Y=zeros(7,2*F.outputH+1,2);
for ih=1:nh
 k=hs(ih);for l=-L:L
  % Keep physical output maps even when dynamic operators are averaged.
  h=k+l;if abs(h)>F.outputH,continue,end
  ix=l+L+1;O=F.O00{ix}+w*F.O01{ix}+w*w*F.O02{ix}+1i*k*w*(F.O10{ix}+w*F.O11{ix})-(k*w)^2*F.O2{ix};
  for b=1:2,Y(:,h+F.outputH+1,b)=Y(:,h+F.outputH+1,b)+O*X(:,ih,b);end
 end
end
meta=struct('dimension',n,'H',H,'residual',residual,'solveSeconds',solveSeconds,'recoverySeconds',toc(tt),'totalSeconds',toc(clock),'nnz',nnz(A));
end

function rows=appendMetrics(rows,rpm,label,n,H,Y,ref,Ya,fullavg)
for c=1:size(Y,1),for b=1:2
 r=squeeze(ref(c,:,b));v=squeeze(Y(c,:,b));a=squeeze(Ya(c,:,b));fa=squeeze(fullavg(c,:,b));den=max(norm(r),1e-30);p=28;
 primary=abs(r(p));valid=primary>1e-8*den;
 if valid,ce=100*abs(v(p)-r(p))/primary;ae=100*abs(abs(v(p))-primary)/primary;pe=angle(v(p)/r(p))*180/pi;else,ce=NaN;ae=NaN;pe=NaN;end
 rows(end+1,:)={rpm,label,n,H,c,b,100*norm(v-r)/den,ce,ae,pe,2*primary,den,100*norm(v-a)/den,100*norm(a-fa)/max(norm(fa),1e-30)};
end,end
end
