function results=run_rotating_term_study(elements,target,mode)
% Base My sensitivity to deleting transported physical G and/or blade Kg.
% Use full H=6 histories for sweeps and independent H=12 refinements.
if nargin<1,elements=266;end
if nargin<2,target=.5;end
if nargin<3,mode="sweep";end
root=fileparts(fileparts(mfilename('fullpath')));
addpath(root,fullfile(root,'cases'));maxNumCompThreads(1);
prior=fullfile(root,'runs','periodic_loads_20261118');
out=fullfile(root,'runs','rotating_term_study');if ~isfolder(out),mkdir(out);end
cfgdata=load(fullfile(prior,'operators64.mat'),'cfg');cfg=cfgdata.cfg;
solver=run_periodic_load_campaign("solver_handles");
md=model.build_model(io.load_model_data(cfg),cfg);
cache='operators64.mat';
if elements==266 || elements==532
    md=solver.bisect(md);if elements==532,md=solver.bisect(md);end
    cache=sprintf('correctionOperators%d.mat',elements);
elseif elements~=133
    error('Supported meshes are 133, 266 and 532.');
end
base=load(fullfile(prior,cache),'F');F=base.F;
s=aero.prepare_structure(md,cfg);
% These mechanisms act at rotating elements. The fixed-base balance row
% contains neither, so its physical recovery operator is identical in all cases.
baseRow=md.dofs.node(1,5);
assert(nnz(s.G(baseRow,:))==0 && nnz(s.Kg(baseRow,:))==0);
parts=sampleTerms(s,F);
verifyTerms(s,parts,F,out,elements,target);
for key=["D0","K1","O10","O01"]
    F.(key)=cellfun(@(v)v*target/.5,F.(key),'UniformOutput',false);
end
variants={F,F,F,F};names=["complete","omitG","omitKg","omitBoth"];
for j=2:4
    for k=1:2*F.L+1
        if j==2 || j==4
            variants{j}.D1{k}=variants{j}.D1{k}-parts{k,1};
            variants{j}.K2{k}=variants{j}.K2{k}-parts{k,2};
        end
        if j==3 || j==4,variants{j}.K2{k}=variants{j}.K2{k}-parts{k,3};end
    end
end
if mode=="stability"
    % The Floquet driver takes base operators at 0.5% and scales targets internally.
    assert(target==.5);
    results=table();
    for j=1:4
        subdir=fullfile(out,"floquet_"+names(j));
        check_floquet_leading(elements,3.4,target,128,variants{j},subdir);
        row=readtable(fullfile(subdir,sprintf('arnoldi_%d_3.4_0.5_128.csv',elements)));
        row.variant=names(j);results=[results;row];
    end
    writetable(results,fullfile(out,sprintf('term_floquet_%d.csv',elements)));
    return
end
assert(mode=="sweep");
selected=[3.35 3.394 3.4 3.42 3.4445 3.49];
if elements==266 && target==.5
    speeds=unique(round([2.8:.025:4,3.3:.002:3.53,selected],6));
else
    speeds=selected;
end
ids=string(elements)+"_"+string(round(10*target));
results=sweep(solver,variants,names,speeds,6);
writetable(results,fullfile(out,"term_sweep_"+ids+".csv"));
peakSpeeds=zeros(1,4);
for j=1:4
    ss=results(results.variant==names(j),:);
    [~,peak]=max(ss.amplitude);
    peakSpeeds(j)=ss.rpm(peak);
    fprintf('%s peak at %.6f rpm; max history %.4f percent\n',names(j),ss.rpm(peak),max(ss.historyChangePct));
end
test=sweep(solver,variants,names,unique([3.394 3.4 3.4445 peakSpeeds]),12);
writetable(test,fullfile(out,"term_H12_"+ids+".csv"));
end

function terms=components(s,psi)
op=aero.turbine_mbc_operators(s,psi,1);
ct=rigid.rotating_constraint_derivatives(s.model,s.model.rigidBodies,psi,1,struct('angularAcceleration',0));
R=op.recovery;P=op.transformation;Q=op.physicalOperators.Q;
Rd=ct.Tdot(:,s.free)*P.T+ct.T(:,s.free)*P.Tdot;
H=Q'*R;
% Hdot accounts for the spin-frame velocity and both moving-coordinate maps.
Hd=Q'*Rd-s.W*H;
terms={H'*s.G*H,H'*s.G*Hd,H'*s.Kg*H};
end

function parts=sampleTerms(s,F)
parts=cell(2*F.L+1,3);
for j=1:F.N
    psi=2*pi*(j-1)/F.N; a=components(s,psi);
    for k=-F.L:F.L
        phase=exp(-1i*k*psi)/F.N;
        for h=1:3
            idx=k+F.L+1;
            if j==1,parts{idx,h}=phase*a{h};else,parts{idx,h}=parts{idx,h}+phase*a{h};end
        end
    end
end
for h=1:3
    scale=max(cellfun(@(a)norm(a,'fro'),parts(:,h)));
    for i=1:size(parts,1)
        if norm(parts{i,h},'fro')<1e-12*scale,parts{i,h}=sparse(s.n,s.n);end
    end
end
end

function verifyTerms(s,parts,F,out,ne,target)
psi=.37129;w=3.4*pi/30;
op=aero.turbine_mbc_operators(s,psi,w);
t=s;t.G=sparse(s.ndof,s.ndof);g=aero.turbine_mbc_operators(t,psi,w);
t=s;t.Kg=sparse(s.ndof,s.ndof);p=aero.turbine_mbc_operators(t,psi,w);
observed={op.D-g.D,op.K-g.K,op.K-p.K};
power=[1,2,2];diff=zeros(1,3);
for h=1:3
    trial=sparse(s.n,s.n);
    for k=-F.L:F.L, trial=trial+exp(1i*k*psi)*parts{k+F.L+1,h};end
    trial=real(trial)*w^power(h);
    diff(h)=norm(trial-observed{h},'fro')/max(norm(trial,'fro'),eps);
end
assert(max(diff)<1e-7,'Transported operator contributions failed verification: %.5g',max(diff));
writetable(array2table([ne,target,diff],'VariableNames',{'elements','targetPercent','DgyroMismatch','KgyroMismatch','KprestressMismatch'}),fullfile(out,sprintf('operator_%d_%d.csv',ne,round(target*10))));
end

function results=sweep(solver,variants,names,speeds,H)
rows=cell(numel(speeds)*4,12);row=0;
for i=1:numel(speeds)
    y=cell(1,4);
    for j=1:4
        [Y,meta]=solver.solve(variants{j},[],speeds(i)*pi/30,H,false);
        y{j}=Y(4,:,1);m=2*y{j}(variants{j}.outputH+4);m0=2*y{1}(variants{j}.outputH+4);
        row=row+1;
        rows(row,:)={speeds(i),names(j),H,real(m),imag(m),abs(m),angle(m)*180/pi,100*(abs(m)/abs(m0)-1),angle(m/m0)*180/pi,100*abs(m-m0)/abs(m0),100*norm(y{j}-y{1})/norm(y{1}),meta.residual};
    end
    if mod(i,20)==0,fprintf('Completed %d of %d speeds, H=%d\n',i,numel(speeds),H);end
end
results=cell2table(rows,'VariableNames',{'rpm','variant','H','real3P','imag3P','amplitude','phaseDeg','amplitudeChangePct','phaseChangeDeg','complexChangePct','historyChangePct','residual'});
end
