function run = create_run_folder(cfg)
%CREATE_RUN_FOLDER Create an isolated, timestamped folder for one execution.

projectRoot = localProjectRoot(cfg);
runsRoot = fullfile(projectRoot, 'runs');
if isfield(cfg, 'output') && isfield(cfg.output, 'runsDirectory') && ...
        strlength(string(cfg.output.runsDirectory)) > 0
    candidate = char(string(cfg.output.runsDirectory));
    if ~localIsAbsolute(candidate)
        candidate = fullfile(projectRoot, candidate);
    end
    runsRoot = candidate;
end
if ~isfolder(runsRoot)
    mkdir(runsRoot);
end

identifier = "analysis";
if isfield(cfg, 'run') && isfield(cfg.run, 'identifier')
    identifier = string(cfg.run.identifier);
elseif isfield(cfg, 'analysis') && isfield(cfg.analysis, 'type')
    identifier = string(cfg.analysis.type);
end
if identifier == "geometry_default" && isfield(cfg,'analysis') && ...
        lower(string(cfg.analysis.type)) ~= "geometry"
    identifier = string(cfg.analysis.type);
end
identifier = regexprep(identifier, '[^A-Za-z0-9_-]', '_');
stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss_SSS'));
folder = fullfile(runsRoot, sprintf('run_%s_%s', stamp, identifier));
suffix = 0;
while isfolder(folder)
    suffix = suffix + 1;
    folder = fullfile(runsRoot, sprintf('run_%s_%s_%02d', stamp, identifier, suffix));
end
mkdir(folder);
mkdir(fullfile(folder, 'figures'));

run = struct();
run.id = string(erase(folder, [runsRoot filesep]));
run.folder = folder;
run.figuresFolder = fullfile(folder, 'figures');
run.logFile = fullfile(folder, 'execution.log');
run.startedAt = datetime('now', 'TimeZone', 'local');
run.status = "running";
end

function root = localProjectRoot(cfg)
if isfield(cfg, 'paths') && isfield(cfg.paths, 'projectRoot')
    root = char(string(cfg.paths.projectRoot));
else
    root = fileparts(fileparts(mfilename('fullpath')));
end
end

function tf = localIsAbsolute(pathValue)
if ispc
    tf = ~isempty(regexp(pathValue, '^[A-Za-z]:[\\/]', 'once')) || startsWith(pathValue, '\\');
else
    tf = startsWith(pathValue, filesep);
end
end
