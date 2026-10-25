function artifacts = export_action02(run,cfg,modelData,action02)
%EXPORT_ACTION02 Persist Action 02 acceptance tables and reproducible plots.
%   This postprocessor consumes stored results and model geometry; it does
%   not assemble matrices or solve an additional structural problem.

arguments
    run (1,1) struct
    cfg (1,1) struct
    modelData (1,1) struct
    action02 (1,1) struct
end

if ~isfolder(run.figuresFolder)
    mkdir(run.figuresFolder);
end

elementDiagnostics = localRequiredTable(action02, { ...
    {'elementDiagnostics'}, {'elementDiagnosticTable'}, ...
    {'diagnostics','elements'}}, 'element diagnostics');
validationTable = localRequiredTable(action02, { ...
    {'checkTable'}, {'checks'}, {'validation'}, {'validationChecks'}}, ...
    'validation checks');
meshConvergence = localRequiredTable(action02, { ...
    {'meshConvergence'}, {'meshConvergenceTable'}, ...
    {'benchmarks','meshConvergence'}}, 'mesh convergence');

writetable(elementDiagnostics, ...
    fullfile(run.folder,'action02_element_diagnostics.csv'));
writetable(validationTable, ...
    fullfile(run.folder,'action02_validation.csv'));
writetable(meshConvergence, ...
    fullfile(run.folder,'action02_mesh_convergence.csv'));

componentSummary = localOptionalTable(action02, { ...
    {'componentSummary'}, {'massByComponent'}, ...
    {'diagnostics','componentSummary'}});
if isempty(componentSummary)
    componentSummary = localComponentSummary(modelData);
end
if ~isempty(componentSummary)
    writetable(componentSummary, ...
        fullfile(run.folder,'action02_component_summary.csv'));
end

subsystemSummary = localOptionalTable(action02, { ...
    {'modalTable'}, {'subsystemFrequencies'}, {'subsystemModal'}, ...
    {'bladeComparison'}, {'benchmarks','subsystems'}});
if ~isempty(subsystemSummary)
    writetable(subsystemSummary, ...
        fullfile(run.folder,'action02_subsystem_modal.csv'));
end

artifacts = struct('elementDiagnostics',elementDiagnostics, ...
    'validation',validationTable,'meshConvergence',meshConvergence, ...
    'componentSummary',componentSummary,'subsystemSummary',subsystemSummary, ...
    'figures',gobjects(0));

makeFigures = true;
if isfield(cfg,'output') && isfield(cfg.output,'makeFigures')
    makeFigures = logical(cfg.output.makeFigures);
end
if ~makeFigures
    return
end

artifacts.figures(end+1) = localPlotMeshConvergence(meshConvergence, ...
    fullfile(run.figuresFolder,'action02_mesh_convergence.png'));
artifacts.figures(end+1) = localPlotLocalAxes(modelData,cfg, ...
    fullfile(run.figuresFolder,'action02_local_axes.png'));
[modeNumber,bladeFrequency] = localBladeFrequencyData(action02,subsystemSummary);
artifacts.figures(end+1) = localPlotBladeComparison( ...
    modeNumber,bladeFrequency, ...
    fullfile(run.figuresFolder,'action02_blade_comparison.png'));
end

function tableValue = localRequiredTable(source,paths,label)
tableValue = localOptionalTable(source,paths);
if isempty(tableValue) || height(tableValue) == 0
    error('post:export_action02:MissingTable', ...
        'Action 02 results do not contain %s.',label);
end
end

function tableValue = localOptionalTable(source,paths)
value = localFirstValue(source,paths);
if isempty(value)
    tableValue = table();
else
    tableValue = localToTable(value);
end
end

function value = localFirstValue(source,paths)
value = [];
for pathIndex = 1:numel(paths)
    path = paths{pathIndex};
    cursor = source;
    found = true;
    for fieldIndex = 1:numel(path)
        if ~isstruct(cursor) || ~isfield(cursor,path{fieldIndex})
            found = false;
            break
        end
        cursor = cursor.(path{fieldIndex});
    end
    if found && ~isempty(cursor)
        value = cursor;
        return
    end
end
end

function tableValue = localToTable(value)
if istimetable(value)
    tableValue = timetable2table(value);
elseif istable(value)
    tableValue = value;
elseif isstruct(value)
    tableValue = struct2table(value);
elseif isnumeric(value) || islogical(value) || isstring(value)
    tableValue = array2table(value);
elseif iscell(value)
    tableValue = cell2table(value);
else
    error('post:export_action02:UnsupportedTableValue', ...
        'Cannot export Action 02 value of class %s as CSV.',class(value));
end
end

function summary = localComponentSummary(modelData)
mesh = modelData.mesh;
elements = mesh.elements;
nodeIds = double(mesh.nodes.id(:));
[foundI,rowI] = ismember(double(elements.nodeI(:)),nodeIds);
[foundJ,rowJ] = ismember(double(elements.nodeJ(:)),nodeIds);
if ~all(foundI & foundJ)
    error('post:export_action02:InvalidConnectivity', ...
        'Cannot summarize components with missing element nodes.');
end
lengths = vecnorm(mesh.nodes.xyz(rowJ,:)-mesh.nodes.xyz(rowI,:),2,2);
sectionIds = double(elements.section(:));
massPerLength = reshape([modelData.sections(sectionIds).m],[],1);
labels = string(elements.type(:));
blade = double(elements.blade(:));
labels(labels == "blade") = "blade_"+string(blade(labels == "blade"));
component = unique(labels,'stable');
elementCount = zeros(numel(component),1);
totalLengthM = zeros(numel(component),1);
distributedMassKg = zeros(numel(component),1);
for index = 1:numel(component)
    mask = labels == component(index);
    elementCount(index) = nnz(mask);
    totalLengthM(index) = sum(lengths(mask));
    distributedMassKg(index) = sum(massPerLength(mask).*lengths(mask));
end
summary = table(component,elementCount,totalLengthM,distributedMassKg);
end

function fig = localPlotMeshConvergence(convergence,fileName)
[x,xName] = localNumericColumn(convergence, ...
    ["elementcount","nelements","meshelements","elements"]);
if isempty(x)
    error('post:export_action02:MissingMeshResolution', ...
        'Mesh-convergence results require an element-count column.');
end
fig = figure('Visible','off','Color','w','Name','Action 02 mesh convergence');
layout = tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');
[tip,~] = localNumericColumn(convergence, ...
    ["tipdisplacement","tipdeflection"]);
[frequency1,~] = localNumericColumn(convergence, ...
    ["frequency1hz","frequency1","freq1hz"]);
[frequency2,~] = localNumericColumn(convergence, ...
    ["frequency2hz","frequency2","freq2hz"]);
[tipError,~] = localNumericColumn(convergence, ...
    ["tiprelativeerror","tiperror"]);
[frequency1Error,~] = localNumericColumn(convergence, ...
    ["frequency1relativeerror","frequency1error","freq1relativeerror"]);
[frequency2Error,~] = localNumericColumn(convergence, ...
    ["frequency2relativeerror","frequency2error","freq2relativeerror"]);
if isempty(tip) || isempty(frequency1) || isempty(frequency2)
    error('post:export_action02:MissingConvergenceResponse', ...
        'Mesh convergence requires tip displacement and two frequencies.');
end

ax1 = nexttile(layout); grid(ax1,'on'); box(ax1,'on');
semilogx(ax1,x,1e6*tip,'-o','LineWidth',1.2);
xlabel(ax1,'Number of elements'); ylabel(ax1,'Tip displacement (\mum)');
title(ax1,'Static response');

ax2 = nexttile(layout); grid(ax2,'on'); box(ax2,'on');
semilogx(ax2,x,frequency1,'-o','LineWidth',1.2);
xlabel(ax2,'Number of elements'); ylabel(ax2,'Frequency (Hz)');
title(ax2,'First bending frequency');

ax3 = nexttile(layout); grid(ax3,'on'); box(ax3,'on');
loglog(ax3,x,max(frequency2,eps),'-o','LineWidth',1.2);
xlabel(ax3,'Number of elements'); ylabel(ax3,'Frequency (Hz)');
title(ax3,'Second bending frequency');

ax4 = nexttile(layout); hold(ax4,'on'); grid(ax4,'on'); box(ax4,'on');
if ~isempty(tipError)
    loglog(ax4,x,max(abs(tipError),eps),'-o','LineWidth',1.2, ...
        'DisplayName','tip displacement');
end
if ~isempty(frequency1Error)
    loglog(ax4,x,max(abs(frequency1Error),eps),'-s','LineWidth',1.2, ...
        'DisplayName','frequency 1');
end
if ~isempty(frequency2Error)
    loglog(ax4,x,max(abs(frequency2Error),eps),'-^','LineWidth',1.2, ...
        'DisplayName','frequency 2');
end
set(ax4,'XScale','log','YScale','log');
yline(ax4,1e-3,'--','0.1% tolerance','HandleVisibility','off');
xlabel(ax4,'Number of elements'); ylabel(ax4,'Relative error');
title(ax4,'Convergence to analytical references');
legend(ax4,'Location','best');
title(layout,'Timoshenko selective-integration mesh convergence');
exportgraphics(fig,fileName,'Resolution',180);
end

function fig = localPlotLocalAxes(modelData,cfg,fileName)
mesh = modelData.mesh;
xyz = double(mesh.nodes.xyz);
elementData = mesh.elements;
nodeIds = double(mesh.nodes.id(:));
nodeI = double(elementData.nodeI(:));
nodeJ = double(elementData.nodeJ(:));
[foundI,rowI] = ismember(nodeI,nodeIds);
[foundJ,rowJ] = ismember(nodeJ,nodeIds);
if ~all(foundI & foundJ)
    error('post:export_action02:InvalidConnectivity', ...
        'Cannot plot local axes for elements with missing nodes.');
end

selected = localSelectedElements(elementData,cfg);
fig = figure('Visible','off','Color','w','Name','Action 02 local axes');
ax = axes(fig); hold(ax,'on'); grid(ax,'on'); box(ax,'on'); axis(ax,'equal');
types = string(elementData.type(:));
uniqueTypes = unique(types,'stable');
palette = lines(max(numel(uniqueTypes),1));
for typeIndex = 1:numel(uniqueTypes)
    mask = types == uniqueTypes(typeIndex);
    rows = find(mask);
    x = [xyz(rowI(rows),1),xyz(rowJ(rows),1),nan(numel(rows),1)].';
    y = [xyz(rowI(rows),2),xyz(rowJ(rows),2),nan(numel(rows),1)].';
    z = [xyz(rowI(rows),3),xyz(rowJ(rows),3),nan(numel(rows),1)].';
    plot3(ax,x(:),y(:),z(:),'-','LineWidth',1.0, ...
        'Color',palette(typeIndex,:),'DisplayName',char(uniqueTypes(typeIndex)));
end

span = norm(max(xyz,[],1)-min(xyz,[],1));
axisLength = max(span*0.035,eps);
axisColors = [0.85 0.15 0.15;0.15 0.60 0.20;0.10 0.35 0.85];
axisNames = ["local 1","local 2","local 3"];
for selectionIndex = 1:numel(selected)
    elementIndex = selected(selectionIndex);
    aux = double(elementData.auxPoint(elementIndex,:));
    [R,~,~] = elements.element_rotation_matrix( ...
        xyz(rowI(elementIndex),:),xyz(rowJ(elementIndex),:),aux);
    origin = 0.5*(xyz(rowI(elementIndex),:)+xyz(rowJ(elementIndex),:));
    for axisIndex = 1:3
        displayName = char(axisNames(axisIndex));
        handleVisibility = 'off';
        if selectionIndex == 1
            handleVisibility = 'on';
        end
        quiver3(ax,origin(1),origin(2),origin(3), ...
            axisLength*R(axisIndex,1),axisLength*R(axisIndex,2), ...
            axisLength*R(axisIndex,3),0,'LineWidth',1.5, ...
            'Color',axisColors(axisIndex,:),'MaxHeadSize',0.5, ...
            'DisplayName',displayName,'HandleVisibility',handleVisibility);
    end
end
xlabel(ax,'x (m)'); ylabel(ax,'y (m)'); zlabel(ax,'z (m)');
title(ax,'Selected Timoshenko local frames'); view(ax,135,20);
legend(ax,'Location','best');
exportgraphics(fig,fileName,'Resolution',180);
end

function selected = localSelectedElements(elements,cfg)
selected = zeros(0,1);
if isfield(cfg,'action02') && ...
        isfield(cfg.action02,'localAxesLegacyElementIds') && ...
        isfield(elements,'legacyId')
    requested = double(cfg.action02.localAxesLegacyElementIds(:));
    [found,rows] = ismember(requested,double(elements.legacyId(:)));
    selected = rows(found);
end
if isempty(selected)
    count = numel(elements.nodeI);
    selected = unique(round(linspace(1,count,min(5,count)))).';
end
end

function [modeNumber,frequencies] = localBladeFrequencyData(action02,summary)
modeNumber = [];
frequencies = [];

matrixValue = localFirstValue(action02, { ...
    {'bladeFrequenciesHz'}, {'bladeComparison','frequenciesHz'}, ...
    {'subsystems','bladeFrequenciesHz'}});
if isnumeric(matrixValue) && ~isempty(matrixValue)
    frequencies = double(matrixValue);
    if size(frequencies,2) ~= 3 && size(frequencies,1) == 3
        frequencies = frequencies.';
    end
    if size(frequencies,2) == 3
        modeNumber = (1:size(frequencies,1)).';
        return
    end
end

comparison = localOptionalTable(action02, { ...
    {'bladeEquivalence'}, {'bladeComparison'}, ...
    {'benchmarks','bladeEquivalence'}});
if ~isempty(comparison)
    summary = comparison;
end
if isempty(summary)
    error('post:export_action02:MissingBladeComparison', ...
        'Action 02 results require frequencies for the three isolated blades.');
end
names = string(summary.Properties.VariableNames);
normalized = localNormalizeNames(names);
wide = zeros(height(summary),3);
wideFound = true;
for blade = 1:3
    column = find((contains(normalized,"blade"+blade) | ...
        contains(normalized,"pala"+blade)) & ...
        (contains(normalized,"frequency") | contains(normalized,"freq") | ...
        endsWith(normalized,"hz")),1);
    if isempty(column) || ~isnumeric(summary.(names(column)))
        wideFound = false;
        break
    end
    wide(:,blade) = double(summary.(names(column))(:));
end
if wideFound
    frequencies = wide;
    [modeNumber,~] = localNumericColumn(summary,["mode","modenumber"]);
    if isempty(modeNumber), modeNumber = (1:height(summary)).'; end
    return
end

labelColumn = find(contains(normalized,"subsystem") | ...
    contains(normalized,"component") | contains(normalized,"name"),1);
frequencyColumn = find(contains(normalized,"frequency") | ...
    contains(normalized,"freq"),1);
modeColumn = find(normalized == "mode" | normalized == "modenumber",1);
if isempty(labelColumn) || isempty(frequencyColumn) || ...
        ~isnumeric(summary.(names(frequencyColumn)))
    error('post:export_action02:InvalidBladeComparison', ...
        'The subsystem table cannot be interpreted as blade frequencies.');
end
labels = lower(string(summary.(names(labelColumn))));
frequencyValues = double(summary.(names(frequencyColumn))(:));
bladeModes = cell(3,1); bladeValues = cell(3,1);
for blade = 1:3
    mask = (contains(labels,"blade") | contains(labels,"pala")) & ...
        contains(labels,string(blade));
    bladeValues{blade} = frequencyValues(mask);
    if isempty(modeColumn)
        bladeModes{blade} = (1:nnz(mask)).';
    else
        bladeModes{blade} = double(summary.(names(modeColumn))(mask));
    end
end
if any(cellfun(@isempty,bladeValues))
    error('post:export_action02:IncompleteBladeComparison', ...
        'Frequencies for all three isolated blades are required.');
end
modeNumber = unique(vertcat(bladeModes{:}));
frequencies = nan(numel(modeNumber),3);
for blade = 1:3
    [found,rows] = ismember(bladeModes{blade},modeNumber);
    frequencies(rows(found),blade) = bladeValues{blade}(found);
end
end

function fig = localPlotBladeComparison(modeNumber,frequencies,fileName)
fig = figure('Visible','off','Color','w','Name','Action 02 blade comparison');
layout = tiledlayout(fig,2,1,'TileSpacing','compact','Padding','compact');
ax1 = nexttile(layout); hold(ax1,'on'); grid(ax1,'on'); box(ax1,'on');
styles = {'-o','-s','-^'};
for blade = 1:3
    plot(ax1,modeNumber,frequencies(:,blade),styles{blade}, ...
        'LineWidth',1.2,'DisplayName',sprintf('blade %d',blade));
end
xlabel(ax1,'Mode'); ylabel(ax1,'Frequency (Hz)');
title(ax1,'Isolated-blade frequency comparison');
legend(ax1,'Location','best');

ax2 = nexttile(layout); grid(ax2,'on'); box(ax2,'on');
spread = (max(frequencies,[],2)-min(frequencies,[],2))./ ...
    max(mean(frequencies,2,'omitnan'),eps);
semilogy(ax2,modeNumber,max(spread,eps),'-o','LineWidth',1.2);
xlabel(ax2,'Mode'); ylabel(ax2,'Relative spread');
title(ax2,'Difference among the three orientations');
exportgraphics(fig,fileName,'Resolution',180);
end

function [values,normalizedName] = localNumericColumn(tableValue,aliases)
values = [];
normalizedName = "";
names = string(tableValue.Properties.VariableNames);
normalized = localNormalizeNames(names);
normalizedAliases = localNormalizeNames(aliases);
for alias = reshape(normalizedAliases,1,[])
    index = find(normalized == alias,1);
    if ~isempty(index) && (isnumeric(tableValue.(names(index))) || ...
            islogical(tableValue.(names(index))))
        values = double(tableValue.(names(index))(:));
        normalizedName = normalized(index);
        return
    end
end
end

function normalized = localNormalizeNames(names)
normalized = lower(regexprep(string(names),'[^A-Za-z0-9]',''));
end
