function [data,cfg]=apply_parameters(data,cfg,factors)
%APPLY_PARAMETERS Update source properties before rebuilding every operator.
names=fieldnames(factors);
for k=1:numel(names)
    name=string(names{k});v=factors.(names{k});
    if ~isnumeric(v)||~isscalar(v)||~isfinite(v)||v<=0
        error('sensitivity:InvalidFactor','%s must be positive and finite.',name);
    end
    switch name
        case "rotor_speed"
            cfg.rotor.speedRPM=cfg.rotor.speedRPM*v;
        case {"blade_density","tower_density","blade_stiffness","tower_stiffness"}
            blade=startsWith(name,"blade");
            if endsWith(name,"density"),fields={'m','Jx','Jy','Jz'};
            else,fields={'EA','GAy','GAz','GJ','EIy','EIz'};end
            for j=1:numel(data.sections)
                isBlade=string(data.sections(j).type)=="blade";
                if isBlade~=blade,continue,end
                for f=1:numel(fields)
                    data.sections(j).(fields{f})=data.sections(j).(fields{f})*v;
                end
                % rawMassColumns remain immutable provenance (tower columns are geometric).
            end
        case {"nacelle_density","hub_density"}
            target=erase(name,"_density");
            for j=1:numel(data.rigidBodies.bodies)
                if string(data.rigidBodies.bodies(j).name)==target
                    b=data.rigidBodies.bodies(j);
                    b.massKg=b.massKg*v;b.inertiaBodyKgM2=b.inertiaBodyKgM2*v;
                    data.rigidBodies.bodies(j)=b;
                end
            end
        case "damping"
            cfg.damping.rayleigh.targetDampingRatios= ...
                cfg.damping.rayleigh.targetDampingRatios*v;
        case "drivetrain_stiffness"
            cfg.drivetrain.stiffness=cfg.drivetrain.stiffness*v;
        case "foundation_stiffness"
            if string(cfg.base.type)~="flexible"
                error('sensitivity:InactiveFoundation','Flexible base required.');
            end
            cfg.foundation.K=cfg.foundation.K*v;
        case "foundation_damping"
            if string(cfg.base.type)~="flexible"
                error('sensitivity:InactiveFoundation','Flexible base required.');
            end
            cfg.foundation.C=cfg.foundation.C*v;
        case "seismic_amplitude"
            cfg.seismic.scaleFactor=cfg.seismic.scaleFactor*v;
        otherwise
            error('sensitivity:UnknownParameter','Unknown factor %s.',name);
    end
end
data.meta.parameterFactors=factors;
cfg.rotor.speedRPMGrid=cfg.rotor.speedRPM;
end
