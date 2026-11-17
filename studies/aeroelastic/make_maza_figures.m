function make_maza_figures(responses,conditions,folder)
%MAKE_MAZA_FIGURES Tip bending and twist, monochrome, no embedded title/caption.
% The isolated model has +Z span, clamped first node and final DOF theta_z.
f=figure('Visible','off','Color','w','Units','centimeters','Position',[2 2 24 19]);
cleanup=onCleanup(@()close(f));layout=tiledlayout(f,3,2,'TileSpacing','compact','Padding','compact');
for c=1:3
    lastTime=1;
    for variant=1:2
        r=responses{c,variant};if ~isempty(r),lastTime=max(lastTime,r.t(end));end
    end
    for channel=1:2
        ax=nexttile(layout);hold(ax,'on');handles=gobjects(0);labels=strings(0);
        for variant=[3 2 1]
            r=responses{c,variant};if isempty(r),continue,end
            if channel==1,y=r.tipWindDisplacement;else,y=r.q(end,:).';end
            styles={'--','-',':'};colors={[.5 .5 .5],[0 0 0],[.6 .6 .6]};
            handles(end+1)=plot(ax,r.t,y,'LineStyle',styles{variant}, ...
                'Color',colors{variant},'LineWidth',.8); %#ok<AGROW>
            if variant==2&&r.status=="rotation_limit"
                plot(ax,r.t(end),y(end),'ko','MarkerFaceColor','w','HandleVisibility','off');
            end
            if variant==3,labels(end+1)="Prescribed loads, 0.005 s";
            elseif variant==2,labels(end+1)="Weak coupling, 0.005 s";
            else,labels(end+1)="Weak coupling, 0.010 s";end %#ok<AGROW>
        end
        if channel==1,ylabel(ax,'Tip displacement, u_x (m)');else,ylabel(ax,'Tip twist, \theta_s (rad)');end
        xlabel(ax,'Time (s)');xlim(ax,[0 lastTime]);
        set(ax,'FontName','Times','FontSize',10,'TickDir','out','Box','off','Color','w','XColor','k','YColor','k');
        letter='a'+2*(c-1)+channel-1;
        if channel==1,label=sprintf('(%c)  U = %g m/s;  \\Omega = %g rad/s',letter,conditions(c,1),conditions(c,2));
        else,label=sprintf('(%c)',letter);end
        labelHeight=.96;if c==1&&channel==1,labelHeight=.35;end
        text(ax,.03,labelHeight,label,'Units','normalized','VerticalAlignment','top', ...
            'FontName','Times','FontSize',10,'BackgroundColor','w','Color','k');
        if c==1&&channel==1&&~isempty(handles)
            lg=legend(ax,handles,labels,'Orientation','horizontal','Box','off','FontSize',10,'TextColor','k');
            lg.Layout.Tile='south';
        end
    end
end
exportgraphics(f,fullfile(folder,'maza_operating_conditions.pdf'),'ContentType','vector','BackgroundColor','white');
exportgraphics(f,fullfile(folder,'maza_operating_conditions.png'),'Resolution',180,'BackgroundColor','white');
end
