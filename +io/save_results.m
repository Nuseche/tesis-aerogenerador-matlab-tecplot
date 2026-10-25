function save_results(run, cfg, modelData, state, ops, results)
%SAVE_RESULTS Persist a complete, reproducible snapshot of a successful run.

arguments
    run (1,1) struct
    cfg (1,1) struct
    modelData (1,1) struct
    state (1,1) struct
    ops (1,1) struct
    results (1,1) struct
end

configuration = cfg; %#ok<NASGU>
save(fullfile(run.folder, 'configuration.mat'), 'configuration', '-v7.3');
localWriteConfiguration(fullfile(run.folder, 'configuration.txt'), cfg);

modelSnapshot = modelData; %#ok<NASGU>
save(fullfile(run.folder, 'model_snapshot.mat'), 'modelSnapshot', '-v7.3');
equilibrium = state; %#ok<NASGU>
save(fullfile(run.folder, 'equilibrium.mat'), 'equilibrium', '-v7.3');
operators = ops; %#ok<NASGU>
save(fullfile(run.folder, 'operators.mat'), 'operators', '-v7.3');
save(fullfile(run.folder, 'results.mat'), 'results', '-v7.3');

if isfield(results, 'action02') && ~isempty(results.action02)
    [M, Ke] = localAction02Matrices(ops); %#ok<ASGLU>
    dofMap = modelData.dofs; %#ok<NASGU>
    elementCache = localNestedField(ops, {'cache'}, struct()); %#ok<NASGU>
    assemblyDiagnostics = localNestedField( ...
        ops, {'diagnostics','structuralAssembly'}, struct()); %#ok<NASGU>
    action02Results = results.action02; %#ok<NASGU>
    schemaVersion = "1.0.0"; %#ok<NASGU>
    save(fullfile(run.folder, 'action02_matrices.mat'), ...
        'schemaVersion','M','Ke','dofMap','elementCache', ...
        'assemblyDiagnostics','action02Results','-v7.3');
end

if isfield(results, 'action03') && ~isempty(results.action03)
    [M,Ke,Tc,Mr,Ker] = localAction03Matrices(ops); %#ok<ASGLU>
    dofMap = modelData.dofs; %#ok<NASGU>
    constraintInfo = localNestedField( ...
        ops,{'diagnostics','constraints'},struct()); %#ok<NASGU>
    action03Results = results.action03; %#ok<NASGU>
    schemaVersion = "1.0.0"; %#ok<NASGU>
    save(fullfile(run.folder,'action03_matrices.mat'), ...
        'schemaVersion','M','Ke','Tc','Mr','Ker','dofMap', ...
        'constraintInfo','action03Results','-v7.3');
end

if isfield(results,'action04') && ~isempty(results.action04)
    [Mdistributed,M,Ke,Tc,Mr,Ker] = localAction04Matrices(ops); %#ok<ASGLU>
    bodyMassDiagnostics = localNestedField( ...
        ops,{'diagnostics','bodyMasses'},struct()); %#ok<NASGU>
    massProperties = results.massProperties; %#ok<NASGU>
    action04Results = results.action04; %#ok<NASGU>
    schemaVersion = "1.0.0"; %#ok<NASGU>
    save(fullfile(run.folder,'action04_matrices.mat'), ...
        'schemaVersion','Mdistributed','M','Ke','Tc','Mr','Ker', ...
        'bodyMassDiagnostics','massProperties','action04Results','-v7.3');
end

if isfield(results,'action05') && ~isempty(results.action05)
    [Massembled,McDistributed,MhDistributed,Mc,Mh,Ke,Tc,Mrc,Mrh] = ...
        localAction05Matrices(ops); %#ok<ASGLU>
    massDiagnostics = localNestedField( ...
        ops,{'diagnostics','massFormulation'},struct()); %#ok<NASGU>
    hrzDiagnostics = localNestedField( ...
        ops,{'diagnostics','hrz'},struct()); %#ok<NASGU>
    action05Results = results.action05; %#ok<NASGU>
    schemaVersion="1.0.0"; %#ok<NASGU>
    save(fullfile(run.folder,'action05_matrices.mat'), ...
        'schemaVersion','Massembled','McDistributed','MhDistributed', ...
        'Mc','Mh','Ke','Tc','Mrc','Mrh','massDiagnostics', ...
        'hrzDiagnostics','action05Results','-v7.3');
end

if isfield(results,'action06') && ~isempty(results.action06)
    M=ops.full.M;Ke=ops.full.Ke;Kg=ops.full.Kg; %#ok<NASGU>
    KOmega=ops.full.KOmega;K=ops.full.K; %#ok<NASGU>
    Tanalysis=ops.reduced.Tc; %#ok<NASGU>
    operatingPoints=ops.operatingPoints; %#ok<NASGU>
    action06Results=results.action06; %#ok<NASGU>
    schemaVersion="1.0.0"; %#ok<NASGU>
    if ~all([issparse(M),issparse(Ke),issparse(Kg),issparse(KOmega), ...
            issparse(K),issparse(Tanalysis)])
        error('io:save_results:Action06MatricesMustBeSparse', ...
            'Action 06 matrices must remain sparse when persisted.');
    end
    save(fullfile(run.folder,'action06_matrices.mat'), ...
        'schemaVersion','M','Ke','Kg','KOmega','K','Tanalysis', ...
        'operatingPoints','action06Results','-v7.3');
end

if isfield(results,'action07') && ~isempty(results.action07)
    M=ops.full.M;C=ops.full.C;G=ops.full.G;D=ops.full.D; %#ok<NASGU>
    Ke=ops.full.Ke;Kg=ops.full.Kg;KOmega=ops.full.KOmega; %#ok<NASGU>
    Kaero=ops.full.Kaero;Caero=ops.full.Caero;K=ops.full.K; %#ok<NASGU>
    Tanalysis=ops.reduced.Tc;operatingPoints=ops.operatingPoints; %#ok<NASGU>
    action07Results=results.action07;schemaVersion="1.0.0"; %#ok<NASGU>
    matrices={M,C,G,D,Ke,Kg,KOmega,Kaero,Caero,K,Tanalysis};
    if ~all(cellfun(@issparse,matrices))
        error('io:save_results:Action07MatricesMustBeSparse', ...
            'Action 07 matrices must remain sparse when persisted.');
    end
    save(fullfile(run.folder,'action07_matrices.mat'), ...
        'schemaVersion','M','C','G','D','Ke','Kg','KOmega','Kaero', ...
        'Caero','K','Tanalysis','operatingPoints','action07Results','-v7.3');
end

if isfield(results,'action08') && ~isempty(results.action08)
    Tanalysis=ops.reduced.Tc; %#ok<NASGU>
    operatingPoints=ops.operatingPoints; %#ok<NASGU>
    modalSolutions=results.modal.solutions; %#ok<NASGU>
    action08Results=results.action08; %#ok<NASGU>
    schemaVersion="1.0.0"; %#ok<NASGU>
    if ~issparse(Tanalysis)
        error('io:save_results:Action08AnalysisMapMustBeSparse', ...
            'Action 08 analysis transformation must remain sparse.');
    end
    for index=1:numel(modalSolutions)
        solution=modalSolutions{index};
        matrices={solution.transformedOperators.M, ...
            solution.transformedOperators.D,solution.transformedOperators.K};
        transforms={solution.mbc.transformation.T, ...
            solution.mbc.transformation.Tinv, ...
            solution.mbc.transformation.Tdot, ...
            solution.mbc.transformation.Tddot};
        if ~all(cellfun(@issparse,[matrices transforms]))
            error('io:save_results:Action08MatricesMustBeSparse', ...
                'Action 08 transformed matrices and maps must remain sparse.');
        end
        if ~all(cellfun(@(A)all(isfinite(nonzeros(A))),[matrices transforms]))
            error('io:save_results:Action08MatricesMustBeFinite', ...
                'Action 08 persisted matrices and maps must be finite.');
        end
    end
    save(fullfile(run.folder,'action08_matrices.mat'), ...
        'schemaVersion','Tanalysis','operatingPoints','modalSolutions', ...
        'action08Results','-v7.3');
end

if isfield(results,'action09') && ~isempty(results.action09)
    operatingPoints=ops.operatingPoints; %#ok<NASGU>
    speeds=cellfun(@(point)double(point.speedRPM),operatingPoints);
    stationaryIndex=find(abs(speeds)<=eps,1);
    rotatingIndex=find(abs(speeds-double(cfg.rotor.speedRPM))<=eps,1);
    if isempty(stationaryIndex)||isempty(rotatingIndex)
        error('io:save_results:MissingAction09OperatingPoints', ...
            'Action 09 persistence requires stationary and rotating operators.');
    end
    stationaryOperators=localAction09Operators( ...
        operatingPoints{stationaryIndex}); %#ok<NASGU>
    rotatingOperators=localAction09Operators( ...
        operatingPoints{rotatingIndex}); %#ok<NASGU>
    Tanalysis=ops.reduced.Tc; %#ok<NASGU>
    responseStationary=results.action09.responses.stationary; %#ok<NASGU>
    responseRotating=results.action09.responses.rotating; %#ok<NASGU>
    convergenceResponses=results.action09.convergenceResponses; %#ok<NASGU>
    elementForces=results.action09.elementForces; %#ok<NASGU>
    Rfull=responseRotating.GammaFullAbsolute; %#ok<NASGU>
    GammaKinematic=responseRotating.GammaKinematic; %#ok<NASGU>
    GammaEffective=responseRotating.GammaEffective; %#ok<NASGU>
    processedRecord=responseRotating.accelerogram; %#ok<NASGU>
    action09Results=rmfield(results.action09, ...
        {'responses','convergenceResponses','elementForces'}); %#ok<NASGU>
    schemaVersion="1.0.0"; %#ok<NASGU>
    matrices={stationaryOperators.full.M,stationaryOperators.full.D, ...
        stationaryOperators.full.K,stationaryOperators.reduced.M, ...
        stationaryOperators.reduced.D,stationaryOperators.reduced.K, ...
        rotatingOperators.full.M,rotatingOperators.full.D, ...
        rotatingOperators.full.K,rotatingOperators.reduced.M, ...
        rotatingOperators.reduced.D,rotatingOperators.reduced.K,Tanalysis,Rfull};
    if ~all(cellfun(@issparse,matrices))
        error('io:save_results:Action09MatricesMustBeSparse', ...
            'Action 09 full/reduced operators and influence maps must remain sparse.');
    end
    if ~all(cellfun(@(A)all(isfinite(nonzeros(A))),matrices))|| ...
            ~all(isfinite(responseRotating.q),'all')|| ...
            ~all(isfinite(responseStationary.q),'all')
        error('io:save_results:Action09DataMustBeFinite', ...
            'Action 09 persisted operators and responses must be finite.');
    end
    save(fullfile(run.folder,'action09_matrices.mat'), ...
        'schemaVersion','stationaryOperators','rotatingOperators', ...
        'operatingPoints','Tanalysis','Rfull','GammaKinematic', ...
        'GammaEffective','processedRecord','responseStationary', ...
        'responseRotating','convergenceResponses','elementForces', ...
        'action09Results','-v7.3');
end

if isfield(results,'action10') && ~isempty(results.action10)
    Tanalysis=ops.reduced.Tc; %#ok<NASGU>
    primaryOperators=struct('M',ops.reduced.M,'D',ops.reduced.D, ...
        'K',ops.reduced.K); %#ok<NASGU>
    preflight=localNestedField(results,{'validationPreflight'},struct()); %#ok<NASGU>
    action10Results=results.action10; %#ok<NASGU>
    canonicalRuns=cfg.action10.canonicalRuns; %#ok<NASGU>
    schemaVersion="1.0.0"; %#ok<NASGU>
    save(fullfile(run.folder,'action10_matrices.mat'), ...
        'schemaVersion','Tanalysis','primaryOperators','preflight', ...
        'canonicalRuns','action10Results','-v7.3');
end

manifest = localManifest(run, cfg, modelData, results); %#ok<NASGU>
save(fullfile(run.folder, 'manifest.mat'), 'manifest');
localWriteText(fullfile(run.folder, 'manifest.json'), jsonencode(manifest, PrettyPrint=true));
end

function manifest = localManifest(run, cfg, modelData, results)
manifest = struct();
manifest.schemaVersion = "1.0.0";
manifest.runId = run.id;
manifest.startedAt = char(run.startedAt);
manifest.completedAt = char(datetime('now', 'TimeZone', 'local'));
manifest.matlabVersion = version;
manifest.computer = computer;
manifest.units = cfg.units;
manifest.analysis = cfg.analysis;
manifest.modelVersion = "turbine-fem-1.0.0";
manifest.nodeCount = size(modelData.mesh.nodes.xyz, 1);
manifest.elementCount = numel(modelData.mesh.elements.id);
manifest.hasModal = isfield(results, 'modal') && ~isempty(results.modal);
manifest.hasTimeHistory = isfield(results, 'time') && ~isempty(results.time);
manifest.hasAction02 = isfield(results, 'action02') && ~isempty(results.action02);
if manifest.hasAction02 && isfield(results.action02, 'passed')
    manifest.action02Passed = logical(results.action02.passed);
end
manifest.hasAction03 = isfield(results,'action03') && ~isempty(results.action03);
if manifest.hasAction03 && isfield(results.action03,'passed')
    manifest.action03Passed = logical(results.action03.passed);
end
manifest.hasAction04 = isfield(results,'action04') && ~isempty(results.action04);
if manifest.hasAction04 && isfield(results.action04,'passed')
    manifest.action04Passed = logical(results.action04.passed);
end
manifest.hasAction05 = isfield(results,'action05') && ~isempty(results.action05);
if manifest.hasAction05 && isfield(results.action05,'passed')
    manifest.action05Passed = logical(results.action05.passed);
end
manifest.hasAction06 = isfield(results,'action06') && ~isempty(results.action06);
if manifest.hasAction06 && isfield(results.action06,'passed')
    manifest.action06Passed = logical(results.action06.passed);
end
manifest.hasAction07 = isfield(results,'action07') && ~isempty(results.action07);
if manifest.hasAction07 && isfield(results.action07,'passed')
    manifest.action07Passed = logical(results.action07.passed);
end
manifest.hasAction08 = isfield(results,'action08') && ~isempty(results.action08);
if manifest.hasAction08 && isfield(results.action08,'passed')
    manifest.action08Passed = logical(results.action08.passed);
end
manifest.hasAction09 = isfield(results,'action09') && ~isempty(results.action09);
if manifest.hasAction09 && isfield(results.action09,'passed')
    manifest.action09Passed = logical(results.action09.passed);
end
manifest.hasAction10 = isfield(results,'action10') && ~isempty(results.action10);
if manifest.hasAction10 && isfield(results.action10,'passed')
    manifest.action10Passed = logical(results.action10.passed);
end
manifest.legacyManifest = "legacy/MANIFEST.sha256";
end

function saved=localAction09Operators(point)
saved=struct('speedRPM',double(point.speedRPM), ...
    'full',struct('M',point.full.M,'D',point.full.D,'K',point.full.K, ...
    'G',point.full.G,'Kg',point.full.Kg,'KOmega',point.full.KOmega), ...
    'reduced',struct('M',point.reduced.M,'D',point.reduced.D, ...
    'K',point.reduced.K,'G',point.reduced.G,'Kg',point.reduced.Kg, ...
    'KOmega',point.reduced.KOmega));
end

function [M, Ke] = localAction02Matrices(ops)
if isfield(ops, 'full') && isfield(ops.full, 'M') && ...
        isfield(ops.full, 'Ke')
    M = ops.full.M;
    Ke = ops.full.Ke;
elseif isfield(ops, 'M') && isfield(ops, 'Ke')
    M = ops.M;
    Ke = ops.Ke;
else
    error('io:save_results:MissingAction02Matrices', ...
        'Action 02 results require stored M and Ke matrices.');
end
if ~issparse(M) || ~issparse(Ke)
    error('io:save_results:Action02MatricesMustBeSparse', ...
        'Action 02 M and Ke must remain sparse when persisted.');
end
end

function [M,Ke,Tc,Mr,Ker] = localAction03Matrices(ops)
requiredFull = {'M','Ke','Tc'};
requiredReduced = {'M','Ke'};
if ~isfield(ops,'full') || ~isfield(ops,'reduced') || ...
        ~all(isfield(ops.full,requiredFull)) || ...
        ~all(isfield(ops.reduced,requiredReduced))
    error('io:save_results:MissingAction03Matrices', ...
        'Action 03 requires full M/Ke/Tc and reduced M/Ke matrices.');
end
M=ops.full.M; Ke=ops.full.Ke; Tc=ops.full.Tc;
Mr=ops.reduced.M; Ker=ops.reduced.Ke;
if ~all([issparse(M),issparse(Ke),issparse(Tc),issparse(Mr),issparse(Ker)])
    error('io:save_results:Action03MatricesMustBeSparse', ...
        'Action 03 matrices must remain sparse when persisted.');
end
end

function [Mdistributed,M,Ke,Tc,Mr,Ker] = localAction04Matrices(ops)
requiredFull={'Mdistributed','M','Ke','Tc'};
requiredReduced={'M','Ke'};
if ~isfield(ops,'full')||~isfield(ops,'reduced')|| ...
        ~all(isfield(ops.full,requiredFull))|| ...
        ~all(isfield(ops.reduced,requiredReduced))
    error('io:save_results:MissingAction04Matrices', ...
        'Action 04 requires distributed/full/reduced mass and stiffness data.');
end
Mdistributed=ops.full.Mdistributed;M=ops.full.M;Ke=ops.full.Ke;
Tc=ops.full.Tc;Mr=ops.reduced.M;Ker=ops.reduced.Ke;
if ~all([issparse(Mdistributed),issparse(M),issparse(Ke), ...
        issparse(Tc),issparse(Mr),issparse(Ker)])
    error('io:save_results:Action04MatricesMustBeSparse', ...
        'Action 04 matrices must remain sparse when persisted.');
end
end

function [Massembled,McDistributed,MhDistributed,Mc,Mh,Ke,Tc,Mrc,Mrh] = ...
        localAction05Matrices(ops)
requiredFull={'Massembled','Mdistributed','M','Ke','Tc'};
if ~isfield(ops,'full')||~isfield(ops,'reduced')|| ...
        ~isfield(ops,'comparison')||~isfield(ops.comparison,'hrz')|| ...
        ~all(isfield(ops.full,requiredFull))|| ...
        ~all(isfield(ops.comparison.hrz,{'Mdistributed','M','reduced'}))
    error('io:save_results:MissingAction05Matrices', ...
        'Action 05 requires consistent and HRZ matrix alternatives.');
end
Massembled=ops.full.Massembled;McDistributed=ops.full.Mdistributed;
Mc=ops.full.M;Ke=ops.full.Ke;Tc=ops.full.Tc;Mrc=ops.reduced.M;
MhDistributed=ops.comparison.hrz.Mdistributed;Mh=ops.comparison.hrz.M;
Mrh=ops.comparison.hrz.reduced.M;
matrices={Massembled,McDistributed,MhDistributed,Mc,Mh,Ke,Tc,Mrc,Mrh};
if ~all(cellfun(@issparse,matrices))
    error('io:save_results:Action05MatricesMustBeSparse', ...
        'Action 05 matrices must remain sparse when persisted.');
end
end

function value = localNestedField(source, path, fallback)
value = fallback;
cursor = source;
for index = 1:numel(path)
    if ~isstruct(cursor) || ~isfield(cursor, path{index})
        return
    end
    cursor = cursor.(path{index});
end
value = cursor;
end

function localWriteConfiguration(fileName, cfg)
textValue = jsonencode(localSerializable(cfg), PrettyPrint=true);
localWriteText(fileName, textValue);
end

function value = localSerializable(value)
if isa(value, 'function_handle')
    value = struct('type', 'function_handle', 'name', func2str(value));
elseif isa(value, 'datetime') || isa(value, 'duration') || isa(value, 'calendarDuration')
    value = string(value);
elseif istable(value)
    value = table2struct(value);
elseif issparse(value)
    value = full(value);
elseif isstruct(value)
    fields = fieldnames(value);
    for index = 1:numel(value)
        for fieldIndex = 1:numel(fields)
            name = fields{fieldIndex};
            value(index).(name) = localSerializable(value(index).(name));
        end
    end
elseif iscell(value)
    value = cellfun(@localSerializable, value, UniformOutput=false);
elseif isobject(value) && ~isstring(value)
    value = string(value);
end
end

function localWriteText(fileName, value)
fid = fopen(fileName, 'w');
if fid < 0
    error('io:save_results:OpenFailed', 'Cannot write %s.', fileName);
end
cleaner = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s\n', value);
end
