function cfg = config_action04_rigid_bodies()
%CONFIG_ACTION04_RIGID_BODIES Isolated spatial rigid-body mass acceptance.

cfg=config_default();
cfg.analysis.type="action04_rigid_bodies";
cfg.base.type="fixed";
cfg.base.fixedNodeIds=1;
cfg.mass.formulation="consistent";
cfg.modal.enabled=false;
cfg.seismic.enabled=false;
cfg.gravity.enabled=false;
cfg.foundation.M=[];cfg.foundation.K=[];cfg.foundation.C=[];
cfg.drivetrain.stiffness=[];cfg.drivetrain.damping=[];
cfg.drivetrain.orientation=[];
cfg.assembly=struct('flexibleOnly',true,'includeFoundation',false, ...
    'includeDrivetrain',false);
cfg.validation.enabled=true;
cfg.validation.constraintTolerance=1e-12;
cfg.validation.matrixSymmetry=1e-12;
cfg.validation.matrixTolerance=1e-12;
cfg.validation.massConservationTolerance=1e-10;
cfg.validation.failOnCritical=true;
cfg.output.makeFigures=false;
cfg.output.plotGeometry=false;
cfg.run.identifier="action04_rigid_bodies";
end
