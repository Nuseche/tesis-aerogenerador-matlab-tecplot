function fig = plot_campbell(modalResults, fileName)
%PLOT_CAMPBELL Plot tracked modal branches and 1P/3P excitation lines.

fig = gobjects(0);
if ~isstruct(modalResults) || ~isfield(modalResults,'campbell'), return; end
campbell = modalResults.campbell;
if ~all(isfield(campbell,{'speedRPM','frequencyHz'})), return; end
speed = campbell.speedRPM(:); frequency = campbell.frequencyHz;
if size(frequency,1) ~= numel(speed), return; end
fig = figure('Visible','off','Color','w'); ax = axes(fig);
plot(ax,speed,frequency,'-o','LineWidth',1,'MarkerSize',3); hold(ax,'on');
plot(ax,speed,speed/60,'--k','LineWidth',1.2,'DisplayName','1P');
plot(ax,speed,3*speed/60,':k','LineWidth',1.4,'DisplayName','3P');
set(ax,'Color','w','XColor','k','YColor','k', ...
    'GridColor',[0.72 0.72 0.72],'MinorGridColor',[0.85 0.85 0.85]);
grid(ax,'on'); box(ax,'on'); xlabel(ax,'Rotor speed (RPM)');
ylabel(ax,'Frequency (Hz)'); title(ax,'Campbell diagram','Color','k');
if nargin>=2 && strlength(string(fileName))>0
    exportgraphics(fig,fileName,'Resolution',180);
end
end
