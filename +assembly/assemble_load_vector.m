function [f,parts,Kexternal] = assemble_load_vector(model,cfg,state)
%ASSEMBLE_LOAD_VECTOR Consistent gravity, centrifugal and applied loads.
    if nargin<2,cfg=struct();end
    if nargin<3,state=struct();end
    [ndof,ne]=model_size(model);gravity=gravityVector(cfg);
    fGravity=zeros(ndof,1);
    for e=1:ne
        c=element_context(model,e);if ~c.active,continue,end
        [~,me]=elements.timoshenko3d_matrices(c.xI,c.xJ,c.auxPoint,c.section,cfg);
        acceleration=[gravity;zeros(3,1);gravity;zeros(3,1)];
        fGravity(c.dofs)=fGravity(c.dofs)+me*acceleration;
    end
    % Bodies use the same spatial offset convention as their mass matrices.
    for b=bodyList(model).'
        [~,d]=rigid.rigid_body_mass_matrix(b);F=d.mass*gravity;moment=cross(d.cgOffsetGlobal,F);
        dofs=nodeDofs(model,getMaster(b));fGravity(dofs)=fGravity(dofs)+[F;moment];
    end

    fCentrifugal=zeros(ndof,1);
    Kcentrifugal=sparse(ndof,ndof);
    centrifugalDetails=struct('configurationDependent',false,'loadNorm',0, ...
        'tangentNorm',0);
    if rotorSpeed(cfg,state)~=0
        [fCentrifugal,centrifugalDetails,Kcentrifugal]= ...
            equilibrium.centrifugal_loads(model,cfg,state);
    end
    loadState=state;
    if ~isfield(loadState,'qdFull'),loadState.qdFull=zeros(ndof,1);end
    [fAerodynamic,aerodynamicDetails]= ...
        assembly.evaluate_aerodynamic_load(model,loadState,cfg,ndof);
    Kaerodynamic=sparse(ndof,ndof);Caerodynamic=sparse(ndof,ndof);
    aerodynamicTangentDetails=struct('method',"not_active");
    if aerodynamicDetails.active
        [Kaerodynamic,Caerodynamic,aerodynamicTangentDetails]= ...
            assembly.linearize_aerodynamic_loads(model,loadState,cfg,ndof);
    end
    fApplied=zeros(ndof,1);
    if isfield(state,"externalLoad"),fApplied=fApplied+fullVector(state.externalLoad,ndof,"state.externalLoad");end
    if isfield(cfg,"loads")
        if isfield(cfg.loads,"vector"),fApplied=fApplied+fullVector(cfg.loads.vector,ndof,"cfg.loads.vector");end
        if isfield(cfg.loads,"nodal"),fApplied=fApplied+nodalLoads(model,cfg.loads.nodal,ndof);end
    end
    if isfield(model,"loads")&&isfield(model.loads,"vector"),fApplied=fApplied+fullVector(model.loads.vector,ndof,"model.loads.vector");end
    f=sparse(fGravity+fCentrifugal+fAerodynamic+fApplied);
    % Kaero=-df_a/dq, whereas Newton requires df_external/dq.
    Kexternal=Kcentrifugal-Kaerodynamic;
    parts=struct("gravity",sparse(fGravity), ...
        "centrifugal",sparse(fCentrifugal), ...
        "aerodynamic",sparse(fAerodynamic),"applied",sparse(fApplied), ...
        "centrifugalTangent",Kcentrifugal, ...
        "aerodynamicStiffness",Kaerodynamic, ...
        "aerodynamicDamping",Caerodynamic, ...
        "centrifugalDetails",centrifugalDetails, ...
        "aerodynamicDetails",aerodynamicDetails, ...
        "aerodynamicTangentDetails",aerodynamicTangentDetails);
end

function g=gravityVector(cfg)
    g=[0;0;-9.80665];
    if isfield(cfg,"gravity")
        if isstruct(cfg.gravity)&&isfield(cfg.gravity,"vector"),g=double(cfg.gravity.vector(:));
        elseif isnumeric(cfg.gravity),g=double(cfg.gravity(:));end
    elseif isfield(cfg,"loads")&&isfield(cfg.loads,"gravity"),g=double(cfg.loads.gravity(:));end
    if numel(g)~=3||any(~isfinite(g)),error("assembly:assemble_load_vector:InvalidGravity","Gravity must be a finite 3-vector.");end
    if isfield(cfg,"gravity")&&isstruct(cfg.gravity)&&isfield(cfg.gravity,"enabled")&&~cfg.gravity.enabled,g=zeros(3,1);end
end
function speed=rotorSpeed(cfg,state)
    if isfield(state,"omega"),speed=norm(double(state.omega));elseif isfield(state,"angularVelocity"),speed=norm(double(state.angularVelocity));
    elseif isfield(cfg,"rotor")&&isfield(cfg.rotor,"speedRadPerSec"),speed=double(cfg.rotor.speedRadPerSec);
    elseif isfield(cfg,"rotor")&&isfield(cfg.rotor,"speedRPM"),speed=double(cfg.rotor.speedRPM)*2*pi/60;else,speed=0;end
end
function list=bodyList(model)
    list=struct([]);if ~isfield(model,"rigidBodies"),return,end;rb=model.rigidBodies;if isfield(rb,"bodies"),list=rb.bodies;else,list=rb;end;list=list(:);
end
function master=getMaster(b)
    if isfield(b,"masterNode"),master=double(b.masterNode);elseif isfield(b,"node"),master=double(b.node);else,error("assembly:assemble_load_vector:MissingMaster","Body requires masterNode.");end
end
function dofs=nodeDofs(model,id)
    row=find(double(model.mesh.nodes.id(:))==id,1);if isempty(row),error("assembly:assemble_load_vector:UnknownNode","Unknown node %g.",id);end
    if isfield(model,"dofs")&&isfield(model.dofs,"node"),dofs=double(model.dofs.node(row,:));else,dofs=6*(row-1)+(1:6);end
end
function f=fullVector(value,n,label)
    f=double(value(:));if numel(f)~=n||any(~isfinite(f)),error("assembly:assemble_load_vector:InvalidLoad","%s must be a finite global vector.",label);end
end
function f=nodalLoads(model,loads,n)
    f=zeros(n,1);
    if istable(loads)
        ids=loads.nodeId;values=loads{:,2:7};
    elseif isstruct(loads)
        ids=[loads.nodeId].';
        if numel(loads)>1,values=vertcat(loads.values);else,values=loads.values;end
    else,error("assembly:assemble_load_vector:InvalidNodalLoads","Nodal loads must be a table or struct.");end
    for k=1:numel(ids),dofs=nodeDofs(model,double(ids(k)));f(dofs)=f(dofs)+double(values(k,:)).';end
end
