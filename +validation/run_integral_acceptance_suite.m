function suite = run_integral_acceptance_suite( ...
        modelData,ops,results,cfg,evidence)
%RUN_INTEGRAL_ACCEPTANCE_SUITE Audit requirements across Actions 02--09.
%   Specialized suites may be supplied in memory or reloaded from explicit
%   canonical run folders. Missing evidence is UNVERIFIED, never PASSED.

if nargin < 5 || isempty(evidence), evidence = struct(); end
if nargin < 4 || isempty(cfg), cfg = struct(); end
if nargin < 3 || isempty(results), results = struct(); end
if nargin < 2 || isempty(ops), ops = struct(); end
if nargin < 1 || isempty(modelData), modelData = struct(); end %#ok<NASGU>

checks = repmat(localRequirement("","","",true,0,0,"","",""),0,1);

% Preflight input and operator evidence.
[inputStatus,inputPass,inputMessage] = localInputStatus(results);
checks(end+1,1) = localRequirement("A10-PRE-001", ...
    "input.modelValidation","preflight",true,double(inputPass),1, ...
    inputStatus,inputMessage, ...
    "Run model.validate_model before assembling operators.", ...
    "results.input.validation"); %#ok<AGROW>

matrixChecks = validation.check_matrix_properties(ops,cfg);
if isstruct(ops) && isfield(ops,'operatingPoints') && ...
        iscell(ops.operatingPoints)
    for operatingIndex = 1:numel(ops.operatingPoints)
        currentChecks = validation.check_matrix_properties( ...
            ops.operatingPoints{operatingIndex},cfg);
        prefix = "operatingPoint"+compose("%02d",operatingIndex)+".";
        for checkIndex = 1:numel(currentChecks)
            currentChecks(checkIndex).name = prefix+currentChecks(checkIndex).name;
        end
        matrixChecks = [matrixChecks; currentChecks]; %#ok<AGROW>
    end
end
matrixTable = localMatrixTable(matrixChecks);
for index = 1:numel(matrixChecks)
    source = matrixChecks(index);
    checks(end+1,1) = localRequirement( ...
        localMatrixRequirementId(source.name),source.name,"preflight", ...
        source.critical,localScalar(source.value), ...
        localScalar(source.tolerance),localPassStatus(source.pass), ...
        source.message,"Inspect the named operator and its assembly ledger.", ...
        "operators.mat"); %#ok<AGROW>
end

% Load suites/results from explicit sources. No assumption is made that all
% historical suites coexist in the current results struct.
requiredActions = localNumericCfg(cfg,{'action10','requiredActions'},2:9);
requireArtifacts = localLogicalCfg(cfg, ...
    {'action10','requireCanonicalArtifacts'},true);
requireHashes = localLogicalCfg(cfg,{'action10','requireHashes'},false);
actionData = cell(9,1); loadedResults = cell(9,1);
evidenceRows = repmat(localEvidenceRow(0,"",false,false,0,""),0,1);
artifactRows = repmat(localArtifactRow(0,""),0,1);
for action = 2:9
    actionName = "action"+compose("%02d",action);
    isRequired = ismember(action,requiredActions);
    [actionData{action},loadedResults{action},source,folder] = ...
        localResolveAction(actionName,results,evidence,cfg);
    [available,passed,failureCount] = localSuiteStatus(actionData{action});
    evidenceRows(end+1,1) = localEvidenceRow(action,source,available, ...
        passed,failureCount,folder); %#ok<AGROW>
    if ~isRequired
        status = "not_applicable"; message = "Action excluded by configuration.";
    elseif ~available
        status = "unverified";
        message = "Required specialized suite was not found in memory or its canonical run.";
    elseif passed
        status = "passed"; message = "Specialized suite reports passed=true.";
    else
        status = "failed"; message = "Specialized suite reports a failed critical gate.";
    end
    checks(end+1,1) = localRequirement( ...
        "A10-INT-"+compose("%03d",action),actionName+".specializedSuite", ...
        "postflight",isRequired,double(passed),1,status,message, ...
        "Run and persist the specialized action suite before Action 10.", ...
        localEvidenceArtifact(folder,actionName+"Results")); %#ok<AGROW>

    artifact = localAuditArtifact(action,folder,requireHashes,evidence);
    artifactRows(end+1,1) = artifact; %#ok<AGROW>
    if ~isRequired || ~requireArtifacts
        artifactStatus = "not_applicable";
        artifactMessage = "Canonical artifact audit disabled or action excluded.";
        artifactCritical = false;
    elseif artifact.complete
        artifactStatus = "passed";
        artifactMessage = "Canonical run is reloadable and declares the action passed.";
        artifactCritical = true;
    elseif strlength(folder)==0 || ~artifact.folderExists
        artifactStatus = "unverified";
        artifactMessage = "Canonical run folder is absent or was not declared.";
        artifactCritical = true;
    else
        artifactStatus = "failed";
        artifactMessage = "Canonical run is present but incomplete or inconsistent.";
        artifactCritical = true;
    end
    checks(end+1,1) = localRequirement( ...
        "A10-ART-001."+actionName,actionName+".canonicalArtifact", ...
        "postflight",artifactCritical,double(artifact.complete),1, ...
        artifactStatus,artifactMessage, ...
        "Restore SUCCESS, manifest, results and action matrix evidence from one run.", ...
        folder); %#ok<AGROW>
end
evidenceTable = struct2table(evidenceRows);
artifactTable = struct2table(artifactRows);

% Modal/QEP/Campbell gates are read from Action 08 and the corresponding
% solution. They need not have been recomputed inside the Action-10 process.
modalResults = localGetField(results,'modal',struct());
if isempty(fieldnames(modalResults)) && isstruct(loadedResults{8})
    modalResults = localGetField(loadedResults{8},'modal',struct());
end
requireModal = localLogicalCfg(cfg,{'action10','requireModalEvidence'}, ...
    ismember(8,requiredActions));
checks = [checks; localModalRequirements( ...
    actionData{8},modalResults,requireModal)]; %#ok<AGROW>

% Action 09 owns detailed temporal physics. Direct state finiteness and its
% stable specialized checks are both required in the full acceptance case.
timeResults = localGetField(results,'time',struct());
if isempty(fieldnames(timeResults)) && isstruct(loadedResults{9})
    timeResults = localGetField(loadedResults{9},'time',struct());
end
requireTime = localLogicalCfg(cfg,{'action10','requireTimeHistory'}, ...
    ismember(9,requiredActions));
checks = [checks; localTimeRequirements( ...
    actionData{9},timeResults,requireTime,cfg)]; %#ok<AGROW>

checks(end+1,1) = localCalibrationRequirement(cfg); %#ok<AGROW>
requirementTable = struct2table(checks);
criticalFailureMask = [checks.critical].' & ~[checks.pass].';

suite = struct();
suite.schemaVersion = "1.0.0";
suite.scope = "integral_preflight_postflight_and_canonical_evidence_audit";
suite.generatedAt = datetime('now','TimeZone','local');
suite.checks = checks;
suite.requirementTable = requirementTable;
suite.matrixTable = matrixTable;
suite.evidenceTable = evidenceTable;
suite.artifactTable = artifactTable;
suite.passed = ~any(criticalFailureMask);
suite.criticalFailures = checks(criticalFailureMask);
suite.unverifiedCount = nnz([checks.status] == "unverified");
suite.failedCount = nnz([checks.status] == "failed");

if localLogicalCfg(cfg,{'validation','failOnCritical'},true) && ~suite.passed
    identifiers = strjoin([suite.criticalFailures.requirementId],', ');
    error('validation:run_integral_acceptance_suite:CriticalFailure', ...
        'Action 10 critical requirements failed or remain unverified: %s', ...
        identifiers);
end
end

function checks = localModalRequirements(action08,modalResults,required)
checks = repmat(localRequirement("","","",true,0,0,"","",""),0,1);
mapping = {
    "A10-MOD-002",["qep.maximumRightResidual","qep.maximumLeftResidual", ...
        "qep.conjugatePairs","qep.biorthogonality"], ...
        "modal.qepResiduals","Action 08 must expose right/left residual, pair and biorthogonality gates.";
    "A10-MOD-003",["tracking.minimumEffectiveMAC", ...
        "tracking.minimumSubspaceMAC"],"modal.campbellContinuity", ...
        "Action 08 must expose individual/effective and subspace tracking gates.";
    "A10-MOD-004","mbc.zeroSpeedConservativeEquivalence", ...
        "modal.zeroSpeedEquivalence", ...
        "Action 08 must expose conservative zero-speed equivalence."};
for row = 1:size(mapping,1)
    checks(end+1,1) = localMappedSuiteRequirement(action08, ...
        mapping{row,2},mapping{row,1},mapping{row,3},required, ...
        mapping{row,4},"action08_matrices.mat"); %#ok<AGROW>
end

if ~required
    checks(end+1,1) = localRequirement("A10-MOD-001", ...
        "modal.finiteAndClassified","postflight",false,0,0, ...
        "not_applicable","Modal evidence excluded by configuration.", ...
        "Enable Action 08 evidence.","results.modal");
    checks(end+1,1) = localRequirement("A10-MOD-005", ...
        "modal.spectrumScopeDeclared","postflight",false,0,0, ...
        "not_applicable","Modal evidence excluded by configuration.", ...
        "Enable Action 08 evidence.","results.modal.solutions");
    return
end

[finite,classified] = localModalState(modalResults);
if isempty(fieldnames(modalResults))
    status = "unverified"; message = "Modal result was not found.";
else
    status = localPassStatus(finite&&classified);
    message = "Computed modal values must be finite and classifications nonempty.";
end
checks(end+1,1) = localRequirement("A10-MOD-001", ...
    "modal.finiteAndClassified","postflight",true, ...
    double(finite&&classified),1,status,message, ...
    "Regenerate and classify every requested Campbell branch.", ...
    "results.modal");

[declared,fractionComplete] = localSpectrumDeclaration(modalResults);
if isempty(fieldnames(modalResults)), status = "unverified";
else, status = localPassStatus(declared); end
checks(end+1,1) = localRequirement("A10-MOD-005", ...
    "modal.spectrumScopeDeclared","postflight",true, ...
    fractionComplete,0,status, ...
    "Every modal solution must explicitly declare spectrumComplete; false is allowed and means targeted roots only.", ...
    "Persist the spectrumComplete flag and limit stability claims accordingly.", ...
    "results.modal.solutions");
end

function checks = localTimeRequirements(action09,timeResults,required,cfg)
checks = repmat(localRequirement("","","",true,0,0,"","",""),0,1);
mapping = {
    "A10-TIM-002",["response.absoluteKinematics", ...
        "constraints.projectedEquilibrium","constraints.supportRowsSeparated"], ...
        "time.kinematicsConstraintsReactions", ...
        "Action 09 must verify absolute kinematics, projected equilibrium and support/MPC separation.";
    "A10-TIM-003",["elements.localGlobalBackwardError", ...
        "elements.globalAssembly"],"time.internalForces", ...
        "Action 09 must verify local/global force recovery and assembly.";
    "A10-TIM-004","response.energyBalance","time.energyBalance", ...
        "Action 09 must verify the declared algorithmic energy balance.";
    "A10-TIM-005",["convergence.monotoneWaveformDifference", ...
        "convergence.modelTemporalOrder","convergence.fineRelativeDifference", ...
        "convergence.fineMaximumDifference"],"time.convergence", ...
        "Action 09 must verify order and agreement of the two finest meshes."};
for row = 1:size(mapping,1)
    checks(end+1,1) = localMappedSuiteRequirement(action09, ...
        mapping{row,2},mapping{row,1},mapping{row,3},required, ...
        mapping{row,4},"action09_matrices.mat"); %#ok<AGROW>
end

if ~required
    checks(end+1,1) = localRequirement("A10-TIM-001", ...
        "time.statesFinite","postflight",false,0,0,"not_applicable", ...
        "Time-history evidence excluded by configuration.", ...
        "Enable Action 09 evidence.","results.time");
    return
end
stateNames = {'q','qd','qdd'}; present = true; finite = true;
for index = 1:numel(stateNames)
    value = localFindRecursive(timeResults,stateNames(index));
    present = present && isnumeric(value) && ~isempty(value);
    finite = finite && isnumeric(value) && ~isempty(value) && ...
        all(isfinite(value(:)));
end
if ~present
    status = "unverified";
    message = "q, qd and qdd were not all found in the temporal artifact.";
else
    status = localPassStatus(finite);
    message = "q, qd and qdd must contain only finite values.";
end
checks(end+1,1) = localRequirement("A10-TIM-001", ...
    "time.statesFinite","postflight",true,double(finite&&present),1, ...
    status,message,"Regenerate the complete temporal state history.", ...
    "results.time");

% The generic postflight is retained as independent, stricter evidence.
if isempty(fieldnames(timeResults))
    checks(end+1,1) = localRequirement("A10-TIM-006", ...
        "time.genericPostflight","postflight",true,NaN,0,"unverified", ...
        "No temporal result was available for the generic postflight.", ...
        "Reload the accepted Action-09 temporal artifact.", ...
        "validation_summary.csv");
else
    postCfg = cfg;
    if ~isfield(postCfg,'validation'), postCfg.validation = struct(); end
    postCfg.validation.failOnCritical = false;
    postCfg.validation.requireEnergyBalance = true;
    post = validation.run_validation_suite(struct(),struct(), ...
        struct('time',timeResults),postCfg,"postflight");
    failed = nnz([post.checks.critical] & ~[post.checks.pass]);
    checks(end+1,1) = localRequirement("A10-TIM-006", ...
        "time.genericPostflight","postflight",true,double(failed),0, ...
        localPassStatus(failed==0), ...
        "Generic postflight must independently pass finite-state and energy gates.", ...
        "Inspect the failed generic time-history check.", ...
        "validation_summary.csv");
end
end

function item = localMappedSuiteRequirement(suiteData,names,id,name, ...
        required,message,artifact)
if ~required
    item = localRequirement(id,name,"postflight",false,0,0, ...
        "not_applicable","Evidence excluded by configuration.", ...
        "Enable the corresponding specialized action.",artifact);
    return
end
[available,passed,measured,tolerance] = localNamedChecks(suiteData,names);
if ~available
    status = "unverified";
elseif passed
    status = "passed";
else
    status = "failed";
end
item = localRequirement(id,name,"postflight",true,measured,tolerance, ...
    status,message,"Regenerate the specialized suite with all named gates.", ...
    artifact);
end

function [available,passed,measured,tolerance] = localNamedChecks(suiteData,names)
available = false; passed = false; measured = NaN; tolerance = NaN;
if ~isstruct(suiteData) || ~isfield(suiteData,'checks') || ...
        ~isstruct(suiteData.checks), return; end
names = string(names); sourceNames = string({suiteData.checks.name});
indices = zeros(numel(names),1);
for index = 1:numel(names)
    found = find(sourceNames==names(index),1);
    if isempty(found), return; end
    indices(index) = found;
end
selected = suiteData.checks(indices);
available = true;
passed = all([selected.pass]);
values = arrayfun(@(entry)localScalar(entry.value),selected);
tolerances = arrayfun(@(entry)localScalar(entry.tolerance),selected);
measured = max(abs(values),[],'omitnan');
tolerance = max(abs(tolerances),[],'omitnan');
end

function [status,pass,message] = localInputStatus(results)
status = "unverified"; pass = false;
message = "Input validation evidence was not found.";
if isstruct(results) && isfield(results,'input') && ...
        isstruct(results.input) && isfield(results.input,'validation') && ...
        isstruct(results.input.validation) && ...
        isfield(results.input.validation,'passed')
    pass = logical(results.input.validation.passed);
    status = localPassStatus(pass);
    message = "Input model validation must report passed=true.";
end
end

function tableValue = localMatrixTable(checks)
if isempty(checks)
    tableValue = table(string.empty(0,1),string.empty(0,1), ...
        false(0,1),zeros(0,1),zeros(0,1),string.empty(0,1), ...
        'VariableNames',{'name','status','pass','value','tolerance','message'});
    return
end
name = string({checks.name}).'; pass = [checks.pass].';
value = arrayfun(@(entry)localScalar(entry.value),checks);
tolerance = arrayfun(@(entry)localScalar(entry.tolerance),checks);
message = string({checks.message}).'; status = strings(numel(checks),1);
status(pass) = "passed"; status(~pass) = "failed";
tableValue = table(name,status,pass,value,tolerance,message);
end

function id = localMatrixRequirementId(name)
name = string(name);
if contains(name,"componentIdentity"), id = "A10-PRE-006";
elseif contains(name,"M.positive"), id = "A10-PRE-007";
elseif contains(name,"Tc."), id = "A10-PRE-008";
elseif contains(name,"G.skew"), id = "A10-PRE-004";
elseif contains(name,"Cpassive.semidefinite"), id = "A10-PRE-005";
elseif contains(name,"symmetry"), id = "A10-PRE-003";
else, id = "A10-PRE-002";
end
end

function [data,loadedResults,source,folder] = localResolveAction( ...
        actionName,results,evidence,cfg)
data = struct(); loadedResults = struct(); source = "missing";
folder = localActionFolder(actionName,evidence,cfg);
if isfield(results,actionName) && isstruct(results.(actionName))
    data = results.(actionName); source = "in_memory";
end
if isempty(fieldnames(data)) && isstruct(evidence)
    if isfield(evidence,actionName) && isstruct(evidence.(actionName))
        data = evidence.(actionName); source = "provided_evidence";
    elseif isfield(evidence,'actions') && isstruct(evidence.actions) && ...
            isfield(evidence.actions,actionName) && ...
            isstruct(evidence.actions.(actionName))
        data = evidence.actions.(actionName); source = "provided_evidence";
    end
end
resultsFile = fullfile(char(folder),'results.mat');
needsReload = isempty(fieldnames(data));
if actionName=="action08"
    needsReload = needsReload || ~isfield(results,'modal') || ...
        ~isstruct(results.modal) || isempty(fieldnames(results.modal));
elseif actionName=="action09"
    needsReload = needsReload || ~isfield(results,'time') || ...
        ~isstruct(results.time) || isempty(fieldnames(results.time));
end
if needsReload && strlength(folder)>0 && isfile(resultsFile)
    try
        loaded = load(resultsFile,'results');
        if isfield(loaded,'results') && isstruct(loaded.results)
            loadedResults = loaded.results;
            if isempty(fieldnames(data)) && isfield(loaded.results,actionName)
                data = loaded.results.(actionName);
                source = "canonical_run";
            elseif source == "missing"
                source = "canonical_run_without_suite";
            end
        end
    catch
        source = "unreadable_canonical_run";
    end
end
end

function folder = localActionFolder(actionName,evidence,cfg)
folder = "";
if isstruct(evidence) && isfield(evidence,'runFolders') && ...
        isstruct(evidence.runFolders) && isfield(evidence.runFolders,actionName)
    folder = string(evidence.runFolders.(actionName));
elseif isstruct(cfg) && isfield(cfg,'action10') && ...
        isfield(cfg.action10,'canonicalRuns') && ...
        isstruct(cfg.action10.canonicalRuns) && ...
        isfield(cfg.action10.canonicalRuns,actionName)
    folder = string(cfg.action10.canonicalRuns.(actionName));
end
if ~isscalar(folder), folder = ""; end
end

function artifact = localAuditArtifact(action,folder,requireHashes,evidence)
artifact = localArtifactRow(action,folder);
if strlength(folder)==0, return; end
artifact.folderExists = isfolder(folder);
if ~artifact.folderExists, return; end
actionName = "action"+compose("%02d",action);
resultsFile = fullfile(char(folder),'results.mat');
manifestFile = fullfile(char(folder),'manifest.mat');
matrixFile = fullfile(char(folder),char(actionName+"_matrices.mat"));
artifact.successMarker = isfile(fullfile(char(folder),'SUCCESS'));
artifact.resultsReadable = localHasVariable(resultsFile,'results');
artifact.manifestReadable = localHasVariable(manifestFile,'manifest');
artifact.matrixReadable = localHasVariable(matrixFile,'schemaVersion');
artifact.schemaCompatible = localSchemaCompatible(manifestFile,matrixFile);
if artifact.manifestReadable
    try
        loaded = load(manifestFile,'manifest'); manifest = loaded.manifest;
        hasField = "hasAction"+compose("%02d",action);
        passedField = actionName+"Passed";
        artifact.manifestDeclared = isfield(manifest,hasField) && ...
            logical(manifest.(hasField));
        artifact.manifestPassed = isfield(manifest,passedField) && ...
            logical(manifest.(passedField));
    catch
    end
end
artifact.hashVerified = ~requireHashes;
if requireHashes
    artifact.resultsSha256 = localFileHash(resultsFile);
    artifact.manifestSha256 = localFileHash(manifestFile);
    artifact.matricesSha256 = localFileHash(matrixFile);
    computed = all(strlength([artifact.resultsSha256, ...
        artifact.manifestSha256,artifact.matricesSha256])==64);
    expected = localExpectedHashes(actionName,evidence);
    if expected.available
        computed = computed && strcmpi(artifact.resultsSha256,expected.results) && ...
            strcmpi(artifact.manifestSha256,expected.manifest) && ...
            strcmpi(artifact.matricesSha256,expected.matrices);
    end
    artifact.hashVerified = computed;
end
artifact.complete = artifact.folderExists && artifact.successMarker && ...
    artifact.resultsReadable && artifact.manifestReadable && ...
    artifact.matrixReadable && artifact.schemaCompatible && ...
    artifact.manifestDeclared && artifact.manifestPassed && ...
    artifact.hashVerified;
end

function compatible = localSchemaCompatible(manifestFile,matrixFile)
compatible = false;
try
    a = load(manifestFile,'manifest'); b = load(matrixFile,'schemaVersion');
    compatible = isfield(a,'manifest') && isfield(a.manifest,'schemaVersion') && ...
        startsWith(string(a.manifest.schemaVersion),"1.") && ...
        isfield(b,'schemaVersion') && startsWith(string(b.schemaVersion),"1.");
catch
end
end

function tf = localHasVariable(fileName,variable)
tf = false;
if ~isfile(fileName), return; end
try
    info = whos('-file',fileName);
    tf = any(string({info.name})==string(variable));
catch
end
end

function expected = localExpectedHashes(actionName,evidence)
expected = struct('available',false,'results',"",'manifest',"", ...
    'matrices',"");
if ~isstruct(evidence) || ~isfield(evidence,'hashes') || ...
        ~isstruct(evidence.hashes) || ~isfield(evidence.hashes,actionName)
    return
end
entry = evidence.hashes.(actionName);
if ~isstruct(entry) || ~all(isfield(entry,{'results','manifest','matrices'}))
    return
end
expected.results = string(entry.results);
expected.manifest = string(entry.manifest);
expected.matrices = string(entry.matrices);
expected.available = all(strlength([expected.results,expected.manifest, ...
    expected.matrices])==64);
end

function digest = localFileHash(fileName)
% macOS/Linux audit helper. Paths are validated and single-quoted so the
% configured run folder cannot add shell syntax.
digest = "";
fileName = char(string(fileName));
if ~isfile(fileName) || isempty(regexp(fileName, ...
        '^[A-Za-z0-9_./ @()+,=-]+$','once'))
    return
end
[status,output] = system(sprintf('shasum -a 256 ''%s''',fileName));
if status ~= 0, return; end
token = regexp(strtrim(output),'^([0-9a-fA-F]{64})\s','tokens','once');
if ~isempty(token), digest = lower(string(token{1})); end
end

function [available,passed,failureCount] = localSuiteStatus(data)
available = isstruct(data) && ~isempty(fieldnames(data)) && ...
    isfield(data,'passed') && isscalar(data.passed);
passed = available && logical(data.passed);
failureCount = NaN;
if available && isfield(data,'checks') && isstruct(data.checks)
    failureCount = nnz([data.checks.critical] & ~[data.checks.pass]);
end
end

function [finite,classified] = localModalState(modalResults)
finite = false; classified = false;
if ~isstruct(modalResults) || isempty(fieldnames(modalResults)), return; end
frequencies = localFindRecursive(modalResults,{'frequencyHz'});
finite = isnumeric(frequencies) && ~isempty(frequencies) && ...
    all(isfinite(frequencies(:)));
if isfield(modalResults,'classification') && iscell(modalResults.classification)
    classified = true;
    for index = 1:numel(modalResults.classification)
        entry = modalResults.classification{index};
        classified = classified && isstruct(entry) && isfield(entry,'labels') && ...
            all(strlength(string(entry.labels))>0);
    end
end
end

function [declared,fractionComplete] = localSpectrumDeclaration(modalResults)
declared = false; fractionComplete = NaN;
if ~isstruct(modalResults) || ~isfield(modalResults,'solutions') || ...
        ~iscell(modalResults.solutions) || isempty(modalResults.solutions)
    return
end
flags = false(numel(modalResults.solutions),1); declared = true;
for index = 1:numel(flags)
    entry = modalResults.solutions{index};
    if ~isstruct(entry) || ~isfield(entry,'spectrumComplete') || ...
            ~isscalar(entry.spectrumComplete)
        declared = false; return
    end
    flags(index) = logical(entry.spectrumComplete);
end
fractionComplete = mean(flags);
end

function item = localCalibrationRequirement(cfg)
paths = {{'drivetrain','calibrationStatus'}, ...
    {'damping','calibrationStatus'},{'aerodynamics','status'}};
present = true; labels = strings(numel(paths),1);
for index = 1:numel(paths)
    labels(index) = string(localAnyCfg(cfg,paths{index},""));
    present = present && isscalar(labels(index)) && strlength(labels(index))>0;
end
if present, status = "passed"; else, status = "unverified"; end
item = localRequirement("A10-ART-004","physics.calibrationTraceability", ...
    "postflight",true,double(present),1,status, ...
    "Drivetrain, damping and aerodynamic calibration states must be explicit.", ...
    "Label missing inputs as benchmark/unprovided rather than calibrated.", ...
    "configuration.mat");
end

function value = localFindRecursive(source,names)
value = [];
if ~isstruct(source), return; end
names = cellstr(string(names));
for index = 1:numel(names)
    if isfield(source,names{index}), value = source.(names{index}); return; end
end
fields = fieldnames(source);
for index = 1:numel(fields)
    candidate = source.(fields{index});
    if isstruct(candidate)
        value = localFindRecursive(candidate,names);
        if ~isempty(value), return; end
    end
end
end

function value = localGetField(source,name,fallback)
value = fallback;
if isstruct(source) && isfield(source,name) && isstruct(source.(name))
    value = source.(name);
end
end

function value = localAnyCfg(cfg,path,fallback)
value = fallback; cursor = cfg;
for index = 1:numel(path)
    if ~isstruct(cursor) || ~isfield(cursor,path{index}), return; end
    cursor = cursor.(path{index});
end
value = cursor;
end

function value = localNumericCfg(cfg,path,fallback)
value = localAnyCfg(cfg,path,fallback);
if ~isnumeric(value) || any(~isfinite(value(:))), value = fallback; end
value = unique(double(value(:).'));
end

function value = localLogicalCfg(cfg,path,fallback)
value = localAnyCfg(cfg,path,fallback);
if ~(islogical(value)||isnumeric(value)) || ~isscalar(value)
    value = fallback;
end
value = logical(value);
end

function value = localScalar(value)
if isnumeric(value) && isscalar(value), value = double(value);
elseif islogical(value) && isscalar(value), value = double(value);
else, value = NaN;
end
end

function status = localPassStatus(pass)
if pass, status = "passed"; else, status = "failed"; end
end

function artifact = localEvidenceArtifact(folder,fallback)
if strlength(folder)>0, artifact = folder; else, artifact = fallback; end
end

function item = localRequirement(id,name,phase,critical,value,tolerance, ...
        status,message,recommendedAction,evidenceArtifact)
if nargin < 10, evidenceArtifact = ""; end
if nargin < 9, recommendedAction = ""; end
if nargin < 8, message = ""; end
status = string(status);
item = struct('requirementId',string(id),'name',string(name), ...
    'phase',string(phase),'status',status, ...
    'pass',status=="passed" || status=="not_applicable", ...
    'value',localScalar(value),'tolerance',localScalar(tolerance), ...
    'critical',logical(critical),'message',string(message), ...
    'recommendedAction',string(recommendedAction), ...
    'evidenceArtifact',string(evidenceArtifact));
end

function row = localEvidenceRow(action,source,available,passed,failures,folder)
row = struct('action',double(action),'source',string(source), ...
    'suiteAvailable',logical(available),'suitePassed',logical(passed), ...
    'criticalFailureCount',localScalar(failures), ...
    'runFolder',string(folder));
end

function row = localArtifactRow(action,folder)
row = struct('action',double(action),'runFolder',string(folder), ...
    'folderExists',false,'successMarker',false,'resultsReadable',false, ...
    'manifestReadable',false,'matrixReadable',false, ...
    'schemaCompatible',false,'manifestDeclared',false, ...
    'manifestPassed',false,'resultsSha256',"",'manifestSha256',"", ...
    'matricesSha256',"",'hashVerified',false,'complete',false);
end
