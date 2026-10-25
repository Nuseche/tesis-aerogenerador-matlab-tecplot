function [G,report] = assemble_gyroscopic_matrix(model,state,cfg)
%ASSEMBLE_GYROSCOPIC_MATRIX Gyroscopic part in inertial nodal coordinates.
%   Corotating energy operators are transported BEFORE global constraints.
%   D_inertia=G+massRate, with massRate=dM/dt symmetric. The accompanying
%   Ktransport belongs to the same change of coordinates and must be kept.

if nargin<2||isempty(state),state=struct();end
if nargin<3,cfg=struct();end
[ndof,ne]=model_size(model);omega=angularVelocity(model,state,cfg);
includeBlades=logicalOption(cfg,{'gyroscopic','includeDistributedBlades'},true);
Gdistributed=sparse(ndof,ndof);Grigid=sparse(ndof,ndof);
Gexternal=sparse(ndof,ndof);
massRate=sparse(ndof,ndof);Ktransport=sparse(ndof,ndof);
Gcorotating=sparse(ndof,ndof);rotatingMass=sparse(ndof,ndof);
elementReport=repmat(struct('elementId',NaN,'blade',NaN, ...
    'norm',0,'skewError',0),0,1);

if includeBlades
    for e=1:ne
        c=element_context(model,e);
        if ~c.active||~isfinite(c.blade)||c.blade<=0,continue,end
        [ge,d]=elements.timoshenko_gyroscopic_matrix( ...
            c.xI,c.xJ,c.auxPoint,c.section,omega,cfg);
        t=assembly.transport_rotating_operators(d.mass,ge,omega);
        Gdistributed(c.dofs,c.dofs)=Gdistributed(c.dofs,c.dofs)+t.G;
        massRate(c.dofs,c.dofs)=massRate(c.dofs,c.dofs)+t.massRate;
        Ktransport(c.dofs,c.dofs)=Ktransport(c.dofs,c.dofs)+t.Ktransport;
        Gcorotating(c.dofs,c.dofs)=Gcorotating(c.dofs,c.dofs)+ge;
        rotatingMass(c.dofs,c.dofs)=rotatingMass(c.dofs,c.dofs)+d.mass;
        elementReport(end+1,1)=struct('elementId',c.id, ...
            'blade',c.blade,'norm',norm(t.G,'fro'), ...
            'skewError',relativeSkew(t.G)); %#ok<AGROW>
    end
end

bodies=bodyList(model);
bodyReport=repmat(struct('name',"",'masterNode',NaN, ...
    'norm',0,'skewError',0,'spatialMass',sparse(6,6)),0,1);
for k=1:numel(bodies)
    body=bodies(k);master=getMaster(body);
    if ~isRotating(body,master),continue,end
    [MR,~]=rigid.rigid_body_mass_matrix(body);
    [gb,d]=assembly.rotating_mass_gyroscopic_matrix(MR,omega);
    t=assembly.transport_rotating_operators(MR,gb,omega);
    dofs=getNodeDofs(model,master);
    Grigid(dofs,dofs)=Grigid(dofs,dofs)+t.G;
    massRate(dofs,dofs)=massRate(dofs,dofs)+t.massRate;
    Ktransport(dofs,dofs)=Ktransport(dofs,dofs)+t.Ktransport;
    Gcorotating(dofs,dofs)=Gcorotating(dofs,dofs)+gb;
    rotatingMass(dofs,dofs)=rotatingMass(dofs,dofs)+MR;
    bodyReport(end+1,1)=struct('name',string(optional(body,'name','body')), ...
        'masterNode',master,'norm',norm(t.G,'fro'),'skewError',relativeSkew(t.G), ...
        'spatialMass',sparse(MR)); %#ok<AGROW>
end

if isfield(state,'elementGyroscopicMatrices')&& ...
        ~isempty(state.elementGyroscopicMatrices)
    cells=state.elementGyroscopicMatrices;
    if ~iscell(cells)||numel(cells)~=ne
        error('assembly:assemble_gyroscopic_matrix:InvalidElementTerms', ...
            'Expected one optional gyroscopic matrix per element.');
    end
    for e=1:ne
        if isempty(cells{e}),continue,end
        c=element_context(model,e);ge=sparse(cells{e});
        if ~isequal(size(ge),[12 12])||any(~isfinite(nonzeros(ge)))
            error('assembly:assemble_gyroscopic_matrix:InvalidElementTerm', ...
                'Element gyroscopic matrix %d has invalid size or values.',e);
        end
        requireSkew(ge,sprintf('element %d',e));
        Gexternal(c.dofs,c.dofs)=Gexternal(c.dofs,c.dofs)+ge;
    end
end
if isfield(state,'Gexternal')&&~isempty(state.Gexternal)
    supplied=sparse(state.Gexternal);
    if ~isequal(size(supplied),[ndof ndof])||any(~isfinite(nonzeros(supplied)))
        error('assembly:assemble_gyroscopic_matrix:InvalidGlobalTerm', ...
            'state.Gexternal must be a finite global matrix.');
    end
    requireSkew(supplied,'global external term');
    Gexternal=Gexternal+supplied;
end

G=Gdistributed+Grigid+Gexternal;
requireSkew(G,'assembled global operator');G=(G-G.')/2;
bladeIds=unique([elementReport.blade]);
bladeNorms=zeros(numel(bladeIds),1);
for index=1:numel(bladeIds)
    bladeNorms(index)=normForBlade( ...
        model,elementReport,bladeIds(index),omega,cfg);
end
report=struct('omega',omega,'formula', ...
    "G_inertial=G_corotating-Mrot*W-W*Mrot; D_inertia=G_inertial+Mdot", ...
    'coordinateFrame',"inertial_snapshot",'massRate',massRate, ...
    'Ktransport',Ktransport,'Gcorotating',Gcorotating, ...
    'rotatingMass',rotatingMass, ...
    'includeDistributedBlades',includeBlades,'elements',elementReport, ...
    'bodies',bodyReport,'bladeIds',bladeIds(:),'bladeNorms',bladeNorms, ...
    'distributedNorm',norm(Gdistributed,'fro'), ...
    'rigidNorm',norm(Grigid,'fro'),'externalNorm',norm(Gexternal,'fro'), ...
    'totalNorm',norm(G,'fro'),'skewError',relativeSkew(G), ...
    'components',struct('distributed',Gdistributed,'rigid',Grigid, ...
    'external',Gexternal));
end

function value=normForBlade(model,reports,blade,omega,cfg)
[n,~]=model_size(model);A=sparse(n,n);rows=find([reports.blade]==blade);
for row=rows
    elementRow=find(double(model.mesh.elements.id(:))==reports(row).elementId,1);
    c=element_context(model,elementRow);
    [ge,d]=elements.timoshenko_gyroscopic_matrix( ...
        c.xI,c.xJ,c.auxPoint,c.section,omega,cfg);
    t=assembly.transport_rotating_operators(d.mass,ge,omega);
    A(c.dofs,c.dofs)=A(c.dofs,c.dofs)+t.G;
end
value=norm(A,'fro');
end

function omega=angularVelocity(model,state,cfg)
if isfield(state,'angularVelocity'),value=state.angularVelocity;
elseif isfield(state,'omega'),value=state.omega;
elseif isfield(cfg,'rotor')&&isfield(cfg.rotor,'speedRadPerSec')
    value=cfg.rotor.speedRadPerSec;
elseif isfield(cfg,'rotor')&&isfield(cfg.rotor,'speedRPM')
    value=cfg.rotor.speedRPM*2*pi/60;
else,value=0;end
if isscalar(value)
    axis=[1;0;0];
    if isfield(model,'rotorAxis')&&isfield(model.rotorAxis,'direction')
        axis=double(model.rotorAxis.direction(:));
    end
    if numel(axis)~=3||any(~isfinite(axis))||norm(axis)==0
        error('assembly:assemble_gyroscopic_matrix:InvalidAxis', ...
            'The rotor axis must be a finite nonzero 3-vector.');
    end
    omega=double(value)*axis/norm(axis);
else
    omega=double(value(:));
    if numel(omega)~=3||any(~isfinite(omega))
        error('assembly:assemble_gyroscopic_matrix:InvalidOmega', ...
            'Angular velocity must be a finite scalar or 3-vector.');
    end
end
end

function list=bodyList(model)
list=struct([]);
if ~isfield(model,'rigidBodies'),return,end
rb=model.rigidBodies;if isfield(rb,'bodies'),list=rb.bodies;else,list=rb;end
list=list(:);
end

function tf=isRotating(body,master)
if isfield(body,'rotating'),tf=logical(body.rotating);else,tf=(master==130);end
end

function master=getMaster(body)
if isfield(body,'masterNode'),master=double(body.masterNode);
elseif isfield(body,'node'),master=double(body.node);
else,error('assembly:assemble_gyroscopic_matrix:MissingBodyMaster', ...
        'Rigid body requires masterNode.');end
end

function dofs=getNodeDofs(model,id)
row=find(double(model.mesh.nodes.id(:))==id,1);
if isempty(row),error('assembly:assemble_gyroscopic_matrix:UnknownBodyMaster', ...
        'Unknown master node %g.',id);end
if isfield(model,'dofs')&&isfield(model.dofs,'node')
    dofs=double(model.dofs.node(row,:));
else,dofs=6*(row-1)+(1:6);end
end

function requireSkew(A,label)
errorValue=relativeSkew(A);
if errorValue>1e-12
    error('assembly:assemble_gyroscopic_matrix:NonSkew', ...
        '%s is not skew-symmetric (relative error %.3e).',label,errorValue);
end
end

function value=relativeSkew(A)
value=norm(A+A.','fro')/max(norm(A,'fro'),eps);
end

function value=optional(s,name,fallback)
if isfield(s,name)&&~isempty(s.(name)),value=s.(name);else,value=fallback;end
end

function value=logicalOption(cfg,path,fallback)
value=fallback;cursor=cfg;
for index=1:numel(path)
    if ~isstruct(cursor)||~isfield(cursor,path{index}),return,end
    cursor=cursor.(path{index});
end
if ~isscalar(cursor),error('assembly:assemble_gyroscopic_matrix:InvalidOption', ...
        'Logical options must be scalar.');end
value=logical(cursor);
end
