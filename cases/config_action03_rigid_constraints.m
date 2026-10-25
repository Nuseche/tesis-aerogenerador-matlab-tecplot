function cfg = config_action03_rigid_constraints()
%CONFIG_ACTION03_RIGID_CONSTRAINTS Isolated exact-constraint acceptance run.
%   Concentrated bodies, equilibrium, rotation and dynamics are excluded.

cfg = config_default();
cfg.analysis.type = "action03_rigid_constraints";
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
cfg.assembly = struct('flexibleOnly',true, ...
    'includeFoundation',false,'includeDrivetrain',false);

cfg.validation.enabled = true;
cfg.validation.constraintTolerance = 1e-12;
cfg.validation.matrixSymmetry = 1e-12;
cfg.validation.matrixTolerance = 1e-12;
cfg.validation.failOnCritical = true;

cfg.action03 = struct();
cfg.action03.expectedFullDofs = 828;
cfg.action03.expectedReducedDofs = 810;
cfg.action03.expectedFreeDofs = 804;
cfg.action03.expectedMasterNodeId = 130;
cfg.action03.expectedSlaveNodeIds = [21;57;93];
cfg.action03.expectedRemovedLegacyIds = (134:137).';
cfg.action03.expectedTransitionLegacyIds = (125:133).';

cfg.output.makeFigures = false;
cfg.output.plotGeometry = false;
cfg.run.identifier = "action03_rigid_constraints";
end
