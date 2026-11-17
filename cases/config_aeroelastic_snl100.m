function cfg=config_aeroelastic_snl100()
%CONFIG_AEROELASTIC_SNL100 Configurable weakly coupled MHT/section-polar case.
cfg=config_default();cfg.analysis.type="aeroelastic_weak";
cfg.rotor.speedRPM=.7547*30/pi;cfg.rotor.rampSeconds=10;cfg.rotor.azimuthRad=0;
cfg.aerodynamics=struct('density',1.225,'windVelocity',[1 0 0],'pitchRad',0, ...
    'aerodynamicCenterFraction',.25,'polarDataset',"openfast_reference_thickness_interpolation", ...
    'inducedVelocityFcn',[],'status',"quasi_steady_reference_polars_not_Maza_UVLM");
cfg.aeroelastic=struct('scope',"turbine",'feedback',true,'rootRadius',6, ...
    'duration',1,'dt',.01,'outputStride',1,'maxElasticRotation',.2, ...
    'structuralScope',"linear_MHT_with_quasistatic_spin_prestress", ...
    'saveResults',true);
cfg.drivetrain.stiffness=[1e9 1e9 1e9 1e10 1e10 1e10];
cfg.drivetrain.calibrationStatus="illustrative_not_calibrated";
cfg.drivetrain.source="Existing stationary MHT benchmark, not identified Sandia coefficients";
cfg.damping.alpha=0;cfg.damping.beta=0;cfg.output.makeFigures=false;
cfg.run.identifier="snl100_aeroelastic_weak";
end
