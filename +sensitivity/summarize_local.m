function summary=summarize_local(campaign)
%SUMMARIZE_LOCAL Tracked derivatives, group centroids, noise and step checks.
study=campaign.study;folder=campaign.folder;
ref=sensitivity.read_case(folder,'nominal');
repeat=sensitivity.read_case(folder,'repeat');strict=sensitivity.read_case(folder,'strict');
continuation=sensitivity.read_case(folder,'continuation');
tContinuation=sensitivity.track_modes(ref,continuation,study);
tRepeat=sensitivity.track_modes(ref,repeat,study);tStrict=sensitivity.track_modes(ref,strict,study);
n=study.branches;lambda=ref.solution.eigenvaluesQEP(1:n);
zeta=ref.solution.dampingRatio(1:n);freq=abs(imag(lambda))/(2*pi);
noiseF=max(abs(freq-tRepeat.matchedFrequencyHz),abs(freq-tStrict.matchedFrequencyHz));
noiseG=max(abs(real(lambda)-real(tRepeat.matchedEigenvalues)), ...
    abs(real(lambda)-real(tStrict.matchedEigenvalues)));
noiseZ=max(abs(zeta-repeat.solution.dampingRatio(tRepeat.assignment)), ...
    abs(zeta-strict.solution.dampingRatio(tStrict.assignment)));
noiseF=max(noiseF,abs(freq-tContinuation.matchedFrequencyHz));
noiseG=max(noiseG,abs(real(lambda)-real(tContinuation.matchedEigenvalues)));
noiseZ=max(noiseZ,abs(zeta-continuation.solution.dampingRatio(tContinuation.assignment)));
noiseF=max(noiseF,100*eps(max(freq,1)));noiseG=max(noiseG,100*eps(max(abs(lambda),1)));
noiseZ=max(noiseZ,100*eps(max(abs(zeta),1)));
rows=cell(0,17);tracking=cell(0,12);sweepRows=cell(0,9);staticRows=cell(0,12);
for p=1:height(study.parameters)
    name=study.parameters.name(p);
    for j=1:numel(study.steps)
        h=study.steps(j);ids=name+"_h"+j+["_minus" "_plus"];
        try
            minus=sensitivity.read_case(folder,ids(1));plus=sensitivity.read_case(folder,ids(2));
        catch ME
            warning('sensitivity:SkippedDerivative','%s: %s',name,ME.message);continue
        end
        tm=sensitivity.track_modes(ref,minus,study);tp=sensitivity.track_modes(ref,plus,study);
        valid=tm.individualValid&tp.individualValid;
        ym=[tm.matchedFrequencyHz real(tm.matchedEigenvalues) minus.solution.dampingRatio(tm.assignment)];
        yp=[tp.matchedFrequencyHz real(tp.matchedEigenvalues) plus.solution.dampingRatio(tp.assignment)];
        y0=[freq real(lambda) zeta];noise=[noiseF noiseG noiseZ];
        types=["frequency" "growth" "dampingRatio"];units=["Hz" "s^-1" "1"];
        scales=[max(freq,1e-3) max(abs(lambda),1e-3) max(abs(zeta),0.01)];
        for b=1:n
            tracking(end+1,:)={name,h,b,tm.assignment(b),tp.assignment(b), ...
                tm.individualMAC(b),tp.individualMAC(b),tm.subspaceMAC(b), ...
                tp.subspaceMAC(b),min(tm.margin(b),tp.margin(b)),valid(b),tm.boundaryAmbiguous(b)||tp.boundaryAmbiguous(b)}; %#ok<AGROW>
            for metric=1:3
                r=sensitivity.central_difference(y0(b,metric),ym(b,metric),yp(b,metric), ...
                    h,scales(b,metric),metric==2);
                resolved=r.signal>=study.signalToNoise*noise(b,metric);
                if ~valid(b),r.derivative=NaN;r.sensitivity=NaN;r.curvature=NaN;end
                rows(end+1,:)={name,h,"individual",string(b),types(metric),units(metric), ...
                    y0(b,metric),ym(b,metric),yp(b,metric),r.derivative,r.sensitivity,r.scale, ...
                    r.normalization,noise(b,metric),resolved,valid(b),r.curvature}; %#ok<AGROW>
            end
            sweepRows(end+1,:)={name,1-h,b,ym(b,1),ym(b,2),ym(b,3), ...
                tm.individualMAC(b),tm.subspaceMAC(b),tm.individualValid(b)}; %#ok<AGROW>
            sweepRows(end+1,:)={name,1+h,b,yp(b,1),yp(b,2),yp(b,3), ...
                tp.individualMAC(b),tp.subspaceMAC(b),tp.individualValid(b)}; %#ok<AGROW>
        end
        % Connected union of nearby groups from both perturbations.
        groups=mergeGroups(tm.clusterId,tp.clusterId);
        for group=unique(groups).'
            members=find(groups==group);if numel(members)<2,continue,end
            qm=modal.subspace_mac(ref.solution.fullModes(:,members), ...
                minus.solution.fullModes(:,tm.assignment(members)),ref.fullMass);
            qp=modal.subspace_mac(ref.solution.fullModes(:,members), ...
                plus.solution.fullModes(:,tp.assignment(members)),ref.fullMass);
            groupValid=min(qm.minimumMAC,qp.minimumMAC)>=study.minimumSubspaceMAC&& ...
                ~any(tm.boundaryAmbiguous(members)|tp.boundaryAmbiguous(members));
            label=join(string(members.'),"+");
            for metric=1:3
                r=sensitivity.central_difference(mean(y0(members,metric)), ...
                    mean(ym(members,metric)),mean(yp(members,metric)),h, ...
                    mean(scales(members,metric)),metric==2);
                noiseValue=max(noise(members,metric));
                if ~groupValid,r.derivative=NaN;r.sensitivity=NaN;r.curvature=NaN;end
                rows(end+1,:)={name,h,"group_centroid",label,types(metric),units(metric), ...
                    mean(y0(members,metric)),mean(ym(members,metric)),mean(yp(members,metric)), ...
                    r.derivative,r.sensitivity,r.scale,r.normalization,noiseValue, ...
                    r.signal>=study.signalToNoise*noiseValue,groupValid,r.curvature}; %#ok<AGROW>
            end
        end
        for c=1:numel(ref.staticQ)
            sc=max(abs(ref.staticQ(c)),1e-3);
            r=sensitivity.central_difference(ref.staticQ(c),minus.staticQ(c),plus.staticQ(c),h,sc,true);
            nv=max(abs(ref.staticQ(c)-strict.staticQ(c)),abs(ref.staticQ(c)-repeat.staticQ(c)));
            nv=max(nv,abs(ref.staticQ(c)-continuation.staticQ(c)));
            nv=max(nv,100*eps(sc));
            staticRows(end+1,:)={name,h,ref.channels(c,1),ref.channels(c,2), ...
                ref.staticQ(c),r.derivative,r.sensitivity,r.scale,r.normalization, ...
                nv,r.signal>=study.signalToNoise*nv,r.curvature}; %#ok<AGROW>
        end
    end
end
T=cell2table(rows,'VariableNames',{'parameter','step','identity','modeOrGroup','response','unit', ...
    'nominal','minus','plus','derivative','sensitivity','scale','normalization', ...
    'numericalNoise','signalResolved','trackingValid','curvature'});
T.stepRelativeDifference=nan(height(T),1);T.stepConverged=false(height(T),1);
for k=1:height(T)
    candidates=find(T.parameter==T.parameter(k)&T.identity==T.identity(k)& ...
        T.modeOrGroup==T.modeOrGroup(k)&T.response==T.response(k)&T.step>T.step(k));
    if isempty(candidates)||~isfinite(T.derivative(k)),continue,end
    [~,i]=min(T.step(candidates));coarse=candidates(i);
    err=abs(T.derivative(k)-T.derivative(coarse))/max(abs(T.derivative(k)),1e-3*abs(T.scale(k)));
    T.stepRelativeDifference(k)=err;T.stepConverged(k)=err<=study.derivativeTolerance;
end
tracking=cell2table(tracking,'VariableNames',{'parameter','step','mode', ...
    'minusAssignment','plusAssignment','minusMAC','plusMAC','minusSubspaceMAC', ...
    'plusSubspaceMAC','minimumMargin','individualValid','spectralBoundaryAmbiguous'});
sweeps=cell2table(sweepRows,'VariableNames',{'parameter','factor','mode','frequencyHz', ...
    'growthPerSecond','dampingRatio','MAC','subspaceMAC','individualValid'});
static=cell2table(staticRows,'VariableNames',{'parameter','step','nodeId','component', ...
    'nominalM','derivativeM','scaledSensitivity','scaleM','normalization', ...
    'numericalNoiseM','signalResolved','curvatureM'});
ranking=table(study.parameters.name,zeros(height(study.parameters),1),zeros(height(study.parameters),1), ...
    'VariableNames',{'parameter','maxAbsResolvedFrequencySensitivity','acceptedFrequencyIndicators'});
for p=1:height(ranking)
    selected=T.parameter==ranking.parameter(p)&T.step==min(study.steps)& ...
        T.response=="frequency"&T.trackingValid&T.signalResolved&T.stepConverged;
    ranking.acceptedFrequencyIndicators(p)=nnz(selected);
    if any(selected),ranking.maxAbsResolvedFrequencySensitivity(p)=max(abs(T.sensitivity(selected)));
    else,ranking.maxAbsResolvedFrequencySensitivity(p)=NaN;end
end
usable=isfinite(ranking.maxAbsResolvedFrequencySensitivity);
ranking=[sortrows(ranking(usable,:),'maxAbsResolvedFrequencySensitivity','descend');ranking(~usable,:)];
summary=struct('table',T,'tracking',tracking,'sweeps',sweeps,'static',static, ...
    'ranking',ranking,'nominal',ref,'noise',table((1:n).',noiseF,noiseG,noiseZ, ...
    'VariableNames',{'mode','frequencyNoiseHz','growthNoisePerSecond','dampingNoise'}), ...
    'scope',"local total sensitivity of a frozen benchmark; no probabilistic interpretation");
writetable(T,fullfile(folder,'local_sensitivity.csv'));writetable(tracking,fullfile(folder,'modal_tracking.csv'));
writetable(sweeps,fullfile(folder,'local_sweeps.csv'));writetable(static,fullfile(folder,'static_sensitivity.csv'));
writetable(ranking,fullfile(folder,'frequency_ranking.csv'));writetable(summary.noise,fullfile(folder,'numerical_noise.csv'));
save(fullfile(folder,'summary.mat'),'summary','-v7.3');
sensitivity.plot_summary(summary,folder);
end
function ids=mergeGroups(a,b)
n=numel(a);ids=zeros(n,1);next=0;
for j=1:n
    if ids(j)>0,continue,end
    next=next+1;queue=j;ids(j)=next;
    while ~isempty(queue)
        k=queue(1);queue(1)=[];
        found=find((a==a(k)|b==b(k))&ids==0);ids(found)=next;queue=[queue;found]; %#ok<AGROW>
    end
end
end
