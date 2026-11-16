function make_tangent_sensitivity_figure()
%MAKE_TANGENT_SENSITIVITY_FIGURE Postprocess or verify the measured inputs study.
root=fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));studyDir=fullfile(root,'studies/measured_inputs');
set(groot,'DefaultFigureVisible','off','DefaultAxesFontName','Arial','DefaultTextFontName','Arial', ...
    'DefaultAxesFontSize',18,'DefaultFigureColor','w','DefaultAxesColor','w', ...
    'DefaultAxesXColor','k','DefaultAxesYColor','k','DefaultTextColor','k','DefaultLegendColor','w','DefaultLegendTextColor','k');
t=readtable(fullfile(studyDir,'tables/refined_local_sensitivities.csv'),'TextType','string');
parameters=["blade_density" "blade_stiffness" "rotor_speed"];types=["earthquake" "wind"];
f=figure('Units','inches','Position',[1 1 12 5]);tl=tiledlayout(f,1,2,'TileSpacing','compact','Padding','compact');
for j=1:2
    ax=nexttile(tl);hold(ax,'on');responses=["nacelle_qH_RMS" "nacelle_aH_RMS"];
    for k=1:2
        y=zeros(1,3);valid=false(1,3);
        for n=1:3,r=t(t.input==types(k)&t.parameter==parameters(n)&t.response==responses(j),:);y(n)=r.S;valid(n)=logical(r.accepted);end
        if k==1,marker='o';grey=[0 0 0];name='Sismo X';else,marker='s';grey=[.45 .45 .45];name='Wind per unit thrust';end
        plot(ax,(1:3)+(k-1.5)*.12,y,'Color',grey,'LineStyle','-','LineWidth',1.4,'Marker',marker,'MarkerFaceColor','w','MarkerSize',8,'DisplayName',name);
        scatter(ax,find(valid)+(k-1.5)*.12,y(valid),55,grey,marker,'filled','MarkerEdgeColor',grey,'HandleVisibility','off');
    end
    yline(ax,0,':','Color',[.6 .6 .6],'HandleVisibility','off');xticks(ax,1:3);xticklabels(ax,{'Mass/inertia','Stiffness','Speed'});xtickangle(ax,15);
    ylabel(ax,'Sensitivity S_i [-]');
    if j==1,title(ax,'Horizontal RMS displacement','FontSize',18,'FontWeight','normal');else,title(ax,'Horizontal RMS acceleration','FontSize',18,'FontWeight','normal');end
    grid(ax,'on');box(ax,'on');ax.GridColor=[.8 .8 .8];ax.GridAlpha=.35;
end
lg=legend(ax,'Location','southoutside','NumColumns',2,'FontSize',14);lg.Layout.Tile='south';
exportgraphics(f,fullfile(studyDir,'figures/sensibilidad_refinada.png'),'Resolution',300,'BackgroundColor','white');
exportgraphics(f,fullfile(studyDir,'figures/sensibilidad_refinada.pdf'),'ContentType','vector','BackgroundColor','white');close(f);
p=fullfile(studyDir,'figure_catalog.json');catalog=jsondecode(fileread(p));
item=struct('id',"sensibilidad_refinada",'engine',"MATLAB R2026a",'sources',{{'refined_local_sensitivities.csv'}});
if ~any(strcmp({catalog.id},'sensibilidad_refinada')),catalog(end+1)=item;end
fid=fopen(p,'w');fprintf(fid,'%s',jsonencode(catalog,PrettyPrint=true));fclose(fid);
end
