function md=refine_isolated_mesh(md,factor)
%REFINE_ISOLATED_MESH Subdivide beams, retaining each parent's material frame.
assert(factor>=1&&factor==fix(factor),'Positive integer subdivision required.');
if factor==1,return,end
old=md.mesh;ne=numel(old.elements.id);xyz=zeros(ne*factor+1,3);aux=zeros(ne*factor,3);
section=zeros(ne*factor,1);
for e=1:ne
    x=old.nodes.xyz(old.elements.nodeI(e),:);y=old.nodes.xyz(old.elements.nodeJ(e),:);
    for k=1:factor
        row=(e-1)*factor+k;xyz(row,:)=x+(k-1)/factor*(y-x);
        aux(row,:)=xyz(row,:)+old.elements.auxPoint(e,:)-x;section(row)=old.elements.section(e);
    end
end
xyz(end,:)=old.nodes.xyz(end,:);n=size(xyz,1);
md.mesh.nodes=struct('id',(1:n).','xyz',xyz);
md.mesh.elements=struct('id',(1:n-1).','legacyId',repelem(old.elements.legacyId,factor), ...
    'nodeI',(1:n-1).','nodeJ',(2:n).','type',repmat("blade",n-1,1), ...
    'section',section,'blade',ones(n-1,1),'auxPoint',aux);
md.dofs=struct('number',6*n,'node',reshape(1:6*n,6,n).','fixed',(1:6).');
md.dofs.element=[md.dofs.node(1:end-1,:) md.dofs.node(2:end,:)];
end
