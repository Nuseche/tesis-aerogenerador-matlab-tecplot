function check_floquet_leading(elements,rpms,targets,steps,F,out)
% Leading multipliers of the full monodromy via matrix-free Arnoldi.
% SDIRK2 uses two full-coordinate sparse dynamic stiffness factorizations
% per step, reused for every Krylov vector.
root=fileparts(fileparts(mfilename('fullpath')));
data=fullfile(root,'runs','periodic_loads_20261118');
if nargin==4
    out=fullfile(root,'runs','stability_20261119');
    if elements==133, source='operators64.mat';
    else, source=sprintf('correctionOperators%d.mat',elements); end
    load(fullfile(data,source),'F');
elseif nargin~=6
    error('Custom Fourier operators require a separate result directory.');
end
if ~isfolder(out),mkdir(out);end
check_floquet_operator_orders(F);
g=1-1/sqrt(2); i0=F.L+1; n=size(F.M{i0},1);
for rpm=rpms
 for target=targets
  w=rpm*pi/30;
  for N=steps
   clock=tic; c=g*2*pi/(N*w); ms=cell(N,2); ks=ms; factors=ms;
   D=cell(1,3); K=D;
   for j=1:3
    k=i0+j-1;
    D{j}=target/0.5*F.D0{k}+w*F.D1{k};
    K{j}=F.K0{k}+target/0.5*w*F.K1{k}+w^2*F.K2{k};
   end
   ix=i0+(0:2); M=F.M(ix);
   for i=1:N
    for j=1:2
     a=[g,1];
     z=exp(1i*(i-1+a(j))*2*pi/N);
     m=at(M,z); d=at(D,z); k=at(K,z);
     ms{i,j}=m; ks{i,j}=c*k;
     factors{i,j}=decomposition(m+c*d+c^2*k,'lu');
    end
   end
   rng(91); propagator=@(v)advance(v,n,N,c,g,ms,ks,factors);
   [V,E,flag]=eigs(propagator,2*n,8,'largestabs','IsFunctionSymmetric',false,'StartVector',randn(2*n,1),'Tolerance',5e-9,'SubspaceDimension',40,'MaxIterations',120);
   assert(flag==0);
   mult=diag(E);[rho,ix]=max(abs(mult));mu=mult(ix);
   resid=norm(propagator(V(:,ix))-mu*V(:,ix))/norm(V(:,ix));
   row=table(elements,n,rpm,target,N,rho,real(mu),imag(mu),log(rho)*w/(2*pi),resid,toc(clock),'VariableNames',{'elements','coordinates','rpm','dampingPercent','stepsPerRevolution','spectralRadius','leadingReal','leadingImag','growthPerSecond','arnoldiResidual','seconds'});
   disp(row);
   writetable(row,fullfile(out,sprintf('arnoldi_%d_%g_%g_%d.csv',elements,rpm,target,N)));
   save(fullfile(out,sprintf('arnoldi_%d_%g_%g_%d.mat',elements,rpm,target,N)),'mult');
   clear ms ks factors propagator
  end
 end
end
end
function b=at(A,z)
b=real(A{1})+2*real(z*A{2}+z^2*A{3});
end
function y=advance(x,n,N,c,g,M,K,factors)
u=x(1:n,:);v=x(n+1:end,:); ratio=(1-g)/g;
for i=1:N
 v1=factors{i,1}\(M{i,1}*v-K{i,1}*u);
 ubar=u+ratio*c*v1; vbar=v+ratio*(v1-v);
 v=factors{i,2}\(M{i,2}*vbar-K{i,2}*ubar);
 u=ubar+c*v;
end
y=[u;v];
end
