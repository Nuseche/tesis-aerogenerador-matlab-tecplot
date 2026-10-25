function [force,report] = evaluate_aerodynamic_load(model,state,cfg,nDof)
%EVALUATE_AERODYNAMIC_LOAD Evaluate the force used by equilibrium and tangent.

force=zeros(nDof,1);report=struct('active',false,'method',"zero_unprovided", ...
    'status',"unprovided",'forceNorm',0);
if ~isfield(cfg,'aerodynamics')||isempty(cfg.aerodynamics),return,end
aero=cfg.aerodynamics;
if isfield(aero,'status')&&~isempty(aero.status),report.status=string(aero.status);end
if ~isfield(aero,'loadFcn')||isempty(aero.loadFcn),return,end
q=zeros(nDof,1);qd=zeros(nDof,1);
if isfield(state,'qFull'),q=double(state.qFull(:));end
if isfield(state,'qdFull'),qd=double(state.qdFull(:));end
if numel(q)~=nDof||numel(qd)~=nDof|| ...
        any(~isfinite(q))||any(~isfinite(qd))
    error('assembly:evaluate_aerodynamic_load:InvalidState', ...
        'qFull and qdFull must be finite full-system vectors.');
end
force=double(aero.loadFcn(q,qd,state,model,cfg));force=force(:);
if numel(force)~=nDof||any(~isfinite(force))
    error('assembly:evaluate_aerodynamic_load:InvalidForce', ...
        'aerodynamics.loadFcn returned an invalid force vector.');
end
report.active=true;report.method="load_function";report.forceNorm=norm(force);
end
