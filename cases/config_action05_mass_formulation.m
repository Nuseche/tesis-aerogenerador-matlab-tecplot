function cfg=config_action05_mass_formulation()
%CONFIG_ACTION05_MASS_FORMULATION Consistent production and HRZ comparison.
cfg=config_default();
cfg.analysis.type="action05_mass_formulation";
cfg.base.type="fixed";cfg.base.fixedNodeIds=1;
cfg.mass.formulation="consistent";
cfg.modal.enabled=false;cfg.seismic.enabled=false;cfg.gravity.enabled=false;
cfg.foundation.M=[];cfg.foundation.K=[];cfg.foundation.C=[];
cfg.drivetrain.stiffness=[];cfg.drivetrain.damping=[];
cfg.drivetrain.orientation=[];
cfg.assembly=struct('flexibleOnly',true,'includeFoundation',false, ...
    'includeDrivetrain',false);
cfg.action05=struct('numberComparisonModes',8, ...
    'modalFrequencyDifferenceTolerance',0.02, ...
    'modalMacTolerance',0.9,'modalResidualTolerance',1e-8);
cfg.validation.enabled=true;
cfg.validation.matrixSymmetry=1e-12;
cfg.validation.matrixTolerance=1e-12;
cfg.validation.constraintTolerance=1e-12;
cfg.validation.massConservationTolerance=1e-10;
cfg.validation.failOnCritical=true;
cfg.output.makeFigures=false;cfg.output.plotGeometry=false;
cfg.run.identifier="action05_mass_formulation";
end
