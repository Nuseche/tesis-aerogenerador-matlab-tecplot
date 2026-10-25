function [Tc,info] = rigid_constraint_matrix(model,bodies,cfg)
%RIGID_CONSTRAINT_MATRIX Exact sparse master-slave kinematic transform.
%   q_full=Tc*q_independent with
%       u_slave=u_master-S(x_slave-x_master)*theta_master,
%       theta_slave=theta_master.
%   Nodes 129 and 130 are never tied to each other. Constraints must be
%   supplied explicitly through BODIES or MODEL.rigidBodies; an empty list
%   produces the identity transform and never injects a legacy constraint.

    if nargin<2||isempty(bodies)
        if isfield(model,"rigidBodies"),bodies=model.rigidBodies;else,bodies=struct();end
    end
    if nargin<3,cfg=struct();end %#ok<NASGU>
    constraints=extractConstraints(bodies,model);
    nodeIds=double(model.mesh.nodes.id(:));
    xyz=double(model.mesh.nodes.xyz);
    if ~isequal(size(xyz),[numel(nodeIds) 3]) || any(~isfinite(xyz),'all')
        error("rigid:rigid_constraint_matrix:InvalidCoordinates", ...
            "mesh.nodes.xyz must be a finite N-by-3 array.");
    end
    dofMap=getDofMap(model,numel(nodeIds));
    ndof=max(dofMap(:));

    slaveIds=[];
    masterBySlave=[];
    for c=1:numel(constraints)
        master=getField(constraints(c),["masterNode","master"]);
        slaves=getField(constraints(c),["slaveNodes","slaves"]);
        master=double(master);
        slaves=double(slaves(:));
        if ~isscalar(master) || ~isfinite(master) || master~=fix(master) || ...
                any(~isfinite(slaves)) || any(slaves~=fix(slaves))
            error("rigid:rigid_constraint_matrix:InvalidNodeId", ...
                "Rigid master and slave IDs must be finite integer values.");
        end
        if any(slaves==master)
            error("rigid:rigid_constraint_matrix:SelfConstraint","A master cannot also be its own slave.");
        end
        if (master==129 && any(slaves==130)) || (master==130 && any(slaves==129))
            error("rigid:rigid_constraint_matrix:DriveTrainMustRemainFlexible", ...
                "Nodes 129 and 130 must remain independent; retain their flexible transition elements.");
        end
        slaveIds=[slaveIds;slaves]; %#ok<AGROW>
        masterBySlave=[masterBySlave;repmat(master,numel(slaves),1)]; %#ok<AGROW>
    end
    if numel(unique(slaveIds))~=numel(slaveIds)
        error("rigid:rigid_constraint_matrix:DuplicateSlave","A slave node appears in more than one rigid constraint.");
    end
    if any(~ismember(slaveIds,nodeIds))||any(~ismember(masterBySlave,nodeIds))
        error("rigid:rigid_constraint_matrix:UnknownNode","All rigid masters and slaves must exist in mesh.nodes.id.");
    end
    if any(ismember(masterBySlave,slaveIds))
        error("rigid:rigid_constraint_matrix:ConstraintChain", ...
            "Constraint chains are not supported; use a single ultimate master.");
    end

    slaveDofs=zeros(numel(slaveIds)*6,1);
    for k=1:numel(slaveIds)
        srow=find(nodeIds==slaveIds(k),1);
        slaveDofs(6*(k-1)+(1:6))=dofMap(srow,:);
    end
    independent=setdiff((1:ndof).',slaveDofs,'stable');
    columnOf=zeros(ndof,1);
    columnOf(independent)=1:numel(independent);

    estimated=ndof+24*numel(slaveIds);
    I=zeros(estimated,1);J=zeros(estimated,1);V=zeros(estimated,1);p=0;
    for k=1:numel(independent)
        p=p+1;I(p)=independent(k);J(p)=k;V(p)=1;
    end
    for k=1:numel(slaveIds)
        srow=find(nodeIds==slaveIds(k),1);mrow=find(nodeIds==masterBySlave(k),1);
        sd=dofMap(srow,:);md=dofMap(mrow,:);
        r=(xyz(srow,:)-xyz(mrow,:)).';
        S=[0 -r(3) r(2);r(3) 0 -r(1);-r(2) r(1) 0];
        B=[eye(3) -S;zeros(3) eye(3)];
        for a=1:6
            for b=1:6
                if B(a,b)~=0
                    col=columnOf(md(b));
                    if col==0,error("rigid:rigid_constraint_matrix:DependentMaster","Master DOFs cannot be dependent.");end
                    p=p+1;I(p)=sd(a);J(p)=col;V(p)=B(a,b);
                end
            end
        end
    end
    Tc=sparse(I(1:p),J(1:p),V(1:p),ndof,numel(independent));
    if sprank(Tc)~=size(Tc,2)
        error("rigid:rigid_constraint_matrix:RankDeficient","Rigid constraint transform does not have full column rank.");
    end
    info=struct("independentDofs",independent,"reducedToFull",independent, ...
        "slaveNodeIds",slaveIds, ...
        "masterNodeBySlave",masterBySlave,"slaveDofs",slaveDofs, ...
        "fullToReduced",columnOf,"rank",sprank(Tc));
end

function constraints=extractConstraints(bodies,model)
    constraints=struct([]);
    if isstruct(bodies)&&isfield(bodies,"constraints")&&~isempty(bodies.constraints)
        constraints=bodies.constraints;
    elseif isfield(model,"rigidBodies")&&isfield(model.rigidBodies,"constraints")
        constraints=model.rigidBodies.constraints;
    end
    constraints=constraints(:);
end

function map=getDofMap(model,n)
    if isfield(model,"dofs")&&isfield(model.dofs,"node"),map=double(model.dofs.node);
    else,map=reshape(1:6*n,6,n).';end
    values=map(:);
    if ~isequal(size(map),[n 6]) || any(~isfinite(values)) || ...
            any(values~=fix(values)) || any(values<1) || ...
            numel(unique(values))~=numel(values) || ...
            ~isequal(sort(values),reshape(1:numel(values),[],1))
        error("rigid:rigid_constraint_matrix:InvalidDofMap","model.dofs.node must be an N-by-6 unique DOF map.");
    end
end

function value=getField(s,names)
    for name=names
        if isfield(s,name),value=s.(name);return,end
    end
    error("rigid:rigid_constraint_matrix:MissingField","Rigid constraint is missing a master/slave field.");
end
