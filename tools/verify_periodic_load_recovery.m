function report=verify_periodic_load_recovery()
% Independent real Fourier collocation in azimuth with direct phase recovery.
% Periodicity is enforced by the differentiation matrices, using the actual
% operating speed at each collocation point and no harmonic operator cache.
root=fileparts(fileparts(mfilename('fullpath')));addpath(root,fullfile(root,'cases'));
folder=fullfile(root,'runs','periodic_loads_20261118');
load(fullfile(folder,'operators64.mat'),'cfg');load(fullfile(folder,'campaign.mat'),'raw');
maxNumCompThreads(1);rpm=3.4445;w=rpm*pi/30;
md=model.build_model(io.load_model_data(cfg),cfg);s=aero.prepare_structure(md,cfg);
[~,~,ec]=assembly.assemble_structural_matrices(md,cfg);er=ec(find([ec.blade]==1 & [ec.assembled],1));
f=zeros(s.ndof,2);axis=md.rotorAxis.direction(:);hub=md.dofs.node(130,1:3);f(hub,1)=axis;f(hub(2),2)=1;
select=sparse(3,s.ndof);select(1,hub)=axis';select(2,md.dofs.node(129,1:3))=axis';select(3,md.dofs.node(56,1:3))=axis';
base=md.dofs.node(1,[5 4]);ref=raw{find(cellfun(@(a)~isempty(a)&&abs(a.rpm-rpm)<1e-8,raw),1)}.reference;
N=19;phase=(0:N-1)'*(2*pi/N)+.057;orders=[0:(N-1)/2,-(N-1)/2:-1];
E=exp(1i*phase*orders);D1=real(E*diag(1i*w*orders)*E'/N);D2=real(E*diag(-(w*orders).^2)*E'/N);
mass=cell(N,1);damp=mass;stiff=mass;ops=mass;B=zeros(s.n*N,2);
for j=1:N
 op=aero.turbine_mbc_operators(s,phase(j),w);ops{j}=op;
 mass{j}=op.M;damp{j}=op.D;stiff{j}=op.K;rows=(j-1)*s.n+(1:s.n);
 B(rows,:)=op.recovery.'*f*cos(3*phase(j));
end
A=blkdiag(stiff{:})+blkdiag(damp{:})*kron(sparse(D1),speye(s.n))+blkdiag(mass{:})*kron(sparse(D2),speye(s.n));
fprintf('Collocation system %d rows, %d nonzeros\n',length(A),nnz(A));
tic;u=A\B;ts=toc;res=norm(A*u-B,'fro')/norm(B,'fro');clear A
full=zeros(s.ndof,N,2);y=zeros(7,N,2);for j=1:N
 rows=(j-1)*s.n+(1:s.n);op=ops{j};
 for b=1:2
  full(:,j,b)=op.recovery*u(rows,b);
  y(1:3,j,b)=select*full(:,j,b);
  local=er.Te*(op.physicalOperators.Q(er.dofs,er.dofs)'*full(er.dofs,j,b));
  nodal=er.KeLocal*local;y(6:7,j,b)=nodal(5:6);
 end
end
stats={};
for b=1:2
 q=full(:,:,b);y(4:5,:,b)=s.M(base,:)*(q*D2')+s.C(base,:)*(q*D1')+s.Ke(base,:)*q;
 direct=y(:,:,b);refhist=real(ref(:,:,b)*exp(1i*(-24:24)'*phase'));
 for c=1:7
  error=norm(direct(c,:)-refhist(c,:))/norm(refhist(c,:));
  primary=2*direct(c,:)*exp(-3i*phase)/N;
  stats(end+1,:)={c,b,error,abs(primary),angle(primary)*180/pi,res,ts};
 end
end
report=cell2table(stats,'VariableNames',{'channel','load','relativeHistoryDifference','primaryAmplitude','primaryPhaseDeg','forceResidual','solveSeconds'});
disp(report);writetable(report,fullfile(folder,'verification_collocation.csv'));
assert(max(report.relativeHistoryDifference)<1e-6 && res<1e-7, ...
    'Independent full-space collocation or reaction recovery failed.');
% Independent scalar solution with periodic mass and exactly cancelling
% stiffness modulation. For the prescribed 3P harmonic, inertia and
% stiffness modulation cancel analytically including the sine component.
p=2*pi*(0:63)/64;omega=.7;nu=3*omega;coef=.2*cos(2*p);
a=dynamics.harmonic_balance(reshape(1+coef,1,1,[]),reshape(.4+0*p,1,1,[]),reshape(9+nu^2*coef,1,1,[]),omega,3,1,9);
x=1/(9-nu^2+1i*.4*nu);ee=abs(2*a.coefficients(1,a.orders==3)-x)/abs(x);
nonprimary=norm(a.coefficients(1,abs(a.orders)~=3))/abs(x);
writetable(table(ee,nonprimary,'VariableNames',{'relativePrimaryError','relativeSidebandLeakage'}),fullfile(folder,'verification_manufactured.csv'));
assert(ee<1e-12&&nonprimary<1e-12);
verifyCantilever(folder);
save(fullfile(folder,'verification_collocation.mat'),'phase','y','report','ee','nonprimary');
end

function verifyCantilever(folder)
% Continuum frequency response of a uniform, clamped-free Timoshenko beam.
% u,theta,V,M obey the first-order section-equilibrium/kinematic equations.
% Compare tip displacement and total support reactions to the assembled FE
% solution. The unit transverse tip force and zero tip couple are identical.
L=5;h=.5;E=210e9;nu=.3;density=7850;A=h^2;I=h^4/12;
GA=5/6*E/(2*(1+nu))*A;EI=E*I;mu=density*A;j=density*I;
sec=struct('EA',E*A,'GAy',GA,'GAz',GA,'GJ',E/(2*(1+nu))*.1406*h^4, ...
    'EIy',EI,'EIz',EI,'m',mu,'Jx',2*j,'Jy',j,'Jz',j,'ycg',0,'zcg',0);
rows={};
for freq=[12 20]
 w=2*pi*freq;
 state=[0 1 1/GA 0;0 0 0 1/EI;-mu*w^2 0 0 0;0 -j*w^2 -1 0];
 propagator=expm(state*L);v0=propagator(3:4,3:4)\[1;0];tip=propagator*[0;0;v0];
 for ne=[8 16 32 64]
  [ke,me]=elements.timoshenko3d_matrices(L/ne,sec);ii=[2 6 8 12];H=sparse(2*(ne+1),2*(ne+1));Hloc=ke(ii,ii)-w^2*me(ii,ii);
  for e=1:ne,ix=2*(e-1)+(1:4);H(ix,ix)=H(ix,ix)+Hloc;end
  f=zeros(size(H,1),1);f(end-1)=1;q=[0;0;H(3:end,3:end)\f(3:end)];r=H(1:2,:)*q;
  er=abs(([q(end-1);r]-[tip(1);-v0])./[tip(1);-v0]);
  rows(end+1,:)={freq,ne,tip(1),-v0(1),-v0(2),q(end-1),r(1),r(2),er(1),er(2),er(3)};
 end
end
data=cell2table(rows,'VariableNames',{'frequencyHz','elements','exactTipM','exactShearN','exactMomentNm','FETipM','FEShearN','FEMomentNm','relativeTipError','relativeShearError','relativeMomentError'});
disp(data);writetable(data,fullfile(folder,'verification_continuum.csv'));
assert(max(data{data.elements==64,9:11},[],'all')<1e-4,'Cantilever continuum error exceeded tolerance.');
end
