function varargout = mbc_transformation(bladeDofMap, azimuth, options)
%MBC_TRANSFORMATION Three-blade collective/cosine/sine transformation.
%   result = rotor.mbc_transformation(map,psi,options) builds q=T*z.
%   map is nEquivalent-by-3 and provides corresponding component indices
%   for blades 1, 2 and 3. The transformed coordinates occupy the map
%   columns 1, 2 and 3 (collective, cosine and sine, respectively). This
%   function is the harmonic block only; mbc_derivatives optionally composes
%   it with homologous blade frames H supplied in options.frameData.
%
%   options.nDof controls the global dimension; options.direction is +1
%   or -1 and defines the ordering of blade azimuth offsets.

arguments
    bladeDofMap
    azimuth (1,1) double {mustBeFinite}
    options = struct()
end

map = normalizeMap(bladeDofMap);
nDof = getOption(options,'nDof',max(map,[],'all'));
direction = getOption(options,'direction',1);
if ~ismember(direction,[-1 1])
    error('rotor:MBC:InvalidDirection','direction must be +1 or -1.');
end
validateMap(map,nDof);

angles = azimuth + direction*(0:2)*(2*pi/3);
[T,Tinv] = buildMatrices(map,nDof,angles);
identityError = norm(Tinv*T-speye(nDof),'fro')/max(1,sqrt(nDof));

result = struct('T',T,'Tinv',Tinv,'azimuth',azimuth, ...
    'bladeAzimuths',angles,'bladeDofMap',map,'nDof',nDof, ...
    'direction',direction,'identityError',identityError, ...
    'coordinateOrder',"collective-cosine-sine");

if nargout <= 1
    varargout{1} = result;
else
    varargout{1} = T;
    varargout{2} = Tinv;
    if nargout >= 3, varargout{3} = result; end
end
end

function [T,Tinv] = buildMatrices(map,nDof,angles)
T = speye(nDof);
Tinv = speye(nDof);
for row = 1:size(map,1)
    physical = map(row,:);
    transformed = physical;
    block = [ones(3,1), cos(angles(:)), sin(angles(:))];
    inverseBlock = [ones(1,3)/3; (2/3)*cos(angles); (2/3)*sin(angles)];
    T(physical,transformed) = block;
    Tinv(transformed,physical) = inverseBlock;
end
end

function map = normalizeMap(input)
if isnumeric(input)
    map = double(input);
elseif iscell(input) && numel(input) == 3
    columns = cellfun(@(x)x(:),input,'UniformOutput',false);
    if numel(columns{1}) ~= numel(columns{2}) || numel(columns{1}) ~= numel(columns{3})
        error('rotor:MBC:UnequalBladeMaps','The three blade maps must have equal length.');
    end
    map = [columns{:}];
elseif isstruct(input)
    candidates = {'bladeDofMap','dofMap','map'};
    map = [];
    for k = 1:numel(candidates)
        if isfield(input,candidates{k}), map = normalizeMap(input.(candidates{k})); break; end
    end
    if isempty(map) && all(isfield(input,{'blade1','blade2','blade3'}))
        map = normalizeMap({input.blade1,input.blade2,input.blade3});
    end
else
    error('rotor:MBC:InvalidMap','Blade map must be numeric, a 3-cell array, or a structure.');
end
if size(map,2) ~= 3
    error('rotor:MBC:InvalidMap','Blade map must have exactly three columns.');
end
end

function validateMap(map,nDof)
if isempty(map) || any(~isfinite(map),'all') || any(map ~= fix(map),'all') || ...
        any(map < 1,'all') || any(map > nDof,'all')
    error('rotor:MBC:InvalidMap','Blade DOF indices must be unique integers in [1,nDof].');
end
if numel(unique(map(:))) ~= numel(map)
    error('rotor:MBC:NonBijectiveMap','Every rotating DOF must occur exactly once in the blade map.');
end
end

function value = getOption(options,name,defaultValue)
value = defaultValue;
if isnumeric(options) && isscalar(options) && strcmp(name,'nDof')
    value = options;
elseif isstruct(options) && isfield(options,name) && ~isempty(options.(name))
    value = options.(name);
end
end
