function md=build_isolated_blade(cfg,data)
%BUILD_ISOLATED_BLADE Straight rotating cantilever with inherited MHT sections.
% Maza's isolated case removes precone/pretilt; root radius is prescribed.
source=io.load_model_data(cfg);raw=source.geometry;ids=21:56;
lengths=vecnorm(diff(raw.coordinates(ids,:),1,1),2,2);lengths=100*lengths/sum(lengths);
s=[0;cumsum(lengths)];n=numel(s);xyz=[zeros(n,2),cfg.aeroelastic.rootRadius+s];
md.mesh.nodes=struct('id',(1:n).','xyz',xyz);
mid=(s(1:end-1)+s(2:end))/2;
pitch=cfg.aerodynamics.pitchRad;if isa(pitch,'function_handle'),pitch=pitch(0);end
beta=interp1(data.geometry.span_m,data.geometry.twist_deg,mid)*pi/180+pitch;
% Local e2 is chordwise and e3=e1 x e2; no aerodynamic twist is inferred from EI.
aux=xyz(1:end-1,:)+[-cos(beta),sin(beta),zeros(n-1,1)];
md.mesh.elements=struct('id',(1:n-1).','legacyId',(1:n-1).','nodeI',(1:n-1).', ...
    'nodeJ',(2:n).','type',repmat("blade",n-1,1),'section',(1:n-1).', ...
    'blade',ones(n-1,1),'auxPoint',aux);
sections=model.resolve_section_mass(source.sections(:),cfg);md.sections=sections(21:55);
for k=1:numel(md.sections),md.sections(k).id=k;end
md.dofs=struct('number',6*n,'node',reshape(1:6*n,6,n).','fixed',(1:6).');
md.dofs.element=[md.dofs.node(1:end-1,:) md.dofs.node(2:end,:)];
md.rigidBodies=struct('bodies',struct([]));md.rotorAxis=struct('direction',[1;0;0],'point',zeros(3,1));
md.boundaryConditions=struct('fixedNodeIds',1,'fixedDofs',(1:6).');
md.aeroelasticScope="isolated_blade_corotating";
end
