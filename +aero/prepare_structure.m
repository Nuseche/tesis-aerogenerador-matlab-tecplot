function system=prepare_structure(md,cfg)
%PREPARE_STRUCTURE MHT rotating energy operators for prescribed rotor motion.
% Quadratic spin potential, mixed Hessian A and momentum b include rotary inertia.
% Initial-stress stiffness uses quasi-static unit-spin axial forces, scaled by omega^2.
[M,Ke]=assembly.assemble_structural_matrices(md,cfg);
[M,~]=rigid.add_body_masses(M,md,md.rigidBodies);
[Tc,~]=rigid.rigid_constraint_matrix(md,md.rigidBodies,struct());
reduced=rigid.reduce_system(Tc,M,Ke,md,cfg);T=Tc(:,reduced.free);n=size(M,1);
Mr=sparse(n,n);Kr=Mr;A=Mr;Kspin=Mr;fspin=zeros(n,1);bspin=fspin;
axis=md.rotorAxis.direction(:);origin=md.rotorAxis.point(:);rotatingNodes=[];
[xi,weights]=elements.gauss_rule(4);
for e=find(md.mesh.elements.blade>0).'
    ni=md.mesh.elements.nodeI(e);nj=md.mesh.elements.nodeJ(e);x=md.mesh.nodes.xyz(ni,:);y=md.mesh.nodes.xyz(nj,:);
    rotatingNodes=[rotatingNodes ni nj]; %#ok<AGROW>
    dofs=[md.dofs.node(ni,:) md.dofs.node(nj,:)];section=md.sections(md.mesh.elements.section(e));
    [ke,me,info]=elements.timoshenko3d_matrices(x,y,md.mesh.elements.auxPoint(e,:),section,cfg);
    Mr(dofs,dofs)=Mr(dofs,dofs)+me;Kr(dofs,dofs)=Kr(dofs,dofs)+ke;
    [~,mass]=elements.section_mass(section,cfg);omega=info.R*axis;
    for k=1:4
        N=elements.timoshenko_kinematic_matrix(xi(k),info.L,info.formulation,info.phiY,info.phiZ)*info.Te;
        pos=info.R*((1-xi(k))/2*x.'+(1+xi(k))/2*y.'-origin);
        z=elements.rotating_section_operators(mass.massPerLength,mass.centroidalInertia,mass.offset,omega,pos);
        weight=info.L*weights(k)/2;
        A(dofs,dofs)=A(dofs,dofs)+N.'*z.A*N*weight;
        Kspin(dofs,dofs)=Kspin(dofs,dofs)+N.'*z.Kcentrifugal*N*weight;
        fspin(dofs)=fspin(dofs)+N.'*z.forceCentrifugal*weight;
        B=[eye(3),-aero.skew(mass.offset)];E=[zeros(3),eye(3)];
        momentum=B.'*(mass.massPerLength*cross(omega,pos+mass.offset))+E.'*(mass.centroidalInertia*omega);
        bspin(dofs)=bspin(dofs)+N.'*momentum*weight;
    end
end
for body=md.rigidBodies.bodies(:).'
    if ~body.rotating,continue,end
    row=find(md.mesh.nodes.id==body.masterNode,1);dofs=md.dofs.node(row,:);rotatingNodes=[rotatingNodes row]; %#ok<AGROW>
    [mb,details]=rigid.rigid_body_mass_matrix(body);
    z=elements.rotating_section_operators(details.mass,details.inertiaGlobalCG,details.cgOffsetGlobal,axis,md.mesh.nodes.xyz(row,:).'-origin);
    Mr(dofs,dofs)=Mr(dofs,dofs)+mb;A(dofs,dofs)=A(dofs,dofs)+z.A;
    Kspin(dofs,dofs)=Kspin(dofs,dofs)+z.Kcentrifugal;fspin(dofs)=fspin(dofs)+z.forceCentrifugal;
    B=[eye(3),-aero.skew(details.cgOffsetGlobal)];E=[zeros(3),eye(3)];
    bspin(dofs)=bspin(dofs)+B.'*(details.mass*cross(axis,md.mesh.nodes.xyz(row,:).'-origin+details.cgOffsetGlobal))+E.'*(details.inertiaGlobalCG*axis);
end
% Independent prestress calculation; only blade geometric terms rotate.
qspin=T*((T.'*Ke*T)\(T.'*fspin));axial=zeros(numel(md.mesh.elements.id),1);
for e=find(md.mesh.elements.blade>0).'
    ni=md.mesh.elements.nodeI(e);nj=md.mesh.elements.nodeJ(e);dofs=[md.dofs.node(ni,:) md.dofs.node(nj,:)];
    [~,Te,L]=elements.element_rotation_matrix(md.mesh.nodes.xyz(ni,:),md.mesh.nodes.xyz(nj,:),md.mesh.elements.auxPoint(e,:));
    ql=Te*qspin(dofs);axial(e)=md.sections(md.mesh.elements.section(e)).EA*(ql(7)-ql(1))/L;
end
Kg=assembly.assemble_geometric_stiffness(md,struct('elementAxialForces',axial),cfg);
% This driver uses explicit Rayleigh coefficients; no hidden damping calibration.
C=cfg.damping.alpha*M+cfg.damping.beta*Ke;Cr=cfg.damping.alpha*Mr+cfg.damping.beta*Kr;
rotatingNodes=unique(rotatingNodes);rotatingDofs=reshape(md.dofs.node(rotatingNodes,:).',[],1);
W=sparse(n,n);W(rotatingDofs,rotatingDofs)=kron(speye(numel(rotatingDofs)/3),sparse(aero.skew(axis)));
system=struct('model',md,'cfg',cfg,'M',M,'Ke',Ke,'C',C,'Mr',Mr,'Kr',Kr,'Cr',Cr,'A',A, ...
    'G',A-A.','Kspin',Kspin,'Kg',Kg,'fspin',fspin,'bspin',bspin,'T',T, ...
    'free',reduced.free,'W',W,'rotatingNodes',rotatingNodes,'rotatingDofs',rotatingDofs, ...
    'axialForceUnitSpin',axial,'n',size(T,2),'ndof',n);
end
