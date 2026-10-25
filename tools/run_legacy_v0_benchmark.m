function outputFile = run_legacy_v0_benchmark(projectRoot, outputFile)
%RUN_LEGACY_V0_BENCHMARK Execute the read-only Version 0 benchmark verbatim.
%   Intended only to regenerate the regression artifact, never for use by
%   the new solver. Figures are hidden, but the inherited script is not
%   edited or intercepted.

if nargin < 1 || isempty(projectRoot)
    projectRoot = fileparts(fileparts(mfilename('fullpath')));
end
if nargin < 2 || isempty(outputFile)
    outputFile = fullfile(tempdir, 'legacy_benchmark.mat');
end
setenv('TESIS_LEGACY_BENCHMARK_OUTPUT', char(string(outputFile)));
source = fullfile(char(string(projectRoot)), 'legacy', 'Codigos_sergio', ...
    '[Diego Turello Version 0]', 'FrecuenciasTorreCompleta.m');
set(groot, 'defaultFigureVisible', 'off');
run(source);
frequencyHz = f(:); %#ok<NODEF>
outputFile = getenv('TESIS_LEGACY_BENCHMARK_OUTPUT');
save(outputFile, 'f', 'frequencyHz', '-v7'); %#ok<NODEF>
close all force
end
