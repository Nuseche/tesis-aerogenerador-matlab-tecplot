function [M,report] = add_body_masses(M,model,bodies)
%ADD_BODY_MASSES Add complete 6-by-6 rigid-body spatial masses at masters.

    if nargin<3 || isempty(bodies)
        if isfield(model,"rigidBodies"), bodies=model.rigidBodies; else, bodies=struct([]); end
    end
    bodyList=extractBodies(bodies);
    ndof=size(M,1);
    if size(M,2)~=ndof
        error("rigid:add_body_masses:NonSquare","Global mass matrix must be square.");
    end
    M=sparse(M);
    report=repmat(struct("name","","masterNode",NaN,"dofs",[],"mass",NaN, ...
        "cgOffsetGlobal",[],"inertiaGlobalCG",[],"inertiaGlobalMaster",[], ...
        "spatialMassMatrix",[],"orientationBodyToGlobal",[], ...
        "offsetStatus","","dataVersion",""),numel(bodyList),1);
    for k=1:numel(bodyList)
        b=bodyList(k);
        master=getMaster(b);
        dofs=nodeDofs(model,master);
        [MR,details]=rigid.rigid_body_mass_matrix(b);
        M(dofs,dofs)=M(dofs,dofs)+sparse(MR);
        report(k).name=string(optionalField(b,"name","body_"+k));
        report(k).masterNode=master;
        report(k).dofs=dofs;
        report(k).mass=details.mass;
        report(k).cgOffsetGlobal=details.cgOffsetGlobal;
        report(k).inertiaGlobalCG=details.inertiaGlobalCG;
        report(k).inertiaGlobalMaster=details.inertiaGlobalMaster;
        report(k).spatialMassMatrix=MR;
        report(k).orientationBodyToGlobal=details.orientationBodyToGlobal;
        report(k).offsetStatus=string(optionalField(b,"offsetStatus","unspecified"));
        report(k).dataVersion=string(optionalField(b,"dataVersion","unspecified"));
    end
    M=(M+M.')/2;
end

function list=extractBodies(bodies)
    if isempty(bodies),list=struct([]);return,end
    if isfield(bodies,"bodies"),list=bodies.bodies;else,list=bodies;end
    list=list(:);
end

function master=getMaster(b)
    if isfield(b,"masterNode"),master=double(b.masterNode);
    elseif isfield(b,"node"),master=double(b.node);
    elseif isfield(b,"master"),master=double(b.master);
    else,error("rigid:add_body_masses:MissingMaster","Every body requires masterNode.");end
end

function dofs=nodeDofs(model,nodeId)
    ids=double(model.mesh.nodes.id(:));
    row=find(ids==nodeId,1);
    if isempty(row),error("rigid:add_body_masses:UnknownMaster","Master node %g does not exist.",nodeId);end
    if isfield(model,"dofs")&&isfield(model.dofs,"node")
        dofs=double(model.dofs.node(row,:));
    else
        dofs=(6*(row-1)+(1:6));
    end
end

function value=optionalField(s,name,defaultValue)
    if isfield(s,name)&&~isempty(s.(name)),value=s.(name);else,value=defaultValue;end
end
