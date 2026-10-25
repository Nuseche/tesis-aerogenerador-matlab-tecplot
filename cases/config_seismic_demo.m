function cfg = config_seismic_demo()
%CONFIG_SEISMIC_DEMO Synthetic SI base-acceleration verification case.

cfg = config_stationary_modal();
cfg.analysis.type = "seismic";
cfg.modal.enabled = false;
cfg.seismic.enabled = true;
t = (0:0.02:4).';
envelope = sin(pi*min(t/4,1)).^2;
ag = 0.35*9.80665*envelope.*sin(2*pi*1.2*t);
cfg.seismic.record = struct('t',t,'acceleration',ag, ...
    'timeUnit',"s",'accelerationUnit',"m/s^2", ...
    'description',"Synthetic tapered 1.2 Hz verification pulse");
cfg.seismic.directions = 1;
cfg.seismic.baselineCorrection = "mean";
cfg.newmark.dt = 0.02;
cfg.newmark.beta = 1/4;
cfg.newmark.gamma = 1/2;
cfg.damping.alpha = 0.02;
cfg.damping.beta = 2e-4;
cfg.output.timeHistoryDofs = [1 2 3 115 116 117];
cfg.output.makeFigures = true;
cfg.run.identifier = "seismic_demo";
end
