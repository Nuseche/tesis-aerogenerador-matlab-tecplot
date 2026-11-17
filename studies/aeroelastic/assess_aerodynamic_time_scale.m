function report=assess_aerodynamic_time_scale(folder)
%ASSESS_AERODYNAMIC_TIME_SCALE Reduced frequency of the computed growing mode.
% This diagnoses a quasi-steady assumption; it does not supply unsteady loads.
if nargin<1,folder=fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))),'runs','aeroelastic_convergence_20261117');end
saved=load(fullfile(folder,'isolated_stability.mat'),'result');
p=saved.result.points{end};mode=saved.result.modes{end};
[~,loads]=aero.evaluate_force(p.system,p.sections,p.data,0,p.q,zeros(size(p.q)),p.op);
omega=abs(imag(mode.lambda));k=omega*p.sections.chord./(2*loads.relativeSpeed);
sections=table(p.sections.spanM,p.sections.chord,loads.relativeSpeed,loads.alphaRad*180/pi,k, ...
    'VariableNames',{'span_m','chord_m','relative_speed_mps','incidence_deg','reduced_frequency'});
assert(all(isfinite(k))&&all(k>0),'A finite nonzero flow is required for this diagnostic.');
use=sections.span_m>=20&sections.span_m<=90;
report=struct('frequency_hz',omega/(2*pi),'sections',sections, ...
    'range20To90m',[min(k(use)) max(k(use))], ...
    'definition','k = oscillation angular frequency * chord / (2 * local equilibrium relative speed)', ...
    'scope','Local time-scale diagnostic only; no universal cutoff, modal-work weighting or unsteady correction.');
writetable(sections,fullfile(folder,'aerodynamic_time_scale.csv'));
save(fullfile(folder,'aerodynamic_time_scale.mat'),'report');
fprintf('Oscillation frequency %.9g Hz; k over 20--90 m: %.9g to %.9g\n',report.frequency_hz,report.range20To90m);
end
