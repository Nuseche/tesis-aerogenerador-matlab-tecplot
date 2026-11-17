function result=run_aeroelastic(cfg)
%RUN_AEROELASTIC Execute the weak section-aerodynamics/MHT coupling.
% Use config_maza_isolated_blade for the isolated rotating cantilever benchmark.
root=fileparts(mfilename('fullpath'));addpath(root);addpath(fullfile(root,'cases'));
if nargin<1,cfg=config_aeroelastic_snl100();end
assert(any(cfg.aeroelastic.scope==["isolated_blade" "turbine"]),'Unsupported aeroelastic scope.');
a=cfg.aeroelastic;
assert(isfinite(a.dt)&&a.dt>0&&isfinite(a.duration)&&a.duration>0,'Positive dt and duration required.');
assert(a.outputStride>=1&&a.outputStride==fix(a.outputStride),'Output stride must be a positive integer.');
assert(isfinite(cfg.aerodynamics.density)&&cfg.aerodynamics.density>0,'Positive air density required.');
if ~isnumeric(cfg.aerodynamics.pitchRad)||~isscalar(cfg.aerodynamics.pitchRad)||~isfinite(cfg.aerodynamics.pitchRad)
    error('aero:PrescribedPitch','Use a constant pitch in radians; time-dependent pitch actuation is not implemented.');
end
if ~isempty(cfg.drivetrain.damping)||~isempty(cfg.foundation.C)
    error('aero:DampingScope','This driver supports explicit Rayleigh damping only.');
end
if string(cfg.aerodynamics.polarDataset)~="openfast_reference_thickness_interpolation"
    error('aero:PolarDataset','Unknown polar dataset.');
end
data=aero.load_snl100();
if a.scope=="isolated_blade",md=aero.build_isolated_blade(cfg,data);
else
    md=model.build_model(io.load_model_data(cfg),cfg);
    % Pitch the inherited material frames together with the aerodynamic chord.
    for e=find(md.mesh.elements.blade>0).'
        ni=md.mesh.elements.nodeI(e);nj=md.mesh.elements.nodeJ(e);x=md.mesh.nodes.xyz(ni,:);
        span=md.mesh.nodes.xyz(nj,:)-x;span=span/norm(span);
        R=aero.rotation(-span*cfg.aerodynamics.pitchRad);
        md.mesh.elements.auxPoint(e,:)=x+(R*(md.mesh.elements.auxPoint(e,:)-x).').';
    end
end
system=aero.prepare_structure(md,cfg);sections=aero.prepare_sections(md,cfg,data);
operatorFcn=@(t) aero.structural_operators(system,t);
forceFcn=@(t,q,v,op) aero.evaluate_force(system,sections,data,t,q,v,op);
steps=round(a.duration/a.dt);
if abs(steps*a.dt-a.duration)>1e-9,error('aero:TimeGrid','duration must be an integer multiple of dt.');end
time=(0:steps).'*a.dt;
rotationDofs=reshape(md.dofs.node(:,4:6).',[],1);
a.rotationMap=system.T(rotationDofs,:);
result=dynamics.weak_coupling_integrate(operatorFcn,forceFcn,time,a);
result.configuration=cfg;result.sourceProvenance=data.provenance;result.structuralNodeCount=numel(md.mesh.nodes.id);
result.structuralScope=a.structuralScope;result.feedback=a.feedback;
result.operatorPolicy="time_varying_prescribed_rotation_and_constraint_derivatives";
result.prestressPolicy="quasistatic_unit_spin_axial_force_scaled_by_omega_squared";
result.tipWindDisplacement=zeros(numel(result.t),1);
if a.scope=="isolated_blade",tip=size(md.mesh.nodes.xyz,1);else,tip=56;end
for k=1:numel(result.t)
    if a.scope=="isolated_blade"
        motion=aero.rotor_motion(result.t(k),cfg);u=system.T*result.q(:,k);
        R=aero.rotation(md.rotorAxis.direction*motion.azimuth);
    else
        op=operatorFcn(result.t(k));u=op.T*result.q(:,k);R=eye(3);
    end
    % Published Maza channel is global X, the prescribed wind direction.
    x=R*u(md.dofs.node(tip,1:3));result.tipWindDisplacement(k)=x(1);
end
result.summary=aero.response_summary(result);
if a.saveResults
    run=io.create_run_folder(cfg);result.runFolder=run.folder;
    save(fullfile(run.folder,'aeroelastic_results.mat'),'result','-v7.3');
    writetable(table(result.t,result.tipWindDisplacement,result.alphaMinRad.',result.alphaMaxRad.', ...
        'VariableNames',{'time_s','tip_global_x_m','minimum_alpha_rad','maximum_alpha_rad'}),fullfile(run.folder,'response.csv'));
    fid=fopen(fullfile(run.folder,'summary.json'),'w');cleanup=onCleanup(@()fclose(fid));
    fprintf(fid,'%s\n',jsonencode(result.summary,PrettyPrint=true));
    fprintf('Aeroelastic result: %s\n',run.folder);
end
end
