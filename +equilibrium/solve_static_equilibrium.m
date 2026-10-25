function state=solve_static_equilibrium(model,reduced,cfg)
%SOLVE_STATIC_EQUILIBRIUM Newton solution with configuration-dependent loads.
%   The residual is fExternal(q)-fInternal(q). The correction tangent is
%   Kinternal-dfExternal/dq and a backtracking line search is applied on the
%   independent free coordinates.

if nargin<3,cfg=struct();end
Tc=sparse(reduced.Tc);n=size(Tc,2);
if isfield(reduced,'free'),free=double(reduced.free(:));else,free=(1:n).';end
fixed=setdiff((1:n).',free,'stable');
eq=struct();if isfield(cfg,'equilibrium'),eq=cfg.equilibrium;end
hasCustomForce=isfield(eq,'internalForceFcn')&&~isempty(eq.internalForceFcn);
hasCustomTangent=isfield(eq,'tangentFcn')&&~isempty(eq.tangentFcn);
if ~hasCustomForce&&~hasCustomTangent
    [~,KbeamZero]=equilibrium.total_lagrangian_internal_force( ...
        model,zeros(size(Tc,1),1),cfg);
    eq.linearExtraStiffness=sparse(reduced.full.Ke)-KbeamZero;
end
q=zeros(n,1);
if isfield(eq,'initialQ')&&~isempty(eq.initialQ)
    if numel(eq.initialQ)~=n||any(~isfinite(eq.initialQ))
        error('equilibrium:solve_static_equilibrium:InvalidInitialState', ...
            'equilibrium.initialQ must be a finite reduced vector.');
    end
    q=double(eq.initialQ(:));
end
q(fixed)=0;
tolerance=scalarOptionAliases(eq,["tolerance","relativeTolerance"],1e-9);
maxIterations=round(scalarOptionAliases(eq, ...
    ["maxIterations","maximumIterations"],30));
maxLineSearch=round(localOption(eq,'maximumLineSearchReductions',10));
history=zeros(maxIterations,4);converged=false;

for iteration=1:maxIterations
    evaluation=localEvaluate(model,Tc,q,reduced,eq,cfg,free);
    history(iteration,1:2)=[iteration evaluation.relativeResidual];
    if evaluation.relativeResidual<=tolerance
        converged=true;history(iteration,3:4)=[0 0];break
    end
    tangentReduced=Tc.'*evaluation.tangentFull*Tc;
    if isempty(free)
        converged=true;history(iteration,3:4)=[0 0];break
    end
    correction=tangentReduced(free,free)\evaluation.residualReduced(free);
    if any(~isfinite(correction))
        error('equilibrium:solve_static_equilibrium:InvalidCorrection', ...
            'Newton correction contains nonfinite values.');
    end
    alpha=1;accepted=false;trial=evaluation;
    for reduction=0:maxLineSearch %#ok<NASGU>
        qTrial=q;qTrial(free)=q(free)+alpha*correction;qTrial(fixed)=0;
        trial=localEvaluate(model,Tc,qTrial,reduced,eq,cfg,free);
        sufficient=trial.relativeResidual <= ...
            evaluation.relativeResidual*(1-1e-4*alpha);
        if sufficient||trial.relativeResidual<tolerance
            accepted=true;break
        end
        alpha=alpha/2;
    end
    if ~accepted
        error('equilibrium:solve_static_equilibrium:LineSearchFailure', ...
            ['Newton line search could not reduce the residual from %.3e; ' ...
             'last trial %.3e.'],evaluation.relativeResidual, ...
            trial.relativeResidual);
    end
    q=qTrial;
    history(iteration,3:4)=[alpha norm(alpha*correction)];
end
if ~converged
    evaluation=localEvaluate(model,Tc,q,reduced,eq,cfg,free);
    if evaluation.relativeResidual<=tolerance
        converged=true;
    else
        error('equilibrium:solve_static_equilibrium:NoConvergence', ...
            ['Static equilibrium did not converge: residual %.3e exceeds ' ...
             'tolerance %.3e after %d iterations.'], ...
            evaluation.relativeResidual,tolerance,maxIterations);
    end
end

evaluation=localEvaluate(model,Tc,q,reduced,eq,cfg,free);
qFull=Tc*q;
reactionFull=evaluation.fInternal-evaluation.fExternal;
externalResultant=localResultant(model,evaluation.fExternal,qFull);
reactionResultant=localResultant(model,reactionFull,qFull);
internalResultant=localResultant(model,evaluation.fInternal,qFull);
globalBalanceError=norm(externalResultant+reactionResultant)/ ...
    max(norm(externalResultant),1);
algebraicBalanceError=norm(externalResultant+reactionResultant- ...
    internalResultant)/max([norm(externalResultant),norm(internalResultant),1]);

axial=evaluation.internalDetails.elementAxialForces;
gravityAxial=axial;
centrifugalAxial=zeros(size(axial));
if isfield(eq,'gravityAxialReference')&& ...
        numel(eq.gravityAxialReference)==numel(axial)
    gravityAxial=double(eq.gravityAxialReference(:));
    centrifugalAxial=axial-gravityAxial;
elseif localRotorSpeed(cfg)~=0
    gravityAxial=nan(size(axial));
    centrifugalAxial=nan(size(axial));
end

state=struct('q',q,'qReduced',q,'qFull',qFull, ...
    'loadFull',evaluation.fExternal,'loadReduced', ...
    Tc.'*evaluation.fExternal,'internalForceFull',evaluation.fInternal, ...
    'reactionFull',reactionFull,'internalTangentFull', ...
    evaluation.Kinternal,'externalLoadTangentFull',evaluation.Kexternal, ...
    'tangentFull',evaluation.tangentFull, ...
    'elementAxialForces',axial,'elementGravityAxialForces',gravityAxial, ...
    'elementCentrifugalAxialForces',centrifugalAxial, ...
    'elementGreenStrain',evaluation.internalDetails.elementGreenStrain, ...
    'residualRelative',evaluation.relativeResidual,'iterations',iteration, ...
    'converged',converged,'history',history(1:iteration,:), ...
    'historyColumns',["iteration","relativeResidual","stepLength", ...
    "correctionNorm"],'loadParts',evaluation.loadParts, ...
    'externalResultant',externalResultant,'reactionResultant',reactionResultant, ...
    'internalResultant',internalResultant, ...
    'globalBalanceError',globalBalanceError, ...
    'algebraicBalanceError',algebraicBalanceError, ...
    'aerodynamicStiffnessFull',evaluation.loadParts.aerodynamicStiffness, ...
    'aerodynamicDampingFull',evaluation.loadParts.aerodynamicDamping, ...
    'stiffnessSourceLedger',struct( ...
    'elastic',"accepted Timoshenko Ke", ...
    'internalGeometric',"numerical Hessian of corotational small-strain energy", ...
    'centrifugal',"subtracted external-load Jacobian", ...
    'aerodynamic',"Kaero=-df_a/dq retained separately from Kg", ...
    'operatingStorage',"combined once as Kg=tangentFull-Ke; KOmega=0"), ...
    'centrifugalIncludedInKg',true, ...
    'formulation',evaluation.internalDetails.formulation, ...
    'rotationRange',evaluation.internalDetails.rotationRange);
end

function evaluation=localEvaluate(model,Tc,q,reduced,eq,cfg,free)
qFull=Tc*q;
loadState=struct('qFull',qFull);
if isfield(cfg,'rotor')&&isfield(cfg.rotor,'speedRPM')
    loadState.angularVelocity=double(cfg.rotor.speedRPM)*2*pi/60* ...
        model.rotorAxis.direction(:);
end
[fExternal,loadParts,Kexternal]= ...
    assembly.assemble_load_vector(model,cfg,loadState);
[fInternal,Kinternal,internalDetails]=localInternal( ...
    model,qFull,reduced,eq,cfg);
residualFull=fExternal-fInternal;
residualReduced=Tc.'*residualFull;
internalReduced=Tc.'*fInternal;
externalReduced=Tc.'*fExternal;
denominator=max([1,norm(externalReduced(free)),norm(internalReduced(free))]);
relativeResidual=norm(residualReduced(free))/denominator;
evaluation=struct('fExternal',fExternal,'fInternal',fInternal, ...
    'Kexternal',Kexternal,'Kinternal',Kinternal, ...
    'tangentFull',Kinternal-Kexternal,'residualFull',residualFull, ...
    'residualReduced',residualReduced,'relativeResidual',relativeResidual, ...
    'loadParts',loadParts,'internalDetails',internalDetails);
end

function [fInternal,Kinternal,details]=localInternal(model,qFull,reduced,eq,cfg)
hasForce=isfield(eq,'internalForceFcn')&&~isempty(eq.internalForceFcn);
hasTangent=isfield(eq,'tangentFcn')&&~isempty(eq.tangentFcn);
if xor(hasForce,hasTangent)
    error('equilibrium:solve_static_equilibrium:IncompleteNonlinearCallbacks', ...
        'Custom equilibrium requires both internalForceFcn and tangentFcn.');
end
if hasForce
    fInternal=double(eq.internalForceFcn(qFull,model,cfg));
    Kinternal=sparse(eq.tangentFcn(qFull,model,cfg));
    [~,~,details]=equilibrium.total_lagrangian_internal_force(model,qFull,cfg);
    details.formulation="user callbacks";
else
    [fInternal,Kinternal,details]= ...
        equilibrium.total_lagrangian_internal_force(model,qFull,cfg);
    if isfield(eq,'linearExtraStiffness')
        Kextra=sparse(eq.linearExtraStiffness);
        fInternal=fInternal+Kextra*qFull;
        Kinternal=Kinternal+Kextra;
        details.linearExtraStiffnessNorm=norm(Kextra,'fro');
    end
end
if numel(fInternal)~=size(reduced.full.Ke,1)|| ...
        ~isequal(size(Kinternal),size(reduced.full.Ke))|| ...
        any(~isfinite(fInternal))||any(~isfinite(nonzeros(Kinternal)))
    error('equilibrium:solve_static_equilibrium:InvalidInternalOperator', ...
        'Internal force/tangent dimensions or coefficients are invalid.');
end
fInternal=sparse(fInternal(:));
end

function resultant=localResultant(model,forceVector,qFull)
ids=double(model.mesh.nodes.id(:));xyz=double(model.mesh.nodes.xyz);
if isfield(model,'dofs')&&isfield(model.dofs,'node')
    map=double(model.dofs.node);
else
    map=reshape(1:6*numel(ids),6,[]).';
end
force=zeros(3,1);moment=zeros(3,1);
for node=1:numel(ids)
    nodal=full(forceVector(map(node,:)));
    force=force+nodal(1:3);
    currentPosition=xyz(node,:).'+qFull(map(node,1:3));
    moment=moment+nodal(4:6)+cross(currentPosition,nodal(1:3));
end
resultant=[force;moment];
end

function speed=localRotorSpeed(cfg)
speed=0;
if isfield(cfg,'rotor')&&isfield(cfg.rotor,'speedRPM')
    speed=double(cfg.rotor.speedRPM);
end
end

function value=localOption(s,name,defaultValue)
value=defaultValue;
if isfield(s,name),value=double(s.(name));end
if ~isscalar(value)||~isfinite(value)||value<0
    error('equilibrium:solve_static_equilibrium:InvalidOption', ...
        '%s must be a finite nonnegative scalar.',name);
end
end

function value=scalarOptionAliases(s,names,defaultValue)
value=defaultValue;chosen=names(1);
for name=names
    if isfield(s,name),value=double(s.(name));chosen=name;break,end
end
if ~isscalar(value)||~isfinite(value)||value<=0
    error('equilibrium:solve_static_equilibrium:InvalidOption', ...
        '%s must be positive and finite.',chosen);
end
end
