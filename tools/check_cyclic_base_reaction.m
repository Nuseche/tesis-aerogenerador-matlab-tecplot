function result = check_cyclic_base_reaction()
% Axial 3P tower-base moment on inherited and exactly cyclic 133-element rotors.
% Rebuild coordinates, sectional frames, constraints and prestress from raw
% structural inputs. The two models have identical support, forcing and damping.
root = fileparts(fileparts(mfilename('fullpath')));
addpath(root,fullfile(root,'cases'));
out = fullfile(root,'runs','cyclic_base_reaction_20261119');
if ~isfolder(out), mkdir(out); end
maxNumCompThreads(1);
api = run_periodic_load_campaign("solver_handles");
cfg = config_aeroelastic_snl100();
cfg.gravity.enabled = false;
omega1 = 2*pi*.17; omega2 = 2*pi;
cfg.damping.alpha = .01*omega1*omega2/(omega1+omega2);
cfg.damping.beta = .01/(omega1+omega2);
data = io.load_model_data(cfg);
inherited = model.build_model(data,cfg);
geometry = data.geometry;
tipAzimuth = 2*pi/3;
for blade = 2:3
    rotation = aero.rotation((blade-1)*tipAzimuth*inherited.rotorAxis.direction);
    origin = inherited.rotorAxis.point.';
    nodes = (21:56)+(blade-1)*36;
    geometry.coordinates(nodes,:) = origin+(data.geometry.coordinates(21:56,:)-origin)*rotation.';
    auxField = sprintf('coorP%daux',blade);
    geometry.(auxField) = origin+(data.geometry.coorP1aux-origin)*rotation.';
end
data.geometry = geometry;
cyclic = model.build_model(data,cfg);
models = {inherited,cyclic};
names = ["inherited","cyclic"];
speeds = unique([3.364:.002:3.474,3.4445]);
checkSpeeds = [3.394,3.4445];
sweepRows = {}; geometryRows = {}; harmonicRows = {};
for branch = 1:2
    md = models{branch}; name = names(branch);
    system = aero.prepare_structure(md,cfg);
    [~,~,elements] = assembly.assemble_structural_matrices(md,cfg);
    geometryChecks = checkGeometry(md,elements);
    if branch == 2
        assert(max(geometryChecks) < 5e-10,'Cyclic-copy test failed.');
        assert(isequal(md.mesh.nodes.xyz([1:20 129:end],:),inherited.mesh.nodes.xyz([1:20 129:end],:)));
    end
    [F,checks] = api.sample(system,elements,64,12);
    assert(checks.reconstruction < 1e-10);
    geometryRows(end+1,:) = [{name},num2cell(geometryChecks),{checks.reconstruction}];
    % Evaluate elastic stiffness directly, before the production Fourier solver
    % discards coefficients below its family-wise relative threshold.
    nAzimuth = 64;
    stiffness = cell(1,nAzimuth);
    angles = 2*pi*(0:nAzimuth-1)/nAzimuth;
    for j = 1:nAzimuth
        staticOperators = aero.turbine_mbc_operators(system,angles(j),0);
        stiffness{j} = staticOperators.K;
    end
    for ell = 0:F.L
        coefficient = sparse(system.n,system.n);
        for j = 1:nAzimuth
            coefficient = coefficient+stiffness{j}*exp(-1i*ell*angles(j))/nAzimuth;
        end
        if ell == 0, meanNorm = norm(coefficient,'fro'); end
        harmonicRows(end+1,:) = {name,ell,norm(coefficient,'fro')/meanNorm};
    end
    clear stiffness
    for rpm = speeds
        omega = rpm*pi/30;
        average = api.solve(F,[],omega,0,true);
        orders = 6;
        if min(abs(checkSpeeds-rpm)) < 1e-9, orders = [6 12]; end
        for H = orders
            [periodic,meta] = api.solve(F,[],omega,H,false);
            p = squeeze(periodic(4,:,1)); a = squeeze(average(4,:,1));
            coefficient = F.outputH+1+3;
            P = 2*p(coefficient); A = 2*a(coefficient);
            sweepRows(end+1,:) = {name,rpm,H,abs(P),rad2deg(angle(P)),abs(A),rad2deg(angle(A)), ...
                100*norm(a-p)/norm(p),meta.residual};
        end
    end
    fprintf('%s completed: %d speeds\n',name,numel(speeds));
end
result = cell2table(sweepRows,'VariableNames',{'rotor','rpm','H','periodicAbsNmPerN','periodicPhaseDeg',...
    'averagedAbsNmPerN','averagedPhaseDeg','historyErrorPct','relativeSolveResidual'});
geometryTable = cell2table(geometryRows,'VariableNames',{'rotor','nodeDifferenceM','auxiliaryDifferenceM',...
    'frameMaxFrobenius','relativeLocalMassDifference','relativeLocalStiffnessDifference','operatorReconstruction'});
harmonicTable = cell2table(harmonicRows,'VariableNames',{'rotor','order','stiffnessFrobeniusOverMean'});
writetable(result,fullfile(out,'response.csv'));
writetable(geometryTable,fullfile(out,'geometry.csv'));
writetable(harmonicTable,fullfile(out,'stiffness_harmonics.csv'));
end

function measures = checkGeometry(md,elements)
measures = zeros(1,5);
origin = md.rotorAxis.point.';
referenceElements = find(md.mesh.elements.blade==1);
for blade = 2:3
    rotation = aero.rotation((blade-1)*2*pi/3*md.rotorAxis.direction);
    nodes = (21:56)+(blade-1)*36;
    offsets = md.mesh.nodes.xyz(21:56,:)-origin;
    nodeErr = md.mesh.nodes.xyz(nodes,:)-(origin+offsets*rotation.');
    peers = find(md.mesh.elements.blade==blade);
    offsets = md.mesh.elements.auxPoint(referenceElements,:)-origin;
    auxErr = md.mesh.elements.auxPoint(peers,:)-(origin+offsets*rotation.');
    measures(1:2) = max(measures(1:2),[max(vecnorm(nodeErr,2,2)),max(vecnorm(auxErr,2,2))]);
    for i = 1:numel(peers)
        a = elements(referenceElements(i)); b = elements(peers(i));
        f1 = md.bladeDofMap.frameR(:,:,i,1); fb = md.bladeDofMap.frameR(:,:,i,blade);
        err = [norm(fb-rotation*f1,'fro'),norm(b.MeLocal-a.MeLocal,'fro')/norm(a.MeLocal,'fro'),...
               norm(b.KeLocal-a.KeLocal,'fro')/norm(a.KeLocal,'fro')];
        measures(3:5) = max(measures(3:5),err);
    end
end
end
