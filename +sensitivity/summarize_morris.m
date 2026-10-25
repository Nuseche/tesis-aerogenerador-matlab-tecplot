function summary=summarize_morris(campaign)
%SUMMARIZE_MORRIS Closed groups across the observed domain; explicit gates.
s=campaign.study;folder=campaign.folder;
[~,vertices,edges]=sensitivity.morris_design(s);
ref=sensitivity.read_case(folder,'nominal');n=s.branches;
ids=string({campaign.design.id}).';N=numel(ids);data=cell(N,1);tr=cell(N,1);
present=false(N,1);existsCase=present;dual=nan(N,1);eq=dual;
adj=eye(n)>0;
for c=1:N
    path=fullfile(folder,ids(c)+'.mat');existsCase(c)=isfile(path);
    if ~existsCase(c),continue,end
    stored=load(path,'record');if stored.record.status~="success",continue,end
    r=stored.record.result;present(c)=true;
    light=struct('solution',struct('fullModes',r.solution.fullModes, ...
        'eigenvaluesQEP',r.solution.eigenvaluesQEP,'dampingRatio',r.solution.dampingRatio));
    data{c}=light;tr{c}=sensitivity.track_modes(ref,light,s);
    for j=1:n,adj(j,:)=adj(j,:)|(tr{c}.clusterId==tr{c}.clusterId(j)).';end
    ops=r.solution.transformedOperators;L=chol(ops.M,'lower');rr=zeros(numel(r.solution.eigenvaluesQEP),1);
    for j=1:numel(rr)
        lam=r.solution.eigenvaluesQEP(j);phi=r.solution.modes(:,j);
        a=lam^2*ops.M*phi;b=lam*ops.D*phi;d=ops.K*phi;
        rr(j)=norm(L\(a+b+d))/max(norm(L\a)+norm(L\b)+norm(L\d),eps);
    end
    dual(c)=max(rr);eq(c)=r.diagnostics.equilibriumResidual;
end
groups=zeros(n,1);next=0;
for j=1:n
    if groups(j)>0,continue,end
    next=next+1;queue=j;groups(j)=next;
    while ~isempty(queue)
        a=queue(1);queue(1)=[];found=find(adj(a,:).'&groups==0);
        groups(found)=next;queue=[queue;found]; %#ok<AGROW>
    end
end
G=next;M=3;Y=nan(N,G,M);good=false(N,G);closed=false(N,G);quality=nan(N,G);
Y0=zeros(G,M);scale=Y0;labels=strings(G,1);groupRows=cell(0,5);
for g=1:G
    ix=find(groups==g);labels(g)=join(string(ix.'),"+");
    lambda=ref.solution.eigenvaluesQEP(ix);
    Y0(g,:)=[mean(abs(imag(lambda))/(2*pi)),mean(real(lambda)),mean(ref.solution.dampingRatio(ix))];
    scale(g,:)=[max(Y0(g,1),1e-3),max(mean(abs(lambda)),1e-3),max(abs(Y0(g,3)),0.01)];
    for c=find(present).'
        a=tr{c}.assignment(ix);lam=data{c}.solution.eigenvaluesQEP(a);
        Y(c,g,:)=[mean(abs(imag(lam))/(2*pi)),mean(real(lam)),mean(data{c}.solution.dampingRatio(a))];
        closed(c,g)=~any(tr{c}.boundaryAmbiguous(ix));
        if numel(ix)>1
            q=modal.subspace_mac(ref.solution.fullModes(:,ix),data{c}.solution.fullModes(:,a),ref.fullMass);
            quality(c,g)=q.minimumMAC;good(c,g)=closed(c,g)&&q.minimumMAC>=s.minimumSubspaceMAC;
        else
            quality(c,g)=tr{c}.individualMAC(ix);good(c,g)=tr{c}.individualValid(ix);
        end
    end
    groupRows(end+1,:)={labels(g),numel(ix),Y0(g,1),all(closed(present,g)),min(quality(present,g))}; %#ok<AGROW>
end
noise=zeros(G,M);noiseValid=true(G,1);
pairs=["nominal" "repeat";"nominal" "strict";"nominal" "continuation"; ...
    "corner1_direct" "corner1_strict";"corner1_direct" "corner1_continuation"; ...
    "corner2_direct" "corner2_strict";"corner2_direct" "corner2_continuation"];
for row=1:size(pairs,1)
    a=find(ids==pairs(row,1));b=find(ids==pairs(row,2));
    if isempty(a)||isempty(b)||~present(a)||~present(b)
        noiseValid(:)=false;continue
    end
    noise=max(noise,reshape(abs(Y(a,:,:)-Y(b,:,:)),G,M));
    noiseValid=noiseValid&good(a,:).'&good(b,:).';
end
noise=max(noise,100*eps(max(abs(Y0),1)));
response=["frequency" "growth" "dampingRatio"];units=["Hz" "s^-1" "1"];
er=cell(0,14);curveRows=cell(0,9);trackingRows=cell(0,5);
for v=1:height(vertices)
    c=find(ids==vertices.caseId(v));if ~present(c),continue,end
    for g=1:G
        trackingRows(end+1,:)={ids(c),labels(g),quality(c,g),closed(c,g),good(c,g)}; %#ok<AGROW>
        curveRows(end+1,:)={vertices.trajectory(v),vertices.vertex(v),ids(c),labels(g), ...
            vertices.factor(v,1),vertices.factor(v,2),vertices.factor(v,3),Y(c,g,1),good(c,g)}; %#ok<AGROW>
    end
end
completed=0;
for trajectory=1:s.morris.trajectories
    list=vertices.caseId(vertices.trajectory==trajectory);[~,indices]=ismember(list,ids);
    if all(existsCase(indices)),completed=trajectory;else,break,end
end
for e=1:height(edges)
    if edges.trajectory(e)>completed,continue,end
    a=find(ids==edges.fromCase(e));b=find(ids==edges.toCase(e));
    for g=1:G
        ix=find(groups==g);edgeQuality=NaN;edgeValid=good(a,g)&&good(b,g)&&noiseValid(g);
        if present(a)&&present(b)
            ma=tr{a}.assignment(ix);mb=tr{b}.assignment(ix);
            q=modal.subspace_mac(data{a}.solution.fullModes(:,ma),data{b}.solution.fullModes(:,mb),ref.fullMass);
            edgeQuality=q.minimumMAC;
            if numel(ix)>1,threshold=s.minimumSubspaceMAC;else,threshold=s.minimumMAC;end
            edgeValid=edgeValid&&edgeQuality>=threshold;
        end
        for metric=1:M
            delta=Y(b,g,metric)-Y(a,g,metric);
            ee=delta/(edges.deltaX(e)*scale(g,metric));
            nb=2*noise(g,metric)/(abs(edges.deltaX(e))*scale(g,metric));
            if ~edgeValid,ee=NaN;end
            er(end+1,:)={edges.trajectory(e),edges.parameter(e),labels(g),response(metric),units(metric), ...
                edges.fromCase(e),edges.toCase(e),edges.deltaX(e),delta,scale(g,metric),ee,nb,edgeValid,edgeQuality}; %#ok<AGROW>
        end
    end
end
effects=cell2table(er,'VariableNames',{'trajectory','parameter','group','response','unit','fromCase','toCase', ...
    'deltaX','deltaResponse','scale','elementaryEffect','empiricalNoiseBound','trackingValid','edgeSubspaceMAC'});
effects.signalResolved=abs(effects.elementaryEffect)>=s.signalToNoise*effects.empiricalNoiseBound;
stats=table();prefixes=s.morris.prefixes(s.morris.prefixes<=completed);
for p=1:height(s.parameters)
    for g=1:G
        for metric=1:M
            selected=effects.parameter==s.parameters.name(p)&effects.group==labels(g)&effects.response==response(metric);
            t=sortrows(effects(selected,:),'trajectory');
            st=sensitivity.morris_statistics(t.elementaryEffect,t.empiricalNoiseBound,t.trackingValid, ...
                prefixes,s.morris.estimatorTolerance,s.signalToNoise);
            st.parameter=repmat(s.parameters.name(p),height(st),1);
            st.group=repmat(labels(g),height(st),1);st.response=repmat(response(metric),height(st),1);
            st.scale=repmat(scale(g,metric),height(st),1);
            stats=[stats;st]; %#ok<AGROW>
        end
    end
end
tracking=cell2table(trackingRows,'VariableNames',{'caseId','group','nominalSubspaceMAC','closedGroup','trackingValid'});
sweeps=cell2table(curveRows,'VariableNames',{'trajectory','vertex','caseId','group', ...
    'bladeDensityFactor','bladeStiffnessFactor','rotorSpeedFactor','frequencyHz','trackingValid'});
groupTable=cell2table(groupRows,'VariableNames',{'group','size','nominalFrequencyHz','closedAcrossObservedDomain','minimumNominalSubspaceMAC'});
residuals=table(ids,existsCase,present,eq,dual,'VariableNames', ...
    {'caseId','caseSaved','success','equilibriumResidual','dualMassQEPResidual'});
noiseRows=cell(0,6);
for g=1:G
    for metric=1:M
        noiseRows(end+1,:)={labels(g),response(metric),units(metric),noise(g,metric),scale(g,metric),noiseValid(g)}; %#ok<AGROW>
    end
end
noiseTable=cell2table(noiseRows,'VariableNames',{'group','response','unit','empiricalNoise','responseScale','verificationTrackingValid'});
summary=struct('statistics',stats,'effects',effects,'tracking',tracking,'sweeps',sweeps, ...
    'groups',groupTable,'noise',noiseTable,'residuals',residuals,'completedTrajectories',completed, ...
    'scope',"Morris exploratory domain; frozen azimuth; partial spectrum; empirical noise envelope", ...
    'allEffectsRetained',true);
writetable(effects,fullfile(folder,'morris_elementary_effects.csv'));
writetable(stats,fullfile(folder,'morris_estimators.csv'));
writetable(tracking,fullfile(folder,'morris_tracking.csv'));writetable(sweeps,fullfile(folder,'morris_sweeps.csv'));
writetable(groupTable,fullfile(folder,'morris_groups.csv'));writetable(noiseTable,fullfile(folder,'morris_noise.csv'));
writetable(residuals,fullfile(folder,'morris_residuals.csv'));
save(fullfile(folder,'morris_summary.mat'),'summary','-v7.3');
save(fullfile(folder,sprintf('morris_summary_r%d.mat',completed)),'summary','-v7.3');
if ~isempty(stats)
    displayRows=stats.response=="frequency"&stats.trajectories==max(prefixes);
    disp(stats(displayRows,{'parameter','group','trajectories','muStar','sigma','acceptedMean','acceptedDispersion'}));
end
fprintf('Morris checkpoint: %d complete trajectories.\n',completed);
end
