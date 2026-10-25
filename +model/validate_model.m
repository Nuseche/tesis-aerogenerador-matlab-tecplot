function report = validate_model(modelData, cfg)
%VALIDATE_MODEL Validate topology, geometry, frames, sections, and contracts.
%   Throws model:validate_model:ValidationFailed before analysis when any
%   physical input check fails. With an output, also returns diagnostics.

if nargin < 2 || isempty(cfg)
    cfg = io.load_configuration();
end
errors = strings(0,1);
warnings = strings(0,1);
mesh = modelData.mesh;

if numel(unique(mesh.nodes.id)) ~= numel(mesh.nodes.id)
    errors(end+1) = "Node identifiers are not unique."; %#ok<AGROW>
end
if numel(unique(mesh.elements.id)) ~= numel(mesh.elements.id)
    errors(end+1) = "Element identifiers are not unique."; %#ok<AGROW>
end
if numel(unique(mesh.elements.legacyId)) ~= numel(mesh.elements.legacyId)
    errors(end+1) = "Retained legacy element identifiers are not unique."; %#ok<AGROW>
end

nodeIds = mesh.nodes.id(:);
[foundI, rowI] = ismember(mesh.elements.nodeI(:), nodeIds);
[foundJ, rowJ] = ismember(mesh.elements.nodeJ(:), nodeIds);
if ~all(foundI & foundJ)
    bad = mesh.elements.id(~(foundI & foundJ));
    errors(end+1) = "Elements reference missing nodes: " + join(string(bad.'), ', '); %#ok<AGROW>
    lengths = nan(numel(mesh.elements.id),1);
else
    vectors = mesh.nodes.xyz(rowJ,:) - mesh.nodes.xyz(rowI,:);
    lengths = vecnorm(vectors, 2, 2);
    bad = mesh.elements.id(~isfinite(lengths) | ...
        lengths <= cfg.validation.geometryTolerance);
    if ~isempty(bad)
        errors(end+1) = "Non-positive/invalid element lengths at IDs: " + ...
            join(string(bad.'), ', '); %#ok<AGROW>
    end
end

sectionIds = mesh.elements.section(:);
if any(sectionIds ~= fix(sectionIds) | sectionIds < 1 | ...
        sectionIds > numel(modelData.sections))
    errors(end+1) = "One or more elements have an invalid section assignment."; %#ok<AGROW>
else
    positiveFields = {'EA','GAy','GAz','GJ','EIy','EIz','m','Jx','Jy','Jz'};
    for sectionId = unique(sectionIds).'
        section = modelData.sections(sectionId);
        for k = 1:numel(positiveFields)
            name = positiveFields{k};
            value = section.(name);
            if ~isscalar(value) || ~isfinite(value) || ...
                    value <= cfg.validation.propertyTolerance
                errors(end+1) = sprintf( ...
                    'Section %g has invalid %s=%.16g (required > %.16g).', ...
                    sectionId, name, value, cfg.validation.propertyTolerance); %#ok<AGROW>
            end
        end
        if lower(string(section.type)) == "blade"
            if ~isfield(section,'torsionalInertiaRule') || ...
                    string(section.torsionalInertiaRule) ~= "perpendicular_axis"
                errors(end+1) = sprintf( ...
                    'Blade section %g has no accepted explicit Jx rule.',sectionId); %#ok<AGROW>
            elseif abs(section.Jx-(section.Jy+section.Jz)) > ...
                    100*eps(max([1,section.Jx,section.Jy+section.Jz]))
                errors(end+1) = sprintf( ...
                    'Blade section %g violates its perpendicular-axis Jx rule.',sectionId); %#ok<AGROW>
            end
        end
    end
end

if any(mesh.elements.legacyType == 3)
    errors(end+1) = "Penalty connector type 3 remains in the flexible mesh."; %#ok<AGROW>
end
if nnz(mesh.elements.legacyType == 4) ~= 9
    errors(end+1) = sprintf('Expected 9 preserved type-4 transitions; found %d.', ...
        nnz(mesh.elements.legacyType == 4)); %#ok<AGROW>
end
if ~all(ismember((125:133).', mesh.elements.legacyId))
    errors(end+1) = "The verified type-4 transition IDs 125:133 were not all preserved."; %#ok<AGROW>
end

for blade = 1:3
    bladeRows = mesh.elements.blade == blade;
    if nnz(bladeRows) ~= 35
        errors(end+1) = sprintf('Blade %d has %d elements; expected 35.', ...
            blade, nnz(bladeRows)); %#ok<AGROW>
    end
    if any(~isfinite(mesh.elements.auxPoint(bladeRows,:)), 'all')
        errors(end+1) = sprintf('Blade %d has a missing auxiliary point.', blade); %#ok<AGROW>
    end
end
try
    frames = model.blade_coordinate_systems(mesh, cfg.validation.frameTolerance);
    frameError = zeros(numel(frames.elementId),1);
    determinantError = zeros(numel(frames.elementId),1);
    for k = 1:numel(frames.elementId)
        R = frames.R(:,:,k);
        frameError(k) = norm(R.'*R-eye(3), 'fro');
        determinantError(k) = abs(det(R)-1);
    end
    if any(frameError > 10*cfg.validation.frameTolerance) || ...
            any(determinantError > 10*cfg.validation.frameTolerance)
        errors(end+1) = sprintf( ...
            'A blade frame is not right-handed/orthonormal (max errors %.3e, %.3e).', ...
            max(frameError), max(determinantError)); %#ok<AGROW>
    end
    rootFrames = zeros(3,3,3);
    for blade = 1:3
        rootIndex = find(frames.blade == blade, 1, 'first');
        rootFrames(:,:,blade) = frames.R(:,:,rootIndex);
    end
    separations = [norm(rootFrames(:,:,1)-rootFrames(:,:,2), 'fro'), ...
        norm(rootFrames(:,:,1)-rootFrames(:,:,3), 'fro'), ...
        norm(rootFrames(:,:,2)-rootFrames(:,:,3), 'fro')];
    if any(separations <= cfg.validation.frameTolerance)
        errors(end+1) = "Blade root coordinate systems are not distinct."; %#ok<AGROW>
    end
catch ME
    errors(end+1) = "Blade frame construction failed: " + string(ME.message); %#ok<AGROW>
end

if modelData.dofs.number ~= 6*numel(nodeIds) || ...
        ~isequal(size(modelData.dofs.node), [numel(nodeIds), 6]) || ...
        ~isequal(size(modelData.dofs.element), [numel(mesh.elements.id), 12])
    errors(end+1) = "The DOF map is inconsistent with the mesh."; %#ok<AGROW>
end
if string(cfg.base.type) == "fixed" && ~isequal(modelData.dofs.fixed(:), (1:6).')
    errors(end+1) = "Fixed-base configuration must restrain all six node-1 DOFs."; %#ok<AGROW>
end

allowedDetached = modelData.rigidBodies.masters(:);
usedNodeIds = unique([mesh.elements.nodeI(:); mesh.elements.nodeJ(:); allowedDetached]);
detached = setdiff(nodeIds, usedNodeIds);
if ~isempty(detached)
    errors(end+1) = "Nodes are disconnected and not declared rigid masters: " + ...
        join(string(detached.'), ', '); %#ok<AGROW>
end

report = struct();
report.passed = isempty(errors);
report.errors = errors;
report.warnings = warnings;
report.checkedAt = datetime('now', 'TimeZone', 'UTC');
report.geometry = struct('minimumLengthM', min(lengths), ...
    'maximumLengthM', max(lengths), 'elementCount', numel(lengths));
report.summary = modelData.summary;

if ~report.passed
    error('model:validate_model:ValidationFailed', ...
        'Input model validation failed:\n - %s', strjoin(cellstr(errors), '\n - '));
end
end
