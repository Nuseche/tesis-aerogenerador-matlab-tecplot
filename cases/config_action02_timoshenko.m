function cfg = config_action02_timoshenko()
%CONFIG_ACTION02_TIMOSHENKO Isolated acceptance run for the flexible beams.
%   This case intentionally excludes rigid bodies, exact constraints,
%   equilibrium, foundation operators, drivetrain operators and dynamics.

cfg = config_default();
cfg.analysis.type = "action02";
cfg.base.type = "fixed";
cfg.base.fixedNodeIds = 1;
cfg.mass.formulation = "consistent";
cfg.modal.enabled = false;
cfg.seismic.enabled = false;
cfg.gravity.enabled = false;

cfg.foundation.M = [];
cfg.foundation.K = [];
cfg.foundation.C = [];
cfg.drivetrain.stiffness = [];
cfg.drivetrain.damping = [];
cfg.drivetrain.orientation = [];

% The assembler may use these explicit switches while preserving the
% default behavior of every integrated analysis case.
cfg.assembly = struct('flexibleOnly',true, ...
    'includeFoundation',false,'includeDrivetrain',false);

% Acceptance tolerances and deterministic benchmark resolution from the
% Action 02 implementation plan.
cfg.validation.enabled = true;
cfg.validation.rotationOrthogonality = 1e-12;
cfg.validation.matrixSymmetry = 1e-12;
cfg.validation.matrixTolerance = 1e-12;
cfg.validation.rigidEnergyRelative = 1e-10;
cfg.validation.massConservation = 1e-10;
cfg.validation.coordinateInvariance = 1e-9;
cfg.validation.analyticalStaticRelative = 1e-6;
cfg.validation.modalBenchmarkRelative = 1e-3;
cfg.validation.meshConvergenceRelative = 1e-3;
cfg.validation.failOnCritical = true;

cfg.action02 = struct();
cfg.action02.meshElementCounts = [1 2 4 8 16 32 64];
cfg.action02.referenceElementCount = 64;
cfg.action02.numberSubsystemModes = 6;
cfg.action02.localAxesLegacyElementIds = [1 20 55 90 125];

cfg.output.makeFigures = true;
cfg.output.plotGeometry = true;
cfg.run.identifier = "action02_timoshenko";
end
