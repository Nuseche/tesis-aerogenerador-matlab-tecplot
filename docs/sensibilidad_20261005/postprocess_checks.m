% Additional dimensional residual checks from stored cases; no new solve.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));addpath(root);
folder=fullfile(root,'runs','sensitivity','initial_20261005');
files=dir(fullfile(folder,'**','*.mat'));rows=cell(0,5);
for k=1:numel(files)
    path=fullfile(files(k).folder,files(k).name);variables=whos('-file',path);
    if ~any(string({variables.name})=="record"),continue,end
    saved=load(path,'record');rec=saved.record;
    if rec.status~="success",continue,end
    r=rec.result;sol=r.solution;ops=sol.transformedOperators;
    L=chol(ops.M,'lower');res=zeros(numel(sol.eigenvaluesQEP),1);
    for j=1:numel(res)
        lam=sol.eigenvaluesQEP(j);phi=sol.modes(:,j);
        a=lam^2*ops.M*phi;b=lam*ops.D*phi;c=ops.K*phi;
        % The dual mass norm turns forces and moments into one energy scale.
        res(j)=norm(L\(a+b+c))/max(norm(L\a)+norm(L\b)+norm(L\c),eps);
    end
    rows(end+1,:)={string(files(k).folder),rec.id,max(res), ...
        r.diagnostics.equilibriumResidual,nnz(r.diagnostics.rigid.rigidCandidate)}; %#ok<SAGROW>
end
T=cell2table(rows,'VariableNames',{'folder','caseId','dualMassQEPResidual', ...
    'equilibriumResidual','rigidCandidates'});
writetable(T,fullfile(folder,'dimensionally_scaled_residuals.csv'));
% Group-wise mesh convergence: same original-node mass metric.
saved=load(fullfile(folder,'mesh','campaign.mat'),'campaign');study=saved.campaign.study;
a=sensitivity.read_case(fullfile(folder,'mesh'),'mesh_1');
b=sensitivity.read_case(fullfile(folder,'mesh'),'mesh_2');
c=sensitivity.read_case(fullfile(folder,'mesh'),'mesh_4');nd=size(a.fullMass,1);
b.solution.fullModes=b.solution.fullModes(1:nd,:);c.solution.fullModes=c.solution.fullModes(1:nd,:);
tb=sensitivity.track_modes(a,b,study);tc=sensitivity.track_modes(a,c,study);t0=sensitivity.track_modes(a,a,study);
rows=cell(0,9);
for group=unique(t0.clusterId).'
    ix=find(t0.clusterId==group);f1=mean(t0.referenceFrequencyHz(ix));
    f2=mean(tb.matchedFrequencyHz(ix));f4=mean(tc.matchedFrequencyHz(ix));
    sb=modal.subspace_mac(a.solution.fullModes(:,ix),b.solution.fullModes(:,tb.assignment(ix)),a.fullMass);
    sc=modal.subspace_mac(a.solution.fullModes(:,ix),c.solution.fullModes(:,tc.assignment(ix)),a.fullMass);
    rows(end+1,:)={join(string(ix.'),"+"),f1,f2,f4,abs(f2-f4)/f4, ...
        abs(f1-f4)/f4,sb.minimumMAC,sc.minimumMAC, ...
        ~any(tb.boundaryAmbiguous(ix)|tc.boundaryAmbiguous(ix))}; %#ok<SAGROW>
end
G=cell2table(rows,'VariableNames',{'group','frequencyMesh1Hz','frequencyMesh2Hz', ...
    'frequencyMesh4Hz','relativeDifference2to4','relativeDifference1to4','minimumMAC2','minimumMAC4','closedGroup'});
writetable(G,fullfile(folder,'mesh','mesh_group_convergence.csv'));
