% Export figures and numerical metadata from the stored Morris summary.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));addpath(root);
folder=fullfile(root,'runs','sensitivity','morris_20261006');docs=fullfile(root,'docs','sensibilidad_morris_20261006');
stored=load(fullfile(folder,'morris_summary.mat'),'summary');summary=stored.summary;
saved=load(fullfile(folder,'campaign.mat'),'campaign');campaign=saved.campaign;
S=summary.statistics;
if summary.completedTrajectories<40
    figureFolder=string(sprintf('figures_r%d',summary.completedTrajectories));
    metadataFile=string(sprintf('report_data_r%d.json',summary.completedTrajectories));
else,figureFolder="figures";metadataFile="report_data.json";end
out=fullfile(folder,figureFolder);if ~isfolder(out),mkdir(out);end
sensitivity.export_nominal_properties(campaign.study,folder);
last=S(S.trajectories==max(S.trajectories),:);F=last(last.response=="frequency",:);
names=["blade_density" "blade_stiffness" "rotor_speed"];
labels=["Densidad de palas" "Rigidez de palas" "Velocidad del rotor"];
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
    ylabel('\mu^* escalada (1)');title("Grupo "+groups(g));
end
if rows*cols>numel(groups)
    nexttile(tl);axis off;
    text(0,.65,{'Color: influencia aceptada','Gris: indicador sin aceptación', ...
        'Barras de error: envolvente','numérica empírica; no son', ...
        'intervalos de confianza'},'FontSize',11,'Color','k');
end
title(tl,string(sprintf('Morris, %d trayectorias: color = influencia resuelta y estabilizada',summary.completedTrajectories)),'Color','k');
save_figure(f,out,'morris_influencia');
f=figure('Visible','off','Color','w','Position',[100 100 1080 heightPx]);tl=tiledlayout(f,rows,cols);
for g=1:numel(groups)
    nexttile(tl);hold on;
    for p=1:numel(names)
        r=S(S.parameter==names(p)&S.group==groups(g)&S.response=="frequency",:);
        plot(r.trajectories,r.muStar,'-o','Color',colors(p,:),'LineWidth',1.4,'DisplayName',labels(p));
    end
    xticks([10 20 40]);xlabel('Trayectorias (1)');ylabel('\mu^* escalada (1)');title("Grupo "+groups(g));grid on;
end
legend('Location','best');title(tl,'Estabilización de prefijos del mismo diseño','Color','k');save_figure(f,out,'morris_convergencia');
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
xlabel('\mu^* escalada (1)');ylabel('\sigma escalada (1)');grid on;
title({'Grupo 10+11: dispersión de efectos elementales','Símbolo vacío = dispersión sin aceptación numérica'});
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
    xlabel('Factor de densidad (1)');ylabel('Factor de rigidez (1)');
    title(string(sprintf('Velocidad del rotor: %.2f rpm',12*speeds(p))));
end
cb=colorbar;cb.Layout.Tile='east';cb.Label.String='Frecuencia media del grupo 10+11 (Hz)';
title(tl,{'Valores calculados en los niveles del dominio exploratorio','Gris = combinación sin evaluación; escala de color común'},'Color','k');
save_figure(f,out,'morris_dominio');
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
ranges=cell2table(groupRanges,'VariableNames',{'group','minimumHz','maximumHz','validVertices','invalidVertices'});
writetable(ranges,fullfile(folder,'morris_frequency_ranges.csv'));
tests=load(fullfile(docs,'module_tests.mat'),'results');
budgetStopped=false;finishedUTC="";
if isfield(campaign,'budgetStopped'),budgetStopped=campaign.budgetStopped;end
if isfield(campaign,'finishedUTC'),finishedUTC=campaign.finishedUTC;end
meta=struct('date',"2026-10-06",'completedTrajectories',summary.completedTrajectories, ...
    'completed',campaign.completed,'budgetStopped',budgetStopped, ...
    'savedSuccessCases',nnz(summary.residuals.success),'failedCaseIds',failed, ...
    'maximumEquilibriumResidual',max(summary.residuals.equilibriumResidual,[],'omitnan'), ...
    'maximumDualMassQEPResidual',max(summary.residuals.dualMassQEPResidual,[],'omitnan'), ...
    'maximumRightQEPResidual',max(qep),'maximumLeftQEPResidual',max(left), ...
    'largestGrowthComputedPerSecond',max(growth),'smallestGrowthComputedPerSecond',min(growth), ...
    'solverSeconds',sum(caseTimes),'meanCaseSeconds',mean(caseTimes), ...
    'uniqueTrackedGroup10Combinations',size(coordinates,1), ...
    'maximumRepeatedGroup10FrequencySpreadHz',max(spreads), ...
    'modulePassed',nnz([tests.results.Passed]),'moduleFailed',nnz([tests.results.Failed]), ...
    'statistics',table2struct(last),'groups',table2struct(summary.groups),'ranges',table2struct(ranges), ...
    'budgetStartUTC',campaign.study.budgetStartUTC,'finishedUTC',finishedUTC, ...
    'seed',campaign.study.morris.seed,'domain',"factors 0.90-1.10; exploratory", ...
    'sourceFingerprint',campaign.provenance.fingerprint);
fid=fopen(fullfile(docs,metadataFile),'w');fprintf(fid,'%s',jsonencode(meta,PrettyPrint=true));fclose(fid);

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
