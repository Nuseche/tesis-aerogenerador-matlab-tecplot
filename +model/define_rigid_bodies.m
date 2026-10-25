function rigidBodies = define_rigid_bodies(modelData, cfg, bodyData)
%DEFINE_RIGID_BODIES Build traced body data and exact root constraints.
%   Angles carry explicit input units and are converted once to radians.
%   Nodes 129 and 130 remain independent masters. Only the three inherited
%   hub-to-root type-3 links are replaced by rigid master/slave equations.

if nargin < 2 || isempty(cfg)
    cfg = io.load_configuration();
end
if nargin < 3 || isempty(bodyData)
    data = io.load_model_data(cfg);
    bodyData = data.rigidBodies;
end
requiredNodes = [21; 57; 93; 129; 130];
if ~all(ismember(requiredNodes, modelData.mesh.nodes.id))
    error('model:define_rigid_bodies:RequiredNodeMissing', ...
        'The mesh must contain blade roots 21/57/93 and masters 129/130.');
end

if ~isfield(cfg, 'rigid') || ~isfield(cfg.rigid, 'orientationConvention') || ...
        string(cfg.rigid.orientationConvention) ~= ...
        "passive_zxz_explicit_angle_units"
    error('model:define_rigid_bodies:UnsupportedOrientationConvention', ...
        ['The accepted convention is passive Z-X-Z with an explicit angle ' ...
         'unit in the versioned rigid-body dataset.']);
end

localValidateDataset(bodyData);
anglesInput = reshape(double(bodyData.orientation.angles),1,3);
angleUnit = lower(string(bodyData.orientation.angleUnit));
switch angleUnit
    case "deg"
        anglesRad = deg2rad(anglesInput);
    case "rad"
        anglesRad = anglesInput;
    otherwise
        error('model:define_rigid_bodies:UnsupportedAngleUnit', ...
            'Rigid-body angleUnit must be deg or rad.');
end
sequence = string(bodyData.orientation.sequence);
if sequence ~= "passive Z-X-Z"
    error('model:define_rigid_bodies:UnsupportedRotationSequence', ...
        'Only the documented passive Z-X-Z sequence is implemented.');
end
rotation = passiveZ(anglesRad(3))*passiveX(anglesRad(2))*passiveZ(anglesRad(1));

sourceFile = string(bodyData.source);
bodyTemplate = struct('name', "", 'masterNode', 0, 'mass', 0, ...
    'cgOffsetBody', zeros(1,3), 'inertiaBody', zeros(3), ...
    'orientationBodyToGlobal', eye(3), ...
    'orientationAnglesInput', anglesInput, ...
    'orientationAngleUnit', angleUnit, ...
    'orientationAnglesRad', anglesRad, ...
    'orientationSequence', sequence, 'source', sourceFile, ...
    'dataVersion', string(bodyData.datasetId), ...
    'offsetStatus', "", 'inertiaFrame', "",'rotating',false);
bodyRecords = bodyData.bodies(:);
bodies = repmat(bodyTemplate,numel(bodyRecords),1);
for bodyIndex = 1:numel(bodyRecords)
    record = bodyRecords(bodyIndex);
    bodies(bodyIndex).name = string(record.name);
    bodies(bodyIndex).masterNode = double(record.masterNode);
    bodies(bodyIndex).mass = double(record.massKg);
    bodies(bodyIndex).cgOffsetBody = reshape(double(record.cgOffsetBodyM),1,3);
    bodies(bodyIndex).inertiaBody = double(record.inertiaBodyKgM2);
    bodies(bodyIndex).orientationBodyToGlobal = rotation;
    bodies(bodyIndex).offsetStatus = string(record.cgOffsetStatus);
    bodies(bodyIndex).inertiaFrame = string(record.inertiaFrame);
    bodies(bodyIndex).rotating = logical(record.rotating);
end

constraints = struct('name', "hub_to_blade_roots", 'masterNode', 130, ...
    'slaveNodes', [21; 57; 93], 'legacyElementIdsRemoved', (135:137).', ...
    'type', "rigid_master_slave", 'source', sourceFile);

rigidBodies = struct();
rigidBodies.masters = [129; 130];
rigidBodies.bodies = bodies;
rigidBodies.constraints = constraints;
rigidBodies.removedLegacyConnectorIds = (134:137).';
rigidBodies.drivetrain = struct('nodeNacelle', 129, 'nodeRotor', 130, ...
    'status', "masters remain separate; no unverified shaft stiffness added", ...
    'removedLegacyPenaltyElementId', 134);
rigidBodies.orientationConvention = ...
    "passive Z-X-Z; dataset units converted explicitly to internal radians";
rigidBodies.data = bodyData;
rigidBodies.dataStatus = struct( ...
    'orientationInterpretation',string(bodyData.orientation.interpretationStatus), ...
    'cgOffsets',"collocated assumption; measured offsets unavailable");
end

function localValidateDataset(bodyData)
required = {'schemaVersion','datasetId','source','orientation','bodies'};
if ~isstruct(bodyData) || ~isscalar(bodyData) || ~all(isfield(bodyData,required))
    error('model:define_rigid_bodies:InvalidDataset', ...
        'Rigid-body dataset does not satisfy the required schema.');
end
orientationRequired = {'angles','angleUnit','sequence','interpretationStatus'};
if ~isstruct(bodyData.orientation) || ...
        ~all(isfield(bodyData.orientation,orientationRequired)) || ...
        numel(bodyData.orientation.angles)~=3 || ...
        any(~isfinite(bodyData.orientation.angles))
    error('model:define_rigid_bodies:InvalidDataset', ...
        'Rigid-body orientation metadata is incomplete or invalid.');
end
bodyRequired = {'name','masterNode','rotating','massKg','cgOffsetBodyM', ...
    'cgOffsetStatus','inertiaBodyKgM2','inertiaFrame'};
records = bodyData.bodies(:);
if numel(records)~=2 || ~all(isfield(records,bodyRequired))
    error('model:define_rigid_bodies:InvalidDataset', ...
        'The Version 0 dataset must define nacelle and hub records.');
end
for index=1:numel(records)
    record=records(index);
    if ~isscalar(record.masterNode) || ~isfinite(record.masterNode) || ...
            record.masterNode~=fix(record.masterNode) || ...
            ~isscalar(record.rotating) || ...
            ~isscalar(record.massKg) || ~isfinite(record.massKg) || ...
            record.massKg<=0 || numel(record.cgOffsetBodyM)~=3 || ...
            any(~isfinite(record.cgOffsetBodyM)) || ...
            ~isequal(size(record.inertiaBodyKgM2),[3 3]) || ...
            any(~isfinite(record.inertiaBodyKgM2),'all')
        error('model:define_rigid_bodies:InvalidDataset', ...
            'Rigid-body record %d contains invalid numeric data.',index);
    end
end
end

function R = passiveZ(angle)
R = [cos(angle), sin(angle), 0; -sin(angle), cos(angle), 0; 0, 0, 1];
end

function R = passiveX(angle)
R = [1, 0, 0; 0, cos(angle), sin(angle); 0, -sin(angle), cos(angle)];
end
