function timeResults = recover_full_response(timeResults, analysisOps, modelData)
%RECOVER_FULL_RESPONSE Recover full nodal states and equilibrium residuals.
%   Optional analysisOps.Tdot/Tddot retain the physical derivatives of a
%   moving constraint map: v=T*qd+Tdot*q and
%   a=T*qdd+2*Tdot*qd+Tddot*q. Missing derivatives mean a constant map.
%   T, Tdot, and Tddot are one supplied operating-point snapshot. Applying
%   them to a history does not advance the geometry or integrate an LTV
%   system; the full states are snapshot reconstructions of that history.

T = analysisOps.Tc;
if ~isnumeric(T)||~ismatrix(T)||any(~isfinite(nonzeros(T)))|| ...
        size(T,2)~=size(timeResults.q,1)
    error('dynamics:RecoverFull:InvalidTransformation', ...
        'Tc must be finite with one column per analysis coordinate.');
end
Tdot=transformationDerivative(analysisOps,'Tdot',size(T));
Tddot=transformationDerivative(analysisOps,'Tddot',size(T));
timeResults.qReduced = timeResults.q;
timeResults.qdReduced = timeResults.qd;
timeResults.qddReduced = timeResults.qdd;
timeResults.qFull = T*timeResults.q;
timeResults.qdFull = T*timeResults.qd+Tdot*timeResults.q;
timeResults.qddFull = T*timeResults.qdd+2*Tdot*timeResults.qd+Tddot*timeResults.q;
timeResults.fullRelative=struct('t',timeResults.t,'q',timeResults.qFull, ...
    'qd',timeResults.qdFull,'qdd',timeResults.qddFull);
timeResults.kinematicRecovery=struct('available',true, ...
    'hasMovingConstraintDerivatives',nnz(Tdot)>0||nnz(Tddot)>0, ...
    'transformationPolicy',"single_operating_point_snapshot", ...
    'velocityFormula',"vFull=Tc*qd+Tdot*q", ...
    'accelerationFormula',"aFull=Tc*qdd+2*Tdot*qd+Tddot*q", ...
    'interpretation', ...
    "snapshot nodal kinematics; no evolving transformation history is reconstructed");

if ~isfield(timeResults,'accelerogram') || ~isfield(timeResults.accelerogram,'acceleration')
    return
end
ag = timeResults.accelerogram.acceleration;
nComponents = size(ag,2);
if isfield(timeResults,'GammaFullAbsolute')&& ...
        isequal(size(timeResults.GammaFullAbsolute),[size(T,1) nComponents])
    GammaFull=timeResults.GammaFullAbsolute;
else
    fullModel=modelData;
    if isfield(fullModel,'Tc'),fullModel=rmfield(fullModel,'Tc');end
    directions=1:nComponents;
    if isfield(timeResults,'directions'),directions=timeResults.directions;end
    GammaFull = dynamics.influence_vector(fullModel,directions,size(T,1));
end
timeResults.GammaFull = GammaFull;
absolute=dynamics.recover_absolute_response( ...
    timeResults.fullRelative,GammaFull,timeResults.accelerogram);
timeResults.absoluteDisplacementFull=absolute.absoluteDisplacement;
timeResults.absoluteVelocityFull=absolute.absoluteVelocity;
timeResults.absoluteAccelerationFull=absolute.absoluteAcceleration;

required = {'Mfull','Dfull','Kfull'};
if ~all(isfield(analysisOps,required)), return; end
if isfield(timeResults,'reactionDiagnostics')&& ...
        isfield(timeResults.reactionDiagnostics,'available')&& ...
        timeResults.reactionDiagnostics.available
    residualFull=timeResults.reactionDiagnostics.constraintForcesFull;
    timeResults.fullEquilibriumResidual=residualFull;
    timeResults.constraintForcesFull=residualFull;
    timeResults.reactionsFull=residualFull;
    timeResults.reactions=residualFull(modelData.dofs.fixed,:);
    return
end
baseForceFull = -(analysisOps.Mfull*GammaFull)*ag.';
otherReduced = zeros(size(timeResults.q));
if isfield(timeResults,'otherForce'), otherReduced = timeResults.otherForce; end
otherFull=zeros(size(baseForceFull));
if any(otherReduced,'all')
    if ~isfield(timeResults,'otherForceFull')||isempty(timeResults.otherForceFull)
        error('dynamics:RecoverFull:AmbiguousOtherForce', ...
            'Full recovery requires otherForceFull for nonzero reduced loads.');
    end
    otherFull=timeResults.otherForceFull;
end
residualFull = analysisOps.Mfull*timeResults.qddFull + ...
    analysisOps.Dfull*timeResults.qdFull + ...
    analysisOps.Kfull*timeResults.qFull - baseForceFull - otherFull;
timeResults.fullEquilibriumResidual = residualFull;
timeResults.constraintForcesFull=residualFull;
timeResults.reactionsFull = residualFull;
timeResults.reactions = residualFull(modelData.dofs.fixed,:);
end

function derivative=transformationDerivative(ops,name,expectedSize)
derivative=sparse(expectedSize(1),expectedSize(2));
if isfield(ops,name)&&~isempty(ops.(name)),derivative=ops.(name);end
if ~isnumeric(derivative)||~isequal(size(derivative),expectedSize)|| ...
        any(~isfinite(nonzeros(derivative)))
    error('dynamics:RecoverFull:InvalidTransformationDerivative', ...
        '%s must be finite and have the same dimensions as Tc.',name);
end
end
