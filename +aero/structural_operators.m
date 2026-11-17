function op=structural_operators(system,time)
%STRUCTURAL_OPERATORS LTV projection including exact derivatives of root constraints.
s=system;cfg=s.cfg;motion=aero.rotor_motion(time,cfg);w=motion.omega;alpha=motion.alpha;
Kc=s.Kr+w*w*(s.Kspin+s.Kg)+alpha*s.A;Dc=s.Cr+w*s.G;
if cfg.aeroelastic.scope=="isolated_blade"
    Q=speye(s.ndof);T=s.T;Td=sparse(size(T,1),size(T,2));Tdd=Td;
    M=s.M;D=s.C+w*s.G;K=s.Ke+w*w*(s.Kspin+s.Kg)+alpha*s.A;
    base=w*w*s.fspin-alpha*s.bspin;
else
    R=aero.rotation(s.model.rotorAxis.direction*motion.azimuth);Q=speye(s.ndof);
    Q(s.rotatingDofs,s.rotatingDofs)=kron(speye(numel(s.rotatingDofs)/3),sparse(R));
    W=w*s.W;Wd=alpha*s.W;
    M=s.M-s.Mr+Q*s.Mr*Q.';
    D=s.C-s.Cr+Q*(Dc-2*s.Mr*W)*Q.';
    K=s.Ke-s.Kr+Q*(Kc-Dc*W+s.Mr*(W*W-Wd))*Q.';
    base=Q*(w*w*s.fspin-alpha*s.bspin);
    constraint=rigid.rotating_constraint_derivatives(s.model,s.model.rigidBodies,motion.azimuth,w,struct('angularAcceleration',alpha));
    T=constraint.T(:,s.free);Td=constraint.Tdot(:,s.free);Tdd=constraint.Tddot(:,s.free);
end
if cfg.gravity.enabled
    g=repmat([cfg.gravity.vector(:);zeros(3,1)],s.ndof/6,1);
    if cfg.aeroelastic.scope=="isolated_blade"
        R=aero.rotation(s.model.rotorAxis.direction*motion.azimuth);g=kron(speye(s.ndof/6),blkdiag(R.',R.'))*g;
    end
    base=base+M*g;
end
op=struct('M',T.'*M*T,'D',T.'*(D*T+2*M*Td),'K',T.'*(K*T+D*Td+M*Tdd), ...
    'baseForce',T.'*base,'T',T,'Tdot',Td,'Q',Q,'motion',motion);
end
