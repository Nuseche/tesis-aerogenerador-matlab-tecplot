function data = load_model_data(cfg)
%LOAD_MODEL_DATA Load immutable MAT inputs without executing legacy scripts.

if nargin < 1 || isempty(cfg)
    cfg = io.load_configuration();
end

geometryFile = requireFile(cfg.data.geometryFile, 'geometry');
sectionsFile = requireFile(cfg.data.sectionsFile, 'sections');
referenceFile = requireFile(cfg.data.referenceFile, 'reference');
rigidBodiesFile = requireFile(cfg.data.rigidBodiesFile, 'rigid bodies');

geometryContainer = load(geometryFile, 'geometry');
sectionsContainer = load(sectionsFile, 'sectionData', 'materialData');
referenceContainer = load(referenceFile, 'reference');
rigidBodyData = jsondecode(fileread(rigidBodiesFile));

if ~isfield(geometryContainer, 'geometry')
    error('io:load_model_data:InvalidGeometryArtifact', ...
        'Expected variable geometry in %s.', geometryFile);
end
if ~all(isfield(sectionsContainer, {'sectionData','materialData'}))
    error('io:load_model_data:InvalidSectionsArtifact', ...
        'Expected sectionData and materialData in %s.', sectionsFile);
end
if ~isfield(referenceContainer, 'reference')
    error('io:load_model_data:InvalidReferenceArtifact', ...
        'Expected variable reference in %s.', referenceFile);
end

data = struct();
data.geometry = geometryContainer.geometry;
data.sections = sectionsContainer.sectionData;
data.material = sectionsContainer.materialData;
data.reference = referenceContainer.reference;
data.rigidBodies = rigidBodyData;
data.meta = struct();
data.meta.schemaVersion = "1.0";
data.meta.units = "SI";
data.meta.files = struct('geometry', string(geometryFile), ...
    'sections', string(sectionsFile), 'reference', string(referenceFile), ...
    'rigidBodies',string(rigidBodiesFile));
data.meta.loadedAt = datetime('now', 'TimeZone', 'UTC');
end

function filePath = requireFile(candidate, label)
filePath = char(string(candidate));
if ~isfile(filePath)
    error('io:load_model_data:MissingArtifact', ...
        'The %s data artifact does not exist: %s. Run tools/import_legacy_version0.m.', ...
        label, filePath);
end
end
