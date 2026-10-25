function modelData = build_model(data, cfg)
%BUILD_MODEL Convert verified Version 0 data into the solver model contract.
%   Type-3 penalty connectors are deliberately excluded. The nine type-4
%   tower-to-nacelle transition members remain flexible and use tower
%   section 20. Blade auxiliary points are selected per blade (P1/P2/P3).

if nargin < 2 || isempty(cfg)
    cfg = io.load_configuration();
end
if ~isfield(data, 'geometry') || ~isfield(data, 'sections')
    error('model:build_model:IncompleteData', ...
        'data must contain geometry and sections.');
end

raw = data.geometry;
requiredGeometry = {'coordinates','connectivity','coorP1aux','coorP2aux','coorP3aux'};
if ~all(isfield(raw, requiredGeometry))
    error('model:build_model:InvalidGeometryArtifact', ...
        'The geometry artifact does not satisfy the Version 0 schema.');
end

coordinates = raw.coordinates;
connectivity = raw.connectivity;
if size(coordinates,2) ~= 3 || size(connectivity,2) ~= 4
    error('model:build_model:InvalidGeometryDimensions', ...
        'Expected coordinates N-by-3 and connectivity E-by-4.');
end

legacyId = connectivity(:,1);
legacyType = connectivity(:,2);
keep = legacyType ~= 3;
kept = connectivity(keep,:);
keptLegacyId = kept(:,1);
keptLegacyType = kept(:,2);
nElements = size(kept,1);

mesh = struct();
mesh.nodes = struct('id', (1:size(coordinates,1)).', 'xyz', coordinates);
mesh.elements = struct();
mesh.elements.id = (1:nElements).';
mesh.elements.legacyId = keptLegacyId;
mesh.elements.legacyType = keptLegacyType;
mesh.elements.nodeI = kept(:,3);
mesh.elements.nodeJ = kept(:,4);
mesh.elements.type = strings(nElements,1);
mesh.elements.section = zeros(nElements,1);
mesh.elements.blade = zeros(nElements,1);
mesh.elements.auxPoint = nan(nElements,3);

for row = 1:nElements
    elementId = keptLegacyId(row);
    switch keptLegacyType(row)
        case 1
            mesh.elements.type(row) = "tower";
            mesh.elements.section(row) = elementId;
        case 2
            mesh.elements.type(row) = "blade";
            [blade, station] = bladeAndStation(elementId);
            mesh.elements.blade(row) = blade;
            mesh.elements.section(row) = 20 + station;
            switch blade
                case 1
                    mesh.elements.auxPoint(row,:) = raw.coorP1aux(station,:);
                case 2
                    mesh.elements.auxPoint(row,:) = raw.coorP2aux(station,:);
                case 3
                    mesh.elements.auxPoint(row,:) = raw.coorP3aux(station,:);
            end
        case 4
            mesh.elements.type(row) = "transition";
            mesh.elements.section(row) = 20;
        otherwise
            error('model:build_model:UnsupportedLegacyType', ...
                'Unsupported legacy element type %g at element %g.', ...
                keptLegacyType(row), elementId);
    end
end

boundaryConditions = struct();
boundaryConditions.type = string(cfg.base.type);
if boundaryConditions.type == "fixed"
    if isfield(cfg.base, 'fixedNodeIds')
        boundaryConditions.fixedNodeIds = cfg.base.fixedNodeIds(:);
    else
        boundaryConditions.fixedNodeIds = 1;
    end
else
    boundaryConditions.fixedNodeIds = zeros(0,1);
end
boundaryConditions.fixedDofs = (1:6).';

modelData = struct();
modelData.mesh = mesh;
modelData.sections = model.resolve_section_mass(data.sections(:),cfg);
modelData.dofs = model.build_dof_map(mesh, boundaryConditions);
modelData.boundaryConditions = boundaryConditions;
modelData.referenceFrames = model.blade_coordinate_systems( ...
    mesh, cfg.validation.frameTolerance);
modelData.bladeDofMap = makeBladeDofMap(mesh, modelData.dofs, ...
    modelData.referenceFrames);

node129 = coordinates(129,:).';
node130 = coordinates(130,:).';
axisDirection = node130 - node129;
axisDirection = axisDirection/norm(axisDirection);
modelData.rotorAxis = struct('point', node130, 'direction', axisDirection, ...
    'definition', "normalized vector from nacelle master 129 to rotor master 130", ...
    'sourceNodeIds', [129;130]);
modelData.rigidBodies = model.define_rigid_bodies(modelData, cfg, data.rigidBodies);

modelData.meta = struct();
modelData.meta.schemaVersion = "1.0";
modelData.meta.units = "SI";
modelData.meta.source = string(raw.source);
modelData.meta.inheritedNodeCount = size(coordinates,1);
modelData.meta.inheritedElementCount = size(connectivity,1);
modelData.meta.flexibleElementCount = nElements;
modelData.meta.removedLegacyType3Ids = legacyId(legacyType == 3);
modelData.meta.preservedLegacyType4Ids = legacyId(legacyType == 4);
modelData.meta.data = data.meta;
modelData.reference = data.reference;
modelData.summary = makeSummary(modelData);
end

function [blade, station] = bladeAndStation(legacyId)
if legacyId >= 20 && legacyId <= 54
    blade = 1;
    station = legacyId - 19;
elseif legacyId >= 55 && legacyId <= 89
    blade = 2;
    station = legacyId - 54;
elseif legacyId >= 90 && legacyId <= 124
    blade = 3;
    station = legacyId - 89;
else
    error('model:build_model:UnknownBladeElement', ...
        'Legacy blade element ID %g is outside the verified ranges.', legacyId);
end
end

function summary = makeSummary(modelData)
mesh = modelData.mesh;
nodeIds = mesh.nodes.id;
[~, rowI] = ismember(mesh.elements.nodeI, nodeIds);
[~, rowJ] = ismember(mesh.elements.nodeJ, nodeIds);
lengths = vecnorm(mesh.nodes.xyz(rowJ,:) - mesh.nodes.xyz(rowI,:), 2, 2);
sectionIds = mesh.elements.section;
massPerLength = reshape([modelData.sections(sectionIds).m], [], 1);
structuralMass = sum(massPerLength.*lengths);
bodyMass = sum([modelData.rigidBodies.bodies.mass]);

summary = struct();
summary.nodeCount = numel(mesh.nodes.id);
summary.flexibleElementCount = numel(mesh.elements.id);
summary.elementCountByType = struct('tower', nnz(mesh.elements.type == "tower"), ...
    'blade', nnz(mesh.elements.type == "blade"), ...
    'transition', nnz(mesh.elements.type == "transition"));
summary.totalFlexibleLengthM = sum(lengths);
summary.lengthByTypeM = struct('tower', sum(lengths(mesh.elements.type == "tower")), ...
    'blade', sum(lengths(mesh.elements.type == "blade")), ...
    'transition', sum(lengths(mesh.elements.type == "transition")));
summary.approximateDistributedMassKg = structuralMass;
summary.concentratedBodyMassKg = bodyMass;
summary.approximateTotalMassKg = structuralMass + bodyMass;
summary.massNote = "sum(m(section)*element length) plus collocated nacelle/hub masses";
end

function bladeDofMap = makeBladeDofMap(mesh, dofs, frames)
% Homologous non-root stations used later by MBC; Tc supplies reduced maps.
nodeIds = [(22:56).', (58:92).', (94:128).'];
full = zeros(35, 6, 3);
frameElementIds = zeros(35, 3);
frameR = zeros(3, 3, 35, 3);
for blade = 1:3
    [found, nodeRows] = ismember(nodeIds(:,blade), mesh.nodes.id);
    if ~all(found)
        error('model:build_model:IncompleteBladeDofMap', ...
            'Blade %d is missing a verified non-root node.', blade);
    end
    full(:,:,blade) = dofs.node(nodeRows,:);
    frameRows = find(frames.blade == blade);
    if numel(frameRows) ~= 35
        error('model:build_model:IncompleteBladeFrameMap', ...
            'Blade %d does not have 35 element frames.', blade);
    end
    frameElementIds(:,blade) = frames.elementId(frameRows);
    frameR(:,:,:,blade) = frames.R(:,:,frameRows);
end
[~, rootRows] = ismember([21;57;93], mesh.nodes.id);

bladeDofMap = struct();
bladeDofMap.station = (1:35).';
bladeDofMap.nodeIds = nodeIds;
bladeDofMap.rootNodeIds = [21;57;93];
bladeDofMap.rootFull = dofs.node(rootRows,:).';
bladeDofMap.full = full;
bladeDofMap.map = zeros(35*6, 3);
for blade = 1:3
    bladeDofMap.map(:,blade) = reshape(full(:,:,blade).', [], 1);
end
bladeDofMap.dofMap = bladeDofMap.map;
bladeDofMap.dofOrder = dofs.order;
bladeDofMap.frameElementIds = frameElementIds;
bladeDofMap.frameR = frameR;
bladeDofMap.frameConvention = frames.convention;
bladeDofMap.coordinateState = ...
    "full global nodal DOFs; reduced indices are assigned only after Tc";
bladeDofMap.homology = ...
    "rows are equal radial stations; third dimension of full is blade 1/2/3";
end
