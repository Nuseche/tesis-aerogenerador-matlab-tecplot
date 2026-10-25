function absolute = recover_absolute_response(relative, Gamma, groundMotion)
%RECOVER_ABSOLUTE_RESPONSE Add support motion to relative response.
%   groundMotion must contain acceleration and may contain velocity and
%   displacement. Missing velocity/displacement are integrated from rest.

arguments
    relative struct
    Gamma {mustBeNumeric}
    groundMotion
end

t = relative.t(:);
[ag,vg,ug] = parseGroundMotion(groundMotion,t);
nComponent = size(Gamma,2);
if size(ag,2) ~= nComponent
    if size(ag,2) == 1 && nComponent > 1
        ag = repmat(ag,1,nComponent); vg = repmat(vg,1,nComponent); ug = repmat(ug,1,nComponent);
    else
        error('dynamics:Absolute:ComponentMismatch','Ground motion and Gamma component counts differ.');
    end
end

absolute = struct('t',t, ...
    'q',relative.q + Gamma*ug.', ...
    'qd',relative.qd + Gamma*vg.', ...
    'qdd',relative.qdd + Gamma*ag.', ...
    'absoluteDisplacement',relative.q + Gamma*ug.', ...
    'absoluteVelocity',relative.qd + Gamma*vg.', ...
    'absoluteAcceleration',relative.qdd + Gamma*ag.', ...
    'groundAcceleration',ag,'groundVelocity',vg,'groundDisplacement',ug);
end

function [ag,vg,ug] = parseGroundMotion(input,t)
if isnumeric(input)
    ag = orient(input,numel(t)); vg = cumtrapz(t,ag); ug = cumtrapz(t,vg); return
end
if ~isstruct(input), error('dynamics:Absolute:InvalidGroundMotion','Ground motion must be numeric or a structure.'); end
ag = pick(input,{'acceleration','a','ag','processedAcceleration'});
if isempty(ag) && isfield(input,'processed'), ag = pick(input.processed,{'acceleration','a','ag'}); end
if isempty(ag), error('dynamics:Absolute:MissingAcceleration','Ground acceleration is required.'); end
ag = orient(ag,numel(t));
vg = pick(input,{'velocity','v','vg'}); ug = pick(input,{'displacement','u','ug'});
if isempty(vg), vg = cumtrapz(t,ag); else, vg = orient(vg,numel(t)); end
if isempty(ug), ug = cumtrapz(t,vg); else, ug = orient(ug,numel(t)); end
end

function value = pick(s,names)
value = [];
for k = 1:numel(names)
    if isfield(s,names{k}) && ~isempty(s.(names{k})), value = s.(names{k}); return; end
end
end

function A = orient(A,nt)
if size(A,1) == nt, return; end
if size(A,2) == nt, A = A.'; return; end
error('dynamics:Absolute:TimeMismatch','Ground motion length must equal numel(relative.t).');
end
