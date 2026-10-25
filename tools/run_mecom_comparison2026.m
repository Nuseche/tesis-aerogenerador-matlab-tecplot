function summary = run_mecom_comparison2026(mode)
%RUN_MECOM_COMPARISON2026 Reproducible, explicitly numerical comparisons.
% Writes only a new runs/run_20260914_mecom_comparison directory. No paper,
% existing artifact, production solver, or physical calibration is changed.
root=fileparts(fileparts(mfilename('fullpath')));
if nargin<1,mode="all";end
addpath(root,fullfile(root,'cases'));
out=fullfile(root,'runs','run_20260914_mecom_comparison');
if ~isfolder(out),mkdir(out);end
rng(20260914,'twister');
set(groot,'defaultFigureVisible','off');
meta=struct('date',string(datetime('now','Format','yyyy-MM-dd HH:mm:ss')), ...
    'matlab',string(version),'computer',string(computer), ...
    'maximumComputationalThreads',maxNumCompThreads, ...
    'repetitions',3,'warmupRepetitions',1,'timing','wall seconds, median of 3 after one warmup', ...
    'scope','numerical benchmark; not field or certified turbine validation');
[~,cpu]=system('sysctl -n machdep.cpu.brand_string');meta.cpu=strtrim(string(cpu));
[~,ram]=system('sysctl -n hw.memsize');meta.ramBytes=str2double(strtrim(ram));
fprintf('MECOM comparison started %s\n',meta.date);
if string(mode)=="rayleigh_mac"
    summary=rayleighMAC(out);return
end
if string(mode)=="figures_only"
    existing=load(fullfile(out,'comparison_summary.mat'));
    raw=load(fullfile(out,'global_raw_data.mat'),'outputValues','t','ag');
    bp=existing.summary.beamParameters;
    beamFigures(out,existing.beamTable,existing.beamRef,bp.lengthM,bp.squareHeightsM);
    models=string(existing.costTable.model)';
    names=unique(string(existing.globalTable.output),'stable')';
    globalFigures(out,names,raw.outputValues,models,raw.t, ...
        existing.summary.globalParameters.modalDimensions,existing.globalTable, ...
        existing.costTable,existing.frequencyTable,raw.ag);
    summary=existing.summary;return
end
[beamTable,beamRef,beamParameters]=beamComparison(out);
fprintf('Cantilever comparison completed: %d rows.\n',height(beamTable));
if string(mode)=="beam_only"
    existing=load(fullfile(out,'comparison_summary.mat'));
    existing.beamTable=beamTable;existing.beamRef=beamRef;
    existing.summary.beamParameters=beamParameters;
    existing.summary.beamReferences=table2struct(beamRef);
    existing.summary.beamResults=table2struct(beamTable);
    existing.summary.metadata.beamUpdated=meta.date;
    summary=existing.summary;
    save(fullfile(out,'comparison_summary.mat'),'-struct','existing','-v7.3');
    fid=fopen(fullfile(out,'comparison_summary.json'),'w');
    fwrite(fid,jsonencode(summary,PrettyPrint=true),'char');fclose(fid);
    disp(beamRef);return
end
[globalTable,frequencyTable,historyTable,costTable,globalParameters]=globalComparison(out);
summary=struct('metadata',meta,'beamParameters',beamParameters, ...
    'beamReferences',table2struct(beamRef), ...
    'globalParameters',globalParameters, ...
    'beamResults',table2struct(beamTable), ...
    'globalResults',table2struct(globalTable), ...
    'costResults',table2struct(costTable), ...
    'globalFrequencies',table2struct(frequencyTable));
save(fullfile(out,'comparison_summary.mat'),'summary','beamTable','beamRef', ...
    'globalTable','frequencyTable','historyTable','costTable','-v7.3');
fid=fopen(fullfile(out,'comparison_summary.json'),'w');
fwrite(fid,jsonencode(summary,PrettyPrint=true),'char');fclose(fid);
disp(beamRef);disp(costTable);disp(globalTable);
fprintf('Saved comparison in %s\n',out);
end

function [results,references,parameters]=beamComparison(out)
meshes=[4 8 16 32 64 128];heights=[0.5 0.05];L=5;
E=210e9;nu=.3;rho=7850;kappa=5/6;G=E/(2*(1+nu));P=1;
roots=[1.875104068711961;4.694091132974175;7.854757438237613;10.99554073487547];
parameters=struct('lengthM',L,'squareHeightsM',heights, ...
    'E_Pa',E,'nu',nu,'rho_kgm3',rho,'shearCorrection',kappa, ...
    'tipForceN',P,'meshElements',meshes, ...
    'referenceElements',512,'referenceCheckElements',256, ...
    'mass','consistent; Timoshenko includes rotary inertia; classical EB excludes it', ...
    'modes','first four planar bending modes, clamped-free');
results=table();references=table();
for ih=1:numel(heights)
    h=heights(ih);A=h^2;I=h^4/12;m=rho*A;J=rho*I;
    sec=struct('EA',E*A,'GAy',kappa*G*A,'GAz',kappa*G*A, ...
        'GJ',G*.1406*h^4,'EIy',E*I,'EIz',E*I, ...
        'm',m,'Jx',2*J,'Jy',J,'Jz',J,'ycg',0,'zcg',0);
    [Mt,Kt]=planeBeam(512,L,sec,"Timoshenko");
    fT=frequencies(Kt,Mt,4);
    [Mcheck,Kcheck]=planeBeam(256,L,sec,"Timoshenko");
    fCheck=frequencies(Kcheck,Mcheck,4);
    fEB=roots.^2/(2*pi*L^2)*sqrt(E*I/m);
    dEB=P*L^3/(3*E*I);dT=dEB+P*L/(kappa*G*A);
    for j=1:4
        row=table(L/h,j,fEB(j),fT(j), ...
            100*abs(fT(j)-fEB(j))/fT(j), ...
            100*abs(fCheck(j)-fT(j))/fT(j),dEB,dT, ...
            'VariableNames',{'slenderness','mode','fEBAnalyticalHz', ...
            'fTimoshenkoReferenceHz','theoryDifferencePercent', ...
            'reference256to512Percent','deflectionEBM','deflectionTimoshenkoM'});
        references=[references;row]; %#ok<AGROW>
    end
    for theory=["Timoshenko" "EulerBernoulli"]
        for ne=meshes
            assemblyTimes=zeros(4,1);solveTimes=zeros(4,1);
            for rep=1:4
                clock=tic;[M,K]=planeBeam(ne,L,sec,theory);assemblyTimes(rep)=toc(clock);
                clock=tic;f=frequencies(K,M,4);force=zeros(size(K,1),1);
                force(end-1)=P;q=K\force;solveTimes(rep)=toc(clock);
            end
            if theory=="Timoshenko",ref=fT;dref=dT;else,ref=fEB;dref=dEB;end
            for j=1:4
                row=table(L/h,theory,ne,2*ne,j,f(j), ...
                    100*abs(f(j)-ref(j))/ref(j),q(end-1), ...
                    100*abs(q(end-1)-dref)/dref, ...
                    median(assemblyTimes(2:end)),median(solveTimes(2:end)), ...
                    'VariableNames',{'slenderness','theory','elements','dofs', ...
                    'mode','frequencyHz','frequencyErrorPercent','tipDeflectionM', ...
                    'deflectionErrorPercent','assemblySeconds','solveSeconds'});
                results=[results;row]; %#ok<AGROW>
            end
        end
    end
end
writetable(results,fullfile(out,'cantilever_comparison.csv'));
writetable(references,fullfile(out,'cantilever_references.csv'));
beamFigures(out,results,references,L,heights);
end

function beamFigures(out,results,references,L,heights)
fig=figure('Color','w','Position',[100 100 1100 450]);tiledlayout(1,2);
for ih=1:2
    nexttile;hold on;
    for theory=["Timoshenko" "EulerBernoulli"]
        rows=results.slenderness==L/heights(ih)&results.theory==theory&results.mode==4;
        loglog(results.elements(rows),max(results.frequencyErrorPercent(rows),1e-10),'-o', ...
            'LineWidth',1.4,'DisplayName',char(theory));
    end
    set(gca,'XScale','log','YScale','log');grid on;
    xlabel('Elements');ylabel('Mode 4 frequency error (%)');
    title(sprintf('Cantilever L/h = %g',L/heights(ih)));legend('Location','southwest');
end
paperStyle(fig);exportgraphics(fig,fullfile(out,'cantilever_convergence.pdf'),'ContentType','vector');close(fig);
fig=figure('Color','w','Position',[100 100 1000 430]);tiledlayout(1,2);
nexttile;hold on;
for ih=1:2
    rows=references.slenderness==L/heights(ih);
    semilogy(references.mode(rows),references.theoryDifferencePercent(rows),'-o', ...
        'LineWidth',1.4,'DisplayName',sprintf('L/h = %g',L/heights(ih)));
end
set(gca,'YScale','log');grid on;legend('Location','best');
xlabel('Bending mode');ylabel('|f_{EB}-f_T| / f_T (%)');
nexttile;hold on;
for theory=["Timoshenko" "EulerBernoulli"]
    rows=results.slenderness==10&results.theory==theory&results.mode==1;
    loglog(results.elements(rows),results.assemblySeconds(rows)+results.solveSeconds(rows),'-o', ...
        'LineWidth',1.4,'DisplayName',char(theory));
end
set(gca,'XScale','log','YScale','log');grid on;legend('Location','best');
xlabel('Elements');ylabel('Assembly + modal/static solution (s)');
paperStyle(fig);exportgraphics(fig,fullfile(out,'cantilever_theory_and_cost.pdf'),'ContentType','vector');close(fig);
end

function [M,K]=planeBeam(ne,L,sec,theory)
le=L/ne;n=2*(ne+1);M=sparse(n,n);K=sparse(n,n);
if theory=="Timoshenko"
    [k3,m3]=elements.timoshenko3d_matrices(le,sec);
    p=[2 6 8 12];ke=k3(p,p);me=m3(p,p);
else
    ke=sec.EIz/le^3*[12 6*le -12 6*le;6*le 4*le^2 -6*le 2*le^2; ...
        -12 -6*le 12 -6*le;6*le 2*le^2 -6*le 4*le^2];
    me=sec.m*le/420*[156 22*le 54 -13*le;22*le 4*le^2 13*le -3*le^2; ...
        54 13*le 156 -22*le;-13*le -3*le^2 -22*le 4*le^2];
end
for e=1:ne
    p=2*(e-1)+(1:4);K(p,p)=K(p,p)+ke;M(p,p)=M(p,p)+me;
end
M=M(3:end,3:end);K=K(3:end,3:end);
end

function [f,V,lambda]=frequencies(K,M,nm)
opt=struct('tol',1e-11,'maxit',3000,'isreal',true, ...
    'v0',ones(size(K,1),1));
if nm>=size(K,1)-1
    [V,D]=eig(full(K),full(M));lambda=real(diag(D));
else
    [V,D,flag]=eigs(K,M,nm,'smallestabs',opt);
    if flag~=0,error('Comparison:eigs','eigs did not converge.');end
    lambda=real(diag(D));
end
[lambda,p]=sort(lambda);V=real(V(:,p));lambda=lambda(1:nm);V=V(:,1:nm);
if any(lambda<=0),error('Comparison:Eigenvalue','Nonpositive constrained eigenvalue.');end
for j=1:nm,V(:,j)=V(:,j)/sqrt(V(:,j)'*M*V(:,j));end
f=sqrt(lambda)/(2*pi);
end

function [metrics,freqTable,history,cost,parameters]=globalComparison(out)
cfg=config_action09_seismic_newmark();
cfg.rotor.speedRPM=0;cfg.gravity.enabled=false;
cfg.output.makeFigures=false;cfg.output.plotGeometry=false;
data=io.load_model_data(cfg);md=model.build_model(data,cfg);
clock=tic;[Mfull,Kfull]=assembly.assemble_structural_matrices(md,cfg);
Mfull=rigid.add_body_masses(Mfull,md,md.rigidBodies);
T=rigid.rigid_constraint_matrix(md,md.rigidBodies,cfg);
red=rigid.reduce_system(T,Mfull,Kfull,md,cfg);T=T(:,red.free);
M=T'*Mfull*T;K=T'*Kfull*T;
[Dfull,damping]=assembly.assemble_damping_matrix(md,Mfull,Kfull,struct(),cfg);
D=T'*Dfull*T;assemblySeconds=toc(clock);
n=size(M,1);nmGrid=[12 24 48 96 192];
R=zeros(size(Mfull,1),2);R(md.dofs.node(:,1),1)=1;R(md.dofs.node(:,2),2)=1;
PgFull=Mfull*R;Pg=T'*PgFull;
dt=.0025;t=(0:dt:8)';omega=2*pi*[.65 .90];amplitudes=[.0030 .0018];
s=sin(t*omega);c=cos(t*omega);
ug=s.^3.*amplitudes;vg=3*s.^2.*c.*(amplitudes.*omega);
ag=3*(2*s.*c.^2-s.^3).*(amplitudes.*omega.^2);
F=-Pg*ag';opt=struct('beta',.25,'gamma',.5);
parameters=struct('model','verified inherited Version 0 geometry, unpreloaded fixed-base', ...
    'fullDofs',size(Mfull,1),'mpcDofs',size(red.Tc,2),'analysisDofs',n, ...
    'elements',numel(md.mesh.elements.id),'nodes',numel(md.mesh.nodes.id), ...
    'speedRPM',0,'gravityEnabled',false,'centrifugalEnabled',false, ...
    'gyroEnabled',false,'aerodynamicLoads','zero, physical aerodynamic coefficients not provided', ...
    'drivetrainStiffness',cfg.drivetrain.stiffness, ...
    'drivetrainStatus','numerical benchmark, not physically calibrated', ...
    'damping',damping.rayleigh,'record','synthetic sin(omega*t)^3, NOT a measured earthquake', ...
    'recordDurationS',8,'dtS',dt,'amplitudesM',amplitudes, ...
    'carrierFrequenciesHz',omega/(2*pi),'directions',[1 2], ...
    'peakGroundAccelerationMps2',max(abs(ag),[],1), ...
    'modalDimensions',nmGrid,'assemblyOnceSeconds',assemblySeconds, ...
    'memoryMetric','bytes of stored M,D,K operators only; NOT peak resident memory', ...
    'timingScope','newmark_integrate including its response and energy arrays; excludes physical output reconstruction');
% Warm up all eigensolve sizes before timing. Each basis is built from the
% same MHT model; frequency agreement is algebraic, not independent validation.
modalBases=cell(numel(nmGrid),1);basisTimes=zeros(numel(nmGrid),1);
allf=[];frequencies(K,M,max(nmGrid));
for j=1:numel(nmGrid)
    frequencies(K,M,nmGrid(j));
    times=zeros(3,1);
    for rep=1:3
        clock=tic;[ff,Phi]=frequencies(K,M,nmGrid(j));times(rep)=toc(clock);
    end
    basisTimes(j)=median(times);modalBases{j}=Phi;
    if j==numel(nmGrid),allf=ff;end
end
freqTable=table((1:numel(allf))',allf,'VariableNames',{'mode','MHTFrequencyHz'});
fprintf('Global frequencies (Hz): ');fprintf(' %.8g',allf(1:12));fprintf('\n');
models=["MHT_full" "MHT_ROM"+string(nmGrid)];nModels=numel(models);
responses=cell(nModels,1);timesAll=zeros(nModels,3);modelsM=cell(nModels,1);modelsD=modelsM;modelsK=modelsM;
modelsM{1}=M;modelsD{1}=D;modelsK{1}=K;
operatorBytes=zeros(nModels,1);forceModels=cell(nModels,1);forceModels{1}=F;
projectionTimes=zeros(nModels,1);basisBytes=zeros(nModels,1);
for j=1:numel(nmGrid)
    P=modalBases{j};pt=zeros(4,1);
    for rep=1:4
        clock=tic;
        modelsM{j+1}=P'*M*P;modelsD{j+1}=P'*D*P;
        modelsK{j+1}=P'*K*P;forceModels{j+1}=P'*F;
        pt(rep)=toc(clock);
    end
    projectionTimes(j+1)=median(pt(2:end));w=whos('P');basisBytes(j+1)=w.bytes;
end
% Rotate execution order between measured repetitions to reduce order bias.
for j=1:nModels
    dynamics.newmark_integrate(modelsM{j},modelsD{j},modelsK{j},t,forceModels{j},opt);
    mm=modelsM{j};dd=modelsD{j};kk=modelsK{j};w=whos('mm','dd','kk');operatorBytes(j)=sum([w.bytes]);
end
for rep=1:3
    for j=circshift(1:nModels,rep-1)
        clock=tic;response=dynamics.newmark_integrate(modelsM{j},modelsD{j},modelsK{j},t,forceModels{j},opt);
        timesAll(j,rep)=toc(clock);responses{j}=response;
    end
end
cost=table(models',[n;nmGrid'],median(timesAll,2),timesAll(:,1),timesAll(:,2),timesAll(:,3), ...
    [0;basisTimes],projectionTimes,operatorBytes,basisBytes,operatorBytes+basisBytes, ...
    'VariableNames',{'model','dofs','newmarkMedianSeconds', ...
    'newmarkRep1Seconds','newmarkRep2Seconds','newmarkRep3Seconds','basisMedianSeconds', ...
    'projectionMedianSeconds','operatorBytes','basisBytes','operatorAndBasisBytes'});
cost.speedupIntegration=cost.newmarkMedianSeconds(1)./cost.newmarkMedianSeconds;
cost.speedupOneCaseIncludingBasis=cost.newmarkMedianSeconds(1)./(cost.newmarkMedianSeconds+cost.basisMedianSeconds+cost.projectionMedianSeconds);
cost.massParticipationXPercent=100*ones(nModels,1);cost.massParticipationYPercent=100*ones(nModels,1);
totalEff=diag(Pg'*(M\Pg));
cost.maxRetainedFrequencyDifferencePercent=zeros(nModels,1);
for j=1:numel(nmGrid)
    pr=modalBases{j}'*Pg;mp=sum(pr.^2,1)'./totalEff;
    cost.massParticipationXPercent(j+1)=100*mp(1);cost.massParticipationYPercent(j+1)=100*mp(2);
    fr=frequencies(modelsK{j+1},modelsM{j+1},nmGrid(j));
    cost.maxRetainedFrequencyDifferencePercent(j+1)=max(100*abs(fr-allf(1:nmGrid(j)))./allf(1:nmGrid(j)));
end
% Independent shear-rigid comparison keeps all distributed rotary inertia.
% It is explicitly NOT called classical Euler--Bernoulli.
mdRay=md;
for j=1:numel(mdRay.sections)
    mdRay.sections(j).GAy=Inf;mdRay.sections(j).GAz=Inf;
    if isfield(mdRay.sections,'K6')&&~isempty(mdRay.sections(j).K6)
        mdRay.sections(j).K6(2,2)=Inf;mdRay.sections(j).K6(3,3)=Inf;
    end
end
[MrFull,KrFull]=assembly.assemble_structural_matrices(mdRay,cfg);
MrFull=rigid.add_body_masses(MrFull,mdRay,mdRay.rigidBodies);
Mr=T'*MrFull*T;Kr=T'*KrFull*T;
[fr,Vr]=frequencies(Kr,Mr,max(nmGrid));freqTable.shearRigidRotaryInertiaHz=fr;
freqTable.shearRigidSortedFrequencyDifferencePercent=100*(fr-allf)./allf;
macTable=matchedMAC(modalBases{end}(:,1:24),Vr(:,1:24),M,allf(1:24),fr(1:24));
writetable(macTable,fullfile(out,'global_shear_rigid_mac.csv'));
parameters.shearRigidComparison='same nodal geometry, rotary inertia and rigid masses; GAy=GAz=Inf; sorted frequencies only, crossings not matched';
outputNames=["nacelle_ux_m" "nacelle_uy_m" "blade1_tip_ux_m" "blade2_tip_ux_m" ...
    "blade3_tip_ux_m" "nacelle_ax_absolute_mps2" "blade1_tip_ax_absolute_mps2" "base_My_Nm"];
outDofs=[md.dofs.node(129,1),md.dofs.node(129,2),md.dofs.node(56,1), ...
    md.dofs.node(92,1),md.dofs.node(128,1),md.dofs.node(129,1),md.dofs.node(56,1)];
H=T(outDofs,:);ground=R(outDofs,:);baseDof=md.dofs.node(1,5);
Hreaction={Mfull(baseDof,:)*T,Dfull(baseDof,:)*T,Kfull(baseDof,:)*T,PgFull(baseDof,:)};
outputValues=cell(nModels,1);metrics=table();history=table(t,ag(:,1),ag(:,2), ...
    'VariableNames',{'timeS','groundAxMps2','groundAyMps2'});
for j=1:nModels
    if j==1,P=speye(n);else,P=modalBases{j-1};end
    r=responses{j};Hp=H*P;Y=zeros(8,numel(t));Y(1:5,:)=Hp(1:5,:)*r.q;
    Y(6:7,:)=Hp(6:7,:)*r.qdd+ground(6:7,:)*ag';
    Y(8,:)=(Hreaction{1}*P)*r.qdd+(Hreaction{2}*P)*r.qd+ ...
        (Hreaction{3}*P)*r.q+Hreaction{4}*ag';outputValues{j}=Y;
    for k=1:8
        ref=outputValues{1}(k,:);value=Y(k,:);
        eh=100*sqrt(trapz(t,(value-ref).^2)/trapz(t,ref.^2));
        ep=100*abs(max(abs(value))-max(abs(ref)))/max(abs(ref));
        row=table(models(j),outputNames(k),eh,ep,max(abs(ref)),max(abs(value)), ...
            'VariableNames',{'model','output','historyErrorPercent','peakErrorPercent','referencePeak','modelPeak'});
        metrics=[metrics;row]; %#ok<AGROW>
        history.(models(j)+"_"+outputNames(k))=value';
    end
end
% Independent temporal refinement of the full model. ROM differences above
% compare identical time grids; this separate comparison quantifies the
% time discretization error without confusing it with modal truncation.
tFine=(0:dt/2:8)';sFine=sin(tFine*omega);cFine=cos(tFine*omega);
agFine=3*(2*sFine.*cFine.^2-sFine.^3).*(amplitudes.*omega.^2);
responseFine=dynamics.newmark_integrate(M,D,K,tFine,-Pg*agFine',opt);
fineIndex=1:2:numel(tFine);Yfine=zeros(8,numel(t));
Yfine(1:5,:)=H(1:5,:)*responseFine.q(:,fineIndex);
Yfine(6:7,:)=H(6:7,:)*responseFine.qdd(:,fineIndex)+ground(6:7,:)*ag';
Yfine(8,:)=Hreaction{1}*responseFine.qdd(:,fineIndex)+ ...
    Hreaction{2}*responseFine.qd(:,fineIndex)+Hreaction{3}*responseFine.q(:,fineIndex)+Hreaction{4}*ag';
timeConvergence=table();
for k=1:8
    ref=Yfine(k,:);coarse=outputValues{1}(k,:);
    eh=100*sqrt(trapz(t,(coarse-ref).^2)/trapz(t,ref.^2));
    ep=100*abs(max(abs(coarse))-max(abs(ref)))/max(abs(ref));
    row=table(outputNames(k),dt,dt/2,eh,ep,max(abs(ref)), ...
        'VariableNames',{'output','coarseDtS','fineDtS','historyErrorPercent','peakErrorPercent','finePeak'});
    timeConvergence=[timeConvergence;row]; %#ok<AGROW>
end
parameters.timeConvergence=table2struct(timeConvergence);
parameters.effectiveMassDenominator='diag(Pg''*(M\\Pg)): kinetic norm of admissible inertial load projection; NOT total physical turbine mass';
writetable(timeConvergence,fullfile(out,'global_time_convergence.csv'));
writetable(table(t,Yfine(1,:)',Yfine(3,:)',Yfine(6,:)',Yfine(8,:)', ...
    'VariableNames',{'timeS','nacelleUxFineM','blade1UxFineM','nacelleAxFineMps2','baseMyFineNm'}), ...
    fullfile(out,'global_fine_histories.csv'));
writetable(metrics,fullfile(out,'global_response_errors.csv'));
writetable(freqTable,fullfile(out,'global_frequencies.csv'));
writetable(cost,fullfile(out,'global_costs.csv'));
writetable(history,fullfile(out,'global_histories.csv'));
save(fullfile(out,'global_raw_data.mat'),'M','D','K','T','Mfull','Kfull','Dfull','Pg', ...
    't','ag','ug','vg','modalBases','responses','outputValues','parameters','timeConvergence', ...
    'tFine','agFine','responseFine','Yfine','-v7.3');
globalFigures(out,outputNames,outputValues,models,t,nmGrid,metrics,cost,freqTable,ag);
end

function globalFigures(out,outputNames,outputValues,models,t,nmGrid,metrics,cost,freqTable,ag)
nModels=numel(models);
fig=figure('Color','w','Position',[100 100 1200 700]);tiledlayout(2,2);
for k=[1 3 6 8]
    nexttile;hold on;
    for j=[1 2 4 nModels]
        plot(t,outputValues{j}(k,:),'LineWidth',1,'DisplayName',strrep(models(j),'_',' '));
    end
    grid on;xlabel('Time (s)');ylabel(strrep(outputNames(k),'_',' '),'Interpreter','none');
    if k==1,legend('Location','best');end
end
paperStyle(fig);exportgraphics(fig,fullfile(out,'global_response_comparison.pdf'),'ContentType','vector');close(fig);
fig=figure('Color','w','Position',[100 100 1100 440]);tiledlayout(1,2);
nexttile;hold on;
for k=[1 3 6 8]
    er=zeros(numel(nmGrid),1);
    for j=1:numel(nmGrid),er(j)=metrics.historyErrorPercent(metrics.model==models(j+1)&metrics.output==outputNames(k));end
    loglog(nmGrid,er,'-o','LineWidth',1.4,'DisplayName',strrep(outputNames(k),'_',' '));
end
set(gca,'XScale','log','YScale','log');grid on;xlabel('Retained modes');ylabel('History error (%)');legend('Location','best','Interpreter','none');
nexttile;bar(1:height(cost),cost.newmarkMedianSeconds);grid on;
xticks(1:height(cost));xticklabels(string(cost.dofs));
xlabel('Coordinates');ylabel('Median Newmark wall time (s)');
paperStyle(fig);exportgraphics(fig,fullfile(out,'global_error_and_cost.pdf'),'ContentType','vector');close(fig);
fig=figure('Color','w','Position',[100 100 1100 440]);tiledlayout(1,2);
nexttile;plot(freqTable.mode(1:24),freqTable.MHTFrequencyHz(1:24),'-o', ...
    freqTable.mode(1:24),freqTable.shearRigidRotaryInertiaHz(1:24),'-s','LineWidth',1.2);
grid on;xlabel('Sorted mode');ylabel('Frequency (Hz)');legend('MHT','Shear-rigid with rotary inertia','Location','best');
nexttile;plot(t,ag,'LineWidth',1.2);grid on;xlabel('Time (s)');ylabel('Synthetic ground acceleration (m/s^2)');legend('x','y');
paperStyle(fig);exportgraphics(fig,fullfile(out,'global_frequency_and_input.pdf'),'ContentType','vector');close(fig);
end

function paperStyle(fig)
set(fig,'Color','w');
ax=findall(fig,'Type','axes');
for j=1:numel(ax)
    set(ax(j),'Color','w','XColor','k','YColor','k', ...
        'GridColor',[.6 .6 .6],'MinorGridColor',[.7 .7 .7], ...
        'FontSize',11,'FontName','Times New Roman');
    ax(j).Title.Color='k';ax(j).XLabel.Color='k';ax(j).YLabel.Color='k';
    ax(j).Title.FontSize=11;ax(j).XLabel.FontSize=11;ax(j).YLabel.FontSize=11;
    curves=flipud(findall(ax(j),'Type','line'));
    styles={'-','--','-.',':'};markers={'o','s','^','d'};
    for k=1:numel(curves)
        style=mod(k-1,numel(styles))+1;
        set(curves(k),'Color','k','LineStyle',styles{style}, ...
            'Marker',markers{style},'LineWidth',1.1,'MarkerSize',4, ...
            'MarkerFaceColor','w');
        np=numel(curves(k).XData);
        if np>24,curves(k).MarkerIndices=unique(round(linspace(1,np,9)));end
    end
    bars=findall(ax(j),'Type','bar');
    for k=1:numel(bars),set(bars(k),'FaceColor',[.8 .8 .8],'EdgeColor','k');end
end
leg=findall(fig,'Type','legend');
for j=1:numel(leg)
    set(leg(j),'Color','w','TextColor','k','EdgeColor',[.5 .5 .5], ...
        'FontName','Times New Roman','FontSize',11);
end
end

function result=rayleighMAC(out)
raw=load(fullfile(out,'global_raw_data.mat'),'M','T','modalBases');
cfg=config_action09_seismic_newmark();cfg.rotor.speedRPM=0;cfg.gravity.enabled=false;
data=io.load_model_data(cfg);md=model.build_model(data,cfg);
for j=1:numel(md.sections)
    md.sections(j).GAy=Inf;md.sections(j).GAz=Inf;
    if isfield(md.sections,'K6')&&~isempty(md.sections(j).K6)
        md.sections(j).K6(2,2)=Inf;md.sections(j).K6(3,3)=Inf;
    end
end
[Mfull,Kfull]=assembly.assemble_structural_matrices(md,cfg);
Mfull=rigid.add_body_masses(Mfull,md,md.rigidBodies);
Mr=raw.T'*Mfull*raw.T;Kr=raw.T'*Kfull*raw.T;
[fr,Vr]=frequencies(Kr,Mr,24);
ft=readtable(fullfile(out,'global_frequencies.csv'));
result=matchedMAC(raw.modalBases{end}(:,1:24),Vr,raw.M,ft.MHTFrequencyHz(1:24),fr);
writetable(result,fullfile(out,'global_shear_rigid_mac.csv'));disp(result);
end

function result=matchedMAC(Phi,Vr,M,fref,fr)
normRef=real(diag(Phi'*M*Phi));normOther=real(diag(Vr'*M*Vr));
mac=abs(Phi'*M*Vr).^2./(normRef*normOther');
[bestMAC,matchedMode]=max(mac,[],2);mode=(1:numel(fref))';
result=table(mode,fref,fr,diag(mac),matchedMode,bestMAC, ...
    100*(fr(matchedMode)-fref)./fref,'VariableNames', ...
    {'MHTMode','MHTFrequencyHz','sameSortedRayleighFrequencyHz','sameSortedMAC', ...
    'bestRayleighMode','bestMAC','matchedFrequencyDifferencePercent'});
% Nearby modes 12--13 rotate substantially within an almost identical
% two-dimensional subspace. Whiten both bases in the same reference mass.
pair=12:13;A=Phi(:,pair);B=Vr(:,pair);
A=A/chol((A'*M*A+A'*M'*A)/2);
B=B/chol((B'*M*B+B'*M'*B)/2);
cosines=svd(A'*M*B);
result.pair12_13MinimumCosineSquared=nan(height(result),1);
result.pair12_13MinimumCosineSquared(pair)=min(cosines.^2);
end
