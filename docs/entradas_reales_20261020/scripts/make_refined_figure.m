root=fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));docs=fullfile(root,'docs/entradas_reales_20261020');
set(groot,'DefaultFigureVisible','off','DefaultAxesFontName','Arial','DefaultTextFontName','Arial', ...
    'DefaultAxesFontSize',18,'DefaultFigureColor','w','DefaultAxesColor','w', ...
    'DefaultAxesXColor','k','DefaultAxesYColor','k','DefaultTextColor','k','DefaultLegendColor','w','DefaultLegendTextColor','k');
t=readtable(fullfile(docs,'tables/refined_local_sensitivities.csv'),'TextType','string');
parameters=["blade_density" "blade_stiffness" "rotor_speed"];types=["earthquake" "wind"];
f=figure('Units','inches','Position',[1 1 12 5]);tl=tiledlayout(f,1,2,'TileSpacing','compact','Padding','compact');
for j=1:2
    ax=nexttile(tl);hold(ax,'on');responses=["gondola_qH_RMS" "gondola_aH_RMS"];
    for k=1:2
        y=zeros(1,3);valid=false(1,3);
        for n=1:3,r=t(t.input==types(k)&t.parameter==parameters(n)&t.response==responses(j),:);y(n)=r.S;valid(n)=logical(r.accepted);end
        if k==1,marker='o';grey=[0 0 0];name='Sismo X';else,marker='s';grey=[.45 .45 .45];name='Viento por unidad de empuje';end
        plot(ax,(1:3)+(k-1.5)*.12,y,'Color',grey,'LineStyle','-','LineWidth',1.4,'Marker',marker,'MarkerFaceColor','w','MarkerSize',8,'DisplayName',name);
        scatter(ax,find(valid)+(k-1.5)*.12,y(valid),55,grey,marker,'filled','MarkerEdgeColor',grey,'HandleVisibility','off');
    end
    yline(ax,0,':','Color',[.6 .6 .6],'HandleVisibility','off');xticks(ax,1:3);xticklabels(ax,{'Masa/inercia','Rigidez','Velocidad'});xtickangle(ax,15);
    ylabel(ax,'Sensibilidad S_i [-]');
    if j==1,title(ax,'Desplazamiento RMS horizontal','FontSize',18,'FontWeight','normal');else,title(ax,'Aceleración RMS horizontal','FontSize',18,'FontWeight','normal');end
    grid(ax,'on');box(ax,'on');ax.GridColor=[.8 .8 .8];ax.GridAlpha=.35;
end
lg=legend(ax,'Location','southoutside','NumColumns',2,'FontSize',14);lg.Layout.Tile='south';
exportgraphics(f,fullfile(docs,'figures/sensibilidad_refinada.png'),'Resolution',300,'BackgroundColor','white');
exportgraphics(f,fullfile(docs,'figures/sensibilidad_refinada.pdf'),'ContentType','vector','BackgroundColor','white');close(f);
p=fullfile(docs,'figure_catalog.json');catalog=jsondecode(fileread(p));
item=struct('id',"sensibilidad_refinada",'engine',"MATLAB R2026a",'sources',{{'refined_local_sensitivities.csv'}});
if ~any(strcmp({catalog.id},'sensibilidad_refinada')),catalog(end+1)=item;end
fid=fopen(p,'w');fprintf(fid,'%s',jsonencode(catalog,PrettyPrint=true));fclose(fid);
