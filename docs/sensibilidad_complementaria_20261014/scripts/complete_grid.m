% Complete only missing points of the previously approved four-level domain.
% Existing physical and sensitivity functions remain unchanged.
root=fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));addpath(root);addpath(fullfile(root,'cases'));
oldFolder=fullfile(root,'runs/sensitivity/morris_20261006');
newFolder=fullfile(root,'runs/sensitivity/grid_completion_20261014');
docs=fullfile(root,'docs/sensibilidad_complementaria_20261014');
loaded=load(fullfile(oldFolder,'campaign.mat'),'campaign');study=loaded.campaign.study;
study.schemaVersion="grid_completion_1.0";study.maximumWallSeconds=300;
study.maxCases=9;study.checkpointCases=[];study.globalEnabled=false;
if isfield(study,'budgetStartUTC'),study=rmfield(study,'budgetStartUTC');end
opts=detectImportOptions(fullfile(oldFolder,'morris_sweeps.csv'));
opts=setvartype(opts,{'group','caseId'},'string');vertices=readtable(fullfile(oldFolder,'morris_sweeps.csv'),opts);
v=vertices(vertices.group=="10+11",:);levels=linspace(.90,1.10,4);
caseIds=strings(4,4,4);oldCount=0;
for j=1:height(v)
    [~,a]=min(abs(levels-v.bladeDensityFactor(j)));
    [~,b]=min(abs(levels-v.bladeStiffnessFactor(j)));
    [~,c]=min(abs(levels-v.rotorSpeedFactor(j)));
    if caseIds(a,b,c)=="",caseIds(a,b,c)=v.caseId(j);oldCount=oldCount+1;end
end
assert(oldCount==58,'Unexpected historical grid coverage.');
design=struct('id',{},'factors',{},'options',{});missing=[];
for a=1:4,for b=1:4,for c=1:4
    if caseIds(a,b,c)~="",continue,end
    id=string(sprintf('grid_%d%d%d',a,b,c));
    f=struct('blade_density',levels(a),'blade_stiffness',levels(b),'rotor_speed',levels(c));
    design(end+1)=struct('id',id,'factors',f,'options',struct()); %#ok<SAGROW>
    caseIds(a,b,c)=id;missing(end+1,:)=[a b c]; %#ok<SAGROW>
end,end,end
assert(numel(design)==6);
design(end+1)=struct('id',"newpoint_strict",'factors',design(1).factors,'options',struct('strict',true));
design(end+1)=struct('id',"newpoint_continuation",'factors',design(1).factors, ...
    'options',struct('continuationGrid',linspace(0,12*design(1).factors.rotor_speed,9).'));
design(end+1)=struct('id',"nominal_repeat",'factors',struct(),'options',struct());
campaign=sensitivity.run_campaign(study,design,newFolder);
assert(campaign.completed&&all(campaign.status.status=="success"),'Keep failed or pending records and investigate.');

ref=sensitivity.read_case(oldFolder,'nominal');
meta=jsondecode(fileread(fullfile(root,'docs/sensibilidad_morris_20261006/report_data.json')));
groups=string({meta.groups.group});G=numel(groups);members=cell(G,1);
for g=1:G,members{g}=str2double(split(groups(g),'+'));end
records=cell(4,4,4);freq=zeros(4,4,4,G);grow=freq;damp=freq;valid=false(size(freq));
rows=cell(0,14);roots=cell(0,9);residualRows=cell(0,5);groupExpansion=false(G,1);
for a=1:4,for b=1:4,for c=1:4
    id=caseIds(a,b,c);isNew=startsWith(id,'grid_');
    if isNew,folder=newFolder;else,folder=oldFolder;end
    r=sensitivity.read_case(folder,id);tr=sensitivity.track_modes(ref,r,study);
    records{a,b,c}=r;
    for g=1:G
        ix=members{g};matched=tr.assignment(ix);lam=r.solution.eigenvaluesQEP(matched);
        f=mean(abs(imag(lam))/(2*pi));gamma=mean(real(lam));zeta=mean(r.solution.dampingRatio(matched));
        closed=~any(tr.boundaryAmbiguous(ix));
        for j=ix(:).'
            linked=find(tr.clusterId==tr.clusterId(j));
            groupExpansion(g)=groupExpansion(g)||any(~ismember(linked,ix));
        end
        if numel(ix)>1
            q=modal.subspace_mac(ref.solution.fullModes(:,ix),r.solution.fullModes(:,matched),ref.fullMass);
            quality=q.minimumMAC;good=closed&&quality>=study.minimumSubspaceMAC;
        else,quality=tr.individualMAC(ix);good=tr.individualValid(ix);end
        freq(a,b,c,g)=f;grow(a,b,c,g)=gamma;damp(a,b,c,g)=zeta;valid(a,b,c,g)=good;
        rows(end+1,:)={a,b,c,id,string(folder),isNew,levels(a),levels(b),levels(c),groups(g),f,gamma,zeta,good}; %#ok<SAGROW>
    end
    ops=r.solution.transformedOperators;L=chol(ops.M,'lower');dual=zeros(numel(r.solution.eigenvaluesQEP),1);
    for j=1:numel(dual)
        lam=r.solution.eigenvaluesQEP(j);phi=r.solution.modes(:,j);
        aa=lam^2*ops.M*phi;bb=lam*ops.D*phi;dd=ops.K*phi;
        dual(j)=norm(L\(aa+bb+dd))/max(norm(L\aa)+norm(L\bb)+norm(L\dd),eps);
        roots(end+1,:)={id,levels(a),levels(b),levels(c),j,abs(imag(lam))/(2*pi),real(lam),r.solution.dampingRatio(j),dual(j)}; %#ok<SAGROW>
    end
    residualRows(end+1,:)={id,r.diagnostics.equilibriumResidual,max(dual),r.diagnostics.qepResidual,r.diagnostics.leftResidual}; %#ok<SAGROW>
end,end,end
assert(~any(groupExpansion),'Additional points merge historical groups; regroup before interpretation.');
grid=cell2table(rows,'VariableNames',{'rhoLevel','stiffnessLevel','speedLevel','caseId','sourceFolder','newSolve', ...
    'bladeDensityFactor','bladeStiffnessFactor','rotorSpeedFactor','group','frequencyHz','growthPerSecond','dampingRatio','trackingValid'});
writetable(grid,fullfile(newFolder,'grid_responses.csv'));
writetable(cell2table(roots,'VariableNames',{'caseId','bladeDensityFactor','bladeStiffnessFactor','rotorSpeedFactor','root','frequencyHz','growthPerSecond','dampingRatio','dualMassResidual'}),fullfile(newFolder,'grid_roots.csv'));
writetable(cell2table(residualRows,'VariableNames',{'caseId','equilibriumResidual','dualMassResidual','rightQEPResidual','leftQEPResidual'}),fullfile(newFolder,'grid_residuals.csv'));
opts=detectImportOptions(fullfile(oldFolder,'morris_noise.csv'));opts=setvartype(opts,{'group','response'},'string');noise=readtable(fullfile(oldFolder,'morris_noise.csv'),opts);
pairs=[design(1).id "newpoint_strict";design(1).id "newpoint_continuation";"nominal" "nominal_repeat"];
noiseRows=cell(0,7);
for g=1:G
    ix=members{g};eta=noise.empiricalNoise(noise.group==groups(g)&noise.response=="frequency");historicalEta=eta;
    controlValid=true;maxDifference=0;
    for j=1:size(pairs,1)
        if pairs(j,1)=="nominal",ra=ref;else,ra=sensitivity.read_case(newFolder,pairs(j,1));end
        rb=sensitivity.read_case(newFolder,pairs(j,2));
        ta=sensitivity.track_modes(ref,ra,study);tb=sensitivity.track_modes(ref,rb,study);
        fa=mean(abs(imag(ra.solution.eigenvaluesQEP(ta.assignment(ix))))/(2*pi));
        fb=mean(abs(imag(rb.solution.eigenvaluesQEP(tb.assignment(ix))))/(2*pi));
        maxDifference=max(maxDifference,abs(fa-fb));eta=max(eta,abs(fa-fb));
        controlValid=controlValid&&~any(ta.boundaryAmbiguous(ix))&&~any(tb.boundaryAmbiguous(ix));
        qq=modal.subspace_mac(ra.solution.fullModes(:,ta.assignment(ix)),rb.solution.fullModes(:,tb.assignment(ix)),ref.fullMass);
        if numel(ix)>1,threshold=study.minimumSubspaceMAC;else,threshold=study.minimumMAC;end
        controlValid=controlValid&&qq.minimumMAC>=threshold;
    end
    noiseRows(end+1,:)={groups(g),historicalEta,maxDifference,eta,controlValid,all(valid(:,:,:,g),'all'),groupExpansion(g)}; %#ok<SAGROW>
end
writetable(cell2table(noiseRows,'VariableNames',{'group','historicalNoiseHz','newControlDifferenceHz','empiricalNoiseHz','controlsValid','allGridVerticesValid','groupExpanded'}),fullfile(newFolder,'grid_noise.csv'));
save(fullfile(newFolder,'grid_summary.mat'),'levels','caseIds','groups','freq','grow','damp','valid','missing','groupExpansion','-v7.3');
fprintf('Completed grid: 58 reused + 6 new points; 3 extra controls; unchanged historical groups.\n');
