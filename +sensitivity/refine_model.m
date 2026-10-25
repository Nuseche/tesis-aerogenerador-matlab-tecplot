function md=refine_model(md,factor)
%REFINE_MODEL Split each constant-property member, preserving original nodes.
if factor~=fix(factor)||factor<1,error('sensitivity:BadRefinement','Integer factor required.');end
if factor==1,return,end
mesh=md.mesh;old=mesh.elements;ne=numel(old.id);names=fieldnames(old);
new=old;
for f=1:numel(names),new.(names{f})=repelem(old.(names{f}),factor,1);end
new.id=(1:ne*factor).';new.legacyId=new.id;
next=max(mesh.nodes.id);
for e=1:ne
    ri=find(mesh.nodes.id==old.nodeI(e),1);rj=find(mesh.nodes.id==old.nodeJ(e),1);
    xi=mesh.nodes.xyz(ri,:);xj=mesh.nodes.xyz(rj,:);chain=[old.nodeI(e) zeros(1,factor-1) old.nodeJ(e)];
    for j=1:factor-1
        next=next+1;chain(j+1)=next;mesh.nodes.id(end+1,1)=next;
        mesh.nodes.xyz(end+1,:)=xi+(xj-xi)*j/factor;
    end
    rows=(e-1)*factor+(1:factor);
    new.nodeI(rows)=chain(1:end-1);new.nodeJ(rows)=chain(2:end);
    % Auxiliary points retain the same cross-section orientation line.
    if all(isfinite(old.auxPoint(e,:)))
        for j=1:factor
            new.auxPoint(rows(j),:)=old.auxPoint(e,:)+(xj-xi)*(j-1)/factor;
        end
    end
end
mesh.elements=new;md.mesh=mesh;
md.dofs=model.build_dof_map(mesh,md.boundaryConditions);
md.referenceFrames=model.blade_coordinate_systems(mesh,1e-10);
md.summary.nodeCount=numel(mesh.nodes.id);md.summary.flexibleElementCount=numel(new.id);
md.meta.refinement=struct('factor',factor,'propertyPolicy',"piecewise constant original sections", ...
    'originalNodesPreserved',true,'geometryChanged',false);
end
