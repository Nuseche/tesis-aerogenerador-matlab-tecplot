function out=turbine_mbc_operators(s,azimuth,omega)
%TURBINE_MBC_OPERATORS Transport the actual LTV system into homologous MBC axes.
% Physical operators are rebuilt at each azimuth BEFORE the MBC transformation.
[~,info]=rigid.rigid_constraint_matrix(s.model,s.model.rigidBodies,struct());
fullToFree=zeros(s.ndof,1);fullToFree(info.independentDofs(s.free))=(1:s.n).';
map=fullToFree(s.model.bladeDofMap.map);
frame=struct('map',map,'referenceR',s.model.bladeDofMap.frameR, ...
    'rotorAxis',s.model.rotorAxis.direction,'nDof',s.n);
root=s.model.mesh.nodes.xyz([21 57 93],:)-s.model.rotorAxis.point.';
axis=s.model.rotorAxis.direction;direction=sign(dot(axis,cross(root(1,:),root(2,:))));
options=struct('nDof',s.n,'frameData',frame,'direction',direction);
s.cfg.rotor.motionFcn=@(t)struct('azimuth',azimuth+omega*t,'omega',omega,'alpha',0);
op=aero.structural_operators(s,0);tr=rotor.mbc_derivatives(map,azimuth,omega,options);
P=tr.T;Pd=tr.Tdot;Pdd=tr.Tddot;
out=struct('M',P.'*op.M*P,'D',P.'*(op.D*P+2*op.M*Pd), ...
    'K',P.'*(op.K*P+op.D*Pd+op.M*Pdd),'recovery',op.T*P, ...
    'forceMap',P.','physicalOperators',op,'transformation',tr,'map',map);
end
