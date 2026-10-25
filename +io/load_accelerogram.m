function varargout = load_accelerogram(source, options)
%LOAD_ACCELEROGRAM Read, convert, baseline-correct and resample a record.
%   record = io.load_accelerogram(source,options)
%   source may be a file, numeric [time acceleration...], table, or struct.
%   Acceleration output is always m/s^2 and time output is seconds.

arguments
    source
    options = struct()
end

options = unwrapOptions(options);
[time,acceleration,metadata] = readSource(source,options);
timeUnit = lower(string(getOption(options,{'timeUnit','timeUnits'}, ...
    getOption(metadata,{'timeUnit','timeUnits'},'s'))));
accelerationUnit = lower(string(getOption(options,{'accelerationUnit','accelUnit','units'}, ...
    getOption(metadata,{'accelerationUnit','accelUnit','units'},'m/s^2'))));

timeScale = unitScaleTime(timeUnit);
accelerationScale = unitScaleAcceleration(accelerationUnit);
timeSI = double(time(:))*timeScale;
accelerationSI = double(acceleration)*accelerationScale;
if size(accelerationSI,1) ~= numel(timeSI)
    if size(accelerationSI,2) == numel(timeSI), accelerationSI = accelerationSI.';
    else, error('io:Accelerogram:DimensionMismatch','Acceleration rows must match the time vector.'); end
end
if any(~isfinite(timeSI)) || any(~isfinite(accelerationSI),'all') || any(diff(timeSI) <= 0)
    error('io:Accelerogram:InvalidData','Time must increase strictly and all samples must be finite.');
end

[velocitySI,velocitySource]=optionalMotion(metadata,options, ...
    {'velocity','v','vg'},'velocityUnit','m/s',@unitScaleVelocity,numel(timeSI));
[displacementSI,displacementSource]=optionalMotion(metadata,options, ...
    {'displacement','u','ug'},'displacementUnit','m', ...
    @unitScaleDisplacement,numel(timeSI));
validateComponents(velocitySI,size(accelerationSI,2),'velocity');
validateComponents(displacementSI,size(accelerationSI,2),'displacement');

original = struct('time',timeSI,'acceleration',accelerationSI, ...
    'velocity',velocitySI,'displacement',displacementSI, ...
    'inputTime',double(time(:)),'inputAcceleration',double(acceleration), ...
    'inputTimeUnit',timeUnit,'inputAccelerationUnit',accelerationUnit);
baselineMethod = lower(string(getOption(options,{'baselineCorrection','baseline'},'none')));
processedAcceleration = correctBaseline(accelerationSI,timeSI,baselineMethod);
providedKinematicsWithBaseline=false;
if ~any(baselineMethod==["none","off"])&& ...
        (velocitySource=="provided"||displacementSource=="provided")
    policy=lower(string(getOption(options, ...
        {'providedKinematicsBaselinePolicy','kinematicsBaselinePolicy'},'error')));
    switch policy
        case "error"
            error('io:Accelerogram:InconsistentProvidedKinematics', ...
                ['Baseline correction changes acceleration while supplied ' ...
                 'velocity/displacement remain unchanged. Select reintegrate ' ...
                 'or preserve explicitly.']);
        case "reintegrate"
            velocitySI=[];displacementSI=[];
            velocitySource="missing";displacementSource="missing";
        case "preserve"
            providedKinematicsWithBaseline=true;
        otherwise
            error('io:Accelerogram:InvalidKinematicsBaselinePolicy', ...
                'Policy must be error, reintegrate, or preserve.');
    end
end

targetTime = getOption(options,{'targetTime','analysisTime'},[]);
targetDt = getOption(options,{'targetDt','dt'},[]);
interpolation = char(getOption(options, ...
    {'interpolation','interpolationMethod'},'linear'));
if isempty(targetTime) && ~isempty(targetDt)
    if targetDt <= 0, error('io:Accelerogram:InvalidDt','targetDt must be positive.'); end
    targetTime = (timeSI(1):targetDt:timeSI(end)).';
    if timeSI(end)-targetTime(end) > 1e-10*max(1,timeSI(end))
        targetTime(end+1,1) = timeSI(end);
    end
end
if isempty(targetTime)
    processedTime = timeSI;
else
    processedTime = double(targetTime(:));
    if processedTime(1) < timeSI(1) || processedTime(end) > timeSI(end)
        error('io:Accelerogram:Extrapolation','Target time must lie within the original record.');
    end
    processedAcceleration = interp1(timeSI,processedAcceleration,processedTime,interpolation);
end

if isempty(velocitySI)
    initialVelocity=initialMotion(options,{'initialVelocity','vg0'}, ...
        size(processedAcceleration,2));
    processedVelocity=cumtrapz(processedTime,processedAcceleration)+initialVelocity;
    velocitySource="integrated_from_processed_acceleration";
else
    processedVelocity=interpolateMotion(timeSI,velocitySI,processedTime,interpolation);
end
if isempty(displacementSI)
    initialDisplacement=initialMotion(options,{'initialDisplacement','ug0'}, ...
        size(processedAcceleration,2));
    processedDisplacement=cumtrapz(processedTime,processedVelocity)+initialDisplacement;
    displacementSource="integrated_from_processed_velocity";
else
    processedDisplacement=interpolateMotion( ...
        timeSI,displacementSI,processedTime,interpolation);
end
scaleFactor=double(getOption(options,{'scaleFactor','amplitudeScale'},1));
if ~isscalar(scaleFactor)||~isfinite(scaleFactor)
    error('io:Accelerogram:InvalidScaleFactor', ...
        'Ground-motion scaleFactor must be a finite scalar.');
end
processedAcceleration=scaleFactor*processedAcceleration;
processedVelocity=scaleFactor*processedVelocity;
processedDisplacement=scaleFactor*processedDisplacement;

processed = struct('time',processedTime,'acceleration',processedAcceleration, ...
    'velocity',processedVelocity,'displacement',processedDisplacement, ...
    'timeUnit',"s",'accelerationUnit',"m/s^2", ...
    'velocityUnit',"m/s",'displacementUnit',"m", ...
    'baselineCorrection',baselineMethod);
record = struct('t',processedTime,'acceleration',processedAcceleration, ...
    'velocity',processedVelocity,'displacement',processedDisplacement, ...
    'timeUnit',"s",'accelerationUnit',"m/s^2", ...
    'velocityUnit',"m/s",'displacementUnit',"m",'original',original, ...
    'processed',processed,'metadata',metadata, ...
    'processing',struct('baselineCorrection',baselineMethod, ...
    'interpolation',string(getOption(options,{'interpolation','interpolationMethod'},'linear')), ...
    'scaleFactor',scaleFactor, ...
    'velocitySource',velocitySource,'displacementSource',displacementSource, ...
    'providedKinematicsWithBaselineCorrection',providedKinematicsWithBaseline));

if nargout <= 1
    varargout{1} = record;
else
    varargout{1} = processedTime;
    varargout{2} = processedAcceleration;
    if nargout >= 3, varargout{3} = record; end
end


function [motion,source]=optionalMotion(metadata,options,names,unitName, ...
        defaultUnit,scaleFunction,nt)
motion=[];source="missing";
if isstruct(metadata),motion=getOption(metadata,names,[]);end
if isempty(motion)&&isstruct(metadata)&&isfield(metadata,'processed')
    motion=getOption(metadata.processed,names,[]);
end
if isempty(motion),return,end
motion=orientMotion(double(motion),nt);
unit=lower(string(getOption(options,unitName, ...
    getOption(metadata,unitName,defaultUnit))));
motion=motion*scaleFunction(unit);source="provided";
if any(~isfinite(motion),'all')
    error('io:Accelerogram:InvalidKinematics', ...
        'Supplied %s contains nonfinite samples.',names{1});
end
end

function motion=interpolateMotion(time,motion,targetTime,method)
if isequal(time,targetTime),return,end
motion=interp1(time,motion,targetTime,method);
end

function value=initialMotion(options,names,nComponent)
value=getOption(options,names,zeros(1,nComponent));
value=double(value(:).');
if isscalar(value),value=repmat(value,1,nComponent);end
if numel(value)~=nComponent||any(~isfinite(value))
    error('io:Accelerogram:InvalidInitialKinematics', ...
        'Initial ground-motion values must be finite scalars or one per component.');
end
end

function motion=orientMotion(motion,nt)
if size(motion,1)==nt,return,end
if size(motion,2)==nt,motion=motion.';return,end
error('io:Accelerogram:KinematicDimensionMismatch', ...
    'Ground velocity/displacement rows must match the time vector.');
end

function validateComponents(motion,nComponent,label)
if ~isempty(motion)&&size(motion,2)~=nComponent
    error('io:Accelerogram:KinematicComponentMismatch', ...
        '%s must have the same component count as acceleration.',label);
end
end
end

function [time,acceleration,metadata] = readSource(source,options)
metadata = struct();
if isnumeric(source)
    if isvector(source)
        dt = getOption(options,{'sourceDt','inputDt','dt'},[]);
        if isempty(dt), error('io:Accelerogram:MissingTime','A numeric acceleration vector requires sourceDt.'); end
        acceleration = source(:); time = (0:numel(source)-1)'*dt;
    elseif size(source,2) >= 2
        time = source(:,1); acceleration = source(:,2:end);
    else
        error('io:Accelerogram:InvalidNumericSource','Numeric source needs time plus acceleration columns.');
    end
elseif istable(source)
    numeric = table2array(source);
    time = numeric(:,1); acceleration = numeric(:,2:end);
elseif isstruct(source)
    time = getOption(source,{'t','time'},[]);
    acceleration = getOption(source,{'acceleration','a','ag','data'},[]);
    metadata = source;
    if isempty(time) && isfield(source,'processed')
        time = getOption(source.processed,{'t','time'},[]);
        acceleration = getOption(source.processed,{'acceleration','a','ag'},[]);
    end
    if isempty(time) || isempty(acceleration)
        error('io:Accelerogram:InvalidStructure','Source structure requires time/t and acceleration/a/ag.');
    end
elseif ischar(source) || (isstring(source) && isscalar(source))
    filename = char(source);
    if ~isfile(filename), error('io:Accelerogram:MissingFile','Accelerogram file not found: %s',filename); end
    [~,~,extension] = fileparts(filename);
    if strcmpi(extension,'.mat')
        loaded = load(filename);
        names = fieldnames(loaded);
        if numel(names) == 1 && isstruct(loaded.(names{1}))
            [time,acceleration,metadata] = readSource(loaded.(names{1}),options);
        else
            time = getOption(loaded,{'t','time'},[]);
            acceleration = getOption(loaded,{'acceleration','a','ag','data'},[]);
            if isempty(time) || isempty(acceleration)
                error('io:Accelerogram:InvalidMatFile','.mat file requires t/time and acceleration/a/ag variables.');
            end
            metadata = loaded;
        end
    else
        numeric = readmatrix(filename);
        numeric = numeric(any(isfinite(numeric),2),:);
        if size(numeric,2) < 2
            error('io:Accelerogram:InvalidTextFile','Text file requires time plus acceleration columns.');
        end
        time = numeric(:,1); acceleration = numeric(:,2:end);
        metadata.filename = string(filename);
    end
else
    error('io:Accelerogram:InvalidSource','Unsupported accelerogram source type.');
end
end

function corrected = correctBaseline(acceleration,time,method)
switch method
    case {"none","off"}
        corrected = acceleration;
    case {"mean","demean","constant"}
        corrected = acceleration-mean(acceleration,1);
    case {"linear","detrend"}
        corrected = zeros(size(acceleration));
        x = time-time(1);
        A = [ones(size(x)) x];
        for k = 1:size(acceleration,2)
            corrected(:,k) = acceleration(:,k)-A*(A\acceleration(:,k));
        end
    otherwise
        error('io:Accelerogram:UnsupportedBaseline','Supported baseline corrections: none, mean, linear.');
end
end

function scale = unitScaleTime(unit)
switch replace(unit,' ','')
    case {"s","sec","second","seconds"}, scale = 1;
    case {"ms","millisecond","milliseconds"}, scale = 1e-3;
    otherwise, error('io:Accelerogram:UnknownTimeUnit','Unsupported time unit: %s',unit);
end
end

function scale = unitScaleAcceleration(unit)
unit = replace(replace(unit,' ',''),'²','^2');
switch unit
    case {"m/s^2","m/s2","m/s/s","mps2","si"}, scale = 1;
    case {"g","gravity"}, scale = 9.80665;
    case {"cm/s^2","cm/s2","gal","gals"}, scale = 0.01;
    case {"mm/s^2","mm/s2"}, scale = 0.001;
    otherwise, error('io:Accelerogram:UnknownAccelerationUnit','Unsupported acceleration unit: %s',unit);
end
end

function scale=unitScaleVelocity(unit)
unit=replace(unit,' ','');
switch unit
    case {"m/s","mps","si"},scale=1;
    case {"cm/s","cmps"},scale=.01;
    case {"mm/s","mmps"},scale=.001;
    otherwise,error('io:Accelerogram:UnknownVelocityUnit', ...
        'Unsupported velocity unit: %s',unit);
end
end

function scale=unitScaleDisplacement(unit)
unit=replace(unit,' ','');
switch unit
    case {"m","meter","metre","si"},scale=1;
    case {"cm"},scale=.01;
    case {"mm"},scale=.001;
    otherwise,error('io:Accelerogram:UnknownDisplacementUnit', ...
        'Unsupported displacement unit: %s',unit);
end
end

function s = unwrapOptions(s)
if isstruct(s) && isfield(s,'seismic') && isstruct(s.seismic), s = s.seismic; end
if isstruct(s) && isfield(s,'accelerogram') && isstruct(s.accelerogram)
    nested = s.accelerogram; fields = fieldnames(s);
    for k = 1:numel(fields)
        if ~strcmp(fields{k},'accelerogram') && ~isfield(nested,fields{k}), nested.(fields{k}) = s.(fields{k}); end
    end
    s = nested;
end
end

function value = getOption(s,names,defaultValue)
if ischar(names) || isstring(names), names = cellstr(names); end
value = defaultValue;
for k = 1:numel(names)
    if isstruct(s) && isfield(s,names{k}) && ~isempty(s.(names{k})), value = s.(names{k}); return; end
end
end
