% Scientific figures authorized by the user while Tecplot's license is expired.
% Data are loaded from saved CSV/JSON; this script does not call the solver.
root=fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));docs=fullfile(root,'docs/sensibilidad_complementaria_20261014');
folder=fullfile(docs,'figures');if ~isfolder(folder),mkdir(folder);end
s=jsondecode(fileread(fullfile(docs,'analysis_summary.json')));
m=jsondecode(fileread(fullfile(root,'docs/sensibilidad_morris_20261006/report_data.json')));
set(groot,'DefaultFigureVisible','off','DefaultAxesFontName','Arial','DefaultTextFontName','Arial', ...
    'DefaultAxesFontSize',18,'DefaultAxesLineWidth',1.5,'DefaultFigureColor','w', ...
    'DefaultAxesColor','w','DefaultAxesXColor','k','DefaultAxesYColor','k', ...
    'DefaultTextColor','k','DefaultLegendColor','w','DefaultLegendTextColor','k');
catalog=struct('id',{},'engine',{},'sources',{},'outputs',{},'style',{});
groups=["1+2" "3" "4+5" "6+7" "8+9" "10+11"];
params=["blade_density" "blade_stiffness" "rotor_speed"];
labels=["Masa/inercia" "Rigidez" "Velocidad"];marks={'o','d','s'};greys=[.08 .18 .35];
f=figure('Units','inches','Position',[1 1 12 4.6]);ax=axes(f,'Position',[.095 .22 .59 .72]);hold(ax,'on');
stats=m.statistics;
for p=1:3
    for accepted=[true false]
        xs=[];ys=[];
        for g=1:numel(groups)
            ix=find(strcmp({stats.response},'frequency')&strcmp({stats.parameter},params(p))&strcmp({stats.group},groups(g)));
            if stats(ix).acceptedMean~=accepted,continue,end
            xs(end+1)=g+(p-2)*.12;ys(end+1)=stats(ix).mu/.20; %#ok<SAGROW>
        end
        if accepted,face=repmat(greys(p),1,3);state=" aceptada";else,face='w';state=" no resuelta";end
        scatter(ax,xs,ys,65,repmat(greys(p),1,3),marks{p},'filled','MarkerFaceColor',face, ...
            'MarkerEdgeColor',repmat(greys(p),1,3),'LineWidth',1.1,'DisplayName',labels(p)+state);
    end
end
yline(ax,0,'Color',[.45 .45 .45],'HandleVisibility','off');
xticks(ax,1:6);xticklabels(ax,groups);xlim(ax,[.6 6.4]);ylim(ax,[-.66 .50]);
xlabel(ax,'Grupo modal','FontSize',20);ylabel(ax,'\mu_i / 0.20 [−]','FontSize',20);
legend(ax,'Location','eastoutside','FontSize',18,'Box','on');style_axes(ax);
catalog(end+1)=savefigs(f,folder,'influencia_firmada_grupos',{fullfile(root,'docs/sensibilidad_morris_20261006/report_data.json')});

opts=detectImportOptions(fullfile(root,'runs/sensitivity/grid_completion_20261014/grid_responses.csv'));
opts=setvartype(opts,'group','string');grid=readtable(fullfile(root,'runs/sensitivity/grid_completion_20261014/grid_responses.csv'),opts);
f0=1.2254297847145597;levels=linspace(.9,1.1,4);colors=[.08 .35 .18 .59];markers={'o','d','s','^'};
f=figure('Units','inches','Position',[1 1 12 4.6]);ax=axes(f,'Position',[.105 .23 .86 .72]);hold(ax,'on');
for c=1:4
    values=zeros(1,4);
    for a=1:4
        r=grid(grid.group=="10+11"&grid.rhoLevel==a&grid.stiffnessLevel==a&grid.speedLevel==c,:);
        assert(height(r)==1);values(a)=r.frequencyHz;
    end
    plot(ax,levels,100*(values-values(1))/f0,'Color',repmat(colors(c),1,3),'Marker',markers{c}, ...
        'MarkerFaceColor',repmat(colors(c),1,3),'LineWidth',1.5,'MarkerSize',6,'DisplayName',sprintf('%.1f rpm',12*levels(c)));
end
xticks(ax,levels);xticklabels(ax,{'0.90','0.9667','1.0333','1.10'});ylim(ax,[-.47 .025]);
xlabel(ax,'Factor común de masa/inercia y rigidez [−]','FontSize',20);ylabel(ax,'100 \Delta f / f_0 [%]','FontSize',20);
legend(ax,'Location','northeast','FontSize',18,'Box','on');style_axes(ax);
catalog(end+1)=savefigs(f,folder,'compensacion_rejilla',{fullfile(root,'runs/sensitivity/grid_completion_20261014/grid_responses.csv')});

f=figure('Units','inches','Position',[1 1 12 5.4]);ax=axes(f,'Position',[.105 .36 .86 .58]);hold(ax,'on');
pairs=["blade_density" "blade_stiffness";"blade_density" "rotor_speed";"blade_stiffness" "rotor_speed"];
names=["Masa–rigidez (\Omega fijo)" "Masa–velocidad (K fijo)" "Rigidez–velocidad (masa fija)"];
for p=1:3
    r=s.mixedContrasts(strcmp({s.mixedContrasts.group},'10+11')&strcmp({s.mixedContrasts.parameter1},pairs(p,1))&strcmp({s.mixedContrasts.parameter2},pairs(p,2)));
    if all([r.resolved]),face=repmat(colors(p),1,3);else,face='w';end
    plot(ax,[r.fixedFactor],[r.contrastRelativePercent],'Color',repmat(colors(p),1,3),'Marker',markers{p}, ...
        'MarkerFaceColor',face,'LineWidth',1.5,'MarkerSize',7,'DisplayName',names(p));
end
ni=find(strcmp({s.noise.group},'10+11'));eta=str2double(s.noise(ni).empiricalNoiseHz);threshold=100*40*eta/f0;
yline(ax,0,'Color',[.45 .45 .45],'HandleVisibility','off');
yline(ax,threshold,'--','Color',[.59 .59 .59],'LineWidth',1.2,'DisplayName','Umbral empírico \pm10b / f_0');
yline(ax,-threshold,'--','Color',[.59 .59 .59],'LineWidth',1.2,'HandleVisibility','off');
xticks(ax,levels);xticklabels(ax,{'0.90','0.9667','1.0333','1.10'});ylim(ax,[-.9 .44]);
xlabel(ax,'Factor que permanece fijo [−]','FontSize',20);ylabel(ax,'100 I_{ij} / f_0 [%]','FontSize',20);
legend(ax,'Location','southoutside','NumColumns',2,'FontSize',17,'Box','on');style_axes(ax);
catalog(end+1)=savefigs(f,folder,'contrastes_interaccion',{fullfile(docs,'mixed_contrasts.csv')});

% Legibility adaptations of existing datasets, with the same scientific values.
f=figure('Units','inches','Position',[1 1 12 4.5]);ax=axes(f,'Position',[.095 .22 .68 .72]);hold(ax,'on');
values=[1.10 1.033333333333333 1.033333333333333; ...
 .966666666666667 1.033333333333333 1.033333333333333; ...
 .966666666666667 .90 1.033333333333333;.966666666666667 .90 .90];
for p=1:3,plot(ax,0:3,values(:,p),'Color',repmat(greys(p),1,3),'Marker',marks{p},'MarkerFaceColor','w', ...
    'MarkerSize',7,'LineWidth',1.5,'DisplayName',labels(p));end
xticks(ax,0:3);yticks(ax,[.90 .966666666667 1.033333333333 1.10]);
yticklabels(ax,{'0.90','0.9667','1.0333','1.10'});ylim(ax,[.88 1.12]);
xlabel(ax,'Vértice de la primera trayectoria','FontSize',20);ylabel(ax,'Factor relativo [−]','FontSize',20);
legend(ax,'Location','eastoutside','FontSize',18,'Box','on');style_axes(ax);
catalog(end+1)=savefigs(f,folder,'trayectoria_legible',{fullfile(root,'runs/sensitivity/morris_20261006/morris_vertices.csv')});

opts=detectImportOptions(fullfile(root,'runs/sensitivity/morris_20261006/morris_estimators.csv'));
opts=setvartype(opts,{'group','parameter','response'},'string');est=readtable(fullfile(root,'runs/sensitivity/morris_20261006/morris_estimators.csv'),opts);
f=figure('Units','inches','Position',[1 1 12 4.7]);tl=tiledlayout(f,1,2,'TileSpacing','compact','Padding','compact');
for g=1:2
    ax=nexttile(tl);hold(ax,'on');group=["6+7" "10+11"];
    for p=1:3
        rs=sortrows(est(est.group==group(g)&est.parameter==params(p)&est.response=="frequency",:),'trajectories');
        plot(ax,rs.trajectories,rs.muStar,'Color',repmat(greys(p),1,3),'Marker',marks{p},'MarkerFaceColor',repmat(greys(p),1,3), ...
            'MarkerSize',7,'LineWidth',1.5,'DisplayName',labels(p));
    end
    xticks(ax,[10 20 40]);xlim(ax,[8 42]);title(ax,"Grupo "+group(g),'FontSize',20,'FontWeight','normal');
    xlabel(ax,'Trayectorias','FontSize',20);ylabel(ax,'\mu_i^* [−]','FontSize',20);style_axes(ax);
end
lg=legend(ax,'Location','southoutside','NumColumns',3,'FontSize',18,'Box','on');lg.Layout.Tile='south';
catalog(end+1)=savefigs(f,folder,'convergencia_legible',{fullfile(root,'runs/sensitivity/morris_20261006/morris_estimators.csv')});

f=figure('Units','inches','Position',[1 1 12 4.5]);ax=axes(f,'Position',[.105 .28 .86 .67]);hold(ax,'on');
gs=["1+2" "4+5" "10+11" "10+11" "10+11"];ps=[1 3 1 2 3];ratios=zeros(1,5);
for j=1:5
    ix=find(strcmp({stats.response},'frequency')&strcmp({stats.parameter},params(ps(j)))&strcmp({stats.group},gs(j)));
    ratios(j)=stats(ix).muStar/stats(ix).muNoiseBound;
    if stats(ix).acceptedMean,face='k';else,face='w';end
    scatter(ax,j,ratios(j),90,'k',marks{ps(j)},'filled','MarkerFaceColor',face,'MarkerEdgeColor','k','LineWidth',1.2,'HandleVisibility','off');
end
ax.YScale='log';ylim(ax,[1 600]);xlim(ax,[.5 5.5]);yticks(ax,[1 10 100]);
yline(ax,10,'--','Umbral: 10','Color',[.4 .4 .4],'FontSize',18,'LabelHorizontalAlignment','left');
xticks(ax,1:5);xticklabels(ax,{'Masa: 1+2','Giro: 4+5','Masa: 10+11','Rigidez: 10+11','Giro: 10+11'});
ax.XTickLabelRotation=0;xlabel(ax,'Factor y grupo modal','FontSize',20);ylabel(ax,'\mu_i^* / envolvente [−]','FontSize',20);style_axes(ax);
catalog(end+1)=savefigs(f,folder,'ruido_legible',{fullfile(root,'docs/sensibilidad_morris_20261006/report_data.json')});

T=readtable(fullfile(root,'runs/sensitivity/initial_20261005/local/modal_energy_evidence.csv'));
T=T(ismember(T.mode,[10 11]),:);f=figure('Units','inches','Position',[1 1 12 4.4]);ax=axes(f,'Position',[.105 .22 .65 .72]);hold(ax,'on');
plot(ax,[10 11]-.05,100*T.bladeMassFraction,'ko','MarkerFaceColor','k','MarkerSize',8,'LineStyle','none','DisplayName','Masa de referencia');
plot(ax,[10 11]+.05,100*T.bladeElasticFraction,'d','Color',[.35 .35 .35],'MarkerFaceColor',[.35 .35 .35], ...
    'MarkerSize',8,'LineStyle','none','DisplayName','Rigidez elástica');
xticks(ax,[10 11]);xlim(ax,[9.7 11.3]);ylim(ax,[0 105]);yticks(ax,[0 25 50 75 100]);
xlabel(ax,'Rama modal','FontSize',20);ylabel(ax,'Participación de palas [%]','FontSize',20);
legend(ax,'Location','eastoutside','FontSize',18,'Box','on');style_axes(ax);
catalog(end+1)=savefigs(f,folder,'participaciones_legibles',{fullfile(root,'runs/sensitivity/initial_20261005/local/modal_energy_evidence.csv')});
fid=fopen(fullfile(docs,'figure_catalog.json'),'w');fprintf(fid,'%s\n',jsonencode(catalog,PrettyPrint=true));fclose(fid);
fprintf('%d scientific figures exported as PNG and vector PDF; MATLAB renderer explicitly identified.\n',numel(catalog));

function style_axes(ax)
grid(ax,'on');ax.GridColor=[.84 .84 .84];ax.GridAlpha=1;ax.MinorGridAlpha=0;
ax.XMinorTick='on';ax.YMinorTick='on';ax.TickDir='in';ax.Box='off';
end
function r=savefigs(f,folder,name,sources)
png=fullfile(folder,[name '.png']);pdf=fullfile(folder,[name '.pdf']);
exportgraphics(f,png,'Resolution',300,'BackgroundColor','white');
exportgraphics(f,pdf,'ContentType','vector','BackgroundColor','white');close(f);
r=struct('id',name,'engine','MATLAB R2026a graphics; authorized alternative on 2026-10-14', ...
    'sources',{sources},'outputs',{{png,pdf}},'style','Monochrome, white background, Arial, black/grey symbols and light grey grid, matching previous Tecplot figures');
end
