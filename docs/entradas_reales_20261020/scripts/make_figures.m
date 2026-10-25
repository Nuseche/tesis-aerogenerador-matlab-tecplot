% Scientific figures using the authorized existing monochrome style.
root=fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));docs=fullfile(root,'docs/entradas_reales_20261020');
folder=fullfile(root,'runs/sensitivity/real_inputs_20261020');figs=fullfile(docs,'figures');
s=jsondecode(fileread(fullfile(docs,'analysis_summary.json')));
set(groot,'DefaultFigureVisible','off','DefaultAxesFontName','Arial','DefaultTextFontName','Arial', ...
    'DefaultAxesFontSize',18,'DefaultAxesLineWidth',1.1,'DefaultFigureColor','w', ...
    'DefaultAxesColor','w','DefaultAxesXColor','k','DefaultAxesYColor','k', ...
    'DefaultTextColor','k','DefaultLegendColor','w','DefaultLegendTextColor','k');
wind=readmatrix(fullfile(docs,'tables/wind_DTU_s70u_SI.csv'));
eq=readmatrix(fullfile(docs,'tables/ARL360_SI.csv'));
catalog=struct('id',{},'engine',{},'sources',{});

f=figure('Units','inches','Position',[1 1 12 5]);tl=tiledlayout(f,2,1,'TileSpacing','compact','Padding','compact');
ax=nexttile(tl);plot(ax,wind(:,1),wind(:,2),'k','LineWidth',.7);xlim(ax,[0 600]);
xlabel(ax,'Tiempo del viento [s]');ylabel(ax,'U a 70 m [m/s]');style(ax);
ylim(ax,[5 7.7]);
ax=nexttile(tl);plot(ax,eq(:,1),eq(:,2)/9.80665,'k','LineWidth',.8);
xlabel(ax,'Tiempo del sismo [s]');ylabel(ax,'a_g / g [-]');xlim(ax,[0 40]);style(ax);
ylim(ax,[-.26 .34]);
catalog(end+1)=savefigure(f,figs,'entradas_medidas',{'wind_DTU_s70u_SI.csv','ARL360_SI.csv'});

[fw,pw,nw]=welch(wind(:,2).^2/mean(wind(:,2).^2)-1,25,20);
[fg,pg,ng]=welch(eq(:,2),50,20);
f=figure('Units','inches','Position',[1 1 12 4.7]);ax=axes(f,'Position',[.10 .20 .86 .72]);hold(ax,'on');
plot(ax,fw,pw,'k-','LineWidth',1.5,'DisplayName','Forma fluctuante del empuje');
plot(ax,fg,pg,'Color',[.45 .45 .45],'LineStyle','--','LineWidth',1.5,'DisplayName','Aceleración del terreno');
for freq=[.230632 .587499 1.225430],xline(ax,freq,':','Color',[.65 .65 .65],'HandleVisibility','off');end
set(ax,'XScale','log','YScale','log');xlim(ax,[.05 12.5]);
xlabel(ax,'Frecuencia [Hz]');ylabel(ax,'PSD / integral de PSD [1/Hz]');
legend(ax,'Location','southwest','FontSize',15);style(ax);
catalog(end+1)=savefigure(f,figs,'contenido_frecuencial',{'wind_DTU_s70u_SI.csv','ARL360_SI.csv'});
writetable(table(fw,pw,'VariableNames',{'frequencyHz','normalizedPSD'}),fullfile(docs,'tables/wind_normalized_psd.csv'));
writetable(table(fg,pg,'VariableNames',{'frequencyHz','normalizedPSD'}),fullfile(docs,'tables/earthquake_normalized_psd.csv'));
spectra=struct('windowSeconds',20,'overlapFraction',.5,'windSegments',nw,'earthquakeSegments',ng, ...
    'interpretation',"variance-normalized shapes, not equal force or equal energy", ...
    'windFractionBelow05Hz',trapz(fw(fw<=.5),pw(fw<=.5)), ...
    'earthquakeFractionBelow05Hz',trapz(fg(fg<=.5),pg(fg<=.5)));
fid=fopen(fullfile(docs,'tables/spectral_summary.json'),'w');fprintf(fid,'%s',jsonencode(spectra,PrettyPrint=true));fclose(fid);

n=readtable(fullfile(docs,'tables/nominal_earthquakes.csv'),'TextType','string');
record=["ARL360" "CHY023-W" "TCU052-N"];labels={'Arleta 1994','CHY023 1999','TCU052 1999'};
f=figure('Units','inches','Position',[1 1 12 4.7]);tl=tiledlayout(f,1,2,'TileSpacing','compact','Padding','compact');
for j=1:2
    response=["gondola_qH" "gondola_aH"];y=zeros(1,3);
    for k=1:3,y(k)=n.finePeak(n.record==record(k)&n.response==response(j));end
    ax=nexttile(tl);bar(ax,1:3,y,'FaceColor',[.65 .65 .65],'EdgeColor','k');xticks(ax,1:3);xticklabels(ax,labels);xtickangle(ax,18);
    if j==1,ylabel(ax,'q_{H,max} de góndola [m]');else,ylabel(ax,'a_{H,max}^{abs} de góndola [m/s^2]');end
    style(ax);
end
catalog(end+1)=savefigure(f,figs,'respuesta_sismos_reales',{'nominal_earthquakes.csv'});

l=readtable(fullfile(docs,'tables/local_sensitivities.csv'),'TextType','string');
f=figure('Units','inches','Position',[1 1 12 5]);tl=tiledlayout(f,1,2,'TileSpacing','compact','Padding','compact');
parameters=["blade_density" "blade_stiffness" "rotor_speed"];types=["earthquake" "wind"];
for j=1:2
    ax=nexttile(tl);hold(ax,'on');responses=["gondola_qH_RMS" "gondola_aH_RMS"];
    for k=1:2
        y=zeros(1,3);valid=false(1,3);
        for p=1:3,r=l(l.input==types(k)&l.parameter==parameters(p)&l.response==responses(j),:);y(p)=r.S;valid(p)=r.accepted;end
        if k==1,marker='o';grey=[0 0 0];name='Sismo X';else,marker='s';grey=[.45 .45 .45];name='Viento por unidad de empuje';end
        plot(ax,(1:3)+(k-1.5)*.12,y,'Color',grey,'LineStyle','-','Marker',marker,'MarkerFaceColor','w','MarkerSize',8,'DisplayName',name);
        scatter(ax,find(valid)+(k-1.5)*.12,y(valid),55,grey,marker,'filled','MarkerEdgeColor',grey,'HandleVisibility','off');
    end
    yline(ax,0,':','Color',[.6 .6 .6],'HandleVisibility','off');xticks(ax,1:3);xticklabels(ax,{'Masa/inercia','Rigidez','Velocidad'});xtickangle(ax,15);
    ylabel(ax,'Sensibilidad S_i [-]');
    if j==1,title(ax,'Desplazamiento RMS horizontal','FontSize',18,'FontWeight','normal');else,title(ax,'Aceleración RMS horizontal','FontSize',18,'FontWeight','normal');end
    style(ax);
end
lg=legend(ax,'Location','southoutside','NumColumns',2,'FontSize',14);lg.Layout.Tile='south';
catalog(end+1)=savefigure(f,figs,'sensibilidad_entradas',{'local_sensitivities.csv'});

df=readtable(fullfile(docs,'tables/differentiation_refinement.csv'),'TextType','string');
f=figure('Units','inches','Position',[1 1 12 4.8]);tl=tiledlayout(f,1,2,'TileSpacing','compact','Padding','compact');
for j=1:2
    ax=nexttile(tl);hold(ax,'on');markers={'o','s','d'};parameterLabels={'Masa/inercia','Rigidez','Velocidad'};
    for k=1:3
        a=sortrows(df(df.input==types(j)&df.parameter==parameters(k)&df.response=="gondola_qH_RMS",:),'h');
        grey=repmat((k-1)*.25,1,3);plot(ax,100*a.h,a.S,'Color',grey,'LineStyle','-','Marker',markers{k},'MarkerFaceColor','w','MarkerSize',7,'DisplayName',parameterLabels{k});
    end
    set(ax,'XScale','log','XDir','reverse');xticks(ax,[.125 .25 .5 1]);xticklabels(ax,{'0.125','0.25','0.5','1'});
    xlabel(ax,'Perturbación h [%]');ylabel(ax,'Secante del RMS [-]');
    if j==1,title(ax,'Sismo alineado','FontSize',18,'FontWeight','normal');else,title(ax,'Viento por unidad de empuje','FontSize',18,'FontWeight','normal');end
    style(ax);
end
lg=legend(ax,'Location','southoutside','NumColumns',3,'FontSize',15);lg.Layout.Tile='south';
catalog(end+1)=savefigure(f,figs,'refinamiento_sensibilidad',{'differentiation_refinement.csv'});

p=readtable(fullfile(docs,'tables/arrival_phase_comparison.csv'),'TextType','string');
f=figure('Units','inches','Position',[1 1 12 5]);tl=tiledlayout(f,1,2,'TileSpacing','compact','Padding','compact');
for j=1:2
    responses=["gondola_qH" "gondola_aH"];ax=nexttile(tl);hold(ax,'on');
    ratios=unique(p.thrustOverReference);low=zeros(size(ratios));high=low;atZero=low;
    for k=1:numel(ratios)
        a=p(p.thrustOverReference==ratios(k)&p.response==responses(j),:);
        low(k)=min(a.overEarthquakePeak);high(k)=max(a.overEarthquakePeak);atZero(k)=a.overEarthquakePeak(a.earthquakeArrivalSeconds==0);
    end
    fill(ax,[ratios;flipud(ratios)],[low;flipud(high)],[.82 .82 .82],'EdgeColor','none','DisplayName','Mínimo-máximo de 29 llegadas');
    plot(ax,ratios,atZero,'k-','LineWidth',1.5,'DisplayName','Llegada en t = 0');
    xlabel(ax,'Empuje medio / F_{ref} [-]');ylabel(ax,'Máximo / máximo sísmico [-]');
    if j==1,title(ax,'Desplazamiento de góndola','FontSize',18,'FontWeight','normal');else,title(ax,'Aceleración de góndola','FontSize',18,'FontWeight','normal');end
    style(ax);
end
lg=legend(ax,'Location','southoutside','NumColumns',2,'FontSize',14);lg.Layout.Tile='south';
catalog(end+1)=savefigure(f,figs,'combinacion_y_llegada',{'arrival_phase_comparison.csv'});

amp=readtable(fullfile(docs,'tables/input_amplitude_sensitivities.csv'),'TextType','string');
f=figure('Units','inches','Position',[1 1 12 4.8]);tl=tiledlayout(f,1,2,'TileSpacing','compact','Padding','compact');
for j=1:2
    responses=["gondola_qH" "gondola_aH"];a=sortrows(amp(amp.step==.005 & amp.response==responses(j),:),'thrustOverReference');
    ax=nexttile(tl);hold(ax,'on');
    plot(ax,a.thrustOverReference,a.S_seismicAmplitude,'k-','LineWidth',1.5,'DisplayName','Amplitud sísmica');
    plot(ax,a.thrustOverReference,a.S_meanThrust,'--','Color',[.45 .45 .45],'LineWidth',1.5,'DisplayName','Empuje medio');
    xlabel(ax,'Empuje medio / F_{ref} [-]');ylabel(ax,'Sensibilidad de amplitud [-]');
    if j==1,title(ax,'Máximo de desplazamiento','FontSize',18,'FontWeight','normal');else,title(ax,'Máximo de aceleración','FontSize',18,'FontWeight','normal');end
    style(ax);
end
lg=legend(ax,'Location','southoutside','NumColumns',2,'FontSize',15);lg.Layout.Tile='south';
catalog(end+1)=savefigure(f,figs,'sensibilidad_amplitudes',{'input_amplitude_sensitivities.csv'});

c=readtable(fullfile(docs,'tables/combined_sensitivities.csv'),'TextType','string');
f=figure('Units','inches','Position',[1 1 12 4.8]);tl=tiledlayout(f,1,2,'TileSpacing','compact','Padding','compact');
for j=1:2
    responses=["gondola_qH_RMS" "base_MH_RMS"];ax=nexttile(tl);hold(ax,'on');markers={'o','s','d'};parameterLabels={'Masa/inercia','Rigidez','Velocidad'};
    for k=1:3
        a=sortrows(c(c.parameter==parameters(k)&c.response==responses(j),:),'thrustOverReference');grey=repmat((k-1)*.25,1,3);
        plot(ax,a.thrustOverReference,a.S,'Color',grey,'LineStyle','-','Marker',markers{k},'MarkerFaceColor','w','MarkerSize',7,'DisplayName',parameterLabels{k});
        ix=logical(a.stepChecksPassed);scatter(ax,a.thrustOverReference(ix),a.S(ix),45,grey,markers{k},'filled','MarkerEdgeColor',grey,'HandleVisibility','off');
    end
    yline(ax,0,':','Color',[.6 .6 .6],'HandleVisibility','off');xlabel(ax,'Empuje medio / F_{ref} [-]');ylabel(ax,'Sensibilidad S_i [-]');
    if j==1,title(ax,'Desplazamiento RMS de góndola','FontSize',18,'FontWeight','normal');else,title(ax,'Momento RMS en base','FontSize',18,'FontWeight','normal');end
    style(ax);
end
lg=legend(ax,'Location','southoutside','NumColumns',3,'FontSize',15);lg.Layout.Tile='south';
catalog(end+1)=savefigure(f,figs,'sensibilidad_combinada',{'combined_sensitivities.csv'});

d=readtable(fullfile(docs,'tables/direction_comparison.csv'),'TextType','string');
f=figure('Units','inches','Position',[1 1 12 4.8]);tl=tiledlayout(f,1,2,'TileSpacing','compact','Padding','compact');
for j=1:2
    responses=["gondola_qH" "gondola_aH"];y=zeros(3,2);
    for k=1:3,a=d(d.record==record(k)&d.response==responses(j),:);y(k,:)=[a.globalXPeak a.globalYPeak];end
    ax=nexttile(tl);b=bar(ax,y,'grouped');b(1).FaceColor=[.3 .3 .3];b(2).FaceColor=[.85 .85 .85];
    xticks(ax,1:3);xticklabels(ax,labels);xtickangle(ax,18);
    if j==1,ylabel(ax,'Desplazamiento horizontal [m]');else,ylabel(ax,'Aceleración absoluta [m/s^2]');end
    style(ax);
end
lg=legend(ax,{'Sismo global X','Sismo global Y'},'Location','southoutside','NumColumns',2,'FontSize',15);lg.Layout.Tile='south';
catalog(end+1)=savefigure(f,figs,'efecto_direccion',{'direction_comparison.csv'});

% Record intensity measures computed from each complete supplied record.
catalogEq=jsondecode(fileread(fullfile(docs,'tables/earthquake_catalog.json')));intensity=cell(0,7);
for j=1:numel(catalogEq)
    a=readmatrix(catalogEq(j).outputCsv);t=a(:,1);ag=a(:,2);
    arias=pi/(2*9.80665)*cumtrapz(t,ag.^2);fraction=arias/arias(end);
    t5=firstCrossing(t,fraction,.05);t95=firstCrossing(t,fraction,.95);
    intensity(end+1,:)={string(catalogEq(j).file),catalogEq(j).pgaG,arias(end),t5,t95,t95-t5,t(end)};
end
writetable(cell2table(intensity,'VariableNames',{'recordFile','pgaG','ariasMps','t05','t95','D05_95Seconds','lastTime'}),fullfile(docs,'tables/earthquake_intensities.csv'));
fid=fopen(fullfile(docs,'figure_catalog.json'),'w');fprintf(fid,'%s',jsonencode(catalog,PrettyPrint=true));fclose(fid);

function t=firstCrossing(time,x,level)
k=find(x>=level,1);if k==1,t=time(1);else,t=interp1(x(k-1:k),time(k-1:k),level);end
end
function style(ax)
grid(ax,'on');box(ax,'on');ax.GridColor=[.8 .8 .8];ax.GridAlpha=.35;
end
function item=savefigure(f,folder,id,sources)
exportgraphics(f,fullfile(folder,[id '.png']),'Resolution',300,'BackgroundColor','white');
exportgraphics(f,fullfile(folder,[id '.pdf']),'ContentType','vector','BackgroundColor','white');close(f);
item=struct('id',id,'engine',"MATLAB R2026a",'sources',{sources});
end
function [freq,p,nseg]=welch(x,fs,seconds)
x=x(:);N=round(fs*seconds);hop=floor(N/2);window=.5-.5*cos(2*pi*(0:N-1)'/N);p=zeros(floor(N/2)+1,1);nseg=0;
for first=1:hop:numel(x)-N+1
    a=x(first:first+N-1);a=a-mean(a);ft=fft(window.*a);power=abs(ft(1:numel(p))).^2/(fs*sum(window.^2));
    power(2:end-1)=2*power(2:end-1);p=p+power;nseg=nseg+1;
end
p=p/nseg;freq=(0:numel(p)-1)'*fs/N;p=p/trapz(freq,p);
end
