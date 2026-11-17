function [pitch,reference]=maza_pitch_reference(data,qDegrees)
%MAZA_PITCH_REFERENCE Adopt a zero-integrated-lift reference for sectional polars.
% Maza defines q=0 by zero lift but does not publish its conventional pitch.
% This reconstruction is model-dependent and is reported, never fitted to u_tip.
g=data.geometry;
fun=@(beta) netLift(data,g,beta);
reference=fzero(fun,[60 120]);pitch=(reference-qDegrees)*pi/180;
end
function value=netLift(data,g,beta)
c=aero.polar_coefficients(data,(90-beta-g.twist_deg)*pi/180,g.thickness);
value=trapz(g.span_m,g.chord_m.*c(:,1));
end
