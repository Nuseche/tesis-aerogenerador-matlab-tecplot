function cfg=config_action07_dynamic_operators()
%CONFIG_ACTION07_DYNAMIC_OPERATORS Damping/gyro/aero operator acceptance.
cfg=config_default();
cfg.analysis.type="action07_dynamic_operators";
cfg.base.type="fixed";cfg.base.fixedNodeIds=1;
cfg.mass.formulation="consistent";
cfg.gravity.enabled=true;cfg.gravity.vector=[0;0;-9.80665];
cfg.rotor.speedRPM=12;cfg.rotor.speedRPMGrid=[0;6;12];
cfg.drivetrain.stiffness=[1e9 1e9 1e9 1e10 1e10 1e10];
cfg.drivetrain.damping=zeros(1,6);
cfg.drivetrain.calibrationStatus="numerical_benchmark_not_physical";
cfg.gyroscopic.includeDistributedBlades=true;
cfg.damping=struct('rayleigh',struct( ...
    'targetFrequenciesHz',[0.2;2.0], ...
    'targetDampingRatios',[0.01;0.01]), ...
    'calibrationStatus',"numerical_benchmark_not_physical");
cfg.aerodynamics=struct('status', ...
    "zero_unprovided_physical_coefficients");
cfg.equilibrium.tolerance=1e-8;
cfg.equilibrium.relativeTolerance=1e-8;
cfg.equilibrium.maximumIterations=40;
cfg.equilibrium.maximumLineSearchReductions=12;
cfg.modal.enabled=false;cfg.seismic.enabled=false;
cfg.action07=struct('skewTolerance',1e-12,'scalingTolerance',1e-12, ...
    'energyTolerance',1e-12,'rigidBenchmarkTolerance',1e-10, ...
    'distributedBenchmarkTolerance',1e-10, ...
    'bladeDispersionTolerance',1e-3,'rayleighTolerance',1e-12, ...
    'aerodynamicTangentTolerance',1e-6, ...
    'aerodynamicConvergenceRatioMinimum',3.5, ...
    'matrixIdentityTolerance',1e-12);
cfg.validation.enabled=true;cfg.validation.failOnCritical=true;
cfg.validation.skewTolerance=1e-12;
cfg.output.makeFigures=false;cfg.output.plotGeometry=false;
cfg.run.identifier="action07_dynamic_operators";
end
