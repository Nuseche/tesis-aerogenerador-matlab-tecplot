% Publication figures from stored accepted data only; no model solve.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));addpath(root);
folder=fullfile(root,'runs','sensitivity','initial_20261005');out=fullfile(folder,'figures_revision');
if ~isfolder(out),mkdir(out);end
stored=load(fullfile(folder,'local','summary.mat'),'summary');T=stored.summary.table;
selected=T.step==0.005&T.response=="frequency"&T.trackingValid&T.signalResolved&T.stepConverged;
A=T(selected,:);labels=strings(height(A),1);
for j=1:height(A)
    if A.parameter(j)=="rotor_speed",name="Velocidad del rotor";
    elseif A.parameter(j)=="blade_density",name="Densidad de palas";
    else,name="Rigidez de palas";end
    labels(j)=name+" | grupo "+A.modeOrGroup(j);
end
f=figure('Visible','off','Color','w','Position',[100 100 940 420]);
barh(A.sensitivity,'FaceColor',[.15 .4 .55]);yticks(1:height(A));yticklabels(labels);
xlabel('Sensibilidad relativa de la frecuencia (adimensional)');grid on;xline(0);
title('Derivadas aceptadas con perturbación de 0.5 %');
paper_style(f);exportgraphics(f,fullfile(out,'sensibilidad_frecuencias.png'),'Resolution',180);
paper_style(f);exportgraphics(f,fullfile(out,'sensibilidad_frecuencias.pdf'),'ContentType','vector');close(f);
C=readtable(fullfile(folder,'seismic','time_convergence.csv'));
f=figure('Visible','off','Color','w','Position',[100 100 850 420]);hold on;
for node=[129 56 92 128]
    rows=C.nodeId==node&C.dtS>0.00125;[dt,order]=sort(C.dtS(rows));e=C.relativeL2ToFinest(rows);
    colors=[0 .447 .741;.85 .325 .098;.18 .55 .3;.494 .184 .556];
    index=find([129 56 92 128]==node,1);
    loglog(dt,e(order),'-o','LineWidth',1.3,'Color',colors(index,:),'DisplayName',"Nodo "+node);
end
set(gca,'XScale','log','YScale','log');xlabel('Paso temporal (s)');ylabel('Diferencia L_2 relativa frente a 0.00125 s');grid on;legend('Location','northwest');
title('Sismo sintético, 0 a 1 s: respuesta de desplazamiento');
paper_style(f);exportgraphics(f,fullfile(out,'convergencia_temporal.png'),'Resolution',180);
paper_style(f);exportgraphics(f,fullfile(out,'convergencia_temporal.pdf'),'ContentType','vector');close(f);
% Genuine local sweeps of accepted GROUP centroids, not frequency indices.
f=figure('Visible','off','Color','w','Position',[100 100 900 380]);tl=tiledlayout(f,1,2);
for panel=1:2
    nexttile(tl);hold on;parameter=["blade_density" "blade_stiffness"];
    rows=T.parameter==parameter(panel)&T.modeOrGroup=="10+11"&T.response=="frequency"&T.identity=="group_centroid"&T.trackingValid;
    B=T(rows,:);x=[1-B.step;1;1+B.step];y=[B.minus;B.nominal(1);B.plus];
    [x,order]=sort(x);plot(x,y(order),'-o','LineWidth',1.4);grid on;
    xlabel('Factor relativo (1)');ylabel('Frecuencia media del grupo 10+11 (Hz)');
    names=["Densidad de palas" "Rigidez de palas"];title(names(panel));
end
paper_style(f);exportgraphics(f,fullfile(out,'barridos_grupo_10_11.png'),'Resolution',180);
paper_style(f);exportgraphics(f,fullfile(out,'barridos_grupo_10_11.pdf'),'ContentType','vector');close(f);
P=readtable(fullfile(folder,'temporal_parameters','temporal_sensitivity.csv'),'TextType','string');
P=P(P.step==.005&P.signalResolved&P.stepConverged,:);
f=figure('Visible','off','Color','w','Position',[100 100 940 430]);
labels=strings(height(P),1);
for j=1:height(P)
    if P.parameter(j)=="blade_density",name="Densidad de palas";else,name="Rigidez de palas";end
    if P.response(j)=="peak_absolute_acceleration",metric="aceleración absoluta";else,metric="desplazamiento relativo";end
    labels(j)=name+" | nodo "+P.nodeId(j)+" | "+metric;
end
barh(P.sensitivity,'FaceColor',[.4 .3 .6]);yticks(1:height(P));yticklabels(labels);xlabel('Sensibilidad relativa del máximo absoluto (1)');grid on;xline(0);
title('Respuesta sísmica: indicadores aceptados, ventana 0 a 1 s');
paper_style(f);exportgraphics(f,fullfile(out,'sensibilidad_sismica.png'),'Resolution',180);
paper_style(f);exportgraphics(f,fullfile(out,'sensibilidad_sismica.pdf'),'ContentType','vector');close(f);

function paper_style(f)
set(f,'Color','w');
set(findall(f,'Type','axes'),'Color','w','XColor','k','YColor','k','GridColor',[.55 .55 .55],'FontSize',11);
set(findall(f,'Type','text'),'Color','k');
leg=findall(f,'Type','legend');
if ~isempty(leg),set(leg,'Color','w','TextColor','k','EdgeColor',[.5 .5 .5]);end
end
