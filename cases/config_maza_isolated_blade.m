function cfg=config_maza_isolated_blade(windSpeed,omega)
%CONFIG_MAZA_ISOLATED_BLADE Reconstruct Maza et al. 2023, Figures 1--3 conditions.
% Aerodynamics are section polars, not the article's UVLM; no fitted response.
if nargin<1,windSpeed=1;end
if nargin<2,omega=.7547;end
cfg=config_aeroelastic_snl100();cfg.aeroelastic.scope="isolated_blade";
cfg.gravity.enabled=false;cfg.rotor.speedRPM=omega*30/pi;
cfg.aerodynamics.windVelocity=[windSpeed 0 0];
data=aero.load_snl100();[cfg.aerodynamics.pitchRad,beta0]=aero.maza_pitch_reference(data,90);
cfg.aerodynamics.pitchReference=struct('paperAngleDegrees',90, ...
    'conventionalZeroLiftPitchDegrees',beta0,'method',"zero_integrated_section_lift_at_zero_spin", ...
    'exactPaperCalibrationKnown',false);
cfg.aeroelastic.duration=400;cfg.aeroelastic.dt=.01;cfg.aeroelastic.outputStride=5;
if windSpeed==25&&omega==.1,cfg.aeroelastic.duration=700;end
cfg.run.identifier=string(sprintf('maza_U%g_Omega%g_weak',windSpeed,omega));
end
