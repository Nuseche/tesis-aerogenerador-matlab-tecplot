function rows=check_periodic_stability(elements,rpms,targets,steps)
% All columns of the one-revolution state transition for the homogeneous
% multiblade equations. Targets are percent critical at 0.17 and 1 Hz.
root=fileparts(fileparts(mfilename('fullpath')));
data=fullfile(root,'runs','periodic_loads_20261118');
out=fullfile(root,'runs','stability_20261119');
if ~isfolder(out),mkdir(out);end
if elements==133
    source='operators64.mat';
else
    source=sprintf('correctionOperators%d.mat',elements);
end
load(fullfile(data,source),'F');
check_floquet_operator_orders(F);
rows=table();
for rpm=rpms
    for target=targets
        for N=steps
            clock=tic;
            w=rpm*pi/30; gamma=1-1/sqrt(2); h=2*pi/(N*w); c=gamma*h;
            ix=F.L+1+(0:2);
            M=F.M(ix); D=cell(1,3); K=D;
            for j=1:3
                k=ix(j);
                D{j}=target/0.5*F.D0{k}+w*F.D1{k};
                K{j}=F.K0{k}+target/0.5*w*F.K1{k}+w^2*F.K2{k};
            end
            n=size(M{1},1);
            U=[eye(n),zeros(n)]; V=[zeros(n),eye(n)];
            for i=0:N-1
                [u1,v1]=stage(U,V,(i+gamma)*2*pi/N,c,M,D,K);
                ratio=(1-gamma)/gamma;
                [U,V]=stage(U+ratio*(u1-U),V+ratio*(v1-V),(i+1)*2*pi/N,c,M,D,K);
            end
            P=[U;V];
            multipliers=eig(P);
            [rho,j]=max(abs(multipliers)); mu=multipliers(j);
            row=table(elements,n,rpm,target,N,rho,real(mu),imag(mu),log(rho)*w/(2*pi),sum(abs(multipliers)>1),toc(clock),'VariableNames',{'elements','coordinates','rpm','dampingPercent','stepsPerRevolution','spectralRadius','leadingReal','leadingImag','growthPerSecond','outsideUnitCircle','seconds'});
            disp(row);
            rows=[rows;row];
            filename=sprintf('floquet_%d_%g_%g_%d',elements,rpm,target,N);
            writetable(row,fullfile(out,[filename,'.csv']));
            save(fullfile(out,[filename,'.mat']),'multipliers');
        end
    end
end
end

function [u,v]=stage(u0,v0,psi,c,M,D,K)
z=exp(1i*psi);
mass=real(M{1})+2*real(z*M{2}+z^2*M{3});
damp=real(D{1})+2*real(z*D{2}+z^2*D{3});
stiff=real(K{1})+2*real(z*K{2}+z^2*K{3});
v=(mass+c*damp+c^2*stiff)\(mass*v0-c*(stiff*u0));
u=u0+c*v;
end
