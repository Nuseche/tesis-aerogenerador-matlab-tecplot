function motion=rotor_motion(time,cfg)
%ROTOR_MOTION Consistent angle, speed and acceleration of a prescribed rotor.
% A custom motionFcn must supply all three fields with mutually consistent units.
if isfield(cfg.rotor,'motionFcn')&&~isempty(cfg.rotor.motionFcn)
    motion=cfg.rotor.motionFcn(time);
else
    omega=cfg.rotor.speedRPM*pi/30;T=cfg.rotor.rampSeconds;
    if ~isscalar(T)||~isfinite(T)||T<0,error('aero:Ramp','Nonnegative finite ramp duration required.');end
    if T>0&&time<T
        x=max(time,0)/T;motion=struct('omega',omega*(3*x^2-2*x^3), ...
            'alpha',omega*(6*x-6*x^2)/T,'azimuth',cfg.rotor.azimuthRad+omega*T*(x^3-.5*x^4));
    else
        motion=struct('omega',omega,'alpha',0,'azimuth',cfg.rotor.azimuthRad+omega*(time-T/2));
    end
end
if ~all(isfield(motion,{'omega','alpha','azimuth'}))||numel([motion.omega motion.alpha motion.azimuth])~=3||any(~isfinite([motion.omega motion.alpha motion.azimuth]))
    error('aero:RotorMotion','Rotor motion must supply finite omega, alpha and azimuth.');
end
end
