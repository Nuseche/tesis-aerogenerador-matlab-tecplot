function sections=prepare_sections(model,cfg,data)
%PREPARE_SECTIONS Two Gauss stations per blade element with work-dual mapping.
% B maps reference-frame nodal displacements to section translations/rotations.
% Its transpose transfers forces, including eccentric moments, without losing work.
rows=find(model.mesh.elements.blade>0);ndof=model.dofs.number;
[xi,w]=elements.gauss_rule(2);ns=2*numel(rows);
B=sparse(6*ns,ndof);position=zeros(ns,3);span=position;chord=position;
lengthWeight=zeros(ns,1);radius=lengthWeight;blade=radius;axis=model.rotorAxis.direction(:);
arc=zeros(numel(rows),1);
for b=unique(model.mesh.elements.blade(rows)).'
    ix=find(model.mesh.elements.blade(rows)==b);distance=0;
    for j=ix.'
        e=rows(j);ni=model.mesh.elements.nodeI(e);nj=model.mesh.elements.nodeJ(e);
        arc(j)=distance;distance=distance+norm(model.mesh.nodes.xyz(nj,:)-model.mesh.nodes.xyz(ni,:));
    end
    if abs(distance-100)>.5,error('aero:BladeLength','Expected the identified 100 m Sandia blade.');end
end
for j=1:numel(rows)
    e=rows(j);ni=model.mesh.elements.nodeI(e);nj=model.mesh.elements.nodeJ(e);
    x=model.mesh.nodes.xyz(ni,:);y=model.mesh.nodes.xyz(nj,:);dofs=[model.dofs.node(ni,:) model.dofs.node(nj,:)];
    sec=model.sections(model.mesh.elements.section(e));
    [~,~,info]=elements.timoshenko3d_matrices(x,y,model.mesh.elements.auxPoint(e,:),sec,cfg);
    er=(y-x).'/info.L;et=cross(axis,er);et=et/norm(et);
    for k=1:2
        a=2*j-2+k;s=(xi(k)+1)/2;radius(a)=arc(j)+s*info.L;
        N=elements.timoshenko_kinematic_matrix(xi(k),info.L,info.formulation,info.phiY,info.phiZ);
        B(6*a-5:6*a,dofs)=blkdiag(info.R.',info.R.')*N*info.Te;
        position(a,:)=(1-s)*x+s*y;span(a,:)=er.';chord(a,:)=-et.';
        lengthWeight(a)=info.L*w(k)/2;blade(a)=model.mesh.elements.blade(e);
    end
end
g=data.geometry;
sections=struct('B',B,'position',position,'span',span,'zeroPitchChord',chord, ...
    'weight',lengthWeight,'spanM',radius,'blade',blade,'axis',axis,'axisPoint',model.rotorAxis.point(:), ...
    'chord',interp1(g.span_m,g.chord_m,radius),'twist',interp1(g.span_m,g.twist_deg,radius)*pi/180, ...
    'pitchAxis',interp1(g.span_m,g.pitch_axis_fraction,radius), ...
    'thickness',interp1(g.span_m,g.thickness,radius));
end
