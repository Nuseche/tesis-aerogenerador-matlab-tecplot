function fig = plot_response(timeResults, fileName, cfg)
%PLOT_RESPONSE Plot selected displacement time histories.

if nargin < 3, cfg = struct(); end
fig = gobjects(0);
if ~isfield(timeResults,'t') || ~isfield(timeResults,'q') || isempty(timeResults.q), return; end
t=timeResults.t(:); q=timeResults.q;
if size(q,2)==numel(t), q=q.'; end
channels=1:min(6,size(q,2));
if isfield(cfg,'output') && isfield(cfg.output,'timeHistoryDofs')
    channels=cfg.output.timeHistoryDofs(:).'; channels=channels(channels<=size(q,2));
end
fig=figure('Visible','off','Color','w'); ax=axes(fig);
plot(ax,t,q(:,channels),'LineWidth',1.0); grid(ax,'on'); box(ax,'on');
xlabel(ax,'Time (s)'); ylabel(ax,'Relative displacement');
legend(ax,compose('DOF %d',channels),'Location','best'); title(ax,'Seismic response');
if nargin>=2 && strlength(string(fileName))>0
    exportgraphics(fig,fileName,'Resolution',180);
end
end
