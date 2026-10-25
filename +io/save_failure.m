function save_failure(run, cfg, ME)
%SAVE_FAILURE Save diagnostics without masking the original exception.

failure = struct();
failure.identifier = string(ME.identifier);
failure.message = string(ME.message);
failure.stack = ME.stack;
failure.cause = arrayfun(@(x) string(x.message), ME.cause, UniformOutput=false);
failure.timestamp = datetime('now', 'TimeZone', 'local');
failure.matlabVersion = version;
save(fullfile(run.folder, 'failure.mat'), 'failure', 'cfg');

fid = fopen(fullfile(run.folder, 'failure.txt'), 'w');
if fid >= 0
    cleaner = onCleanup(@() fclose(fid)); %#ok<NASGU>
    fprintf(fid, '[%s] %s\n%s\n', failure.identifier, failure.message, ...
        getReport(ME, 'extended', 'hyperlinks', 'off'));
end
end
