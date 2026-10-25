function frames = blade_coordinate_systems(mesh, tolerance)
%BLADE_COORDINATE_SYSTEMS Build right-handed blade frames from auxiliaries.
%   The legacy convention is retained: e1 runs node I to J, e3 is the
%   projected auxiliary direction, and e2 = -cross(e1,e3). R(:,:,k) has
%   global basis vectors [e1 e2 e3] as columns.

if nargin < 2 || isempty(tolerance)
    tolerance = 1.0e-10;
end
bladeRows = find(mesh.elements.blade(:) > 0);
nFrames = numel(bladeRows);
nodeIds = mesh.nodes.id(:);
xyz = mesh.nodes.xyz;

frames = struct();
frames.elementRow = bladeRows;
frames.elementId = mesh.elements.id(bladeRows);
frames.blade = mesh.elements.blade(bladeRows);
frames.origin = zeros(nFrames, 3);
frames.auxPoint = mesh.elements.auxPoint(bladeRows,:);
frames.e1 = zeros(nFrames, 3);
frames.e2 = zeros(nFrames, 3);
frames.e3 = zeros(nFrames, 3);
frames.R = zeros(3, 3, nFrames);

for k = 1:nFrames
    row = bladeRows(k);
    [foundI, i] = ismember(mesh.elements.nodeI(row), nodeIds);
    [foundJ, j] = ismember(mesh.elements.nodeJ(row), nodeIds);
    if ~(foundI && foundJ)
        error('model:blade_coordinate_systems:UnknownNode', ...
            'Element %g references an unknown node.', mesh.elements.id(row));
    end
    xi = xyz(i,:).';
    xj = xyz(j,:).';
    axisVector = xj - xi;
    lengthElement = norm(axisVector);
    if lengthElement <= tolerance
        error('model:blade_coordinate_systems:ZeroLength', ...
            'Blade element %g has length %.16g <= %.16g.', ...
            mesh.elements.id(row), lengthElement, tolerance);
    end
    e1 = axisVector/lengthElement;
    auxiliaryVector = frames.auxPoint(k,:).' - xi;
    projected = auxiliaryVector - dot(auxiliaryVector, e1)*e1;
    projectedNorm = norm(projected);
    scale = max([1, norm(auxiliaryVector), lengthElement]);
    if ~all(isfinite(auxiliaryVector)) || projectedNorm <= tolerance*scale
        error('model:blade_coordinate_systems:DegenerateAuxiliaryPoint', ...
            ['Blade element %g has a collinear/invalid auxiliary point; ' ...
             'projected norm %.16g <= tolerance %.16g.'], ...
            mesh.elements.id(row), projectedNorm, tolerance*scale);
    end
    e3 = projected/projectedNorm;
    e2 = -cross(e1, e3);
    e2 = e2/norm(e2);
    e3 = cross(e1, e2);
    e3 = e3/norm(e3);
    rotation = [e1, e2, e3];

    frames.origin(k,:) = xi.';
    frames.e1(k,:) = e1.';
    frames.e2(k,:) = e2.';
    frames.e3(k,:) = e3.';
    frames.R(:,:,k) = rotation;
end

frames.convention = "columns_global_e1_e2_e3; e2=-cross(e1,e3)";
frames.tolerance = tolerance;
end
