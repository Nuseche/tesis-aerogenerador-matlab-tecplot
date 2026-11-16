function verify_combination(campaignFolder)
%VERIFY_COMBINATION Postprocess or verify the measured inputs study.
% Independent direct combined-load check using the EXISTING seismic API.
root=fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));addpath(root);addpath(fullfile(root,'cases'));
studyDir=fullfile(root,'studies/measured_inputs');
if nargin<1 || strlength(string(campaignFolder))==0
    campaignFolder=fullfile(root,'runs','studies','measured_inputs');
end
folder=fullfile(campaignFolder);
s=jsondecode(fileread(fullfile(studyDir,'analysis_summary.json')));Fref=s.referenceMeanThrustKN;
study=sensitivity.config_local();cfg=study.nominal;data=io.load_model_data(cfg);
rng(study.seed,'twister');md=model.build_model(data,cfg);
[M,Ke]=assembly.assemble_structural_matrices(md,cfg);M=assembly.apply_mass_formulation(M,cfg,md);
M=rigid.add_body_masses(M,md,md.rigidBodies);Tc=rigid.rigid_constraint_matrix(md,md.rigidBodies,cfg);
red=rigid.reduce_system(Tc,M,Ke,md,cfg);sweep=assembly.build_operating_sweep(md,red,cfg);ops=sweep.primaryOps;
am=model.prepare_analysis_model(md,ops.reduced);
eq=load(fullfile(folder,'aligned_ARL360_nominal_dt05000.mat'),'r');eq=eq.r;
wind=load(fullfile(folder,'wind_full_dt05000.mat'),'r');wind=wind.r;
t=(0:.005:2).';rawEq=readmatrix(fullfile(studyDir,'tables/ARL360_SI.csv'));
rawWind=readmatrix(fullfile(studyDir,'tables/wind_DTU_s70u_SI.csv'));
ag=interp1(rawEq(:,1),rawEq(:,2),t,'linear');
g=interp1(rawWind(:,1),rawWind(:,2).^2/mean(rawWind(:,2).^2),t,'linear');
f=zeros(size(M,1),1);row=find(md.mesh.nodes.id==130,1);f(md.dofs.node(row,1:3))=1000*Fref*md.rotorAxis.direction(:);
cfg.seismic=struct('record',struct('t',t,'acceleration',ag,'accelerationUnit',"m/s^2"), ...
    'directions',1,'baselineCorrection',"none",'scaleFactor',1, ...
    'otherForceFull',f*g.','otherForce',ops.reduced.Tc.'*f*g.');
cfg.newmark=struct('beta',1/4,'gamma',1/2,'q0',Fref*wind.windLinearMeanState,'qd0',zeros(size(ops.reduced.M,1),1));
tr=dynamics.run_seismic_analysis(ops,am,cfg);tr=dynamics.recover_full_response(tr,ops.reduced,md);
dofs=zeros(size(eq.channels,1),1);
for j=1:numel(dofs),row=find(md.mesh.nodes.id==eq.channels(j,1),1);dofs(j)=md.dofs.node(row,eq.channels(j,2));end
direct={tr.qFull(dofs,:),tr.absoluteAccelerationFull(dofs,:),tr.reactionDiagnostics.constraintForcesFull(md.dofs.fixed,:)};
fields=["historyQ" "historyA" "historyR"];checks=struct();
for j=1:3
    superposed=interp1(eq.t,eq.(fields(j)).',t).'+Fref*interp1(wind.t,wind.(fields(j)).',t).';
    checks.(fields(j))=norm(direct{j}-superposed,'fro')/max(norm(direct{j},'fro'),eps);
end
assert(max(struct2array(checks))<1e-7,'Direct combined load differs from superposition');
checks.windowSeconds=2;checks.dt=.005;checks.meanThrustKN=Fref;
checks.relativeReducedResidual=max(tr.relativeResidual);
checks.otherForceProjectionError=tr.reactionDiagnostics.otherForceProjectionError;
checks.scope="direct combined run with existing API; same frozen linear operators";
fid=fopen(fullfile(studyDir,'combined_load_verification.json'),'w');fprintf(fid,'%s',jsonencode(checks,PrettyPrint=true));fclose(fid);
disp(checks);
end
