function results = run_seismic_analysis(ops, modelData, cfg)
%RUN_SEISMIC_ANALYSIS Integrate relative base-excited structural response.
%   M*qdd + D*qd + K*q = -M*Gamma*ag + fOther.
%   Matrices and constraint-map derivatives are frozen at the supplied
%   operating point. Physical snapshot recovery retains Tdot/Tddot, but
%   this routine does not integrate time-varying (LTV) rotating operators.

arguments
    ops struct
    modelData = struct()
    cfg = struct()
end

analysisOps = selectAnalysisOps(ops);
[M,D,K] = extractMatrices(analysisOps);
n = size(M,1);
seismicCfg = nestedStruct(cfg,'seismic');
newmarkCfg = nestedStruct(cfg,'newmark');
if isempty(fieldnames(newmarkCfg)) && isfield(seismicCfg,'newmark'), newmarkCfg = seismicCfg.newmark; end

source = getOption(seismicCfg,{'record','accelerogram','file','filename','path'},[]);
if isempty(source) && isfield(ops,'accelerogram'), source = ops.accelerogram; end
if isempty(source), error('dynamics:Seismic:MissingRecord','cfg.seismic must supply a record or file.'); end
if isstruct(source) && ~any(isfield(source,{'t','time','acceleration','a','ag','data'}))
    nestedSource = getOption(source,{'record','file','filename','path'},[]);
    if ~isempty(nestedSource)
        nestedFields = fieldnames(source);
        for nestedIndex = 1:numel(nestedFields)
            if ~isfield(seismicCfg,nestedFields{nestedIndex})
                seismicCfg.(nestedFields{nestedIndex}) = source.(nestedFields{nestedIndex});
            end
        end
        source = nestedSource;
    end
end

loadOptions = seismicCfg;
targetDt = getOption(newmarkCfg,{'dt','timeStep'},getOption(seismicCfg,{'dt','targetDt'},[]));
if ~isempty(targetDt), loadOptions.targetDt = targetDt; end
record = io.load_accelerogram(source,loadOptions);
t = record.t;
ag = record.acceleration;
directions = getOption(seismicCfg,{'directions','components','direction'},1:size(ag,2));

influenceDiagnostics=struct();GammaKinematic=[];GammaFullAbsolute=[];
if isfield(analysisOps,'Gamma') && ~isempty(analysisOps.Gamma)
    Gamma = analysisOps.Gamma;
    influenceDiagnostics.source="provided_effective_influence";
elseif isfield(ops,'Gamma') && ~isempty(ops.Gamma)
    Gamma = ops.Gamma;
    influenceDiagnostics.source="provided_effective_influence";
else
    influenceModel = modelData;
    if isfield(analysisOps,'Tc') && size(analysisOps.Tc,2) == n
        influenceModel.Tc = analysisOps.Tc;
    elseif isfield(ops,'Tc') && size(ops.Tc,2) == n
        influenceModel.Tc = ops.Tc;
    end
    [GammaKinematic,kinematicDiagnostics] = ...
        dynamics.influence_vector(influenceModel,directions,n);
    [Gamma,GammaFullAbsolute,massDiagnostics]=massConsistentInfluence( ...
        ops,analysisOps,modelData,M,directions,GammaKinematic);
    influenceDiagnostics=struct('source',massDiagnostics.source, ...
        'kinematic',kinematicDiagnostics,'massProjection',massDiagnostics);
end
if isempty(GammaKinematic)
    if isfield(analysisOps,'GammaKinematic')&&~isempty(analysisOps.GammaKinematic)
        GammaKinematic=analysisOps.GammaKinematic;
    elseif isfield(ops,'GammaKinematic')&&~isempty(ops.GammaKinematic)
        GammaKinematic=ops.GammaKinematic;
    else
        influenceModel=modelData;
        TcProvided=pick(analysisOps,{'Tc'});if isempty(TcProvided),TcProvided=pick(ops,{'Tc'});end
        if ~isempty(TcProvided),influenceModel.Tc=TcProvided;end
        GammaKinematic=dynamics.influence_vector(influenceModel,directions,n);
    end
end
if size(Gamma,1) ~= n || size(Gamma,2) ~= size(ag,2)
    error('dynamics:Seismic:InfluenceMismatch','Gamma must be nDof-by-numberOfComponents.');
end

baseForceOperator=M*Gamma;
baseForce = -baseForceOperator*ag.';
[otherForce,otherForceFull] = resolveOtherForce( ...
    ops,analysisOps,seismicCfg,t,n);
totalForce = baseForce + otherForce;
relative = dynamics.newmark_integrate(M,D,K,t,totalForce,newmarkCfg);
absolute = dynamics.recover_absolute_response(relative,GammaKinematic,record);

results = relative;
results.relative = struct('q',relative.q,'qd',relative.qd,'qdd',relative.qdd);
results.absoluteDisplacement = absolute.absoluteDisplacement;
results.absoluteVelocity = absolute.absoluteVelocity;
results.absoluteAcceleration = absolute.absoluteAcceleration;
results.Gamma = Gamma;
results.directions=directions;
results.GammaEffective = Gamma;
results.GammaKinematic = GammaKinematic;
results.GammaFullAbsolute = GammaFullAbsolute;
results.influenceDiagnostics = influenceDiagnostics;
results.baseForceOperator=baseForceOperator;
results.baseForce = baseForce;
results.otherForce = otherForce;
results.otherForceFull = otherForceFull;
results.accelerogram = record;
[results.reactions,results.reactionDiagnostics,results.fullRelative, ...
    results.kinematicRecovery] = calculateReactions( ...
    ops,analysisOps,modelData,relative,otherForce,otherForceFull,ag,directions);
results.integrationMetadata=struct('operatorPolicy',"frozen_operating_point", ...
    'isLTVIntegration',false,'operatorsUpdatedDuringIntegration',false, ...
    'constraintDerivativePolicy',"retain supplied snapshot Tdot and Tddot", ...
    'reducedAbsoluteStateInterpretation', ...
    "coordinate-wise relative-plus-base values; use full states for physical nodal kinematics");
end

function [reactions,diagnostics,fullRelative,kinematicRecovery] = calculateReactions(ops,analysisOps, ...
        modelData,response,otherForce,otherForceFull,ag,directions)
% Exact support reactions require unreduced matrices/Tc. Preserve a useful
% equilibrium residual when only the reduced system is available.
Tc=pick(analysisOps,{'Tc'});if isempty(Tc),Tc=pick(ops,{'Tc'});end
fullRelative=struct('t',response.t,'q',zeros(0,numel(response.t)), ...
    'qd',zeros(0,numel(response.t)),'qdd',zeros(0,numel(response.t)));
kinematicRecovery=struct('available',false,'interpretation', ...
    "full kinematics unavailable without a constraint transformation");
if ~isempty(Tc)
    recoveryOps=struct('Tc',Tc);
    derivativeNames={'Tdot','Tddot'};
    for derivativeIndex=1:numel(derivativeNames)
        name=derivativeNames{derivativeIndex};
        derivative=pick(analysisOps,{name});
        if isempty(derivative),derivative=pick(ops,{name});end
        if ~isempty(derivative),recoveryOps.(name)=derivative;end
    end
    % response has no accelerogram here: the shared function only recovers
    % the relative kinematic snapshot, without attempting force recovery.
    recovered=dynamics.recover_full_response(response,recoveryOps,modelData);
    fullRelative=recovered.fullRelative;
    kinematicRecovery=recovered.kinematicRecovery;
end
Mfull = pick(analysisOps,{'Mfull'});Dfull=pick(analysisOps,{'Dfull'});
Kfull=pick(analysisOps,{'Kfull'});
if isempty(Mfull),Mfull=pick(ops,{'Mfull'});end
if isempty(Dfull),Dfull=pick(ops,{'Dfull'});end
if isempty(Kfull),Kfull=pick(ops,{'Kfull'});end
if isfield(ops,'full') && isstruct(ops.full)
    if isempty(Mfull), Mfull = pick(ops.full,{'M','mass'}); end
    if isempty(Dfull), Dfull = pick(ops.full,{'D','Ctotal','C'}); end
    if isempty(Kfull), Kfull = pick(ops.full,{'K','Kt','Ktotal'}); end
end
if ~isempty(Tc) && ~isempty(Mfull) && ~isempty(Kfull)
    if isempty(Dfull), Dfull = sparse(size(Mfull,1),size(Mfull,1)); end
    q=fullRelative.q;qd=fullRelative.qd;qdd=fullRelative.qdd;
    fullModel = modelData;
    if isfield(fullModel,'Tc'), fullModel = rmfield(fullModel,'Tc'); end
    GammaFull = dynamics.influence_vector(fullModel,directions,size(Mfull,1));
    fullForce = -(Mfull*GammaFull)*ag.';
    if ~isempty(otherForceFull)
        projectionError=norm(Tc.'*otherForceFull-otherForce,'fro')/ ...
            max([norm(otherForce,'fro'),norm(Tc.'*otherForceFull,'fro'),eps]);
        if projectionError>1e-10
            error('dynamics:Seismic:IncompatibleFullOtherForce', ...
                'Tc''*otherForceFull does not reproduce otherForce.');
        end
        fullForce=fullForce+otherForceFull;
    elseif any(otherForce,'all')
        if isempty(otherForceFull)
            error('dynamics:Seismic:AmbiguousFullOtherForce', ...
                ['Full reactions require otherForceFull whenever a reduced ' ...
                 'nonseismic force is applied.']);
        end
    else
        projectionError=0;
    end
    reactions = Mfull*qdd + Dfull*qd + Kfull*q - fullForce;
    projected=Tc.'*reactions;
    projectedTerms={Tc.'*(Mfull*qdd),Tc.'*(Dfull*qd), ...
        Tc.'*(Kfull*q),Tc.'*fullForce};
    columnNorm=@(A)sqrt(sum(abs(A).^2,1));
    scale=columnNorm(projectedTerms{1})+columnNorm(projectedTerms{2})+ ...
        columnNorm(projectedTerms{3})+columnNorm(projectedTerms{4});
    projectedRelative=columnNorm(projected)./max(scale,eps);
    diagnostics=struct('available',true,'constraintForcesFull',reactions, ...
        'projectedResidual',projected,'relativeProjectedResidual', ...
        max(projectedRelative), ...
        'otherForceProjectionError',projectionError, ...
        'kinematicRecovery',kinematicRecovery, ...
        'interpretation', ...
        "frozen-snapshot full residual contains support and MPC generalized constraint forces");
    return
end
reactions = [];
diagnostics=struct('available',false,'constraintForcesFull',zeros(0,0), ...
    'projectedResidual',response.equilibriumResidual, ...
    'relativeProjectedResidual',max(response.relativeResidual), ...
    'otherForceProjectionError',NaN,'interpretation', ...
    "no physical reactions available; projectedResidual is reduced equilibrium only");
end

function [F,Ffull] = resolveOtherForce(ops,analysisOps,seismicCfg,t,n)
source = [];
if isfield(ops,'forceTime'), source = ops.forceTime;
elseif isfield(ops,'force'), source = ops.force;
elseif isfield(seismicCfg,'otherForce'), source = seismicCfg.otherForce;
end
if isempty(source), F = zeros(n,numel(t));
else
if isa(source,'function_handle')
    F = zeros(n,numel(t)); for k = 1:numel(t), F(:,k) = source(t(k)); end
elseif isequal(size(source),[n numel(t)]), F = source;
elseif isequal(size(source),[numel(t) n]), F = source.';
else, error('dynamics:Seismic:InvalidOtherForce','Other force has incompatible dimensions.');
end
end
fullSource=[];
if isfield(ops,'otherForceFull'),fullSource=ops.otherForceFull;
elseif isfield(ops,'forceTimeFull'),fullSource=ops.forceTimeFull;
elseif isfield(analysisOps,'otherForceFull'),fullSource=analysisOps.otherForceFull;
elseif isfield(seismicCfg,'otherForceFull'),fullSource=seismicCfg.otherForceFull;
end
if isempty(fullSource),Ffull=[];return,end
nFull=size(pick(analysisOps,{'Mfull'}),1);
if nFull==0,nFull=size(pick(ops,{'Mfull'}),1);end
if nFull==0&&isfield(ops,'full')&&isstruct(ops.full)
    nFull=size(pick(ops.full,{'M','mass'}),1);
end
if isa(fullSource,'function_handle')
    Ffull=zeros(nFull,numel(t));
    for k=1:numel(t),Ffull(:,k)=fullSource(t(k));end
elseif isequal(size(fullSource),[nFull numel(t)]),Ffull=fullSource;
elseif isequal(size(fullSource),[numel(t) nFull]),Ffull=fullSource.';
else,error('dynamics:Seismic:InvalidFullOtherForce', ...
        'otherForceFull has incompatible dimensions.');
end
end

function [Gamma,Rfull,diagnostics]=massConsistentInfluence( ...
        ops,analysisOps,modelData,M,directions,GammaKinematic)
Tc=pick(analysisOps,{'Tc'});if isempty(Tc),Tc=pick(ops,{'Tc'});end
Mfull=pick(analysisOps,{'Mfull'});if isempty(Mfull),Mfull=pick(ops,{'Mfull'});end
if isempty(Mfull)&&isfield(ops,'full')&&isstruct(ops.full)
    Mfull=pick(ops.full,{'M','mass'});
end
if isempty(Tc)||isempty(Mfull)||size(Tc,2)~=size(M,1)|| ...
        size(Tc,1)~=size(Mfull,1)
    Gamma=GammaKinematic;Rfull=sparse(0,0);
    diagnostics=struct('source',"reduced_mass_times_kinematic_influence", ...
        'projectedMassOperator',M*Gamma, ...
        'relativeMassProjectionError',NaN);
    return
end
fullModel=modelData;
if isfield(fullModel,'Tc'),fullModel=rmfield(fullModel,'Tc');end
Rfull=dynamics.influence_vector(fullModel,directions,size(Mfull,1));
projected=Tc.'*(Mfull*Rfull);
Gamma=M\projected;
errorValue=norm(M*Gamma-projected,'fro')/max(norm(projected,'fro'),eps);
if errorValue>1e-12
    error('dynamics:Seismic:MassProjectionFailure', ...
        'Mass-consistent influence solve has error %.3e.',errorValue);
end
diagnostics=struct('source',"full_mass_consistent_projection", ...
    'projectedMassOperator',projected, ...
    'relativeMassProjectionError',errorValue, ...
    'formula',"GammaEffective=Mreduced\\(Tc'*Mfull*Rfull)");
end

function [M,D,K] = extractMatrices(ops)
M = pick(ops,{'M','mass'}); K = pick(ops,{'Kt','Ktotal','K'});
D = pick(ops,{'D','Ctotal'});
if isempty(D)
    D = pick(ops,{'C'}); if isempty(D), D = sparse(size(M,1),size(M,1)); end
    G = pick(ops,{'G'}); if ~isempty(G), D = D+G; end
end
if isempty(M) || isempty(K), error('dynamics:Seismic:MissingMatrices','ops requires M and K/Kt.'); end
end

function selected = selectAnalysisOps(ops)
selected = ops;
if isfield(ops,'reduced') && isstruct(ops.reduced), selected = ops.reduced; end
end

function value = pick(s,names)
value = [];
for k = 1:numel(names), if isfield(s,names{k}) && ~isempty(s.(names{k})), value=s.(names{k}); return; end, end
end

function value = getOption(s,names,defaultValue)
value = defaultValue;
for k = 1:numel(names), if isstruct(s)&&isfield(s,names{k})&&~isempty(s.(names{k})), value=s.(names{k}); return; end, end
end

function out = nestedStruct(s,name)
out = struct(); if isstruct(s)&&isfield(s,name)&&isstruct(s.(name)), out=s.(name); end
end
