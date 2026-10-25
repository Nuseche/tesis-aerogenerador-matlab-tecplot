function artifacts = import_legacy_version0(projectRoot, benchmarkFile)
%IMPORT_LEGACY_VERSION0 Materialize solver-independent Version 0 MAT data.
%   This is the only function that executes the inherited GeoTorre.m and
%   Secciones.m scripts. The solver loads only the resulting MAT artifacts.
%   BENCHMARKFILE must contain f, obtained by executing the unmodified
%   FrecuenciasTorreCompleta.m with MATLAB R2026a.

if nargin < 1 || isempty(projectRoot)
    projectRoot = fileparts(fileparts(mfilename('fullpath')));
end
if nargin < 2 || isempty(benchmarkFile)
    benchmarkFile = fullfile(tempdir, 'legacy_benchmark.mat');
end
projectRoot = char(string(projectRoot));
legacyDir = fullfile(projectRoot, 'legacy', 'Codigos_sergio', ...
    '[Diego Turello Version 0]');
geoSource = fullfile(legacyDir, 'GeoTorre.m');
sectionSource = fullfile(legacyDir, 'Secciones.m');
solverSource = fullfile(legacyDir, 'FrecuenciasTorreCompleta.m');
assert(isfile(geoSource) && isfile(sectionSource) && isfile(solverSource), ...
    'tools:import_legacy_version0:MissingLegacySource', ...
    'The read-only Version 0 mirror is incomplete.');

run(geoSource);
geometry = struct();
geometry.schemaVersion = "1.0";
geometry.units = "m";
geometry.coordinates = coor;
geometry.connectivity = conect;
geometry.coorP1aux = coorP1aux;
geometry.coorP2aux = coorP2aux;
geometry.coorP3aux = coorP3aux;
geometry.source = "legacy/Codigos_sergio/[Diego Turello Version 0]/GeoTorre.m";
geometry.sourceSHA256 = "23237070dc2489046f60e3ced16deb233fa0dc6c3edcf2b6b39648f69ef077b1";
geometry.legacyColumns = struct('connectivity', ...
    ["element_id", "legacy_type", "node_i", "node_j"]);

run(sectionSource);
materialData = struct();
materialData.youngPa = 2.100e11;
materialData.poisson = 0.3000;
materialData.shearPa = materialData.youngPa/(2*(1+materialData.poisson));
materialData.densityKgM3 = 7.850e3;
materialData.source = "legacy/.../Secciones.m + FrecuenciasTorreCompleta.m " + ...
    "lines defining YOUNG/POISS/DENS";
materialData.note = "Constants copied exactly from Version 0; no material fitted.";

template = struct('id', 0, 'name', "", 'type', "", ...
    'EA', 0, 'GAy', 0, 'GAz', 0, 'GJ', 0, 'EIy', 0, 'EIz', 0, ...
    'm', 0, 'Jx', 0, 'Jy', 0, 'Jz', 0, 'ycg', 0, 'zcg', 0, ...
    'rawMassColumns', nan(1,4), 'massUnits', "", ...
    'torsionalInertiaRule', "", 'torsionalInertiaStatus', "", ...
    'source', "", 'sourceRow', 0, 'assumptions', "");
sectionData = repmat(template, 55, 1);
E = materialData.youngPa;
G = materialData.shearPa;
rhoTower = materialData.densityKgM3;
for row = 1:20
    rawTower = secc_torre(row,:);
    sectionData(row).id = row;
    sectionData(row).name = "tower_" + compose('%02d', row);
    sectionData(row).type = "tower";
    sectionData(row).EA = E*rawTower(1);
    sectionData(row).GAy = G*rawTower(2);
    sectionData(row).GAz = G*rawTower(3);
    sectionData(row).GJ = G*rawTower(4);
    sectionData(row).EIy = E*rawTower(5);
    sectionData(row).EIz = E*rawTower(6);
    sectionData(row).m = rhoTower*rawTower(1);
    % The mass polar moment is Iy+Iz.  The legacy TORINE column is used for
    % Saint-Venant stiffness and differs slightly because the published
    % table is rounded; it must not create a non-physical inertia tensor.
    sectionData(row).Jx = rhoTower*(rawTower(5)+rawTower(6));
    sectionData(row).Jy = rhoTower*rawTower(5);
    sectionData(row).Jz = rhoTower*rawTower(6);
    sectionData(row).rawMassColumns = rawTower([1 4 5 6]);
    sectionData(row).massUnits = ...
        "kg/m and kg*m per metre after multiplication by tower density";
    sectionData(row).torsionalInertiaRule = "perpendicular_axis_tubular";
    sectionData(row).torsionalInertiaStatus = "verified";
    sectionData(row).source = ...
        "legacy/.../Secciones.m:secc_torre + Version 0 material constants";
    sectionData(row).sourceRow = row;
    sectionData(row).assumptions = ...
        "centroid on reference line, as in Version 0 centered beam mass";
end

rhoBlade = rho_pala;
for station = 1:35
    id = 20 + station;
    stiffness = secc_pala(station,:);
    inertia = inercia_pala(station,:);
    sectionData(id).id = id;
    sectionData(id).name = "blade_" + compose('%02d', station);
    sectionData(id).type = "blade";
    sectionData(id).EA = stiffness(1);
    sectionData(id).GAy = stiffness(2);
    sectionData(id).GAz = stiffness(3);
    sectionData(id).GJ = stiffness(4);
    sectionData(id).EIy = stiffness(5);
    sectionData(id).EIz = stiffness(6);
    sectionData(id).m = rhoBlade*inertia(1);
    % TORDEN is identically zero in Version 0.  Preserve that absence in
    % the immutable artifact; model.resolve_section_mass applies only an
    % explicitly configured physical rule.  In particular, do not recover
    % Jx from EA, GJ or an effective modulus.
    sectionData(id).Jx = NaN;
    sectionData(id).Jy = rhoBlade*inertia(3);
    sectionData(id).Jz = rhoBlade*inertia(4);
    sectionData(id).rawMassColumns = inertia;
    sectionData(id).massUnits = ...
        "legacy AXIALD/TORDEN/INERT2/INERT3 multiplied by rho_pala";
    sectionData(id).torsionalInertiaRule = "unresolved_in_source_artifact";
    sectionData(id).torsionalInertiaStatus = "requires_configuration";
    sectionData(id).source = ...
        "legacy/.../Secciones.m:secc_pala,inercia_pala,rho_pala";
    sectionData(id).sourceRow = station;
    sectionData(id).assumptions = ...
        "direct generalized stiffness; AXIALD used only as mass data; " + ...
        "TORDEN=0 retained unresolved; centered reference line";
end

geometryPath = fullfile(projectRoot, 'data', 'geometry', 'legacy_geometry_v0.mat');
sectionsPath = fullfile(projectRoot, 'data', 'sections', 'legacy_sections_v0.mat');
save(geometryPath, 'geometry', '-v7');
save(sectionsPath, 'sectionData', 'materialData', '-v7');

if ~isfile(benchmarkFile)
    error('tools:import_legacy_version0:MissingBenchmark', ...
        'Benchmark MAT not found: %s', benchmarkFile);
end
benchmark = load(benchmarkFile, 'f');
if ~isfield(benchmark, 'f') || numel(benchmark.f) ~= 20 || ...
        any(~isfinite(benchmark.f))
    error('tools:import_legacy_version0:InvalidBenchmark', ...
        'Benchmark MAT must contain exactly twenty finite frequencies in f.');
end
reference = struct();
reference.schemaVersion = "1.0";
reference.frequencyHz = benchmark.f(:);
reference.count = numel(reference.frequencyHz);
reference.baseType = "fixed";
reference.massFormulation = "legacy_abs_row_sum_diagonal";
reference.solver = "unmodified Version 0 FrecuenciasTorreCompleta.m";
reference.matlabRelease = "R2026a";
reference.generatedOn = datetime(2026,8,25,'TimeZone','America/Bogota');
reference.source = "legacy/Codigos_sergio/[Diego Turello Version 0]/FrecuenciasTorreCompleta.m";
reference.sourceSHA256 = "94a616a7a18f44a649fc722469911514f7066887a4e60f5ca6bc8c4d39e24bb0";
reference.notes = [ ...
    "Regression target for the inherited model only; it includes penalty ", ...
    "connectors, Euler-Bernoulli stiffness, and abs row-sum mass lumping."];
referencePath = fullfile(projectRoot, 'data', 'reference', ...
    'legacy_fixed_base_frequencies_v0.mat');
save(referencePath, 'reference', '-v7');
mode = (1:reference.count).';
frequency_hz = reference.frequencyHz;
referenceCsvPath = fullfile(projectRoot, 'data', 'reference', ...
    'legacy_fixed_base_frequencies_v0.csv');
fileId = fopen(referenceCsvPath, 'wt');
if fileId < 0
    error('tools:import_legacy_version0:CannotWriteReferenceCsv', ...
        'Cannot create %s.', referenceCsvPath);
end
closeCsv = onCleanup(@() fclose(fileId)); %#ok<NASGU>
fprintf(fileId, 'mode,frequency_hz\n');
fprintf(fileId, '%d,%.17g\n', [mode.'; frequency_hz.']);

artifacts = struct('geometry', string(geometryPath), ...
    'sections', string(sectionsPath), 'reference', string(referencePath), ...
    'referenceCsv', string(referenceCsvPath));
end
