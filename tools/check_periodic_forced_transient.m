function check_periodic_forced_transient(rpm, steps, revolutions, elements, dampingPercent)
% Start the complete periodic model at rest under unit axial cos(3 psi) forcing.
% Compare each sampled revolution with the H=12 particular moment history.
if nargin<1, rpm=3.4445; end
if nargin<2, steps=768; end
if nargin<3, revolutions=150; end
if nargin<4, elements=133; end
if nargin<5, dampingPercent=0.5; end
maxNumCompThreads(1);
root=fileparts(fileparts(mfilename('fullpath')));
out=fullfile(root,'runs','periodic_loads_20261118');
if elements==133
    cache='operators64.mat';
else
    cache=sprintf('correctionOperators%d.mat',elements);
end
S=load(fullfile(out,cache),'F');
F=S.F;
for name=["D0","K1","O10","O01"]
    F.(name)=cellfun(@(x)(dampingPercent/.5)*x,F.(name),'UniformOutput',false);
end
solver=run_periodic_load_campaign("solver_handles");
w=rpm*pi/30;
dt=2*pi/(w*steps);
n=size(F.M{F.L+1},1);
Y=solver.solve(F,[],w,12,false);
angles=2*pi*(1:steps)/steps;
ref=real(Y(4,:,1)*exp(1i*(-F.outputH:F.outputH)'*angles));
D=cell(steps,1);
K=cell(steps,1);
factors=cell(steps,1);
Oq=cell(steps,1);
Ov=cell(steps,1);
Oa=cell(steps,1);
loadHistory=zeros(n,steps);
for j=1:steps
    az=angles(j);
    Mj=matrixAt(F.M,az,F.L);
    D{j}=matrixAt(F.D0,az,F.L)+w*matrixAt(F.D1,az,F.L);
    K{j}=matrixAt(F.K0,az,F.L)+w*matrixAt(F.K1,az,F.L)+w^2*matrixAt(F.K2,az,F.L);
    factors{j}=decomposition(Mj+(dt/2)*D{j}+(dt^2/4)*K{j},'lu');
    O=matrixAt(F.O00,az,F.L)+w*matrixAt(F.O01,az,F.L)+w^2*matrixAt(F.O02,az,F.L);
    Oq{j}=O(4,:);
    O=matrixAt(F.O10,az,F.L)+w*matrixAt(F.O11,az,F.L);
    Ov{j}=O(4,:);
    O=matrixAt(F.O2,az,F.L);
    Oa{j}=O(4,:);
    b=matrixAt(F.B,az,F.L);
    loadHistory(:,j)=b(:,1)*cos(3*az);
end
% The final azimuth node is 2*pi, identical to the initial azimuth.
q=zeros(n,1);
v=zeros(n,1);
a=Mj\loadHistory(:,end);
history=zeros(1,steps);
rows=zeros(revolutions,8);
refamp=2*sum(ref.*exp(-3i*angles))/steps;
for rev=1:revolutions
    for j=1:steps
        qp=q+dt*v+(dt^2/4)*a;
        vp=v+(dt/2)*a;
        a=factors{j}\(loadHistory(:,j)-D{j}*vp-K{j}*qp);
        q=qp+(dt^2/4)*a;
        v=vp+(dt/2)*a;
        history(j)=Oq{j}*q+Ov{j}*v+Oa{j}*a;
    end
    amp=2*sum(history.*exp(-3i*angles))/steps;
    rows(rev,:)=[rpm,steps,rev,100*norm(history-ref)/norm(ref),abs(amp),angle(amp/refamp)*180/pi,abs(refamp),dt];
    if mod(rev,10)==0, fprintf('%d/%d revolutions (N=%d), error %.5g%%\n',rev,revolutions,steps,rows(rev,4));end
end
T=array2table(rows,'VariableNames',{'rpm','stepsPerRev','revolution','baseHistoryErrorPct','baseAmplitude','phaseMinusFourierDeg','fourierAmplitude','dt'});
if elements==133 && dampingPercent==.5
    filename=sprintf('newmark_periodic_%g_%d.csv',rpm,steps);
else
    filename=sprintf('newmark_periodic_%del_%gpct_%g_%d.csv',elements,dampingPercent,rpm,steps);
end
T.elements=repmat(elements,height(T),1);
T.dampingPercent=repmat(dampingPercent,height(T),1);
writetable(T,fullfile(out,filename));
end

function A=matrixAt(coefs,psi,L)
A=real(coefs{L+1});
for l=1:L
    c=coefs{L+1+l};
    if nnz(c), A=A+2*real(c*exp(1i*l*psi));end
end
end
