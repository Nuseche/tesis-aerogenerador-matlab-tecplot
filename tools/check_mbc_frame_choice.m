function check_mbc_frame_choice(elements)
% Change only the coordinates used for multiblade projection on the same turbine.
% The physical elements, rigid connections, loads and recovery are identical.
if nargin == 0, elements = 133; end
root = fileparts(fileparts(mfilename('fullpath')));
addpath(root,fullfile(root,'cases'));
out = fullfile(root,'runs','periodic_loads_20261118');
api = run_periodic_load_campaign("solver_handles");
original = load(fullfile(out,'operators64.mat'),'cfg','F');
modelData = model.build_model(io.load_model_data(original.cfg),original.cfg);
switch elements
    case 133
        originalF = original.F;
    case 266
        modelData = api.bisect(modelData);
        saved = load(fullfile(out,'correctionOperators266.mat'),'F');
        originalF = saved.F;
    case 532
        modelData = api.bisect(api.bisect(modelData));
        saved = load(fullfile(out,'correctionOperators532.mat'),'F');
        originalF = saved.F;
    case 1064
        modelData = api.bisect(api.bisect(api.bisect(modelData)));
    otherwise
        error('Supported meshes have 133, 266, 532 or 1064 elements.')
end
sys = aero.prepare_structure(modelData,original.cfg);
[~,~,elementCache] = assembly.assemble_structural_matrices(modelData,original.cfg);
axis = modelData.rotorAxis.direction(:);
roots = modelData.mesh.nodes.xyz([21 57 93],:) - modelData.rotorAxis.point.';
orientation = sign(dot(axis,cross(roots(1,:),roots(2,:))));
W = aero.skew(axis);
frames = modelData.bladeDofMap.frameR;
for b = 2:3
    offset = orientation*(b-1)*2*pi/3;
    rotation = eye(3) + sin(offset)*W + (1-cos(offset))*W^2;
    for j = 1:size(frames,3)
        frames(:,:,j,b) = rotation*frames(:,:,j,1);
    end
end
sys.model.bladeDofMap.frameR = frames;
[aligned,checks] = api.sample(sys,elementCache,64,12);
assert(checks.reconstruction < 1e-10);
speeds = unique([3.32:.002:3.60,3.4445]);
rows = zeros(numel(speeds),4);
j3 = aligned.outputH+4;
for j = 1:numel(speeds)
    rpm = speeds(j);
    y = api.solve(aligned,[],rpm*pi/30,0,true);
    value = 2*y(4,j3,1);
    rows(j,:) = [elements,rpm,abs(value),rad2deg(angle(value))];
end
names = {'elements','rpm','alignedAverageNmPerN','alignedAveragePhaseDeg'};
writetable(array2table(rows,'VariableNames',names),fullfile(out,sprintf('review_frame_average_%d.csv',elements)));
if elements == 1064
    % The native-frame 1064 run archives the 3P phasor at these two speeds.
    originalPeaks = readtable(fullfile(out,'review_1064_periodic_resolution.csv'));
    alt = zeros(height(originalPeaks),5);
    for j = 1:height(originalPeaks)
        rpm = originalPeaks.rpm(j);
        y = api.solve(aligned,[],rpm*pi/30,originalPeaks.H(j),false);
        p = 2*y(4,j3,1);
        ym = api.solve(aligned,[],rpm*pi/30,0,true);
        historyError = 100*norm(ym(4,:,1)-y(4,:,1))/norm(y(4,:,1));
        alt(j,:) = [rpm,originalPeaks.H(j),abs(p),rad2deg(angle(p)),historyError];
    end
    writetable(array2table(alt,'VariableNames',{'rpm','H','alignedPeriodicNmPerN','alignedPeriodicPhaseDeg','alignedAverageHistoryErrorPct'}), ...
        fullfile(out,'review_frame_1064_periodic_spots.csv'));
    return
end
selected = [3.394,3.4445,3.49];
comparisons = zeros(numel(selected),8);
for j = 1:numel(selected)
    omega = selected(j)*pi/30;
    yp = api.solve(originalF,[],omega,12,false);
    ya = api.solve(aligned,[],omega,12,false);
    y0 = api.solve(originalF,[],omega,0,true);
    y1 = api.solve(aligned,[],omega,0,true);
    change = 100*norm(yp(4,:,1)-ya(4,:,1))/norm(yp(4,:,1));
    dif = 100*norm(y1(4,:,1)-ya(4,:,1))/norm(ya(4,:,1));
    comparisons(j,:) = [elements,selected(j),2*abs(yp(4,j3,1)),2*abs(ya(4,j3,1)),change, ...
        2*abs(y0(4,j3,1)),2*abs(y1(4,j3,1)),dif];
end
writetable(array2table(comparisons,'VariableNames',{'elements','rpm','periodicNmPerN', ...
    'alignedPeriodicNmPerN','periodicHistoryChangePct','averageNmPerN','alignedAverageNmPerN', ...
    'alignedAverageHistoryErrorPct'}),fullfile(out,sprintf('review_frame_compare_%d.csv',elements)));
end
