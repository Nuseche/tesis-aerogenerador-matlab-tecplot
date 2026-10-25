function cfg=config_action08_mbc_qep_campbell()
%CONFIG_ACTION08_MBC_QEP_CAMPBELL Homologous-frame MBC/QEP acceptance sweep.
cfg=config_default();
cfg.analysis.type="action08_mbc_qep_campbell";
cfg.base.type="fixed";cfg.base.fixedNodeIds=1;
cfg.mass.formulation="consistent";
cfg.gravity.enabled=true;cfg.gravity.vector=[0;0;-9.80665];
cfg.rotor.speedRPM=12;cfg.rotor.speedRPMGrid=(0:1.5:12).';
cfg.rotor.azimuthRad=0;
cfg.rotor.mbc=struct('enabled',true,'azimuth',0,'direction',1, ...
    'method',"frozen",'nAzimuthSamples',36);
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
cfg.modal.enabled=true;cfg.modal.solver="quadratic";cfg.modal.number=12;
cfg.modal.tolerance=1e-10;cfg.modal.maxIterations=2000;
cfg.modes.number=12;
cfg.modes.trackingMacWeight=0.85;
cfg.modes.trackingFrequencyScale=0.25;
cfg.modes.degenerateFrequencyTolerance=0.10;
cfg.action08=struct('inverseTolerance',1e-12, ...
    'firstDerivativeTolerance',1e-8,'secondDerivativeTolerance',2e-5, ...
    'homologyTolerance',1e-12,'zeroSpeedFrequencyTolerance',1e-6, ...
    'qepResidualTolerance',1e-8,'pairTolerance',1e-8, ...
    'leftResidualTolerance',1e-8,'biorthogonalityTolerance',1e-6, ...
    'benchmarkTolerance',1e-10,'minimumIndividualTrackingMAC',0.8, ...
    'minimumSubspaceTrackingMAC',0.95, ...
    'minimumEffectiveTrackingMAC',0.8);
cfg.validation.enabled=true;cfg.validation.failOnCritical=true;
cfg.output.makeFigures=true;cfg.output.plotGeometry=false;
cfg.output.modesToPlot=3;
cfg.run.identifier="action08_mbc_qep_campbell";
end
