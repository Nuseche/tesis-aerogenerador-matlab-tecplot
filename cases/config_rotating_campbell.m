function cfg = config_rotating_campbell()
%CONFIG_ROTATING_CAMPBELL Three-speed QEP/MBC demonstration.

cfg = config_stationary_modal();
cfg.analysis.type = "rotating_modal";
cfg.modal.solver = "quadratic";
cfg.modal.number = 12;
cfg.modes.number = 12;
cfg.rotor.speedRPM = 6;
cfg.rotor.speedRPMGrid = [0; 6; 12];
cfg.rotor.mbc = struct('enabled',true,'azimuth',0,'direction',1, ...
    'formulation',"frozen");
cfg.damping.alpha = 2e-3;
cfg.damping.beta = 2e-5;
cfg.run.identifier = "rotating_campbell_demo";
end
