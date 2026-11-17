function [f,report]=evaluate_force(system,sections,data,time,q,qd,op)
%EVALUATE_FORCE Work-consistent section forces projected to structural coordinates.
if ~system.cfg.aeroelastic.feedback,q=zeros(size(q));qd=zeros(size(qd));end
u=op.T*q;v=op.T*qd+op.Tdot*q;
if system.cfg.aeroelastic.scope=="turbine"
    v=op.Q.'*(v-op.motion.omega*system.W*u);u=op.Q.'*u;
end
[force,report]=aero.section_loads(sections,data,u,v,time,op.motion,system.cfg);
f=op.T.'*(op.Q*force);report.projectedPower=f.'*qd;
end
