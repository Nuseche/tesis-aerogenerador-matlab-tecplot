root='/Users/nuseche/Desktop/Tesis_codigos';addpath(root);addpath(fullfile(root,'cases'));
folder=fullfile(root,'runs','sensitivity','initial_20261005');
diary(fullfile(folder,'verification_execution.log'));
for phase=["verification" "seismic" "foundation"]
    try
        sensitivity.run_initial_study(folder,phase);
    catch ME
        fprintf('PHASE %s FAILED: %s\n%s\n',phase,ME.message,getReport(ME,'extended','hyperlinks','off'));
    end
end
diary off
