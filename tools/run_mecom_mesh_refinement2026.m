function study = run_mecom_mesh_refinement2026()
%RUN_MECOM_MESH_REFINEMENT2026 Refine only the existing piecewise beam model.
% No sectional/geometric interpolation is invented. Every original member
% is split into equal collinear members with the same section and frame.
% This stationary, unprestressed numerical benchmark preserves all original
% nodes, masses, MPCs and the explicitly uncalibrated drivetrain operator.
root = fileparts(fileparts(mfilename('fullpath')));
addpath(root,fullfile(root,'cases'));
folder = fullfile(root,'runs','run_20260914_mecom_mesh_refinement');
if isfolder(folder)
    error('mecom:ExistingRun','Refusing to overwrite %s.',folder);
end
mkdir(folder);
cfg = config_action06_equilibrium();
cfg.rotor.speedRPM = 0;
cfg.gravity.enabled = false;
data = io.load_model_data(cfg);
base = model.build_model(data,cfg);
factors = [1 2 4 8];
nModes = 12;
frequency = zeros(nModes,numel(factors));
nodes = zeros(numel(factors),1); dofs = nodes; mass = nodes;
maxResidual = nodes; elapsed = nodes; modalShapes = cell(numel(factors),1);
for k = 1:numel(factors)
    refined = subdivide(base,factors(k));
    clock = tic;
    [M,K] = assembly.assemble_structural_matrices(refined,cfg);
    M = rigid.add_body_masses(M,refined,refined.rigidBodies);
    Tc = rigid.rigid_constraint_matrix(refined,refined.rigidBodies,cfg);
    red = rigid.reduce_system(Tc,M,K,refined,cfg);
    T = Tc(:,red.free);
    Mr = T.'*M*T; Kr = T.'*K*T;
    rng(20260914,'twister');
    opts = struct('tol',1e-12,'maxit',6000,'isreal',true);
    [V,L,flag] = eigs(Kr,Mr,nModes,'smallestabs',opts);
    assert(flag==0,'Eigenvalue iteration failed to converge.');
    [lambda,order] = sort(real(diag(L))); V = V(:,order);
    assert(all(lambda>0),'Clamped benchmark contains nonpositive eigenvalues.');
    frequency(:,k) = sqrt(lambda)/(2*pi);
    residual = zeros(nModes,1);
    for j=1:nModes
        residual(j) = norm(Kr*V(:,j)-lambda(j)*Mr*V(:,j))/ ...
            ((norm(Kr,'fro')+abs(lambda(j))*norm(Mr,'fro'))*norm(V(:,j)));
    end
    recovered = T*V;
    modalShapes{k} = recovered(1:6*numel(base.mesh.nodes.id),:);
    translation = zeros(size(M,1),1); translation(1:6:end)=1;
    mass(k) = translation.'*M*translation;
    nodes(k) = numel(refined.mesh.nodes.id); dofs(k)=size(Mr,1);
    maxResidual(k)=max(residual); elapsed(k)=toc(clock);
    fprintf('Refinement %d: nodes %d, dofs %d, mass %.12g kg, f1 %.12g Hz, f12 %.12g Hz\n', ...
        factors(k),nodes(k),dofs(k),mass(k),frequency(1,k),frequency(end,k));
end
relativeErrorPercent = 100*abs(frequency-frequency(:,end))./frequency(:,end);
summary = table(factors.',nodes,133*factors.',dofs,mass,frequency(1,:).', ...
    frequency(end,:).',max(relativeErrorPercent,[],1).',maxResidual,elapsed, ...
    'VariableNames',{'subdivision','nodes','elements','analysisDofs','massKg', ...
    'f1Hz','f12Hz','maxFirst12FrequencyErrorPercent','maxNormwiseResidual','wallSeconds'});
mode = (1:nModes).';
frequencies = table(mode,frequency(:,1),frequency(:,2),frequency(:,3),frequency(:,4), ...
    relativeErrorPercent(:,1),relativeErrorPercent(:,2),relativeErrorPercent(:,3), ...
    'VariableNames',{'mode','f_h1','f_h2','f_h4','f_h8','error_h1_percent', ...
    'error_h2_percent','error_h4_percent'});
study = struct('createdUTC',string(datetime('now','TimeZone','UTC')), ...
    'description','Stationary zero gravity comparison on original piecewise section field; h8 is a numerical reference, not an exact solution.', ...
    'configuration',cfg,'summary',summary,'frequencies',frequencies, ...
    'modalShapesAtOriginalNodes',{modalShapes});
writetable(summary,fullfile(folder,'mesh_summary.csv'));
writetable(frequencies,fullfile(folder,'mesh_frequencies.csv'));
save(fullfile(folder,'mesh_study.mat'),'study','-v7');
fprintf('%s\n',jsonencode(table2struct(summary)));
fprintf('%s\n',jsonencode(table2struct(frequencies)));
end

function refined = subdivide(base,factor)
refined=base;
if factor==1,return,end
original=base.mesh.elements;
ne=numel(original.id); oldNodes=numel(base.mesh.nodes.id);
xyz=[base.mesh.nodes.xyz;zeros(ne*(factor-1),3)];
newElements=struct();
fields=fieldnames(original);
for k=1:numel(fields)
    value=original.(fields{k});
    newElements.(fields{k})=repelem(value,factor,1);
end
newElements.id=(1:ne*factor).';
for e=1:ne
    i=original.nodeI(e); j=original.nodeJ(e);
    a=base.mesh.nodes.xyz(i,:); b=base.mesh.nodes.xyz(j,:);
    added=oldNodes+(e-1)*(factor-1)+(1:factor-1);
    xyz(added,:)=a+((1:factor-1).'/factor).*(b-a);
    chain=[i added j]; rows=(e-1)*factor+(1:factor);
    newElements.nodeI(rows)=chain(1:end-1);
    newElements.nodeJ(rows)=chain(2:end);
end
refined.mesh.nodes.id=(1:size(xyz,1)).';
refined.mesh.nodes.xyz=xyz;
refined.mesh.elements=newElements;
refined.dofs=model.build_dof_map(refined.mesh,base.boundaryConditions);
% These maps are not used for stationary structural assembly and describe
% only the legacy station layout. Remove them rather than expose stale data.
refined=rmfield(refined,{'referenceFrames','bladeDofMap','summary'});
refined.meta.flexibleElementCount=ne*factor;
end
