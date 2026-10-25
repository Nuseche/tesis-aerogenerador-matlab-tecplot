function tableOut = export_modal_summary(run, modalResults)
%EXPORT_MODAL_SUMMARY Export stationary/rotating/Campbell modal metadata.

rows = localCollect(modalResults, "modal");
if isempty(rows)
    tableOut = table();
    return
end
tableOut = struct2table(rows);
writetable(tableOut, fullfile(run.folder, 'modal_summary.csv'));
end

function rows = localCollect(value, caseName)
template = struct('caseName', "", 'speedRPM', NaN, 'mode', NaN, ...
    'realLambda', NaN, 'imagLambda', NaN, 'frequencyHz', NaN, ...
    'naturalFrequencyHz', NaN, 'dampingRatio', NaN, 'classification', "");
rows = repmat(template, 0, 1);
if ~isstruct(value), return; end

if isfield(value,'speedRPM') && numel(value.speedRPM) > 0 && ...
        isfield(value,'frequencyHz') && ismatrix(value.frequencyHz) && ...
        size(value.frequencyHz,1) == numel(value.speedRPM)
    speedGrid = value.speedRPM(:);
    frequencyGrid = value.frequencyHz;
    naturalGrid = localField(value, {'naturalFrequencyHz'});
    dampingGrid = localField(value, {'dampingRatio'});
    lambdaGrid = localField(value, {'eigenvalues'});
    classificationGrid = localField(value, {'classification','labels'});
    for speedIndex = 1:numel(speedGrid)
        for modeIndex = 1:size(frequencyGrid,2)
            if ~isfinite(frequencyGrid(speedIndex,modeIndex)), continue; end
            row = template;
            row.caseName = caseName; row.speedRPM = speedGrid(speedIndex);
            row.mode = modeIndex; row.frequencyHz = frequencyGrid(speedIndex,modeIndex);
            if ~isempty(naturalGrid), row.naturalFrequencyHz = naturalGrid(speedIndex,modeIndex); end
            if ~isempty(dampingGrid), row.dampingRatio = dampingGrid(speedIndex,modeIndex); end
            if ~isempty(lambdaGrid)
                row.realLambda = real(lambdaGrid(speedIndex,modeIndex));
                row.imagLambda = imag(lambdaGrid(speedIndex,modeIndex));
            end
            row.classification = localClassification( ...
                classificationGrid,speedIndex,modeIndex);
            rows(end+1,1) = row; %#ok<AGROW>
        end
    end
    return
end

function label=localClassification(value,speedIndex,modeIndex)
label="";
if isempty(value),return,end
if iscell(value)
    if speedIndex>numel(value),return,end
    current=value{speedIndex};
    if isstruct(current)
        if isfield(current,'labels'),current=current.labels;else,return,end
    end
else
    current=value;
    if isstruct(current)
        if speedIndex>numel(current)||~isfield(current(speedIndex),'labels'),return,end
        current=current(speedIndex).labels;
    elseif ismatrix(current)&&size(current,1)>=speedIndex
        current=current(speedIndex,:);
    end
end
if numel(current)>=modeIndex,label=string(current(modeIndex));end
end

lambda = localField(value, {'eigenvalues','lambda'});
frequency = localField(value, {'frequencyHz','frequenciesHz','dampedFrequencyHz'});
natural = localField(value, {'naturalFrequencyHz','undampedFrequencyHz'});
damping = localField(value, {'dampingRatio','dampingRatios'});
classification = localField(value, {'classification','labels'});
if ~isempty(lambda) || ~isempty(frequency)
    n = max([numel(lambda), numel(frequency), numel(natural), numel(damping), 1]);
    speed = NaN;
    if isfield(value, 'speedRPM') && isscalar(value.speedRPM), speed = value.speedRPM; end
    for i = 1:n
        row = template;
        row.caseName = caseName;
        row.speedRPM = speed;
        row.mode = i;
        if i <= numel(lambda)
            row.realLambda = real(lambda(i)); row.imagLambda = imag(lambda(i));
        end
        if i <= numel(frequency), row.frequencyHz = real(frequency(i)); end
        if i <= numel(natural), row.naturalFrequencyHz = real(natural(i)); end
        if i <= numel(damping), row.dampingRatio = real(damping(i)); end
        if i <= numel(classification)
            if iscell(classification), row.classification = string(classification{i});
            else, row.classification = string(classification(i)); end
        end
        rows(end+1,1) = row; %#ok<AGROW>
    end
    return
end

fields = fieldnames(value);
for i = 1:numel(fields)
    child = value.(fields{i});
    if isstruct(child)
        childName = caseName + "." + string(fields{i});
        childRows = localCollect(child, childName);
        rows = [rows; childRows]; %#ok<AGROW>
    end
end
end

function value = localField(s, names)
value = [];
for i = 1:numel(names)
    if isfield(s, names{i}) && ~isempty(s.(names{i}))
        value = s.(names{i}); return
    end
end
end
