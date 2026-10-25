function results = main(configFile)
%MAIN Coordinate one reproducible wind-turbine analysis.

projectRoot = fileparts(mfilename('fullpath'));
addpath(projectRoot);
if nargin < 1
    configFile = [];
end
cfg = io.load_configuration(configFile);
run = io.create_run_folder(cfg);
diary(run.logFile);
cleanupObject = onCleanup(@() diary('off')); %#ok<NASGU>

fprintf('Wind-turbine solver run %s\n',run.id);
fprintf('MATLAB %s, analysis=%s, base=%s, mass=%s\n', ...
    version,string(cfg.analysis.type),string(cfg.base.type),string(cfg.mass.formulation));

try
    data = io.load_model_data(cfg);
    modelData = model.build_model(data,cfg);
    inputValidation = model.validate_model(modelData,cfg);

    results = struct();
    results.meta = struct('schemaVersion',"1.0.0",'runId',run.id, ...
        'runFolder',string(run.folder),'modelVersion',"turbine-fem-1.0.0", ...
        'matlabVersion',string(version),'analysisType',string(cfg.analysis.type), ...
        'massFormulation',string(cfg.mass.formulation),'units',cfg.units, ...
        'startedAt',run.startedAt);
    results.input = struct('validation',inputValidation,'summary',modelData.summary, ...
        'reference',modelData.reference);
    state = struct();
    ops = struct();

    analysisType = lower(string(cfg.analysis.type));
    geometryOnly = any(analysisType == ...
        ["geometry","geometry_only","validate","validation"]);
    action02Only = any(analysisType == ...
        ["action02","action02_timoshenko","timoshenko_validation"]);
    action03Only = any(analysisType == ...
        ["action03","action03_rigid_constraints","rigid_constraint_validation"]);
    action04Only = any(analysisType == ...
        ["action04","action04_rigid_bodies","rigid_body_mass_validation"]);
    action05Only = any(analysisType == ...
        ["action05","action05_mass_formulation","mass_formulation_validation"]);
    action06Only = any(analysisType == ...
        ["action06","action06_equilibrium","equilibrium_validation"]);
    action07Only = any(analysisType == ...
        ["action07","action07_dynamic_operators", ...
         "dynamic_operator_validation"]);
    action08Only = any(analysisType == ...
        ["action08","action08_mbc_qep_campbell", ...
         "mbc_qep_campbell_validation"]);
    action09Only = any(analysisType == ...
        ["action09","action09_seismic_newmark", ...
         "seismic_newmark_validation"]);
    action10Only = any(analysisType == ...
        ["action10","action10_full_acceptance", ...
         "integral_acceptance_validation"]);
    if action02Only
        % Action 02 deliberately stops at the unconstrained flexible mesh.
        % Rigid bodies, Tc, equilibrium and all operating-point operators
        % belong to later actions and must not contaminate these benchmarks.
        [M,Ke,elementCache,assemblyDiagnostics] = ...
            assembly.assemble_structural_matrices(modelData,cfg);
        ops = struct();
        ops.full = struct('M',M,'Ke',Ke);
        ops.cache = elementCache;
        ops.diagnostics = struct('structuralAssembly',assemblyDiagnostics);
        results.action02 = validation.run_timoshenko_suite( ...
            modelData,M,Ke,elementCache,assemblyDiagnostics,cfg);
        if ~isfield(results.action02,'elementDiagnostics')
            results.action02.elementDiagnostics = ...
                localAction02ElementDiagnostics(elementCache);
        end
        results.meta.analysisScope = "unconstrained_flexible_mesh";
    elseif action03Only
        % Action 03 isolates exact master/slave kinematics. Concentrated
        % bodies and all operating-point physics begin in later actions.
        [M,Ke,elementCache,assemblyDiagnostics] = ...
            assembly.assemble_structural_matrices(modelData,cfg);
        bodies = modelData.rigidBodies;
        [Tc,constraintDiagnostics] = rigid.rigid_constraint_matrix( ...
            modelData,bodies,cfg);
        reduced = rigid.reduce_system(Tc,M,Ke,modelData,cfg);
        ops = struct();
        ops.full = struct('M',M,'Ke',Ke,'Tc',Tc);
        ops.reduced = reduced;
        ops.cache = elementCache;
        ops.diagnostics = struct('structuralAssembly',assemblyDiagnostics, ...
            'constraints',constraintDiagnostics);
        results.action03 = validation.run_rigid_constraint_suite( ...
            modelData,M,Ke,Tc,reduced,constraintDiagnostics, ...
            assemblyDiagnostics,cfg);
        results.meta.analysisScope = ...
            "exact_rigid_constraints_without_concentrated_body_masses";
    elseif action04Only
        % Action 04 adds only the traced spatial masses of nacelle and hub
        % before applying the already accepted exact constraint transform.
        [Mdistributed,Ke,elementCache,assemblyDiagnostics] = ...
            assembly.assemble_structural_matrices(modelData,cfg);
        [Mdistributed,massDiagnostics] = ...
            assembly.apply_mass_formulation(Mdistributed,cfg,modelData);
        bodies=modelData.rigidBodies;
        [M,bodyMassDiagnostics]=rigid.add_body_masses( ...
            Mdistributed,modelData,bodies);
        [Tc,constraintDiagnostics]=rigid.rigid_constraint_matrix( ...
            modelData,bodies,cfg);
        reduced=rigid.reduce_system(Tc,M,Ke,modelData,cfg);
        massProperties=rigid.compute_mass_properties(modelData,M,Tc);
        ops=struct();
        ops.full=struct('Mdistributed',Mdistributed,'M',M,'Ke',Ke,'Tc',Tc);
        ops.reduced=reduced;
        ops.cache=elementCache;
        ops.diagnostics=struct('structuralAssembly',assemblyDiagnostics, ...
            'massFormulation',massDiagnostics,'bodyMasses',bodyMassDiagnostics, ...
            'constraints',constraintDiagnostics);
        results.massProperties=massProperties;
        results.action04=validation.run_rigid_body_mass_suite( ...
            modelData,Mdistributed,M,Ke,Tc,reduced,constraintDiagnostics, ...
            bodyMassDiagnostics,massProperties,cfg);
        results.meta.analysisScope= ...
            "distributed_mass_plus_spatial_nacelle_and_hub_before_Tc";
    elseif action05Only
        % Action 05 keeps consistent mass as production and builds HRZ only
        % as an explicitly labelled sensitivity alternative.
        [Massembled,Ke,elementCache,assemblyDiagnostics]= ...
            assembly.assemble_structural_matrices(modelData,cfg);
        [McDistributed,consistentDiagnostics]= ...
            assembly.apply_mass_formulation(Massembled,cfg,modelData);
        hrzCfg=cfg;hrzCfg.mass.formulation="hrz";
        [MhDistributed,hrzDiagnostics]= ...
            assembly.apply_mass_formulation(Massembled,hrzCfg,modelData);
        bodies=modelData.rigidBodies;
        [Mc,bodyReportConsistent]=rigid.add_body_masses( ...
            McDistributed,modelData,bodies);
        [Mh,bodyReportHrz]=rigid.add_body_masses( ...
            MhDistributed,modelData,bodies);
        [Tc,constraintDiagnostics]=rigid.rigid_constraint_matrix( ...
            modelData,bodies,cfg);
        reducedConsistent=rigid.reduce_system(Tc,Mc,Ke,modelData,cfg);
        reducedHrz=rigid.reduce_system(Tc,Mh,Ke,modelData,cfg);
        propertiesConsistent=rigid.compute_mass_properties(modelData,Mc,Tc);
        propertiesHrz=rigid.compute_mass_properties(modelData,Mh,Tc);
        ops=struct();
        ops.full=struct('Massembled',Massembled,'Mdistributed',McDistributed, ...
            'M',Mc,'Ke',Ke,'Tc',Tc);
        ops.reduced=reducedConsistent;
        ops.comparison.hrz=struct('Mdistributed',MhDistributed,'M',Mh, ...
            'reduced',reducedHrz);
        ops.cache=elementCache;
        ops.diagnostics=struct('structuralAssembly',assemblyDiagnostics, ...
            'massFormulation',consistentDiagnostics,'hrz',hrzDiagnostics, ...
            'bodyMasses',bodyReportConsistent,'bodyMassesHrz',bodyReportHrz, ...
            'constraints',constraintDiagnostics);
        results.massProperties=propertiesConsistent;
        results.action05=validation.run_mass_formulation_suite( ...
            modelData,Massembled,McDistributed,MhDistributed,Mc,Mh,Ke,Tc, ...
            reducedConsistent,reducedHrz,bodyReportConsistent,bodyReportHrz, ...
            propertiesConsistent,propertiesHrz,consistentDiagnostics, ...
            hrzDiagnostics,cfg);
        results.meta.analysisScope= ...
            "consistent_production_with_optional_hrz_sensitivity";
    elseif action06Only
        [Mdistributed,Ke,elementCache,assemblyDiagnostics]= ...
            assembly.assemble_structural_matrices(modelData,cfg);
        [Mdistributed,massDiagnostics]= ...
            assembly.apply_mass_formulation(Mdistributed,cfg,modelData);
        bodies=modelData.rigidBodies;
        [M,bodyMassDiagnostics]=rigid.add_body_masses( ...
            Mdistributed,modelData,bodies);
        [Tc,constraintDiagnostics]=rigid.rigid_constraint_matrix( ...
            modelData,bodies,cfg);
        reduced=rigid.reduce_system(Tc,M,Ke,modelData,cfg);
        massProperties=rigid.compute_mass_properties(modelData,M,Tc);
        sweep=assembly.build_operating_sweep(modelData,reduced,cfg);
        state=sweep.primaryState;
        state.operatingPoints=sweep.states;
        state.speedRPMGrid=sweep.speedRPM;
        ops=sweep.primaryOps;
        ops.operatingPoints=sweep.ops;
        ops.cache=elementCache;
        ops.diagnostics.structuralAssembly=assemblyDiagnostics;
        ops.diagnostics.massFormulation=massDiagnostics;
        ops.diagnostics.bodyMasses=bodyMassDiagnostics;
        ops.diagnostics.constraints=constraintDiagnostics;
        results.equilibrium=state;
        results.massProperties=massProperties;
        results.action06=validation.run_equilibrium_suite( ...
            modelData,reduced,sweep,cfg);
        results.meta.analysisScope= ...
            "corotational_gravity_and_centrifugal_equilibrium";
    elseif action07Only
        [Mdistributed,Ke,elementCache,assemblyDiagnostics]= ...
            assembly.assemble_structural_matrices(modelData,cfg);
        [Mdistributed,massDiagnostics]= ...
            assembly.apply_mass_formulation(Mdistributed,cfg,modelData);
        bodies=modelData.rigidBodies;
        [M,bodyMassDiagnostics]=rigid.add_body_masses( ...
            Mdistributed,modelData,bodies);
        [Tc,constraintDiagnostics]=rigid.rigid_constraint_matrix( ...
            modelData,bodies,cfg);
        reduced=rigid.reduce_system(Tc,M,Ke,modelData,cfg);
        massProperties=rigid.compute_mass_properties(modelData,M,Tc);
        sweep=assembly.build_operating_sweep(modelData,reduced,cfg);
        state=sweep.primaryState;state.operatingPoints=sweep.states;
        state.speedRPMGrid=sweep.speedRPM;
        ops=sweep.primaryOps;ops.operatingPoints=sweep.ops;
        ops.cache=elementCache;
        ops.diagnostics.structuralAssembly=assemblyDiagnostics;
        ops.diagnostics.massFormulation=massDiagnostics;
        ops.diagnostics.bodyMasses=bodyMassDiagnostics;
        ops.diagnostics.constraints=constraintDiagnostics;
        results.equilibrium=state;results.massProperties=massProperties;
        results.action07=validation.run_dynamic_operator_suite( ...
            modelData,reduced,sweep,cfg);
        results.meta.analysisScope= ...
            "damping_distributed_and_rigid_gyroscopy_aerodynamic_linearization";
    elseif action08Only
        [Mdistributed,Ke,elementCache,assemblyDiagnostics]= ...
            assembly.assemble_structural_matrices(modelData,cfg);
        [Mdistributed,massDiagnostics]= ...
            assembly.apply_mass_formulation(Mdistributed,cfg,modelData);
        bodies=modelData.rigidBodies;
        [M,bodyMassDiagnostics]=rigid.add_body_masses( ...
            Mdistributed,modelData,bodies);
        [Tc,constraintDiagnostics]=rigid.rigid_constraint_matrix( ...
            modelData,bodies,cfg);
        reduced=rigid.reduce_system(Tc,M,Ke,modelData,cfg);
        massProperties=rigid.compute_mass_properties(modelData,M,Tc);
        sweep=assembly.build_operating_sweep(modelData,reduced,cfg);
        state=sweep.primaryState;state.operatingPoints=sweep.states;
        state.speedRPMGrid=sweep.speedRPM;
        ops=sweep.primaryOps;ops.operatingPoints=sweep.ops;
        ops.cache=elementCache;
        ops.diagnostics.structuralAssembly=assemblyDiagnostics;
        ops.diagnostics.massFormulation=massDiagnostics;
        ops.diagnostics.bodyMasses=bodyMassDiagnostics;
        ops.diagnostics.constraints=constraintDiagnostics;
        analysisModel=model.prepare_analysis_model(modelData,ops.reduced);
        results.equilibrium=state;results.massProperties=massProperties;
        results.modal=modal.run_analysis(sweep.ops,analysisModel,cfg);
        results.action08=validation.run_mbc_qep_campbell_suite( ...
            modelData,reduced,sweep,analysisModel,results.modal,cfg);
        results.meta.analysisScope= ...
            "homologous_frame_mbc_qep_and_optimal_campbell_tracking";
    elseif action09Only
        [Mdistributed,Ke,elementCache,assemblyDiagnostics]= ...
            assembly.assemble_structural_matrices(modelData,cfg);
        [Mdistributed,massDiagnostics]= ...
            assembly.apply_mass_formulation(Mdistributed,cfg,modelData);
        bodies=modelData.rigidBodies;
        [M,bodyMassDiagnostics]=rigid.add_body_masses( ...
            Mdistributed,modelData,bodies);
        [Tc,constraintDiagnostics]=rigid.rigid_constraint_matrix( ...
            modelData,bodies,cfg);
        reduced=rigid.reduce_system(Tc,M,Ke,modelData,cfg);
        massProperties=rigid.compute_mass_properties(modelData,M,Tc);
        sweep=assembly.build_operating_sweep(modelData,reduced,cfg);
        zeroIndex=find(abs(sweep.speedRPM)<=eps,1);
        rotatingIndex=find(abs(sweep.speedRPM-cfg.rotor.speedRPM)<=eps,1);
        if isempty(zeroIndex)||isempty(rotatingIndex)
            error('main:Action09OperatingPoints', ...
                'Action 09 requires both 0 RPM and the primary rotating point.');
        end
        analysisModel=model.prepare_analysis_model( ...
            modelData,sweep.primaryOps.reduced);
        stationary=localAction09Response( ...
            sweep.ops{zeroIndex},analysisModel,modelData,cfg);
        rotating=localAction09Response( ...
            sweep.ops{rotatingIndex},analysisModel,modelData,cfg);
        timeSteps=double(cfg.action09.timeStepGrid(:));
        convergence=cell(numel(timeSteps),1);
        for timeStepIndex=1:numel(timeSteps)
            stepCfg=cfg;stepCfg.newmark.dt=timeSteps(timeStepIndex);
            convergence{timeStepIndex}=localAction09Response( ...
                sweep.ops{rotatingIndex},analysisModel,modelData,stepCfg);
        end
        elementForces=dynamics.recover_element_forces( ...
            modelData,rotating.qFull,elementCache);
        responseSet=struct('stationary',stationary,'rotating',rotating);
        action09=validation.run_seismic_newmark_suite( ...
            modelData,reduced,sweep,responseSet,convergence, ...
            elementForces,cfg);
        action09.responses=responseSet;
        action09.convergenceResponses=convergence;
        action09.elementForces=elementForces;
        action09.operatingPointIndices=struct( ...
            'stationary',zeroIndex,'rotating',rotatingIndex);
        state=sweep.primaryState;state.operatingPoints=sweep.states;
        state.speedRPMGrid=sweep.speedRPM;
        ops=sweep.primaryOps;ops.operatingPoints=sweep.ops;
        ops.cache=elementCache;
        ops.diagnostics.structuralAssembly=assemblyDiagnostics;
        ops.diagnostics.massFormulation=massDiagnostics;
        ops.diagnostics.bodyMasses=bodyMassDiagnostics;
        ops.diagnostics.constraints=constraintDiagnostics;
        results.equilibrium=state;results.massProperties=massProperties;
        results.time=rotating;results.action09=action09;
        results.meta.analysisScope= ...
            "linearized_multicomponent_seismic_response_at_frozen_operating_point";
    elseif action10Only
        % Action 10 recomputes the downstream modal and temporal blocks in
        % memory while independently reloading and hashing the accepted
        % Action-02--09 artifacts named by the configuration.
        [Mdistributed,Ke,elementCache,assemblyDiagnostics]= ...
            assembly.assemble_structural_matrices(modelData,cfg);
        [Mdistributed,massDiagnostics]= ...
            assembly.apply_mass_formulation(Mdistributed,cfg,modelData);
        bodies=modelData.rigidBodies;
        [M,bodyMassDiagnostics]=rigid.add_body_masses( ...
            Mdistributed,modelData,bodies);
        [Tc,constraintDiagnostics]=rigid.rigid_constraint_matrix( ...
            modelData,bodies,cfg);
        reduced=rigid.reduce_system(Tc,M,Ke,modelData,cfg);
        massProperties=rigid.compute_mass_properties(modelData,M,Tc);
        sweep=assembly.build_operating_sweep(modelData,reduced,cfg);
        state=sweep.primaryState;state.operatingPoints=sweep.states;
        state.speedRPMGrid=sweep.speedRPM;
        ops=sweep.primaryOps;ops.operatingPoints=sweep.ops;
        ops.cache=elementCache;
        ops.diagnostics.structuralAssembly=assemblyDiagnostics;
        ops.diagnostics.massFormulation=massDiagnostics;
        ops.diagnostics.bodyMasses=bodyMassDiagnostics;
        ops.diagnostics.constraints=constraintDiagnostics;
        results.equilibrium=state;results.massProperties=massProperties;

        % Stop before modal/time integration if any model or operator gate
        % invalidates the solve.
        results.validationPreflight=validation.run_validation_suite( ...
            modelData,ops,results,cfg,"preflight");

        analysisModel=model.prepare_analysis_model(modelData,ops.reduced);
        results.modal=modal.run_analysis(sweep.ops,analysisModel,cfg);
        results.action08=validation.run_mbc_qep_campbell_suite( ...
            modelData,reduced,sweep,analysisModel,results.modal,cfg);

        zeroIndex=find(abs(sweep.speedRPM)<=eps,1);
        rotatingIndex=find(abs(sweep.speedRPM-cfg.rotor.speedRPM)<=eps,1);
        if isempty(zeroIndex)||isempty(rotatingIndex)
            error('main:Action10OperatingPoints', ...
                'Action 10 requires both 0 RPM and the primary rotating point.');
        end
        stationary=localAction09Response( ...
            sweep.ops{zeroIndex},analysisModel,modelData,cfg);
        rotating=localAction09Response( ...
            sweep.ops{rotatingIndex},analysisModel,modelData,cfg);
        timeSteps=double(cfg.action09.timeStepGrid(:));
        convergence=cell(numel(timeSteps),1);
        for timeStepIndex=1:numel(timeSteps)
            stepCfg=cfg;stepCfg.newmark.dt=timeSteps(timeStepIndex);
            convergence{timeStepIndex}=localAction09Response( ...
                sweep.ops{rotatingIndex},analysisModel,modelData,stepCfg);
        end
        elementForces=dynamics.recover_element_forces( ...
            modelData,rotating.qFull,elementCache);
        responseSet=struct('stationary',stationary,'rotating',rotating);
        action09=validation.run_seismic_newmark_suite( ...
            modelData,reduced,sweep,responseSet,convergence, ...
            elementForces,cfg);
        action09.responses=responseSet;
        action09.convergenceResponses=convergence;
        action09.elementForces=elementForces;
        action09.operatingPointIndices=struct( ...
            'stationary',zeroIndex,'rotating',rotatingIndex);
        results.time=rotating;results.action09=action09;

        evidence=struct('runFolders',cfg.action10.canonicalRuns);
        results.action10=validation.run_integral_acceptance_suite( ...
            modelData,ops,results,cfg,evidence);
        results.meta.analysisScope= ...
            "integral_preflight_modal_temporal_and_persisted_evidence_acceptance";
    elseif ~geometryOnly
        [Mdistributed,Ke,~,assemblyDiagnostics] = ...
            assembly.assemble_structural_matrices(modelData,cfg);
        [Mdistributed,massDiagnostics] = ...
            assembly.apply_mass_formulation(Mdistributed,cfg,modelData);
        bodies = modelData.rigidBodies;
        [M,bodyMassDiagnostics] = rigid.add_body_masses( ...
            Mdistributed,modelData,bodies);
        [Tc,constraintDiagnostics] = rigid.rigid_constraint_matrix( ...
            modelData,bodies,cfg);
        reduced = rigid.reduce_system(Tc,M,Ke,modelData,cfg);
        massProperties = rigid.compute_mass_properties(modelData,M,Tc);

        sweep = assembly.build_operating_sweep(modelData,reduced,cfg);
        state = sweep.primaryState;
        state.operatingPoints = sweep.states;
        state.speedRPMGrid = sweep.speedRPM;
        ops = sweep.primaryOps;
        ops.operatingPoints = sweep.ops;
        ops.diagnostics.structuralAssembly = assemblyDiagnostics;
        ops.diagnostics.massFormulation = massDiagnostics;
        ops.diagnostics.bodyMasses = bodyMassDiagnostics;
        ops.diagnostics.constraints = constraintDiagnostics;
        analysisModel = model.prepare_analysis_model(modelData,ops.reduced);

        results.equilibrium = state;
        results.massProperties = massProperties;
        if cfg.modal.enabled
            results.modal = modal.run_analysis(sweep.ops,analysisModel,cfg);
        end
        if cfg.seismic.enabled
            seismicOps = ops.reduced;
            seismicOps.Mfull = ops.full.M;
            seismicOps.Dfull = ops.full.D;
            seismicOps.Kfull = ops.full.K;
            seismicOps.Tc = ops.reduced.Tc;
            results.time = dynamics.run_seismic_analysis(seismicOps,analysisModel,cfg);
            results.time = dynamics.recover_full_response( ...
                results.time,seismicOps,modelData);
        end
    end

    if cfg.validation.enabled
        results.validation = validation.run_validation_suite( ...
            modelData,ops,results,cfg);
        results.validation.input = inputValidation;
    else
        results.validation = struct('passed',true,'checks',struct([]), ...
            'input',inputValidation,'disabled',true);
    end

    results.meta.completedAt = datetime('now','TimeZone','local');
    io.save_results(run,cfg,modelData,state,ops,results);
    post.export_all(run,cfg,modelData,results);
    io.mark_run_success(run);
    fprintf('Completed successfully. Results: %s\n',run.folder);
catch ME
    io.save_failure(run,cfg,ME);
    fprintf(2,'Run failed: %s\n',ME.message);
    rethrow(ME);
end
end

function response=localAction09Response(pointOps,analysisModel,modelData,cfg)
seismicOps=pointOps.reduced;
seismicOps.Mfull=pointOps.full.M;
seismicOps.Dfull=pointOps.full.D;
seismicOps.Kfull=pointOps.full.K;
seismicOps.Tc=pointOps.reduced.Tc;
response=dynamics.run_seismic_analysis(seismicOps,analysisModel,cfg);
response=dynamics.recover_full_response(response,seismicOps,modelData);
response.speedRPM=pointOps.speedRPM;
response.operatorDiagnostics=pointOps.diagnostics;
response.snapshotMetadata=struct('speedRPM',pointOps.speedRPM, ...
    'operatorPolicy',"frozen_operating_point",'isLTVIntegration',false, ...
    'constraintRecovery',response.kinematicRecovery, ...
    'interpretation', ...
    "Newmark uses one frozen operator set; Tdot/Tddot recover snapshot nodal derivatives, not an evolving rotor trajectory");
end

function diagnostics = localAction02ElementDiagnostics(elementCache)
% Keep CSV-oriented scalar diagnostics with the persisted Action-02 result.
numberOfElements = numel(elementCache);
assembled = false(numberOfElements,1);
elementId = nan(numberOfElements,1);
nodeI = nan(numberOfElements,1);
nodeJ = nan(numberOfElements,1);
sectionId = nan(numberOfElements,1);
component = strings(numberOfElements,1);
blade = zeros(numberOfElements,1);
lengthM = nan(numberOfElements,1);
orthogonalityError = nan(numberOfElements,1);
determinantR = nan(numberOfElements,1);
symmetryErrorK = nan(numberOfElements,1);
symmetryErrorM = nan(numberOfElements,1);
minimumMassEigenvalue = nan(numberOfElements,1);
rigidModeCount = nan(numberOfElements,1);
formulation = strings(numberOfElements,1);
for index = 1:numberOfElements
    entry = elementCache(index);
    assembled(index) = logical(entry.assembled);
    elementId(index) = double(entry.id);
    nodeI(index) = double(entry.nodeI);
    nodeJ(index) = double(entry.nodeJ);
    sectionId(index) = double(entry.sectionId);
    component(index) = string(entry.component);
    blade(index) = double(entry.blade);
    lengthM(index) = double(entry.L);
    R = double(entry.R);
    orthogonalityError(index) = norm(R*R.'-eye(3),'fro');
    determinantR(index) = det(R);
    symmetryErrorK(index) = double(entry.symmetryErrorK);
    symmetryErrorM(index) = double(entry.symmetryErrorM);
    minimumMassEigenvalue(index) = double(entry.minMassEigenvalue);
    rigidModeCount(index) = double(entry.rigidModeCount);
    formulation(index) = string(entry.formulation);
end
finite = isfinite(lengthM) & isfinite(orthogonalityError) & ...
    isfinite(determinantR) & isfinite(symmetryErrorK) & ...
    isfinite(symmetryErrorM) & isfinite(minimumMassEigenvalue) & ...
    isfinite(rigidModeCount);
diagnostics = table(elementId,nodeI,nodeJ,sectionId,component,blade, ...
    lengthM,assembled,finite,orthogonalityError,determinantR, ...
    symmetryErrorK,symmetryErrorM,minimumMassEigenvalue, ...
    rigidModeCount,formulation);
end
