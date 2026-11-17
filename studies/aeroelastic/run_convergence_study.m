function report=run_convergence_study(folder)
%RUN_CONVERGENCE_STUDY Time, space, finite-difference and modal-work evidence.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));addpath(root);addpath(fullfile(root,'cases'));
if nargin<1,folder=fullfile(root,'runs','aeroelastic_convergence_20261117');end
if ~isfolder(folder),mkdir(folder);end
for dt=[.000625 .0003125 .00015625 .000078125]
    cfg=config_maza_isolated_blade(25,.1);cfg.aeroelastic.duration=60;cfg.aeroelastic.dt=dt;
    cfg.aeroelastic.outputStride=round(.01/dt);cfg.aeroelastic.saveResults=false;
    r=run_aeroelastic(cfg);save(fullfile(folder,sprintf('acceleration_dt_%g.mat',dt)),'r','-v7.3');
end
report=struct('temporal',analyze_time_convergence(folder),'stability',analyze_isolated_stability(folder));
end
