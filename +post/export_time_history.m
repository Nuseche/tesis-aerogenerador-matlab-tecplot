function summary = export_time_history(run, timeResults, cfg)
%EXPORT_TIME_HISTORY Export selected response channels and extrema.

if nargin < 3, cfg = struct(); end
if ~isfield(timeResults, 't') || isempty(timeResults.t)
    summary = table(); return
end
t = timeResults.t(:);
q = localOrient(timeResults, 'q', numel(t));
qd = localOrient(timeResults, 'qd', numel(t));
qdd = localOrient(timeResults, 'qdd', numel(t));
absoluteAcceleration = localOrient(timeResults, 'absoluteAcceleration', numel(t));

channels = 1:min(12, size(q,2));
if isfield(cfg, 'output') && isfield(cfg.output, 'timeHistoryDofs')
    requested = cfg.output.timeHistoryDofs(:).';
    channels = requested(requested >= 1 & requested <= size(q,2));
end
out = table(t, 'VariableNames', {'time_s'});
for i = channels
    if ~isempty(q), out.(sprintf('q_%d', i)) = q(:,i); end
    if ~isempty(qd), out.(sprintf('qd_%d', i)) = qd(:,i); end
    if ~isempty(qdd), out.(sprintf('qdd_%d', i)) = qdd(:,i); end
    if ~isempty(absoluteAcceleration)
        out.(sprintf('absAcc_%d', i)) = absoluteAcceleration(:,i);
    end
end
writetable(out, fullfile(run.folder, 'time_history.csv'));

if isempty(q)
    summary = table(); return
end
summary = table((1:size(q,2)).', min(q,[],1).', max(q,[],1).', ...
    max(abs(q),[],1).', 'VariableNames', {'dof','minimum','maximum','maximumAbsolute'});
writetable(summary, fullfile(run.folder, 'time_extrema.csv'));
end

function value = localOrient(s, name, nt)
value = [];
if ~isfield(s, name) || isempty(s.(name)), return; end
value = s.(name);
if size(value,1) ~= nt && size(value,2) == nt, value = value.'; end
if size(value,1) ~= nt
    error('post:export_time_history:Shape', '%s must have one dimension equal to numel(t).', name);
end
end
