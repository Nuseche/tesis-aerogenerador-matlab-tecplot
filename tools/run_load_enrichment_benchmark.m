function summary = run_load_enrichment_benchmark(folder)
%RUN_LOAD_ENRICHMENT_BENCHMARK Load-residual enrichment on archived full matrices.
% No physical parameters or production solvers are changed.  The benchmark
% compares dynamical Galerkin spaces, not a displacement-only static correction.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(root,fullfile(root,'cases'));
if nargin<1,folder=fullfile(root,'runs','load_enrichment_20261118');end
if ~isfolder(folder),mkdir(folder);end
source=fullfile(root,'runs','run_20260914_mecom_comparison','global_raw_data.mat');
a=load(source,'M','D','K','T','Mfull','Dfull','Kfull','Pg','t','ag', ...
    'modalBases','outputValues','parameters','tFine','agFine','Yfine');
M=a.M;D=a.D;K=a.K;Pg=a.Pg;t=a.t;ag=a.ag;F=-Pg*ag';
n=size(M,1);assert(n==804,'This campaign requires the archived 804-coordinate model.');
cfg=config_seismic_verification();cfg.rotor.speedRPM=0;cfg.gravity.enabled=false;
md=model.build_model(io.load_model_data(cfg),cfg);
assert(size(a.Mfull,1)==6*numel(md.mesh.nodes.id),'Archived physical ordering differs.');
R=zeros(size(a.Mfull,1),2);R(md.dofs.node(:,1),1)=1;R(md.dofs.node(:,2),2)=1;
PgFull=a.Mfull*R;
assert(norm(a.T'*PgFull-Pg,'fro')/norm(Pg,'fro')<1e-12,'Inertial load map mismatch.');
outputs=["nacelle_ux_m" "nacelle_uy_m" "blade1_tip_ux_m" "blade2_tip_ux_m" ...
    "blade3_tip_ux_m" "nacelle_ax_absolute_mps2" "blade1_tip_ax_absolute_mps2" "base_My_Nm"];
outDofs=[md.dofs.node(129,1),md.dofs.node(129,2),md.dofs.node(56,1), ...
    md.dofs.node(92,1),md.dofs.node(128,1),md.dofs.node(129,1),md.dofs.node(56,1)];
H=a.T(outDofs,:);ground=R(outDofs,:);base=md.dofs.node(1,5);
reaction={a.Mfull(base,:)*a.T,a.Dfull(base,:)*a.T,a.Kfull(base,:)*a.T,PgFull(base,:)};
assert(norm(M-a.T'*a.Mfull*a.T,'fro')/norm(M,'fro')<1e-12,'Archived mass inconsistency.');
assert(norm(K-a.T'*a.Kfull*a.T,'fro')/norm(K,'fro')<1e-12,'Archived stiffness inconsistency.');
[~,flagM]=chol(M);[~,flagK]=chol(K);assert(flagM==0&&flagK==0,'Positive reference operators required.');
rgrid=[12 24 48 96];specs=struct('name',"full804",'kind',"full",'r',0,'family',0);
for r=rgrid
    [~,audit]=buildBasis(M,K,Pg,r,"enriched");k=audit.addedRank;
    assert(k>=1&&k<=2,'Unexpected residual rank.');
    specs(end+1)=struct('name',"modal"+r,'kind',"modal",'r',r,'family',r); %#ok<AGROW>
    specs(end+1)=struct('name',"enriched"+r+"plus"+k,'kind',"enriched",'r',r,'family',r); %#ok<AGROW>
    specs(end+1)=struct('name',"modal"+(r+k),'kind',"modal",'r',r+k,'family',r); %#ok<AGROW>
end
ns=numel(specs);prepared=cell(ns,1);bases=cell(ns,1);audits=cell(ns,1);
values=cell(ns,1);timing=zeros(ns,3,4);residual=zeros(ns,1);
opt=struct('beta',.25,'gamma',.5);rng(20261118,'twister');
% Warm up every complete pipeline. Three following repeats alternate order.
for rep=0:3
    order=1:ns;if rep>0,order=circshift(order,rep-1);end
    for j=order
        clock=tic;
        if specs(j).kind=="full",Q=speye(n);audit=struct('addedRank',0);else
            [Q,audit]=buildBasis(M,K,Pg,specs(j).r,specs(j).kind);
        end
        prep=toc(clock);if specs(j).kind=="full",prep=0;end
        clock=tic;
        p=projectSystem(M,D,K,F,H,reaction,Q,specs(j).kind);
        projection=toc(clock);
        clock=tic;response=dynamics.newmark_integrate(p.M,p.D,p.K,t,p.F,opt);integration=toc(clock);
        clock=tic;Y=recoverOutputs(p,response,ground,ag);recovery=toc(clock);
        if rep>0,timing(j,rep,:)=[prep projection integration recovery];end
        bases{j}=Q;prepared{j}=p;audits{j}=audit;values{j}=Y;
        residual(j)=max(response.relativeResidual);
        fprintf('Load enrichment rep=%d %s dim=%d integration=%.4g s\n',rep,specs(j).name,size(Q,2),integration);
    end
end
clear response
reference=values{1};historicalError=norm(reference-a.outputValues{1},'fro')/norm(a.outputValues{1},'fro');
assert(historicalError<1e-8,'Current full response does not reproduce archived outputs.');
errorRows={};checkRows={};costRows={};repRows={};staticRows={};
history=table(t,ag(:,1),ag(:,2),'VariableNames',{'timeS','groundAxMps2','groundAyMps2'});
X=K\Pg;Lm=chol(M,'lower');
for j=1:ns
    Q=bases{j};p=prepared{j};Y=values{j};name=specs(j).name;
    for c=1:8
        [e,ep]=historyError(t,Y(c,:),reference(c,:));
        errorRows(end+1,:)={name,specs(j).kind,specs(j).family,size(Q,2),outputs(c),e,ep, ...
            max(abs(reference(c,:))),max(abs(Y(c,:)))}; %#ok<AGROW>
        history.(name+"_"+outputs(c))=Y(c,:)';
    end
    Xr=Q*(p.K\(Q'*Pg));
    for direction=1:2
        es=norm(Lm'*(Xr(:,direction)-X(:,direction)))/norm(Lm'*X(:,direction));
        staticRows(end+1,:)={name,direction,es,norm(K*Xr(:,direction)-Pg(:,direction))/norm(Pg(:,direction))}; %#ok<AGROW>
    end
    if specs(j).kind=="enriched"
        assert(max(cell2mat(staticRows(end-1:end,3)))<1e-8,'Enriched space does not reproduce the static load responses.');
    end
    massError=norm(Q'*M*Q-eye(size(Q,2)),'fro');
    if specs(j).kind=="full",massError=NaN;end
    checkRows(end+1,:)={name,size(Q,2),audits{j}.addedRank,massError,residual(j)}; %#ok<AGROW>
    med=reshape(median(timing(j,:,:),2),1,4);
    costRows(end+1,:)={name,specs(j).kind,specs(j).family,size(Q,2),med(1),med(2),med(3),med(4),sum(med)}; %#ok<AGROW>
    for rep=1:3
        tm=reshape(timing(j,rep,:),1,4);
        repRows(end+1,:)={name,rep,tm(1),tm(2),tm(3),tm(4),sum(tm)}; %#ok<AGROW>
    end
end
errors=cell2table(errorRows,'VariableNames',{'model','method','retainedModeFamily','dofs','output', ...
    'historyErrorPercent','peakErrorPercent','referencePeak','modelPeak'});
costs=cell2table(costRows,'VariableNames',{'model','method','retainedModeFamily','dofs', ...
    'preparationMedianSeconds','projectionMedianSeconds','integrationMedianSeconds','recoveryMedianSeconds','sumStageMediansSeconds'});
costs.speedupIntegration=costs.integrationMedianSeconds(1)./costs.integrationMedianSeconds;
costs.speedupAllMeasuredStages=costs.sumStageMediansSeconds(1)./costs.sumStageMediansSeconds;
repetitions=cell2table(repRows,'VariableNames',{'model','repetition','preparationSeconds','projectionSeconds', ...
    'integrationSeconds','recoverySeconds','sumStageSeconds'});
checks=cell2table(checkRows,'VariableNames',{'model','dofs','addedRank','massOrthogonalityFrobenius','maximumNormalizedEquilibriumResidual'});
staticChecks=cell2table(staticRows,'VariableNames',{'model','loadDirection','relativeMassNormStaticError','relativeUnprojectedStaticResidual'});
% Select the smallest enriched space meeting 1% in all eight histories;
% if no space qualifies, refine the enriched space with the smallest maximum.
enriched=find(string({specs.kind})=="enriched");maxError=zeros(size(enriched));
for k=1:numel(enriched),maxError(k)=max(errors.historyErrorPercent(errors.model==specs(enriched(k)).name));end
accepted=find(maxError<1,1);
if isempty(accepted),[~,accepted]=min(maxError);selection="lowest maximum history error; no enriched space meets 1% in all outputs";
else,selection="smallest tested enriched space below 1% in all eight history errors";end
selected=enriched(accepted);Q=bases{selected};p=prepared{selected};
tf=a.tFine;agf=a.agFine;
fine=dynamics.newmark_integrate(p.M,p.D,p.K,tf,-Q'*Pg*agf',opt);
Yfine=recoverOutputs(p,fine,ground,agf);ix=1:2:numel(tf);timeRows={};
for c=1:8
    [timeError,timePeak]=historyError(t,values{selected}(c,:),Yfine(c,ix));
    [fineModal,finePeak]=historyError(t,Yfine(c,ix),a.Yfine(c,:));
    timeRows(end+1,:)={specs(selected).name,outputs(c),mean(diff(t)),mean(diff(tf)),timeError,timePeak,fineModal,finePeak}; %#ok<AGROW>
end
timeCheck=cell2table(timeRows,'VariableNames',{'model','output','coarseDtS','fineDtS', ...
    'coarseToFineHistoryChangePercent','coarseToFinePeakChangePercent','fineStepModalErrorPercent','fineStepModalPeakErrorPercent'});
% Independent direct frequency-domain solves remove time discretization and
% retain complex response, acceleration feedthrough and dynamic reactions.
frequenciesHz=[.65 .90 1.95 2.70];harmonic=harmonicComparison(M,D,K,Pg,H,reaction,ground,bases,specs,frequenciesHz);
[~,revision]=system(sprintf('git -C "%s" rev-parse HEAD',root));
[~,cpu]=system('sysctl -n machdep.cpu.brand_string');
metadata=struct('created',string(datetime('now','Format','yyyy-MM-dd HH:mm:ss')), ...
    'sourceFile',string(source),'sourceSHA256',fileHash(source),'driverSHA256',fileHash(mfilename('fullpath')+".m"), ...
    'codeRevision',strtrim(string(revision)),'matlab',string(version),'computer',string(computer), ...
    'cpu',strtrim(string(cpu)),'threads',maxNumCompThreads,'warmups',1,'repetitions',3, ...
    'timingScope',"matrices already assembled; eigensolve/residual construction, projection of operators/force/output rows, Newmark with diagnostics, eight-output recovery; disk I/O excluded", ...
    'timingAggregation',"separate stage medians, whose sum defines total measured stages; raw per-repeat sums also exported", ...
    'basis',"M-orthonormal conservative modes, augmented with load residuals from K inverse Pg; M-weighted SVD rank threshold 1e-10 after unit mass-norm scaling of each static load response", ...
    'historicalFullOutputRelativeFrobeniusChange',historicalError, ...
    'fineCase',specs(selected).name,'fineCaseSelection',selection, ...
    'harmonicInput',"unit prescribed support acceleration in X or Y; response includes absolute acceleration and physical base reaction feedthrough", ...
    'phaseValidity',"reference amplitude exceeds 1e-8 times the largest reference amplitude for that output across the four frequencies and both inputs", ...
    'conditions',a.parameters);
summary=struct('metadata',metadata,'costs',table2struct(costs),'errors',table2struct(errors), ...
    'checks',table2struct(checks),'staticChecks',table2struct(staticChecks),'timeRefinement',table2struct(timeCheck));
writetable(errors,fullfile(folder,'response_errors.csv'));writetable(costs,fullfile(folder,'costs.csv'));
writetable(repetitions,fullfile(folder,'timing_repetitions.csv'));writetable(checks,fullfile(folder,'numerical_checks.csv'));
writetable(staticChecks,fullfile(folder,'static_checks.csv'));writetable(timeCheck,fullfile(folder,'time_refinement.csv'));
writetable(harmonic,fullfile(folder,'harmonic_response.csv'));writetable(history,fullfile(folder,'histories.csv'));
fineHistory=array2table([tf,Yfine'],'VariableNames',cellstr(["timeS",outputs]));
writetable(fineHistory,fullfile(folder,'selected_enriched_fine_histories.csv'));
save(fullfile(folder,'enrichment_data.mat'),'summary','metadata','specs','bases','audits','values','t','ag', ...
    'tf','agf','Yfine','errors','costs','repetitions','checks','staticChecks','timeCheck','harmonic','-v7.3');
fid=fopen(fullfile(folder,'summary.json'),'w');fwrite(fid,jsonencode(summary,PrettyPrint=true),'char');fclose(fid);
writeReport(folder,summary,costs,errors,timeCheck,staticChecks,specs,selected);
disp(costs);disp(errors(errors.output=="base_My_Nm",:));disp(timeCheck);
fprintf('Load-enrichment campaign saved to %s\n',folder);
end

function [Q,audit]=buildBasis(M,K,B,r,kind)
options=struct('tol',1e-11,'maxit',3000,'isreal',true,'v0',ones(size(K,1),1));
[Phi,L,flag]=eigs(K,M,r,'smallestabs',options);assert(flag==0,'Eigensolve failed.');
[lambda,ix]=sort(real(diag(L)));Phi=real(Phi(:,ix));assert(all(lambda>0),'Nonpositive eigenvalue.');
Phi=Phi/chol((Phi'*M*Phi+Phi'*M'*Phi)/2);
Q=Phi;audit=struct('addedRank',0,'frequenciesHz',sqrt(lambda)/(2*pi));
if kind=="enriched"
    X=K\B;Lmass=chol(M,'lower');
    scales=sqrt(sum((Lmass'*X).^2,1));Xs=X./scales;
    residual=Xs-Phi*(Phi'*M*Xs);
    residual=residual-Phi*(Phi'*M*residual);
    [U,S,~]=svd(Lmass'*residual,'econ');sv=diag(S);keep=sv>1e-10;
    W=Lmass'\U(:,keep);Q=[Phi,W];Q=Q/chol((Q'*M*Q+Q'*M'*Q)/2);
    audit.addedRank=sum(keep);audit.residualSingularValues=sv;
    audit.staticColumnMassNorms=scales;audit.staticSolveRelativeResidual=norm(K*X-B,'fro')/norm(B,'fro');
    audit.maximumModalResidualOverlap=max(abs(Phi'*M*Q(:,r+1:end)),[],'all');
end
assert(norm(Q'*M*Q-eye(size(Q,2)),'fro')<1e-8,'Mass orthogonality failure.');
end

function p=projectSystem(M,D,K,F,H,reaction,Q,kind)
if kind=="full",p=struct('M',M,'D',D,'K',K,'F',F,'H',H,'reaction',{reaction});return,end
rp=reaction;for k=1:3,rp{k}=reaction{k}*Q;end
p=struct('M',Q'*M*Q,'D',Q'*D*Q,'K',Q'*K*Q,'F',Q'*F,'H',H*Q,'reaction',{rp});
end

function Y=recoverOutputs(p,r,ground,ag)
Y=zeros(8,numel(r.t));Y(1:5,:)=p.H(1:5,:)*r.q;
Y(6:7,:)=p.H(6:7,:)*r.qdd+ground(6:7,:)*ag';
Y(8,:)=p.reaction{1}*r.qdd+p.reaction{2}*r.qd+p.reaction{3}*r.q+p.reaction{4}*ag';
end

function [e,ep]=historyError(t,y,reference)
e=100*sqrt(trapz(t,(y-reference).^2)/trapz(t,reference.^2));
ep=100*abs(max(abs(y))-max(abs(reference)))/max(abs(reference));
end

function result=harmonicComparison(M,D,K,B,H,reaction,ground,bases,specs,frequencies)
nf=numel(frequencies);nm=numel(bases);response=complex(zeros(8,2,nf,nm));
for j=1:nm
    Q=bases{j};mr=Q'*M*Q;dr=Q'*D*Q;kr=Q'*K*Q;br=-Q'*B;hr=H*Q;
    for k=1:nf
        w=2*pi*frequencies(k);x=(kr+1i*w*dr-w*w*mr)\br;
        response(1:5,:,k,j)=hr(1:5,:)*x;
        response(6:7,:,k,j)=-w*w*hr(6:7,:)*x+ground(6:7,:);
        response(8,:,k,j)=(-w*w*reaction{1}+1i*w*reaction{2}+reaction{3})*Q*x+reaction{4};
    end
end
rows={};scales=max(abs(response(:,:,:,1)),[],[2 3]);
for j=1:nm
    for k=1:nf
        for d=1:2
            for c=1:8
                ref=response(c,d,k,1);value=response(c,d,k,j);valid=abs(ref)>1e-8*scales(c)&&scales(c)>0;
                amplitudeError=NaN;complexError=NaN;phaseError=NaN;
                if valid
                    amplitudeError=100*abs(abs(value)-abs(ref))/abs(ref);
                    complexError=100*abs(value-ref)/abs(ref);
                    phaseError=angle(value*conj(ref))*180/pi;
                end
                rows(end+1,:)={specs(j).name,c,d,frequencies(k),real(ref),imag(ref),real(value),imag(value), ...
                    abs(ref),abs(value),angle(ref)*180/pi,angle(value)*180/pi,valid,amplitudeError,complexError,phaseError,abs(value-ref)}; %#ok<AGROW>
            end
        end
    end
end
result=cell2table(rows,'VariableNames',{'model','outputIndex','loadDirection','frequencyHz', ...
    'referenceReal','referenceImag','responseReal','responseImag','referenceAmplitude','responseAmplitude', ...
    'referencePhaseDeg','responsePhaseDeg','relativeMetricsValid','amplitudeErrorPercent','complexErrorPercent','wrappedPhaseErrorDeg','absoluteComplexError'});
end

function hash=fileHash(path)
[status,line]=system(sprintf('shasum -a 256 "%s"',path));assert(status==0,'Hash calculation failed.');
parts=split(strtrim(string(line)));hash=parts(1);
end

function writeReport(folder,summary,costs,errors,timeCheck,staticChecks,specs,selected)
fid=fopen(fullfile(folder,'findings.txt'),'w');cleanup=onCleanup(@()fclose(fid)); %#ok<NASGU>
fprintf(fid,'Load-residual enrichment of the stationary 804-coordinate model\n\n');
fprintf(fid,'Same full matrices, damping, support acceleration, initial conditions and time step for every space. No SIMPACT run, nonlinear comparison or physical calibration.\n');
fprintf(fid,'Residual enrichment adds the independent part of K inverse Pg to the retained conservative eigenspace; the resulting Galerkin coordinates are integrated dynamically. Pure-modal equal-dimension controls are included.\n\n');
fprintf(fid,'model, dimension, maximum of eight history errors (%%), base My error (%%), all measured stage speedup\n');
for j=1:height(costs)
    rows=errors.model==costs.model(j);moment=rows&errors.output=="base_My_Nm";
    fprintf(fid,'%s, %d, %.9g, %.9g, %.6g\n',costs.model(j),costs.dofs(j), ...
        max(errors.historyErrorPercent(rows)),errors.historyErrorPercent(moment),costs.speedupAllMeasuredStages(j));
end
fprintf(fid,'\nSelected fine-step check: %s (%s).\n',specs(selected).name,summary.metadata.fineCaseSelection);
fprintf(fid,'Largest same-space coarse/fine history change: %.9g%%. Largest fine-step modal error at common stored times: %.9g%%.\n', ...
    max(timeCheck.coarseToFineHistoryChangePercent),max(timeCheck.fineStepModalErrorPercent));
enriched=startsWith(string(staticChecks.model),"enriched");
fprintf(fid,'Largest enriched static relative mass-norm error: %.9g. Archived full-history reproduction change: %.9g.\n', ...
    max(staticChecks.relativeMassNormStaticError(enriched)),summary.metadata.historicalFullOutputRelativeFrobeniusChange);
fprintf(fid,'\nInterpretation and limits\n');
fprintf(fid,'Errors compare the adopted full model on the same grid; they are not total physical-model errors. Static exactness for the two load directions does not establish dynamic exactness. The harmonic table uses independent direct complex solves at the four prescribed analytic frequencies, retains inertial/damping moment terms and acceleration feedthrough, and masks relative metrics near zero response.\n');
fprintf(fid,'Costs are medians of three repeats after one warmup, alternating model order, on already assembled matrices. Preparation includes each eigensolve and, for enrichment, the static solves and orthogonalization. Projection includes forces and output rows. Integration includes existing solver energy/residual diagnostics. Recovery of all eight outputs is measured separately; assembly, input loading and export are excluded. Report raw repetitions when assessing small timing differences.\n');
fprintf(fid,'The fine-step case is selected by a declared criterion from the enriched family. Its modal error uses the archived full fine-step solution sampled at the original times. Frequency-domain results do not suffer Newmark time discretization. This campaign concerns the stationary support-loading case; it does not establish periodic rotating accuracy or a universally optimal basis.\n');
end
