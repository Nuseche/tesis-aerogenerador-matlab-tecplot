function make_measured_input_figures(campaignFolder)
%MAKE_MEASURED_INPUT_FIGURES Postprocess or verify the measured inputs study.
% Scientific figures using the authorized existing monochrome style.
root=fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));studyDir=fullfile(root,'studies/measured_inputs');

if nargin<1 || strlength(string(campaignFolder))==0
    campaignFolder=fullfile(root,'runs','studies','measured_inputs');
end
folder=fullfile(campaignFolder);figs=fullfile(studyDir,'figures');
s=jsondecode(fileread(fullfile(studyDir,'analysis_summary.json')));
set(groot,'DefaultFigureVisible','off','DefaultAxesFontName','Arial','DefaultTextFontName','Arial', ...
    'DefaultAxesFontSize',18,'DefaultAxesLineWidth',1.1,'DefaultFigureColor','w', ...
    'DefaultAxesColor','w','DefaultAxesXColor','k','DefaultAxesYColor','k', ...
    'DefaultTextColor','k','DefaultLegendColor','w','DefaultLegendTextColor','k');
wind=readmatrix(fullfile(studyDir,'tables/wind_DTU_s70u_SI.csv'));
eq=readmatrix(fullfile(studyDir,'tables/ARL360_SI.csv'));
catalog=struct('id',{},'engine',{},'sources',{});

f=figure('Units','inches','Position',[1 1 12 5]);tl=tiledlayout(f,2,1,'TileSpacing','compact','Padding','compact');
ax=nexttile(tl);plot(ax,wind(:,1),wind(:,2),'k','LineWidth',.7);xlim(ax,[0 600]);
xlabel(ax,'Wind record time [s]');ylabel(ax,'U at 70 m [m/s]');style(ax);
ylim(ax,[5 7.7]);
ax=nexttile(tl);plot(ax,eq(:,1),eq(:,2)/9.80665,'k','LineWidth',.8);
xlabel(ax,'Earthquake record time [s]');ylabel(ax,'a_g / g [-]');xlim(ax,[0 40]);style(ax);
ylim(ax,[-.26 .34]);
catalog(end+1)=savefigure(f,figs,'measured_inputs',{'wind_DTU_s70u_SI.csv','ARL360_SI.csv'});

[fw,pw,nw]=welch(wind(:,2).^2/mean(wind(:,2).^2)-1,25,20);
[fg,pg,ng]=welch(eq(:,2),50,20);
f=figure('Units','inches','Position',[1 1 12 4.7]);ax=axes(f,'Position',[.10 .20 .86 .72]);hold(ax,'on');
plot(ax,fw,pw,'k-','LineWidth',1.5,'DisplayName','Fluctuating thrust shape');
plot(ax,fg,pg,'Color',[.45 .45 .45],'LineStyle','--','LineWidth',1.5,'DisplayName','Ground acceleration');
for freq=[.230632 .587499 1.225430],xline(ax,freq,':','Color',[.65 .65 .65],'HandleVisibility','off');end
set(ax,'XScale','log','YScale','log');xlim(ax,[.05 12.5]);
xlabel(ax,'Frequency [Hz]');ylabel(ax,'PSD / PSD integral [1/Hz]');
legend(ax,'Location','southwest','FontSize',15);style(ax);
catalog(end+1)=savefigure(f,figs,'frequency_content',{'wind_DTU_s70u_SI.csv','ARL360_SI.csv'});
writetable(table(fw,pw,'VariableNames',{'frequencyHz','normalizedPSD'}),fullfile(studyDir,'tables/wind_normalized_psd.csv'));
writetable(table(fg,pg,'VariableNames',{'frequencyHz','normalizedPSD'}),fullfile(studyDir,'tables/earthquake_normalized_psd.csv'));
spectra=struct('windowSeconds',20,'overlapFraction',.5,'windSegments',nw,'earthquakeSegments',ng, ...
    'interpretation',"variance-normalized shapes, not equal force or equal energy", ...
    'windFractionBelow05Hz',trapz(fw(fw<=.5),pw(fw<=.5)), ...
    'earthquakeFractionBelow05Hz',trapz(fg(fg<=.5),pg(fg<=.5)));
fid=fopen(fullfile(studyDir,'tables/spectral_summary.json'),'w');fprintf(fid,'%s',jsonencode(spectra,PrettyPrint=true));fclose(fid);

n=readtable(fullfile(studyDir,'tables/nominal_earthquakes.csv'),'TextType','string');
record=["ARL360" "CHY023-W" "TCU052-N"];labels={'Arleta 1994','CHY023 1999','TCU052 1999'};
f=figure('Units','inches','Position',[1 1 12 4.7]);tl=tiledlayout(f,1,2,'TileSpacing','compact','Padding','compact');
for j=1:2
    response=["nacelle_qH" "nacelle_aH"];y=zeros(1,3);
    for k=1:3,y(k)=n.finePeak(n.record==record(k)&n.response==response(j));end
    ax=nexttile(tl);bar(ax,1:3,y,'FaceColor',[.65 .65 .65],'EdgeColor','k');xticks(ax,1:3);xticklabels(ax,labels);xtickangle(ax,18);
    if j==1,ylabel(ax,'q_{H,max} at the nacelle [m]');else,ylabel(ax,'a_{H,max}^{abs} at the nacelle [m/s^2]');end
    style(ax);
end
catalog(end+1)=savefigure(f,figs,'measured_seismic_response',{'nominal_earthquakes.csv'});

l=readtable(fullfile(studyDir,'tables/local_sensitivities.csv'),'TextType','string');
f=figure('Units','inches','Position',[1 1 12 5]);tl=tiledlayout(f,1,2,'TileSpacing','compact','Padding','compact');
parameters=["blade_density" "blade_stiffness" "rotor_speed"];types=["earthquake" "wind"];
for j=1:2
    ax=nexttile(tl);hold(ax,'on');responses=["nacelle_qH_RMS" "nacelle_aH_RMS"];
    for k=1:2
        y=zeros(1,3);valid=false(1,3);
        for p=1:3,r=l(l.input==types(k)&l.parameter==parameters(p)&l.response==responses(j),:);y(p)=r.S;valid(p)=r.accepted;end
        if k==1,marker='o';grey=[0 0 0];name='Sismo X';else,marker='s';grey=[.45 .45 .45];name='Wind per unit thrust';end
        plot(ax,(1:3)+(k-1.5)*.12,y,'Color',grey,'LineStyle','-','Marker',marker,'MarkerFaceColor','w','MarkerSize',8,'DisplayName',name);
        scatter(ax,find(valid)+(k-1.5)*.12,y(valid),55,grey,marker,'filled','MarkerEdgeColor',grey,'HandleVisibility','off');
    end
    yline(ax,0,':','Color',[.6 .6 .6],'HandleVisibility','off');xticks(ax,1:3);xticklabels(ax,{'Mass/inertia','Stiffness','Speed'});xtickangle(ax,15);
    ylabel(ax,'Sensitivity S_i [-]');
    if j==1,title(ax,'Horizontal RMS displacement','FontSize',18,'FontWeight','normal');else,title(ax,'Horizontal RMS acceleration','FontSize',18,'FontWeight','normal');end
    style(ax);
end
lg=legend(ax,'Location','southoutside','NumColumns',2,'FontSize',14);lg.Layout.Tile='south';
catalog(end+1)=savefigure(f,figs,'input_sensitivity',{'local_sensitivities.csv'});

df=readtable(fullfile(studyDir,'tables/differentiation_refinement.csv'),'TextType','string');
f=figure('Units','inches','Position',[1 1 12 4.8]);tl=tiledlayout(f,1,2,'TileSpacing','compact','Padding','compact');
for j=1:2
    ax=nexttile(tl);hold(ax,'on');markers={'o','s','d'};parameterLabels={'Mass/inertia','Stiffness','Speed'};
    for k=1:3
        a=sortrows(df(df.input==types(j)&df.parameter==parameters(k)&df.response=="nacelle_qH_RMS",:),'h');
        grey=repmat((k-1)*.25,1,3);plot(ax,100*a.h,a.S,'Color',grey,'LineStyle','-','Marker',markers{k},'MarkerFaceColor','w','MarkerSize',7,'DisplayName',parameterLabels{k});
    end
    set(ax,'XScale','log','XDir','reverse');xticks(ax,[.125 .25 .5 1]);xticklabels(ax,{'0.125','0.25','0.5','1'});
    xlabel(ax,'Perturbation h [%]');ylabel(ax,'RMS secant [-]');
    if j==1,title(ax,'Aligned earthquake','FontSize',18,'FontWeight','normal');else,title(ax,'Wind per unit thrust','FontSize',18,'FontWeight','normal');end
    style(ax);
end
lg=legend(ax,'Location','southoutside','NumColumns',3,'FontSize',15);lg.Layout.Tile='south';
catalog(end+1)=savefigure(f,figs,'sensitivity_refinement',{'differentiation_refinement.csv'});

p=readtable(fullfile(studyDir,'tables/arrival_phase_comparison.csv'),'TextType','string');
f=figure('Units','inches','Position',[1 1 12 5]);tl=tiledlayout(f,1,2,'TileSpacing','compact','Padding','compact');
for j=1:2
    responses=["nacelle_qH" "nacelle_aH"];ax=nexttile(tl);hold(ax,'on');
    ratios=unique(p.thrustOverReference);low=zeros(size(ratios));high=low;atZero=low;
    for k=1:numel(ratios)
        a=p(p.thrustOverReference==ratios(k)&p.response==responses(j),:);
        low(k)=min(a.overEarthquakePeak);high(k)=max(a.overEarthquakePeak);atZero(k)=a.overEarthquakePeak(a.earthquakeArrivalSeconds==0);
    end
    fill(ax,[ratios;flipud(ratios)],[low;flipud(high)],[.82 .82 .82],'EdgeColor','none','DisplayName','Range over 29 arrival times');
    plot(ax,ratios,atZero,'k-','LineWidth',1.5,'DisplayName','Arrival at t = 0');
    xlabel(ax,'Mean thrust / F_{ref} [-]');ylabel(ax,'Peak / seismic peak [-]');
    if j==1,title(ax,'Nacelle displacement','FontSize',18,'FontWeight','normal');else,title(ax,'Nacelle acceleration','FontSize',18,'FontWeight','normal');end
    style(ax);
end
lg=legend(ax,'Location','southoutside','NumColumns',2,'FontSize',14);lg.Layout.Tile='south';
catalog(end+1)=savefigure(f,figs,'combined_arrival_response',{'arrival_phase_comparison.csv'});

amp=readtable(fullfile(studyDir,'tables/input_amplitude_sensitivities.csv'),'TextType','string');
f=figure('Units','inches','Position',[1 1 12 4.8]);tl=tiledlayout(f,1,2,'TileSpacing','compact','Padding','compact');
for j=1:2
    responses=["nacelle_qH" "nacelle_aH"];a=sortrows(amp(amp.step==.005 & amp.response==responses(j),:),'thrustOverReference');
    ax=nexttile(tl);hold(ax,'on');
    plot(ax,a.thrustOverReference,a.S_seismicAmplitude,'k-','LineWidth',1.5,'DisplayName','Seismic amplitude');
    plot(ax,a.thrustOverReference,a.S_meanThrust,'--','Color',[.45 .45 .45],'LineWidth',1.5,'DisplayName','Empuje medio');
    xlabel(ax,'Mean thrust / F_{ref} [-]');ylabel(ax,'Amplitude sensitivity [-]');
    if j==1,title(ax,'Peak displacement','FontSize',18,'FontWeight','normal');else,title(ax,'Peak acceleration','FontSize',18,'FontWeight','normal');end
    style(ax);
end
lg=legend(ax,'Location','southoutside','NumColumns',2,'FontSize',15);lg.Layout.Tile='south';
catalog(end+1)=savefigure(f,figs,'amplitude_sensitivity',{'input_amplitude_sensitivities.csv'});

c=readtable(fullfile(studyDir,'tables/combined_sensitivities.csv'),'TextType','string');
f=figure('Units','inches','Position',[1 1 12 4.8]);tl=tiledlayout(f,1,2,'TileSpacing','compact','Padding','compact');
for j=1:2
    responses=["nacelle_qH_RMS" "base_MH_RMS"];ax=nexttile(tl);hold(ax,'on');markers={'o','s','d'};parameterLabels={'Mass/inertia','Stiffness','Speed'};
    for k=1:3
        a=sortrows(c(c.parameter==parameters(k)&c.response==responses(j),:),'thrustOverReference');grey=repmat((k-1)*.25,1,3);
        plot(ax,a.thrustOverReference,a.S,'Color',grey,'LineStyle','-','Marker',markers{k},'MarkerFaceColor','w','MarkerSize',7,'DisplayName',parameterLabels{k});
        ix=logical(a.stepChecksPassed);scatter(ax,a.thrustOverReference(ix),a.S(ix),45,grey,markers{k},'filled','MarkerEdgeColor',grey,'HandleVisibility','off');
    end
    yline(ax,0,':','Color',[.6 .6 .6],'HandleVisibility','off');xlabel(ax,'Mean thrust / F_{ref} [-]');ylabel(ax,'Sensitivity S_i [-]');
    if j==1,title(ax,'Nacelle RMS displacement','FontSize',18,'FontWeight','normal');else,title(ax,'Base RMS moment','FontSize',18,'FontWeight','normal');end
    style(ax);
end
lg=legend(ax,'Location','southoutside','NumColumns',3,'FontSize',15);lg.Layout.Tile='south';
catalog(end+1)=savefigure(f,figs,'combined_sensitivity',{'combined_sensitivities.csv'});

d=readtable(fullfile(studyDir,'tables/direction_comparison.csv'),'TextType','string');
f=figure('Units','inches','Position',[1 1 12 4.8]);tl=tiledlayout(f,1,2,'TileSpacing','compact','Padding','compact');
for j=1:2
    responses=["nacelle_qH" "nacelle_aH"];y=zeros(3,2);
    for k=1:3,a=d(d.record==record(k)&d.response==responses(j),:);y(k,:)=[a.globalXPeak a.globalYPeak];end
    ax=nexttile(tl);b=bar(ax,y,'grouped');b(1).FaceColor=[.3 .3 .3];b(2).FaceColor=[.85 .85 .85];
    xticks(ax,1:3);xticklabels(ax,labels);xtickangle(ax,18);
    if j==1,ylabel(ax,'Horizontal displacement [m]');else,ylabel(ax,'Absolute acceleration [m/s^2]');end
    style(ax);
end
lg=legend(ax,{'Sismo global X','Sismo global Y'},'Location','southoutside','NumColumns',2,'FontSize',15);lg.Layout.Tile='south';
catalog(end+1)=savefigure(f,figs,'direction_effect',{'direction_comparison.csv'});

% Record intensity measures computed from each complete supplied record.
catalogEq=jsondecode(fileread(fullfile(studyDir,'tables/earthquake_catalog.json')));intensity=cell(0,7);
for j=1:numel(catalogEq)
    a=readmatrix(catalogEq(j).outputCsv);t=a(:,1);ag=a(:,2);
    arias=pi/(2*9.80665)*cumtrapz(t,ag.^2);fraction=arias/arias(end);
    t5=firstCrossing(t,fraction,.05);t95=firstCrossing(t,fraction,.95);
    intensity(end+1,:)={string(catalogEq(j).file),catalogEq(j).pgaG,arias(end),t5,t95,t95-t5,t(end)};
end
writetable(cell2table(intensity,'VariableNames',{'recordFile','pgaG','ariasMps','t05','t95','D05_95Seconds','lastTime'}),fullfile(studyDir,'tables/earthquake_intensities.csv'));
fid=fopen(fullfile(studyDir,'figure_catalog.json'),'w');fprintf(fid,'%s',jsonencode(catalog,PrettyPrint=true));fclose(fid);

end

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
