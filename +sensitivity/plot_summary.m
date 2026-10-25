function plot_summary(summary,folder)
%PLOT_SUMMARY Small panels with SI units and explicit identity validity.
if ~isfolder(fullfile(folder,'figures')),mkdir(fullfile(folder,'figures'));end
T=summary.table;names=unique(T.parameter,'stable');h=min(T.step);
f=figure('Visible','off','Color','w','Position',[100 100 980 680]);
cleanup=onCleanup(@()close(f));
t=tiledlayout(f,2,1,'TileSpacing','compact');
for panel=1:2
    if panel==1,type="frequency";ylabelText='S_f (adimensional)';
    else,type="growth";ylabelText='(1/|lambda_0|) d sigma / d factor';end
    nexttile(t);hold on;
    for p=1:numel(names)
        select=T.parameter==names(p)&T.step==h&T.response==type&T.trackingValid&T.signalResolved&T.stepConverged;
        vals=T.sensitivity(select);scatter(p*ones(size(vals)),vals,32,'filled','MarkerFaceAlpha',0.7);
    end
    yline(0,'Color',[.4 .4 .4]);grid on;xlim([0.5 numel(names)+0.5]);
    xticks(1:numel(names));xticklabels(strrep(names,'_',' '));xtickangle(25);ylabel(ylabelText);
end
title(t,'Sensibilidad local aceptada: ramas individuales y centroides de grupos');
paperStyle(f);exportgraphics(f,fullfile(folder,'figures','local_sensitivity.png'),'Resolution',180);
paperStyle(f);exportgraphics(f,fullfile(folder,'figures','local_sensitivity.pdf'),'ContentType','vector');
clear cleanup
for name=["rotor_speed" "blade_density" "tower_stiffness"]
    if ~any(summary.sweeps.parameter==name),continue,end
    f=figure('Visible','off','Color','w','Position',[100 100 800 440]);cleanup=onCleanup(@()close(f));hold on;
    S=summary.sweeps;sel=S.parameter==name& S.individualValid;
    for b=1:4
        rows=sel&S.mode==b;[x,order]=sort(S.factor(rows));y=S.frequencyHz(rows);
        plot(x,y(order),'-o','DisplayName',"Rama "+b,'LineWidth',1.2);
    end
    xlabel('Factor relativo al nominal (1)');ylabel('Frecuencia amortiguada (Hz)');grid on;
    title(strrep(name,'_',' ')+": barrido local exploratorio");legend('Location','best');
    paperStyle(f);exportgraphics(f,fullfile(folder,'figures',name+'.png'),'Resolution',180);clear cleanup
end
end

function paperStyle(f)
set(f,'Color','w');
set(findall(f,'Type','axes'),'Color','w','XColor','k','YColor','k','GridColor',[.55 .55 .55]);
set(findall(f,'Type','text'),'Color','k');
leg=findall(f,'Type','legend');
if ~isempty(leg),set(leg,'Color','w','TextColor','k','EdgeColor',[.5 .5 .5]);end
end
