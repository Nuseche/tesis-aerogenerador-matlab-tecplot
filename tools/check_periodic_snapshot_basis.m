function check_periodic_snapshot_basis(elements,tolerance,reviewDetails)
% Construct a real Galerkin space from displacements under axial 3P forcing.
% No load output or validation-speed solution enters the basis.
if nargin < 1, elements = 133; end
if nargin < 2, tolerance = 1e-10; end
if nargin < 3, reviewDetails = false; end
solver = run_periodic_load_campaign("solver_handles");
root = fileparts(fileparts(mfilename('fullpath')));
out = fullfile(root,'runs','periodic_loads_20261118');
maxNumCompThreads(1);
if elements == 133
    cache = 'operators64.mat';
    filename = 'correction_snapshot_basis.csv';
elseif elements == 266
    cache = 'correctionOperators266.mat';
    filename = 'correction_snapshot_basis266.csv';
else
    error('Supported meshes have 133 or 266 elements.');
end
if tolerance ~= 1e-10
    filename = sprintf('correction_snapshot_sensitivity%d_%g.csv',elements,tolerance);
end
load(fullfile(out,cache),'F');
H = 12;
trainingRPM = [3.35,3.49];
[Q,G,trainingTime,projectionTime,orthError] = trainModel(solver,F,H,trainingRPM,tolerance);
rows = [];
details = {};
channels = ["hub axial displacement","nacelle axial displacement","blade-1 tip axial displacement", ...
    "tower base My","tower base Mx","blade-1 root M2","blade-1 root M3"];
units = ["m/N","m/N","m/N","N m/N","N m/N","N m/N","N m/N"];
for rpm = [2.8,3.35,3.37,3.394,3.42,3.4445,3.47,3.49,3.52,3.55,4]
    w = rpm*pi/30;
    [ref,fullRun] = solver.solve(F,[],w,H,false);
    [y,smallRun] = solver.solve(G,[],w,H,false);
    d = squeeze(y(:,:,1)-ref(:,:,1)); r=squeeze(ref(:,:,1));
    referenceRms = vecnorm(r,2,2);
    errorRms = vecnorm(d,2,2);
    errorPct = 100*errorRms./referenceRms;
    if reviewDetails
        for c = 1:numel(channels)
            details(end+1,:) = {rpm,ismember(rpm,trainingRPM),c,channels(c),units(c), ...
                referenceRms(c),norm(y(c,:,1)),errorRms(c),errorPct(c)};
        end
    end
    rows(end+1,:) = [rpm,ismember(rpm,trainingRPM),size(Q,2),...
        errorPct(1),errorPct(4),errorPct(6),max(errorPct),...
        trainingTime,projectionTime,fullRun.totalSeconds,smallRun.totalSeconds,...
        orthError,smallRun.residual];
end
tbl = array2table(rows,'VariableNames',{'rpm','training','dimension','hubErrorPct',...
    'baseMyErrorPct','rootM2ErrorPct','maxSevenErrorPct','trainingSeconds',...
    'basisProjectionSeconds','fullSeconds','reducedSeconds','orthogonalityError','reducedResidual'});
if reviewDetails
    reviewOut = fullfile(root,'runs','snapshot_review');
    if ~isfolder(reviewOut), mkdir(reviewOut); end
    filePrefix = sprintf('snapshot_%d_',elements);
    fields = {'rpm','training','channel','output','unit','referenceRms','reducedRms','errorRms','errorPct'};
    writetable(cell2table(details,'VariableNames',fields),fullfile(reviewOut,[filePrefix 'outputs.csv']));
    speed = 3.4445;
    w = speed*pi/30;
    % The preceding solves warm both paths. Alternate their order across repetitions.
    trials = zeros(5,7);
    for trial = 1:size(trials,1)
        [~,~,trainTime,projectTime] = trainModel(solver,F,H,trainingRPM,tolerance);
        if mod(trial,2) == 1
            [~,full] = solver.solve(F,[],w,H,false);
            [~,red] = solver.solve(G,[],w,H,false);
        else
            [~,red] = solver.solve(G,[],w,H,false);
            [~,full] = solver.solve(F,[],w,H,false);
        end
        trials(trial,:) = [trial,speed,trainTime,projectTime,trainTime+projectTime, ...
            full.totalSeconds,red.totalSeconds];
    end
    timings = array2table(trials,'VariableNames',{'trial','rpm','twoTrainingSolvesSeconds', ...
        'projectionSeconds','offlineTotalSeconds','fullOnlineSeconds','reducedOnlineSeconds'});
    writetable(timings,fullfile(reviewOut,[filePrefix 'timings.csv']));
else
    writetable(tbl,fullfile(out,filename));
end
disp(tbl(:,1:7))
end

function [Q,G,trainingTime,projectionTime,orthError] = trainModel(solver,F,H,trainingRPM,tolerance)
start = tic;
samples = [];
for rpm = trainingRPM
    [~,~,x] = solver.solve(F,[],rpm*pi/30,H,false);
    positive = x(:,H+2:end,1);
    samples = [samples,real(x(:,H+1,1)),real(positive),imag(positive)];
end
trainingTime = toc(start);
start = tic;
R = chol(real(F.M{F.L+1}));
[U,S,~] = svd(R*samples,'econ');
sv = diag(S);
Q = R\U(:,sv>tolerance*sv(1));
G = solver.project(F,Q);
orthError = norm(Q'*real(F.M{F.L+1})*Q-eye(size(Q,2)),2);
projectionTime = toc(start);
end
