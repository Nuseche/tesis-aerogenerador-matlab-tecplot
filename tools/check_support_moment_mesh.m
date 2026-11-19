function check_support_moment_mesh()
% Evaluate the same support transient on nested structural meshes.
root=fileparts(fileparts(mfilename('fullpath')));addpath(root,fullfile(root,'cases'));
cfg=config_seismic_verification();cfg.rotor.speedRPM=0;cfg.gravity.enabled=false;
md=model.build_model(io.load_model_data(cfg),cfg); maxNumCompThreads(1);
t=(0:.0025:8)'; om=2*pi*[.65 .9];u=[.003 .0018];st=sin(t*om);ct=cos(t*om);
ag=3*(2*st.*ct.^2-st.^3).*(u.*om.^2);
hist=cell(3,1);factors=[1 2 4];rows={};
for j=1:3
 s=subdivide(md,factors(j));[m,k]=assembly.assemble_structural_matrices(s,cfg);
 m=rigid.add_body_masses(m,s,s.rigidBodies);
 d=assembly.assemble_damping_matrix(s,m,k,struct(),cfg);
 C=rigid.rigid_constraint_matrix(s,s.rigidBodies,cfg);
 red=rigid.reduce_system(C,m,k,s,cfg);T=C(:,red.free);
 R=zeros(size(k,1),2);R(s.dofs.node(:,1),1)=1;R(s.dofs.node(:,2),2)=1;
 f=m*R;z=dynamics.newmark_integrate(T'*m*T,T'*d*T,T'*k*T,t,-(T'*f)*ag',struct('beta',.25,'gamma',.5));
 b=s.dofs.node(1,5);hist{j}=[T(s.dofs.node(129,1),:)*z.q;T(s.dofs.node(56,1),:)*z.q; (m(b,:)*T)*z.qdd+(d(b,:)*T)*z.qd+(k(b,:)*T)*z.q+f(b,:)*ag'];clear z
end
for j=1:3
 for c=1:3
  ref=hist{3}(c,:);err=hist{j}(c,:)-ref;rows(end+1,:)={factors(j),c,max(abs(ref)),100*sqrt(trapz(t,err.^2)/trapz(t,ref.^2))};
 end
end
folder=fullfile(root,'runs','load_enrichment_20261118');
writetable(cell2table(rows,'VariableNames',{'subdivision','channel','referencePeak','relativeL2Percent'}),fullfile(folder,'output_mesh.csv'));
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
