% Quadratic reference elastic energies and mass participation of mode shapes.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));addpath(root);addpath(fullfile(root,'cases'));
folder=fullfile(root,'runs','sensitivity','initial_20261005','local');
r=sensitivity.read_case(folder,'nominal');cfg=r.configuration;
md=model.build_model(io.load_model_data(cfg),cfg);
[~,Ke,cache,report]=assembly.assemble_structural_matrices(md,cfg);
Phi=r.solution.fullModes(:,1:12);elastic=zeros(12,3);mass=zeros(12,4);
for e=1:numel(cache)
    if ~cache(e).assembled,continue,end
    p=Phi(cache(e).dofs,:);ek=real(sum(conj(p).*(cache(e).KeGlobal*p),1)).';
    em=real(sum(conj(p).*(cache(e).MeGlobal*p),1)).';
    if cache(e).component=="blade",col=2;else,col=1;end
    elastic(:,col)=elastic(:,col)+ek;mass(:,col)=mass(:,col)+em;
end
elastic(:,3)=real(sum(conj(Phi).*(report.components.Kdrivetrain*Phi),1)).';
for j=1:2
    body=md.rigidBodies.bodies(j);node=find(md.mesh.nodes.id==body.masterNode,1);
    p=Phi(md.dofs.node(node,:),:);R=body.orientationBodyToGlobal;
    J=R*body.inertiaBody*R';B=blkdiag(body.mass*eye(3),J);
    mass(:,2+j)=real(sum(conj(p).*(B*p),1)).';
end
elastic=elastic./sum(elastic,2);mass=mass./sum(mass,2);
T=table((1:12).',r.solution.dampedFrequencyHz(1:12),string(r.solution.classification(1:12)), ...
    elastic(:,1),elastic(:,2),elastic(:,3),mass(:,1),mass(:,2),mass(:,3),mass(:,4), ...
    'VariableNames',{'mode','frequencyHz','kinematicClassification','towerElasticFraction', ...
    'bladeElasticFraction','drivetrainElasticFraction','towerMassFraction', ...
    'bladeMassFraction','nacelleMassFraction','hubMassFraction'});
writetable(T,fullfile(folder,'modal_energy_evidence.csv'));disp(T([3 4 8 9 10 11 12],:));
% Check buffer at selected spectral boundary, retaining any ambiguity.
la=r.solution.eigenvaluesQEP;distance=abs(la(12)-la(13))/max(abs(la([12 13])));
fprintf('Branch 12--13 complex relative separation = %.8g\n',distance);
