function mark_run_success(run)
%MARK_RUN_SUCCESS Create the completion marker after all exports succeed.

arguments
    run (1,1) struct
end
fileName = fullfile(run.folder,'SUCCESS');
fid = fopen(fileName,'w');
if fid < 0
    error('io:mark_run_success:OpenFailed','Cannot create %s.',fileName);
end
cleaner = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'completedAt=%s\n',char(datetime('now','TimeZone','local')));
end
