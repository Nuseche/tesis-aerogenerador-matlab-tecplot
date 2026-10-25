function cfg = config_default()
%CONFIG_DEFAULT Return the complete, reproducible default analysis setup.
%   Paths are resolved from this file, never from the current directory.

projectRoot = fileparts(mfilename('fullpath'));

cfg = struct();
cfg.schemaVersion = "1.0";
cfg.units = struct('system', "SI", 'length', "m", 'mass', "kg", ...
    'time', "s", 'force', "N", 'stress', "Pa", 'angle', "rad");

cfg.paths = struct();
cfg.paths.projectRoot = string(projectRoot);
cfg.paths.dataRoot = string(fullfile(projectRoot, 'data'));
cfg.paths.runsRoot = string(fullfile(projectRoot, 'runs'));

cfg.data = struct();
cfg.data.version = "legacy_v0_verified";
cfg.data.geometryFile = string(fullfile(projectRoot, 'data', 'geometry', ...
    'legacy_geometry_v0.mat'));
cfg.data.sectionsFile = string(fullfile(projectRoot, 'data', 'sections', ...
    'legacy_sections_v0.mat'));
cfg.data.referenceFile = string(fullfile(projectRoot, 'data', 'reference', ...
    'legacy_fixed_base_frequencies_v0.mat'));
cfg.data.rigidBodiesFile = string(fullfile(projectRoot, 'data', 'rigid_bodies', ...
    'legacy_rigid_bodies_v0.json'));

% The inherited sources do not contain a verified 129--130 drivetrain
% stiffness. The safe default therefore validates/exports geometry only;
% executable analysis cases with an explicit illustrative drivetrain live
% in cases/. No physical coefficient is invented silently.
cfg.analysis = struct('type', "geometry");
cfg.base = struct('type', "fixed", 'fixedNodeIds', 1);
cfg.rotor = struct('speedRPM', 0, 'azimuthRad', 0, ...
    'axisConvention', "nacelle_master_to_rotor_master");
cfg.mass = struct('formulation', "consistent");
% Action 02 keeps the production-quality closed two-node Timoshenko
% interpolation as the default.  The literal linear/SRI formulation from
% the implementation plan is also available as "selective_integration"
% for locking and convergence benchmarks.
cfg.elements = struct('formulation', "closed_exact", ...
    'regularIntegrationPoints', 2, 'shearIntegrationPoints', 1, ...
    'massIntegrationPoints', 2);
cfg.assembly = struct('flexibleOnly', false);
% Version 0 labels INERT2/INERT3 as the two centroidal transverse mass
% moments.  The longitudinal polar moment is therefore resolved explicitly
% by the perpendicular-axis rule; it is never inferred from EA or GJ.
cfg.sections = struct('blade', struct( ...
    'torsionalInertiaRule', "perpendicular_axis", ...
    'interpretationStatus', "documented_legacy_INERT2_INERT3"));
cfg.modal = struct('enabled', false, 'number', 30, 'solver', "auto");
cfg.modes = struct('number', 30);
cfg.seismic = struct('enabled', false);
cfg.newmark = struct('beta', 1/4, 'gamma', 1/2);
cfg.gravity = struct('enabled', true, 'vector', [0; 0; -9.80665]);
cfg.loads = struct();
cfg.foundation = struct('nodeId', 1, 'M', [], 'K', [], 'C', []);
cfg.drivetrain = struct('stiffness', [], 'damping', [], 'orientation', []);
cfg.damping = struct('alpha', 0, 'beta', 0);
cfg.gyroscopic = struct('includeDistributedBlades', true, ...
    'formulation',"quadratic_energy_with_inertial_transport", ...
    'reference',"Meirovitch 1997 section 4.4 equations 4.51-4.70");
cfg.aerodynamics = struct('status', ...
    "zero_unprovided_physical_coefficients");

cfg.rigid = struct();
cfg.rigid.orientationConvention = "passive_zxz_explicit_angle_units";

cfg.validation = struct();
cfg.validation.enabled = true;
cfg.validation.geometryTolerance = 1.0e-10;
cfg.validation.frameTolerance = 1.0e-10;
cfg.validation.propertyTolerance = 0;
cfg.validation.symmetryTolerance = 1.0e-10;
cfg.validation.constraintTolerance = 1.0e-12;
cfg.validation.massConservationTolerance = 1.0e-10;
cfg.validation.rotationOrthogonality = 1.0e-12;
cfg.validation.matrixSymmetry = 1.0e-12;
cfg.validation.rigidEnergyRelative = 1.0e-10;
cfg.validation.massConservation = 1.0e-10;
cfg.validation.coordinateInvariance = 1.0e-9;
cfg.validation.analyticalStaticRelative = 1.0e-6;
cfg.validation.modalBenchmarkRelative = 1.0e-3;
cfg.validation.meshConvergenceRelative = 1.0e-3;
cfg.validation.failOnCritical = true;

cfg.equilibrium = struct('tolerance', 1.0e-8, 'maxIterations', 40, ...
    'relativeTolerance', 1.0e-8, 'maximumIterations', 40);
cfg.output = struct('saveInputs', true, 'saveDiagnostics', true, ...
    'plotGeometry', false, 'makeFigures', false, 'modesToPlot', 6, ...
    'timeHistoryDofs', [], 'runsDirectory', string(fullfile(projectRoot,'runs')));
cfg.run = struct('identifier', "geometry_default");
end
