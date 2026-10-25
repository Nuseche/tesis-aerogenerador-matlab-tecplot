function cfg = config_flexible_foundation()
%CONFIG_FLEXIBLE_FOUNDATION Legacy soft-foundation stationary modal case.

cfg = config_stationary_modal();
cfg.base.type = "flexible";
cfg.foundation.nodeId = 1;
cfg.foundation.K = diag([2.635e9 2.635e9 3.200e9 ...
    2.133e11 2.133e11 2.987e11]);
cfg.foundation.M = diag([3.767e6 3.767e6 5.302e6 ...
    2.065e8 2.065e8 7.287e7]);
cfg.foundation.C = diag([7.642e7 7.642e7 1.360e8 ...
    2.901e9 2.901e9 2.270e9]);
cfg.foundation.source = ...
    "Legacy Version 0 soft foundation matrices, SI, preserved verbatim.";
cfg.modal.solver = "quadratic";
cfg.modes.number = 12;
cfg.modal.number = 12;
cfg.output.makeFigures = false;
cfg.run.identifier = "flexible_foundation_demo";
end
