function [force,report]=section_loads(sections,data,q,qd,time,motion,cfg)
%SECTION_LOADS Quasi-steady forces from instantaneous section velocity triangles.
% q,qd are in nominal rotor-corotating axes; motion gives azimuth,omega,alpha.
% Wind is an inertial vector or @(time,positions) returning N-by-3 velocities.
a=cfg.aerodynamics;n=numel(sections.weight);u=reshape(sections.B*q,6,n).';
v=reshape(sections.B*qd,6,n).';[Q,~]=aero.rotation(sections.axis*motion.azimuth);
pitch=a.pitchRad;if isa(pitch,'function_handle'),pitch=pitch(time);end
if ~isscalar(pitch)||~isfinite(pitch),error('aero:Pitch','Pitch must return a finite scalar in radians.');end
omega=motion.omega*sections.axis;W=aero.skew(omega);
span=zeros(n,3);chord=span;offset=span;velocity=span;positions=span;J=zeros(3,3,n);
for k=1:n
    er=sections.span(k,:).';c0=sections.zeroPitchChord(k,:).';
    Rb=aero.rotation(-er*(pitch+sections.twist(k)));c0=Rb*c0;
    [E,J(:,:,k)]=aero.rotation(u(k,4:6));span(k,:)=(E*er).';chord(k,:)=(E*c0).';
    offset(k,:)=(E*((a.aerodynamicCenterFraction-sections.pitchAxis(k))*sections.chord(k)*c0)).';
    r=sections.position(k,:).'-sections.axisPoint+u(k,1:3).'+offset(k,:).';
    velocity(k,:)=(W*r+v(k,1:3).'+cross(J(:,:,k)*v(k,4:6).',offset(k,:).')).';
    positions(k,:)=(sections.axisPoint+Q*r).';
end
wind=a.windVelocity;if isa(wind,'function_handle'),wind=wind(time,positions);end
if isvector(wind)&&numel(wind)==3,wind=repmat(reshape(wind,1,3),n,1);end
if ~isequal(size(wind),[n 3])||any(~isfinite(wind),'all'),error('aero:Wind','Wind must be a finite 3-vector or N-by-3 array.');end
relative=wind*Q-velocity;
if isfield(a,'inducedVelocityFcn')&&~isempty(a.inducedVelocityFcn)
    induced=a.inducedVelocityFcn(time,positions);
    if ~isequal(size(induced),[n 3])||any(~isfinite(induced),'all'),error('aero:Induction','Induced velocity must be N-by-3 in inertial axes.');end
    relative=relative+induced*Q;
end
relative=relative-sum(relative.*span,2).*span;speed=sqrt(sum(relative.^2,2));
normal=cross(chord,span,2);alpha=atan2(sum(relative.*normal,2),sum(relative.*chord,2));
c=aero.polar_coefficients(data,alpha,sections.thickness);drag=relative./max(speed,eps);lift=cross(drag,span,2);
dynamic=.5*a.density*speed.^2.*sections.chord;
f=dynamic.*(c(:,1).*lift+c(:,2).*drag);
m=(dynamic.*sections.chord.*c(:,3)).*span+cross(offset,f,2);
generalized=zeros(n,6);generalized(:,1:3)=f;
for k=1:n,generalized(k,4:6)=(J(:,:,k).'*m(k,:).').';end
force=sections.B.'*reshape((sections.weight.*generalized).',[],1);
report=struct('alphaRad',alpha,'relativeSpeed',speed,'coefficients',c, ...
    'forcePerLength',f,'momentPerLength',m,'positions',positions, ...
    'sectionPower',sum(sections.weight.*sum(generalized.*v,2)), ...
    'nodalPower',force.'*qd,'maxElasticRotation',max(vecnorm(u(:,4:6),2,2)), ...
    'windVelocity',wind,'pitchRad',pitch,'model',"quasi_steady_section_polars");
end
