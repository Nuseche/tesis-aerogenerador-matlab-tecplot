function export_morris_results(campaignFolder)
%EXPORT_MORRIS_RESULTS Run or inspect the specified morris campaign.
% Export figures and numerical metadata from the stored Morris summary.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));addpath(root);
if nargin < 1 || strlength(string(campaignFolder)) == 0
    campaignFolder=fullfile(root,'runs','studies','morris');
end
folder=fullfile(campaignFolder);
stored=load(fullfile(folder,'morris_summary.mat'),'summary');summary=stored.summary;
saved=load(fullfile(folder,'campaign.mat'),'campaign');campaign=saved.campaign;
S=summary.statistics;
if summary.completedTrajectories<40
    figureFolder=string(sprintf('figures_r%d',summary.completedTrajectories));
    metadataFile=string(sprintf('report_data_r%d.json',summary.completedTrajectories));
else,figureFolder="figures";metadataFile="report_data.json";end
out=fullfile(folder,figureFolder);if ~isfolder(out),mkdir(out);end
% Rebase input locations when reading a campaign created on another machine.
exportStudy=campaign.study;current=config_default();
exportStudy.nominal.paths=current.paths;exportStudy.nominal.data=current.data;
sensitivity.export_nominal_properties(exportStudy,folder);
last=S(S.trajectories==max(S.trajectories),:);F=last(last.response=="frequency",:);
names=["blade_density" "blade_stiffness" "rotor_speed"];
labels=["Blade density" "Blade stiffness" "Rotor speed"];
colors=[.15 .4 .65;.18 .55 .3;.7 .3 .15];
groups=unique(F.group(F.acceptedMean),'stable');
if isempty(groups),groups=["6+7";"8+9";"10+11"];end
if numel(groups)>3,rows=2;cols=ceil(numel(groups)/2);heightPx=650;else,rows=1;cols=numel(groups);heightPx=380;end
f=figure('Visible','off','Color','w','Position',[100 100 1080 heightPx]);
tl=tiledlayout(f,rows,cols,'TileSpacing','compact');
for g=1:numel(groups)
    nexttile(tl);hold on;
    for p=1:numel(names)
        r=F(F.parameter==names(p)&F.group==groups(g),:);
        if isempty(r)||~isfinite(r.muStar),continue,end
        if r.acceptedMean,face=colors(p,:);else,face=[.78 .78 .78];end
        bar(p,r.muStar,'FaceColor',face,'EdgeColor',colors(p,:));
        errorbar(p,r.muStar,r.muNoiseBound,'k','LineStyle','none');
    end
    xticks(1:3);xticklabels(labels);xtickangle(25);grid on;
    ylabel('\mu^* scaled (1)');title("Group "+groups(g));
end
if rows*cols>numel(groups)
    nexttile(tl);axis off;
    text(0,.65,{'Color: accepted influence','Gray: unaccepted indicator', ...
        'Error bars: empirical','numerical envelope; not', ...
        'confidence intervals'},'FontSize',11,'Color','k');
end
title(tl,string(sprintf('Morris, %d trajectories: color = resolved, stabilized influence',summary.completedTrajectories)),'Color','k');
save_figure(f,out,'morris_influence');
f=figure('Visible','off','Color','w','Position',[100 100 1080 heightPx]);tl=tiledlayout(f,rows,cols);
for g=1:numel(groups)
    nexttile(tl);hold on;
    for p=1:numel(names)
        r=S(S.parameter==names(p)&S.group==groups(g)&S.response=="frequency",:);
        plot(r.trajectories,r.muStar,'-o','Color',colors(p,:),'LineWidth',1.4,'DisplayName',labels(p));
    end
    xticks([10 20 40]);xlabel('Trajectories (1)');ylabel('\mu^* scaled (1)');title("Group "+groups(g));grid on;
end
legend('Location','best');title(tl,'Prefix stabilization for the same design','Color','k');save_figure(f,out,'morris_prefix_stabilization');
f=figure('Visible','off','Color','w','Position',[100 100 720 420]);hold on;
for p=1:numel(names)
    r=F(F.parameter==names(p)&F.group=="10+11",:);if isempty(r)||~isfinite(r.muStar),continue,end
    if r.acceptedDispersion,face=colors(p,:);else,face='none';end
    scatter(r.muStar,r.sigma,85,colors(p,:),'filled','DisplayName',labels(p), ...
        'MarkerFaceColor',face,'MarkerEdgeColor',colors(p,:),'LineWidth',1.2);
    if r.muStar>.06
        text(r.muStar-.0008,r.sigma,labels(p),'FontSize',10,'HorizontalAlignment','right');
    else,text(r.muStar+.0008,r.sigma,labels(p),'FontSize',10);end
end
xlabel('\mu^* scaled (1)');ylabel('\sigma scaled (1)');grid on;
title({'Group 10+11: elementary-effect dispersion','Open symbol: numerically unaccepted dispersion'});
save_figure(f,out,'morris_dispersion');
W=summary.sweeps;W=W(W.group=="10+11"&W.trackingValid,:);
[coordinates,~,repetition]=unique(round([W.bladeDensityFactor W.bladeStiffnessFactor W.rotorSpeedFactor],12),'rows');
spreads=zeros(size(coordinates,1),1);
for j=1:numel(spreads),values=W.frequencyHz(repetition==j);spreads(j)=max(values)-min(values);end
f=figure('Visible','off','Color','w','Position',[100 100 880 650]);tl=tiledlayout(f,2,2);
density=unique(round(W.bladeDensityFactor,12));stiffness=unique(round(W.bladeStiffnessFactor,12));
speeds=unique(round(W.rotorSpeedFactor,12));bounds=[min(W.frequencyHz),max(W.frequencyHz)];
for p=1:numel(speeds)
    ax=nexttile(tl);A=nan(numel(stiffness),numel(density));
    ix=find(abs(W.rotorSpeedFactor-speeds(p))<1e-10);
    for j=ix.'
        [~,a]=min(abs(density-W.bladeDensityFactor(j)));[~,b]=min(abs(stiffness-W.bladeStiffnessFactor(j)));
        A(b,a)=W.frequencyHz(j);
    end
    h=imagesc(density,stiffness,A);h.AlphaData=isfinite(A);set(ax,'YDir','normal','Tag','morris_missing_background');
    clim(bounds);xticks(density);yticks(stiffness);
    xlabel('Density factor (1)');ylabel('Stiffness factor (1)');
    title(string(sprintf('Rotor speed: %.2f rpm',12*speeds(p))));
end
cb=colorbar;cb.Layout.Tile='east';cb.Label.String='Mean frequency of group 10+11 (Hz)';
title(tl,{'Computed values at the exploratory domain levels','Grey = unevaluated combination; shared color scale'},'Color','k');
save_figure(f,out,'morris_domain');
% All computed modal representatives, not only centroids, for scope checks.
growth=[];qep=[];left=[];caseTimes=[];failed=strings(0,1);
for j=1:numel(campaign.design)
    if ~summary.residuals.caseSaved(j),continue,end
    path=fullfile(folder,campaign.design(j).id+'.mat');if ~isfile(path),continue,end
    x=load(path,'record');r=x.record;
    if r.status~="success",failed(end+1)=r.id;continue,end %#ok<SAGROW>
    growth=[growth;real(r.result.solution.eigenvaluesQEP(:))]; %#ok<AGROW>
    qep(end+1)=r.result.diagnostics.qepResidual;left(end+1)=r.result.diagnostics.leftResidual; %#ok<SAGROW>
    caseTimes(end+1)=r.elapsedSeconds; %#ok<SAGROW>
end
groupRanges=cell(0,5);
for g=unique(summary.sweeps.group).'
    rows=summary.sweeps.group==g&summary.sweeps.trackingValid;
    y=summary.sweeps.frequencyHz(rows);
    if isempty(y),lo=NaN;hi=NaN;else,lo=min(y);hi=max(y);end
    groupRanges(end+1,:)={g,lo,hi,nnz(rows),nnz(~summary.sweeps.trackingValid(summary.sweeps.group==g))}; %#ok<SAGROW>
end
ranges=cell2table(groupRanges,'VariableNames',{'group','minimumHz','maximumHz','validVertexs','invalidVertexs'});
writetable(ranges,fullfile(folder,'morris_frequency_ranges.csv'));
budgetStopped=false;finishedUTC="";budgetStartUTC="";
if isfield(campaign.study,'budgetStartUTC'),budgetStartUTC=campaign.study.budgetStartUTC;end
if isfield(campaign,'budgetStopped'),budgetStopped=campaign.budgetStopped;end
if isfield(campaign,'finishedUTC'),finishedUTC=campaign.finishedUTC;end
meta=struct('date',string(datetime('now','Format','yyyy-MM-dd')),'completedTrajectories',summary.completedTrajectories, ...
    'completed',campaign.completed,'budgetStopped',budgetStopped, ...
    'savedSuccessCases',nnz(summary.residuals.success),'failedCaseIds',failed, ...
    'maximumEquilibriumResidual',max(summary.residuals.equilibriumResidual,[],'omitnan'), ...
    'maximumDualMassQEPResidual',max(summary.residuals.dualMassQEPResidual,[],'omitnan'), ...
    'maximumRightQEPResidual',max(qep),'maximumLeftQEPResidual',max(left), ...
    'largestGrowthComputedPerSecond',max(growth),'smallestGrowthComputedPerSecond',min(growth), ...
    'solverSeconds',sum(caseTimes),'meanCaseSeconds',mean(caseTimes), ...
    'uniqueTrackedGroup10Combinations',size(coordinates,1), ...
    'maximumRepeatedGroup10FrequencySpreadHz',max(spreads), ...
        'statistics',table2struct(last),'groups',table2struct(summary.groups),'ranges',table2struct(ranges), ...
    'budgetStartUTC',budgetStartUTC,'finishedUTC',finishedUTC, ...
    'seed',campaign.study.morris.seed,'domain',"factors 0.90-1.10; exploratory", ...
    'sourceFingerprint',campaign.provenance.fingerprint);
fid=fopen(fullfile(folder,metadataFile),'w');fprintf(fid,'%s',jsonencode(meta,PrettyPrint=true));fclose(fid);

end

function save_figure(f,out,name)
name=string(name);
set(f,'Color','w');
set(findall(f,'Type','axes'),'Color','w','XColor','k','YColor','k','ZColor','k','GridColor',[.55 .55 .55],'FontSize',10);
set(findall(f,'Type','axes','Tag','morris_missing_background'),'Color',[.85 .85 .85]);
set(findall(f,'Type','text'),'Color','k');
leg=findall(f,'Type','legend');if ~isempty(leg),set(leg,'Color','w','TextColor','k');end
set(findall(f,'Type','colorbar'),'Color','k');
exportgraphics(f,fullfile(out,name+'.png'),'Resolution',180);
exportgraphics(f,fullfile(out,name+'.pdf'),'ContentType','vector');close(f);
end
