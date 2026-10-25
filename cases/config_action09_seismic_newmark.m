function cfg=config_action09_seismic_newmark()
%CONFIG_ACTION09_SEISMIC_NEWMARK Canonical multicomponent seismic benchmark.
% The analytic ground motion and every mechanical coefficient in this case
% are verification data. They are not a site accelerogram or calibrated
% design input for a commercial turbine.

cfg=config_default();
cfg.analysis.type="action09_seismic_newmark";
cfg.base.type="fixed";cfg.base.fixedNodeIds=1;
cfg.mass.formulation="consistent";
cfg.gravity.enabled=true;cfg.gravity.vector=[0;0;-9.80665];
cfg.rotor.speedRPM=12;cfg.rotor.speedRPMGrid=[0;12];
cfg.rotor.azimuthRad=0;
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

% u_g=A*sin(omega*t)^3 gives analytic velocity and acceleration and starts
% without a displacement, velocity, or acceleration jump.
t=(0:0.00125:1).';
omega=[2*pi*0.65 2*pi*0.90];amplitude=[0.0030 0.0018];
s=sin(t*omega);c=cos(t*omega);
ug=s.^3.*amplitude;
vg=3*s.^2.*c.*(amplitude.*omega);
ag=3*(2*s.*c.^2-s.^3).*(amplitude.*omega.^2);
cfg.seismic.enabled=true;
cfg.seismic.record=struct('t',t,'acceleration',ag,'velocity',vg, ...
    'displacement',ug,'timeUnit',"s",'accelerationUnit',"m/s^2", ...
    'velocityUnit',"m/s",'displacementUnit',"m", ...
    'description',"analytic sin(omega*t)^3 two-component benchmark", ...
    'status',"synthetic_verification_not_design_accelerogram");
cfg.seismic.directions=[1 2];
cfg.seismic.baselineCorrection="none";
cfg.seismic.scaleFactor=1;
cfg.seismic.interpolation="linear";
cfg.seismic.recordStatus="synthetic_verification_not_design_accelerogram";
cfg.newmark.dt=0.01;cfg.newmark.beta=1/4;cfg.newmark.gamma=1/2;
cfg.newmark.requireUnconditionalStability=true;
cfg.action09=struct( ...
    'timeStepGrid',[0.02 0.01 0.005 0.0025 0.00125], ...
    'productionTimeStep',0.01, ...
    'responseNodes',[1 129 130 56 92 128], ...
    'convergenceNodeId',129,'convergenceComponent',"uy", ...
    'seriesTolerance',1e-12,'kinematicTolerance',1e-12, ...
    'massProjectionTolerance',1e-12,'forceIdentityTolerance',1e-14, ...
    'sdofErrorTolerance',1e-4,'minimumSdofOrder',1.9, ...
    'superpositionTolerance',1e-10,'dynamicResidualTolerance',1e-9, ...
    'benchmarkEnergyTolerance',1e-8,'modelEnergyTolerance',1e-6, ...
    'projectedEquilibriumTolerance',1e-9, ...
    'elementBackwardTolerance',1e-12,'elementAssemblyTolerance',1e-12, ...
    'minimumModelOrder',1.8,'fineRelativeDifferenceTolerance',1e-3, ...
    'fineMaximumDifferenceTolerance',0.01);
cfg.modal.enabled=false;
cfg.validation.enabled=true;cfg.validation.failOnCritical=true;
cfg.validation.energyTolerance=1e-6;
cfg.output.makeFigures=true;cfg.output.plotGeometry=false;
% These are reduced indices only for the generic legacy plot/export. The
% Action-09 CSVs resolve all published channels by node and component.
cfg.output.timeHistoryDofs=[];
cfg.run.identifier="action09_seismic_newmark";
end
