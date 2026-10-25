function suite=run_equilibrium_suite(modelData,reduced,sweep,cfg)
%RUN_EQUILIBRIUM_SUITE Specialized gravity/centrifugal acceptance checks.

tol=localCfg(cfg,{'equilibrium','tolerance'},1e-8);
matrixTol=localCfg(cfg,{'action06','matrixTolerance'},1e-10);
balanceTol=localCfg(cfg,{'action06','globalBalanceTolerance'},2e-3);
internalTol=localCfg(cfg,{'action06','internalTangentTolerance'},2e-6);
centrifugalTol=localCfg(cfg,{'action06','centrifugalTangentTolerance'},2e-6);
scalingTol=localCfg(cfg,{'action06','omegaScalingTolerance'},1e-10);
checks=repmat(localCheck("",true,0,0,"",false),0,1);

states=sweep.states;operatingOps=sweep.ops;count=numel(states);
converged=cellfun(@(state)logical(state.converged),states);
residuals=cellfun(@(state)double(state.residualRelative),states);
iterations=cellfun(@(state)double(state.iterations),states);
balances=cellfun(@(state)double(state.globalBalanceError),states);
checks(end+1,1)=localCheck("equilibrium.allConverged",all(converged), ...
    nnz(~converged),0,"Every requested operating point converged.",true);
checks(end+1,1)=localCheck("equilibrium.maximumResidual",max(residuals)<=tol, ...
    max(residuals),tol,"Maximum reduced free-DOF residual.",true);
checks(end+1,1)=localCheck("equilibrium.genuineIterations",all(iterations>1), ...
    min(iterations),2,"Nonlinear equilibria require more than one evaluation.",true);
checks(end+1,1)=localCheck("equilibrium.globalForceMomentBalance", ...
    max(balances)<=balanceTol,max(balances),balanceTol, ...
    "Maximum external-plus-reaction force/moment resultant.",true);

monotone=true;
for index=1:count
    history=states{index}.history(:,2);
    monotone=monotone&&all(diff(history)<=max(1e-12,1e-8*history(1:end-1)));
end
checks(end+1,1)=localCheck("equilibrium.acceptedResidualMonotone",monotone, ...
    double(~monotone),0,"Accepted Newton/line-search residuals do not increase.",true);
checks(end+1,1)=localCheck("continuation.startsAtZero", ...
    sweep.continuationSpeedRPM(1)==0,sweep.continuationSpeedRPM(1),0, ...
    "Continuation always starts at the gravity-only state.",true);

[internalError,centrifugalError]=localTangentErrors( ...
    modelData,reduced,states{end},cfg);
checks(end+1,1)=localCheck("tangent.internalDirectionalDerivative", ...
    internalError<=internalTol,internalError,internalTol, ...
    "Corotational internal tangent versus centered directional derivative.",true);
checks(end+1,1)=localCheck("tangent.centrifugalDirectionalDerivative", ...
    centrifugalError<=centrifugalTol,centrifugalError,centrifugalTol, ...
    "Centrifugal load Jacobian versus centered directional derivative.",true);

[forceScalingError,tangentScalingError,signError]= ...
    localOmegaScaling(modelData,cfg);
checks(end+1,1)=localCheck("centrifugal.forceOmegaSquared", ...
    forceScalingError<=scalingTol,forceScalingError,scalingTol, ...
    "Undeformed centrifugal force scales with Omega squared.",true);
checks(end+1,1)=localCheck("centrifugal.tangentOmegaSquared", ...
    tangentScalingError<=scalingTol,tangentScalingError,scalingTol, ...
    "Centrifugal Jacobian scales with Omega squared.",true);
checks(end+1,1)=localCheck("centrifugal.speedSignInvariant", ...
    signError<=scalingTol,signError,scalingTol, ...
    "Centrifugal force is invariant to the sign of Omega.",true);
axisForce=localAxisBodyForce();
checks(end+1,1)=localCheck("centrifugal.zeroOnAxis",axisForce<=1e-12, ...
    axisForce,1e-12,"A collocated point mass on the rotor axis has zero load.",true);

identityError=0;maximumKOmega=0;maximumKgSymmetry=0;
for index=1:count
    state=states{index};ops=operatingOps{index};
    reconstructed=ops.full.Ke+ops.full.Kg+ops.full.KOmega;
    identityError=max(identityError,norm(reconstructed-state.tangentFull,'fro')/ ...
        max(norm(state.tangentFull,'fro'),1));
    maximumKOmega=max(maximumKOmega,norm(ops.full.KOmega,'fro'));
    maximumKgSymmetry=max(maximumKgSymmetry,norm(ops.full.Kg-ops.full.Kg.','fro')/ ...
        max(norm(ops.full.Kg,'fro'),eps));
end
checks(end+1,1)=localCheck("stiffness.singleSourceIdentity", ...
    identityError<=matrixTol,identityError,matrixTol, ...
    "Ke+Kg+KOmega equals the stored equilibrium tangent exactly once.",true);
checks(end+1,1)=localCheck("stiffness.noDoubleCountKOmega", ...
    maximumKOmega==0,maximumKOmega,0, ...
    "KOmega is zero because its load Jacobian is already in the tangent.",true);
checks(end+1,1)=localCheck("stiffness.KgSymmetry", ...
    maximumKgSymmetry<=matrixTol,maximumKgSymmetry,matrixTol, ...
    "Equilibrium tangent correction is symmetric.",true);

axialConsistent=true;axialFinite=true;
for index=1:count
    state=states{index};
    if state.speedRPM==0
        axialConsistent=axialConsistent&& ...
            norm(state.elementCentrifugalAxialForces,inf)==0;
    else
        axialConsistent=axialConsistent&&norm( ...
            state.elementAxialForces-state.elementGravityAxialForces- ...
            state.elementCentrifugalAxialForces,inf)<=1e-8* ...
            max(norm(state.elementAxialForces,inf),1);
    end
    axialFinite=axialFinite&&all(isfinite(state.elementAxialForces))&& ...
        all(isfinite(state.elementGravityAxialForces))&& ...
        all(isfinite(state.elementCentrifugalAxialForces));
end
checks(end+1,1)=localCheck("axial.sourceSeparationFinite",axialFinite, ...
    double(~axialFinite),0,"Gravity, incremental centrifugal and total axial arrays are finite.",true);
checks(end+1,1)=localCheck("axial.sourceSum",axialConsistent, ...
    double(~axialConsistent),0,"Gravity plus incremental centrifugal equals total axial force.",true);
towerMask=modelData.mesh.elements.type=="tower";
minimumTowerAxial=min(states{1}.elementAxialForces(towerMask));
checks(end+1,1)=localCheck("gravity.towerCompressionSign", ...
    minimumTowerAxial<0,minimumTowerAxial,0, ...
    "Gravity produces compression (negative sign) in at least one tower element.",true);

[timoshenkoDifference,timoshenkoSymmetry]=localGeometricBenchmark(modelData);
checks(end+1,1)=localCheck("geometric.timoshenkoIntegrated", ...
    timoshenkoDifference>0,timoshenkoDifference,0, ...
    "Finite shear flexibility changes the integrated initial-stress matrix.",true);
checks(end+1,1)=localCheck("geometric.symmetry", ...
    timoshenkoSymmetry<=matrixTol,timoshenkoSymmetry,matrixTol, ...
    "Integrated Timoshenko geometric stiffness is symmetric.",true);

for index=1:count
    checks=[checks;localMatrixChecks(states{index}.tangentFull, ...
        "tangent.rpm"+string(states{index}.speedRPM),matrixTol)]; %#ok<AGROW>
end

equilibriumTable=localEquilibriumTable(states);
axialTable=localAxialTable(modelData,states);
continuationTable=localContinuationTable(sweep);
suite=struct('schemaVersion',"1.0.0", ...
    'scope',"corotational_gravity_and_configuration_dependent_centrifugal_equilibrium", ...
    'checks',checks,'checkTable',struct2table(checks), ...
    'equilibriumTable',equilibriumTable,'axialTable',axialTable, ...
    'continuationTable',continuationTable, ...
    'metrics',struct('maximumResidual',max(residuals), ...
    'maximumGlobalBalanceError',max(balances),'internalTangentError', ...
    internalError,'centrifugalTangentError',centrifugalError, ...
    'forceOmegaScalingError',forceScalingError, ...
    'tangentOmegaScalingError',tangentScalingError, ...
    'stiffnessIdentityError',identityError,'maximumKOmegaNorm',maximumKOmega, ...
    'minimumTowerAxialForce',minimumTowerAxial));
suite.passed=all([checks.pass] | ~[checks.critical]);
suite.criticalFailures=checks(~[checks.pass] & [checks.critical]);
if logical(localCfg(cfg,{'validation','failOnCritical'},1))&&~suite.passed
    names=strjoin(string({suite.criticalFailures.name}),', ');
    error('validation:run_equilibrium_suite:CriticalFailure', ...
        'Action 06 critical checks failed: %s',names);
end
end

function [internalError,centrifugalError]=localTangentErrors(model,reduced,state,cfg)
Tc=reduced.Tc;z=Tc*sin((1:size(Tc,2)).'/17);z=z/max(norm(z),1);h=1e-4;
q=state.qFull;
[fp]=equilibrium.total_lagrangian_internal_force(model,q+h*z,cfg);
[fm]=equilibrium.total_lagrangian_internal_force(model,q-h*z,cfg);
[~,Kzero]=equilibrium.total_lagrangian_internal_force(model,zeros(size(q)),cfg);
Kextra=reduced.full.Ke-Kzero;
finiteDifference=(fp-fm)/(2*h)+Kextra*z;
prediction=state.internalTangentFull*z;
internalError=norm(finiteDifference-prediction)/max(norm(finiteDifference),1);
plusState=state;plusState.qFull=q+h*z;
minusState=state;minusState.qFull=q-h*z;
fPlus=equilibrium.centrifugal_loads(model,cfg,plusState);
fMinus=equilibrium.centrifugal_loads(model,cfg,minusState);
finiteDifference=(fPlus-fMinus)/(2*h);
prediction=state.externalLoadTangentFull*z;
centrifugalError=norm(finiteDifference-prediction)/max(norm(finiteDifference),1);
end

function [forceError,tangentError,signError]=localOmegaScaling(model,cfg)
zero=zeros(model.dofs.number,1);state=struct('qFull',zero);
cfg6=cfg;cfg6.rotor.speedRPM=6;
cfg12=cfg;cfg12.rotor.speedRPM=12;
cfgMinus=cfg;cfgMinus.rotor.speedRPM=-6;
[f6,~,K6]=equilibrium.centrifugal_loads(model,cfg6,state);
[f12,~,K12]=equilibrium.centrifugal_loads(model,cfg12,state);
[fMinus,~,KMinus]=equilibrium.centrifugal_loads(model,cfgMinus,state);
forceError=norm(f12-4*f6)/max(norm(f12),1);
tangentError=norm(K12-4*K6,'fro')/max(norm(K12,'fro'),1);
signError=max(norm(fMinus-f6)/max(norm(f6),1), ...
    norm(KMinus-K6,'fro')/max(norm(K6,'fro'),1));
end

function normForce=localAxisBodyForce()
model.mesh.nodes=struct('id',130,'xyz',[0 0 0]);
model.mesh.elements=struct('id',zeros(0,1),'nodeI',zeros(0,1), ...
    'nodeJ',zeros(0,1),'section',zeros(0,1),'blade',zeros(0,1));
model.sections=struct([]);model.dofs.node=1:6;model.dofs.number=6;
model.rotorAxis=struct('point',[0;0;0],'direction',[1;0;0]);
model.rigidBodies.bodies=struct('name',"axis_mass",'masterNode',130, ...
    'mass',10,'cgOffsetBody',zeros(3,1),'inertiaBody',eye(3), ...
    'orientationBodyToGlobal',eye(3),'rotating',true);
cfg.rotor.speedRPM=12;
force=equilibrium.centrifugal_loads(model,cfg,struct('qFull',zeros(6,1)));
normForce=norm(force);
end

function [difference,symmetry]=localGeometricBenchmark(model)
row=find(model.mesh.elements.type=="tower",1);ids=model.mesh.nodes.id;
i=find(ids==model.mesh.elements.nodeI(row),1);
j=find(ids==model.mesh.elements.nodeJ(row),1);
xI=model.mesh.nodes.xyz(i,:);xJ=model.mesh.nodes.xyz(j,:);
direction=(xJ-xI).';direction=direction/norm(direction);
basis=eye(3);[~,axisIndex]=min((basis.'*direction).^2);
aux=xI+basis(:,axisIndex).';section=model.sections(model.mesh.elements.section(row));
Ktim=elements.geometric_stiffness(xI,xJ,aux,1e6,section);
Keb=elements.geometric_stiffness(norm(xJ-xI),1e6);
[~,T]=elements.element_rotation_matrix(xI,xJ,aux);
KebGlobal=T.'*Keb*T;
difference=norm(Ktim-KebGlobal,'fro')/max(norm(KebGlobal,'fro'),1);
symmetry=norm(Ktim-Ktim.','fro')/max(norm(Ktim,'fro'),eps);
end

function tableValue=localEquilibriumTable(states)
n=numel(states);speedRPM=zeros(n,1);iterations=speedRPM;residualRelative=speedRPM;
maximumDisplacement=speedRPM;gravityLoadNorm=speedRPM;
centrifugalLoadNorm=speedRPM;externalTangentNorm=speedRPM;globalBalanceError=speedRPM;
for index=1:n
    state=states{index};speedRPM(index)=state.speedRPM;
    iterations(index)=state.iterations;residualRelative(index)=state.residualRelative;
    maximumDisplacement(index)=max(abs(state.qFull));
    gravityLoadNorm(index)=norm(state.loadParts.gravity);
    centrifugalLoadNorm(index)=norm(state.loadParts.centrifugal);
    externalTangentNorm(index)=norm(state.externalLoadTangentFull,'fro');
    globalBalanceError(index)=state.globalBalanceError;
end
tableValue=table(speedRPM,iterations,residualRelative,maximumDisplacement, ...
    gravityLoadNorm,centrifugalLoadNorm,externalTangentNorm,globalBalanceError);
end

function tableValue=localAxialTable(model,states)
ne=numel(model.mesh.elements.id);n=numel(states)*ne;
speedRPM=zeros(n,1);elementId=speedRPM;component=strings(n,1);
gravityAxialN=speedRPM;centrifugalIncrementAxialN=speedRPM;totalAxialN=speedRPM;
cursor=0;
for speedIndex=1:numel(states)
    state=states{speedIndex};rows=cursor+(1:ne);cursor=cursor+ne;
    speedRPM(rows)=state.speedRPM;elementId(rows)=model.mesh.elements.legacyId;
    component(rows)=model.mesh.elements.type;
    gravityAxialN(rows)=state.elementGravityAxialForces;
    centrifugalIncrementAxialN(rows)=state.elementCentrifugalAxialForces;
    totalAxialN(rows)=state.elementAxialForces;
end
tableValue=table(speedRPM,elementId,component,gravityAxialN, ...
    centrifugalIncrementAxialN,totalAxialN);
end

function tableValue=localContinuationTable(sweep)
speedRPM=sweep.continuationSpeedRPM(:);n=numel(speedRPM);
requested=ismember(speedRPM,sweep.speedRPM);iterations=zeros(n,1);residual=zeros(n,1);
for index=1:n
    iterations(index)=sweep.continuationStates{index}.iterations;
    residual(index)=sweep.continuationStates{index}.residualRelative;
end
tableValue=table(speedRPM,requested,iterations,residual);
end

function checks=localMatrixChecks(A,label,tol)
checks=repmat(localCheck("",true,0,0,"",false),0,1);
checks(end+1,1)=localCheck(label+".sparse",issparse(A),double(~issparse(A)),0, ...
    "Matrix remains sparse.",true);
finite=all(isfinite(nonzeros(A)));
checks(end+1,1)=localCheck(label+".finite",finite,double(~finite),0, ...
    "Stored coefficients are finite.",true);
symmetry=norm(A-A.','fro')/max(norm(A,'fro'),eps);
checks(end+1,1)=localCheck(label+".symmetry",symmetry<=tol,symmetry,tol, ...
    "Relative Frobenius symmetry residual.",true);
end

function check=localCheck(name,pass,value,tolerance,message,critical)
check=struct('name',string(name),'pass',logical(pass),'value',value, ...
    'tolerance',tolerance,'message',string(message),'critical',logical(critical));
end

function value=localCfg(cfg,path,fallback)
value=fallback;cursor=cfg;
for index=1:numel(path)
    if ~isstruct(cursor)||~isfield(cursor,path{index}),return;end
    cursor=cursor.(path{index});
end
if isnumeric(cursor)&&isscalar(cursor)&&isfinite(cursor),value=double(cursor);end
end
