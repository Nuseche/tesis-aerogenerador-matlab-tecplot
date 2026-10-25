function cfg=config_action06_equilibrium()
%CONFIG_ACTION06_EQUILIBRIUM Nonlinear gravity/centrifugal benchmark sweep.
cfg=config_default();
cfg.analysis.type="action06_equilibrium";
cfg.base.type="fixed";cfg.base.fixedNodeIds=1;
cfg.mass.formulation="consistent";
cfg.gravity.enabled=true;cfg.gravity.vector=[0;0;-9.80665];
cfg.rotor.speedRPM=12;cfg.rotor.speedRPMGrid=[0;6;12];
cfg.drivetrain.stiffness=[1e9 1e9 1e9 1e10 1e10 1e10];
cfg.drivetrain.damping=zeros(1,6);
cfg.drivetrain.calibrationStatus="numerical_benchmark_not_physical";
cfg.drivetrain.source= ...
    "Action 06 solver benchmark; no identified Version 0 shaft tangent exists.";
cfg.equilibrium.tolerance=1e-8;
cfg.equilibrium.relativeTolerance=1e-8;
cfg.equilibrium.maxIterations=40;
cfg.equilibrium.maximumIterations=40;
cfg.equilibrium.maximumLineSearchReductions=12;
cfg.modal.enabled=false;cfg.seismic.enabled=false;
cfg.action06=struct('internalTangentTolerance',2e-6, ...
    'centrifugalTangentTolerance',2e-6,'omegaScalingTolerance',1e-10, ...
    'globalBalanceTolerance',2e-3,'matrixTolerance',1e-10);
cfg.validation.enabled=true;cfg.validation.failOnCritical=true;
cfg.output.makeFigures=false;cfg.output.plotGeometry=false;
cfg.run.identifier="action06_equilibrium";
end
