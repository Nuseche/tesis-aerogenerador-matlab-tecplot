function cfg = config_stationary_modal()
%CONFIG_STATIONARY_MODAL Reproducible functional case at zero rotor speed.
% The drivetrain values are illustrative and must be calibrated before
% using frequencies as thesis predictions.

cfg = config_default();
cfg.analysis.type = "stationary_modal";
cfg.modal.enabled = true;
cfg.modal.solver = "conservative";
cfg.modal.number = 20;
cfg.modes.number = 20;
cfg.rotor.speedRPM = 0;
cfg.drivetrain.stiffness = [1e9 1e9 1e9 1e10 1e10 1e10];
cfg.drivetrain.calibrationStatus = "illustrative_not_calibrated";
cfg.drivetrain.source = ...
    "Functional verification case; replace with identified drivetrain tangent.";
cfg.damping.alpha = 0;
cfg.damping.beta = 0;
cfg.output.makeFigures = true;
cfg.run.identifier = "stationary_modal_demo";
end
