function cfg = load_configuration(configFile)
%LOAD_CONFIGURATION Load defaults and recursively apply an explicit override.
%   CFG = IO.LOAD_CONFIGURATION() returns CONFIG_DEFAULT. CONFIGFILE may be
%   a scalar struct, an absolute/relative MAT file containing cfg or config,
%   a JSON file, or a function M-file returning a scalar struct.

cfg = config_default();
if nargin == 0 || isempty(configFile)
    validateConfiguration(cfg);
    return
end

if isstruct(configFile)
    override = configFile;
else
    configFile = string(configFile);
    if ~isscalar(configFile) || strlength(configFile) == 0
        error('io:load_configuration:InvalidInput', ...
            'configFile must be a scalar path or a scalar struct.');
    end
    filePath = resolveFile(configFile, cfg.paths.projectRoot);
    [folder, functionName, extension] = fileparts(filePath);
    switch lower(extension)
        case '.mat'
            loaded = load(filePath);
            if isfield(loaded, 'cfg')
                override = loaded.cfg;
            elseif isfield(loaded, 'config')
                override = loaded.config;
            else
                error('io:load_configuration:MissingVariable', ...
                    'MAT configuration must contain cfg or config: %s', filePath);
            end
        case '.json'
            override = jsondecode(fileread(filePath));
        case '.m'
            originalPath = path;
            restorePath = onCleanup(@() path(originalPath)); %#ok<NASGU>
            addpath(folder, '-begin');
            override = feval(functionName);
        otherwise
            error('io:load_configuration:UnsupportedFormat', ...
                'Unsupported configuration extension "%s".', extension);
    end
end

if ~isstruct(override) || ~isscalar(override)
    error('io:load_configuration:InvalidOverride', ...
        'The configuration override must be a scalar struct.');
end
cfg = mergeStruct(cfg, override);
validateConfiguration(cfg);
end

function filePath = resolveFile(candidate, projectRoot)
candidate = char(candidate);
if isfile(candidate)
    filePath = candidate;
else
    filePath = fullfile(char(projectRoot), candidate);
end
if ~isfile(filePath)
    error('io:load_configuration:FileNotFound', ...
        'Configuration file not found: %s', candidate);
end
[ok, attributes] = fileattrib(filePath);
if ok
    filePath = attributes.Name;
else
    filePath = char(filePath);
end
end

function output = mergeStruct(base, override)
output = base;
names = fieldnames(override);
for k = 1:numel(names)
    name = names{k};
    if isfield(output, name) && isstruct(output.(name)) && ...
            isscalar(output.(name)) && isstruct(override.(name)) && ...
            isscalar(override.(name))
        output.(name) = mergeStruct(output.(name), override.(name));
    else
        output.(name) = override.(name);
    end
end
end

function validateConfiguration(cfg)
required = {'units','analysis','base','rotor','mass','elements','assembly', ...
    'sections','modes','seismic','newmark','validation','data','paths'};
missing = required(~isfield(cfg, required));
if ~isempty(missing)
    error('io:load_configuration:IncompleteConfiguration', ...
        'Missing configuration groups: %s', strjoin(missing, ', '));
end
if string(cfg.units.system) ~= "SI"
    error('io:load_configuration:UnitsMustBeSI', ...
        'The model requires coherent SI units.');
end
if ~isscalar(cfg.rotor.speedRPM) || ~isfinite(cfg.rotor.speedRPM)
    error('io:load_configuration:InvalidRotorSpeed', ...
        'cfg.rotor.speedRPM must be a finite scalar.');
end
if ~isscalar(cfg.modes.number) || cfg.modes.number < 1 || ...
        cfg.modes.number ~= fix(cfg.modes.number)
    error('io:load_configuration:InvalidModeCount', ...
        'cfg.modes.number must be a positive integer.');
end
if cfg.newmark.beta <= 0 || cfg.newmark.gamma <= 0
    error('io:load_configuration:InvalidNewmarkParameters', ...
        'Newmark beta and gamma must be positive.');
end
formulation = lower(string(cfg.elements.formulation));
if ~any(formulation == ["closed_exact","selective_integration"])
    error('io:load_configuration:InvalidElementFormulation', ...
        'cfg.elements.formulation must be closed_exact or selective_integration.');
end
counts = [cfg.elements.regularIntegrationPoints, ...
    cfg.elements.shearIntegrationPoints,cfg.elements.massIntegrationPoints];
if any(~isfinite(counts)) || any(counts ~= fix(counts)) || ...
        any(counts < 1) || any(counts > 3)
    error('io:load_configuration:InvalidGaussRule', ...
        'Action 02 Gauss point counts must be integers from 1 to 3.');
end
rule = lower(string(cfg.sections.blade.torsionalInertiaRule));
if rule ~= "perpendicular_axis"
    error('io:load_configuration:UnresolvedBladeTorsion', ...
        ['The legacy blade TORDEN column is zero. The only documented ' ...
         'completion currently accepted is perpendicular_axis.']);
end
end
