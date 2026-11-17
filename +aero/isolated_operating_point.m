function point=isolated_operating_point(cfg,step)
%ISOLATED_OPERATING_POINT Equilibrium and aeroelastic tangent at constant speed.
if nargin<2,step=1e-5;end
assert(cfg.aeroelastic.scope=="isolated_blade"&&~cfg.gravity.enabled, ...
    'This autonomous operating point requires an isolated blade without gravity.');
cfg.rotor.rampSeconds=0;data=aero.load_snl100();md=aero.build_isolated_blade(cfg,data);
sys=aero.prepare_structure(md,cfg);sec=aero.prepare_sections(md,cfg,data);
op=aero.structural_operators(sys,0);zero=zeros(sys.n,1);
force=@(q,v)aero.evaluate_force(sys,sec,data,0,q,v,op);
q=op.K\(op.baseForce+force(zero,zero));history=[];
for iteration=1:20
    f=force(q,zero);r=op.K*q-op.baseForce-f;
    relative=norm(r)/max(norm(op.K*q)+norm(op.baseForce)+norm(f),1);history(end+1)=relative; %#ok<AGROW>
    if relative<1e-10,break,end
    [Fq,~]=aero.force_tangent(force,q,zero,step);dq=-(op.K-Fq)\r;
    accepted=false;
    for alpha=2.^-(0:12)
        trial=q+alpha*dq;rr=op.K*trial-op.baseForce-force(trial,zero);
        if norm(rr)<norm(r),q=trial;accepted=true;break,end
    end
    if ~accepted,error('aero:OperatingPoint','Equilibrium line search did not decrease residual.');end
end
if relative>=1e-10,error('aero:OperatingPoint','Equilibrium failed to converge.');end
[Fq,Fv]=aero.force_tangent(force,q,zero,step);
point=struct('configuration',cfg,'system',sys,'sections',sec,'data',data,'op',op, ...
    'q',q,'Fq',Fq,'Fv',Fv,'M',op.M,'D',op.D-Fv,'K',op.K-Fq, ...
    'equilibriumResidual',relative,'residualHistory',history,'differenceStep',step);
end
