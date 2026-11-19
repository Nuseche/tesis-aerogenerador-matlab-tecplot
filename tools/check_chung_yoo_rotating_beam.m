function check_chung_yoo_rotating_beam(meshes)
% Uniform Euler--Bernoulli cantilever, Chung and Yoo, JSV 249 (2002),
% 147--164, DOI 10.1006/jsvi.2001.3856, Eqs. 43--47 and Tables 2--3.
% Use the same preprocessor for G, Kspin, fspin and Kg as the turbine.
if nargin==0, meshes=[10 20 40 80 100 160]; end
maxNumCompThreads(1);
root=fileparts(fileparts(mfilename('fullpath')));
out=fullfile(root,'runs','chung_yoo_20261119');
if ~isfolder(out),mkdir(out);end
cfg=struct('assembly',struct('flexibleOnly',true),'damping',struct('alpha',0,'beta',0));
flapRef=[3.5160 22.0345;3.6816 22.1810;4.1373 22.6149;4.7973 23.3203; ...
    5.5850 24.2733;6.4495 25.4461;7.3604 26.8091;8.2996 28.3341; ...
    9.2568 29.9954;10.2257 31.7705;11.2023 33.6404];
chordRef=[3.6196 4.9700 7.3337;4.3978 13.0482 41.2275;6.6430 27.2660 74.0031];
hubRatios=[0 1 5];spins=[2 10 50];
rows={};checks=[];
for ne=meshes
    for j=1:numel(hubRatios)
        delta=hubRatios(j);
        md=beam(ne,delta);s=aero.prepare_structure(md,cfg);
        x=linspace(0,1,ne+1)';l=x(1:end-1);r=x(2:end);
        meanSquare=(l.^2+l.*r+r.^2)/3;
        exactMean=delta*(1-(l+r)/2)+(1-meanSquare)/2;
        ux=zeros(size(s.M,1),1);ux(md.dofs.node(:,1))=1;
        uy=zeros(size(ux));uy(md.dofs.node(:,2))=1;
        signedGyro=uy.'*s.G*ux;
        checks(end+1,:)=[ne,delta,max(abs(s.axialForceUnitSpin-exactMean))/max(exactMean), ...
            signedGyro,abs(signedGyro-2)/2,norm(s.G+s.G.','fro')/norm(s.G,'fro')];
        if delta==0
            dofs=reshape(md.dofs.node(2:end,[3 5]).',[],1);
            for g=0:10
                vals=eigs(s.Ke(dofs,dofs)+g^2*(s.Kg(dofs,dofs)+s.Kspin(dofs,dofs)), ...
                    s.M(dofs,dofs),2,0,'Tolerance',1e-11);
                f=sort(sqrt(real(vals)));
                for k=1:2
                    value=flapRef(g+1,k);
                    rows(end+1,:)={ne,"flap",k,delta,g,value,f(k),100*(f(k)-value)/value,NaN};
                end
            end
        end
        dofs=reshape(md.dofs.node(2:end,[1 2 6]).',[],1);
        M=s.M(dofs,dofs);
        for i=1:numel(spins)
            g=spins(i);
            K=s.Ke(dofs,dofs)+g^2*(s.Kg(dofs,dofs)+s.Kspin(dofs,dofs));
            G=g*s.G(dofs,dofs);
            f=firstGyroFrequency(M,G,K);
            noGyro=eigs(K,M,1,0,'Tolerance',1e-11);
            value=chordRef(j,i);
            rows(end+1,:)={ne,"chord",1,delta,g,value,f,100*(f-value)/value,sqrt(real(noGyro))};
        end
    end
end
T=cell2table(rows,'VariableNames',{'elements','plane','mode','hubRadiusOverLength','gamma', ...
    'published','calculated','differencePct','frequencyWithoutGyro'});
writetable(T,fullfile(out,'frequencies.csv'));
A=array2table(checks,'VariableNames',{'elements','hubRadiusOverLength','maxCellMeanTensionErrorOverMax', ...
    'gyroscopicResultant','signedGyroRelativeError','skewRelativeError'});
assert(max(A.maxCellMeanTensionErrorOverMax)<1e-9 && max(A.signedGyroRelativeError)<1e-11);
writetable(A,fullfile(out,'operator_checks.csv'));
disp(T(T.elements==max(meshes) & (T.plane=="chord" | T.gamma==10),:));
end

function md=beam(ne,delta)
% L = EI_y = EI_z = mass/length = 1 gives T=1 and EA=alpha^2.
x=linspace(delta,delta+1,ne+1)';xyz=[x,zeros(ne+1,2)];ids=(1:ne)';
md.mesh.nodes=struct('id',(1:ne+1)','xyz',xyz);
md.mesh.elements=struct('id',ids,'nodeI',ids,'nodeJ',ids+1,'blade',ones(ne,1), ...
    'section',ones(ne,1),'auxPoint',xyz(1:end-1,:)+[0 1 0]);
md.sections=struct('id',1,'EA',70^2,'GAy',Inf,'GAz',Inf,'GJ',1,'EIy',1,'EIz',1, ...
    'm',1,'J',zeros(3));
md.dofs.node=reshape(1:6*(ne+1),6,[])';md.dofs.fixed=1:6;
md.rigidBodies=struct('bodies',struct([]),'constraints',struct([]));
md.rotorAxis=struct('direction',[0;0;1],'point',zeros(3,1));
end

function f=firstGyroFrequency(M,G,K)
% Use the inverse of the first-order state operator to isolate low modes.
n=size(M,1);dK=decomposition(K,'lu');
invState=@(x)[-(dK\(G*x(1:n,:)+M*x(n+1:end,:)));x(1:n,:)];
mu=eigs(invState,2*n,4,'largestabs','IsFunctionSymmetric',false,'Tolerance',1e-11,'StartVector',ones(2*n,1));
lambda=1./mu;
assert(max(abs(real(lambda)))<1e-5*max(abs(lambda)),'Expected purely oscillatory eigenvalues.');
f=min(abs(imag(lambda)));
end
