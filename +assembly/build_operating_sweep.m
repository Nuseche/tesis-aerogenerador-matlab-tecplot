function sweep = build_operating_sweep(modelData, reduced, cfg)
%BUILD_OPERATING_SWEEP Solve equilibria by speed continuation and form ops.

speedRequested = cfg.rotor.speedRPM;
if isfield(cfg.rotor,'speedRPMGrid') && ~isempty(cfg.rotor.speedRPMGrid)
    speedRequested = cfg.rotor.speedRPMGrid(:);
else
    speedRequested = speedRequested(:);
end
if any(~isfinite(speedRequested))
    error('assembly:build_operating_sweep:InvalidSpeed','Rotor speeds must be finite.');
end
if numel(unique(speedRequested)) ~= numel(speedRequested)
    error('assembly:build_operating_sweep:DuplicateSpeed', ...
        'The Campbell speed grid cannot contain duplicate values.');
end

positive=sort(speedRequested(speedRequested>0),'ascend');
negative=-sort(abs(speedRequested(speedRequested<0)),'ascend');
speedContinuation=unique([0;positive;negative],'stable');

statesContinuation = cell(numel(speedContinuation),1);
opsContinuation = cell(numel(speedContinuation),1);
previousQ = [];
zeroState=[];
for index = 1:numel(speedContinuation)
    stepCfg = cfg;
    stepCfg.rotor.speedRPM = speedContinuation(index);
    if speedContinuation(index)<0&& ...
            (index==1||speedContinuation(index-1)>=0)
        previousQ=zeroState.qReduced;
    end
    if ~isempty(previousQ)
        stepCfg.equilibrium.initialQ = previousQ;
    end
    if ~isempty(zeroState)&&speedContinuation(index)~=0
        stepCfg.equilibrium.gravityAxialReference= ...
            zeroState.elementAxialForces;
    end
    currentState = equilibrium.solve_static_equilibrium(modelData,reduced,stepCfg);
    currentState.speedRPM = speedContinuation(index);
    currentState.angularVelocity = speedContinuation(index)*2*pi/60 * ...
        modelData.rotorAxis.direction(:);
    currentOps = assembly.build_operating_matrices(modelData,reduced,currentState,stepCfg);
    currentOps.speedRPM = speedContinuation(index);
    statesContinuation{index} = currentState;
    opsContinuation{index} = currentOps;
    previousQ = currentState.qReduced;
    if speedContinuation(index)==0,zeroState=currentState;end
end

requestedIndex=zeros(numel(speedRequested),1);
for index=1:numel(speedRequested)
    requestedIndex(index)=find(speedContinuation==speedRequested(index),1);
end
sweep = struct();
sweep.speedRPM = speedRequested;
sweep.states = statesContinuation(requestedIndex);
sweep.ops = opsContinuation(requestedIndex);
sweep.continuationOrder = requestedIndex;
sweep.continuationSpeedRPM = speedContinuation;
sweep.continuationStates=statesContinuation;
sweep.continuationOps=opsContinuation;
targetSpeed = cfg.rotor.speedRPM;
[~,sweep.primaryIndex] = min(abs(speedRequested-targetSpeed));
sweep.primaryState = sweep.states{sweep.primaryIndex};
sweep.primaryOps = sweep.ops{sweep.primaryIndex};
end
