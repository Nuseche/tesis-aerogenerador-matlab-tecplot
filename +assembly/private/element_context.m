function ctx=element_context(model,e)
%ELEMENT_CONTEXT Normalize one beam element from the public model contract.
    mesh=model.mesh; nodes=mesh.nodes; elements=mesh.elements;
    ids=double(nodes.id(:)); xyz=double(nodes.xyz);
    ni=double(at(elements,"nodeI",e));nj=double(at(elements,"nodeJ",e));
    ri=find(ids==ni,1);rj=find(ids==nj,1);
    if isempty(ri)||isempty(rj),error("assembly:UnknownConnectivity","Element %d references an unknown node.",e);end
    if isfield(elements,"auxPoint")
        aux=double(atRow(elements,"auxPoint",e,3));
    else,aux=[NaN NaN NaN];end
    if any(~isfinite(aux)),aux=defaultAux(xyz(ri,:),xyz(rj,:));end
    sid=at(elements,"section",e);
    section=findSection(model.sections,sid);
    dofs=assembly.element_dof_indices(model,e);
    ctx=struct("nodeI",ni,"nodeJ",nj,"rowI",ri,"rowJ",rj,"xI",xyz(ri,:), ...
        "xJ",xyz(rj,:),"auxPoint",aux,"section",section,"dofs",dofs, ...
        "id",double(optionalAt(elements,"id",e,e)),"active",isActive(elements,e), ...
        "sectionId",double(sid),"type",string(optionalAt(elements,"type",e,"flexible")), ...
        "blade",double(optionalAt(elements,"blade",e,0)));
end

function value=at(s,name,e)
    f=s.(name);
    if iscell(f),value=f{e};elseif numel(s)>1,value=s(e).(name);else,value=f(e);end
end
function row=atRow(s,name,e,width)
    f=s.(name);
    if numel(s)>1,row=reshape(s(e).(name),1,width);else,row=reshape(f(e,:),1,width);end
end
function value=optionalAt(s,name,e,defaultValue)
    if isfield(s,name),value=at(s,name,e);else,value=defaultValue;end
end
function n=countElements(elements)
    if numel(elements)>1,n=numel(elements);else,n=numel(elements.nodeI);end
end
function tf=isActive(elements,e)
    tf=true;
    if isfield(elements,"active"),tf=logical(at(elements,"active",e));end
    if isfield(elements,"isRigidConstraint")&&logical(at(elements,"isRigidConstraint",e)),tf=false;end
    if isfield(elements,"formulation")
        form=string(at(elements,"formulation",e));
        if strcmpi(form,"rigid"),tf=false;end
    end
end
function section=findSection(sections,sid)
    if isnumeric(sid)&&isscalar(sid)&&sid>=1&&sid<=numel(sections)&&sid==floor(sid)
        candidate=sections(sid);
        if ~isfield(candidate,"id")||isequal(double(candidate.id),double(sid)),section=candidate;return,end
    end
    if isfield(sections,"id")
        allIds={sections.id};
        for k=1:numel(allIds)
            if isequal(string(allIds{k}),string(sid)),section=sections(k);return,end
        end
    end
    error("assembly:UnknownSection","Section '%s' was not found.",string(sid));
end
function aux=defaultAux(xi,xj)
    e=(xj-xi).';e=e/norm(e);basis=eye(3);[~,k]=min((basis.'*e).^2);
    aux=xi+basis(:,k).';
end
