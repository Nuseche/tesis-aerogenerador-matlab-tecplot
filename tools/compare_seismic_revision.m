function report=compare_seismic_revision(oldRun,newRun,outCsv)
%COMPARE_SEISMIC_REVISION Compare stored Action-09 physical response channels.
% report=compare_seismic_revision(oldRun,newRun,outCsv) writes sixty rows:
% 0/12 RPM x nodes 129,130,56,92,128 x x/y/z x relative displacement and
% absolute acceleration. No model assembly, integration, interpolation, or
% historical-file mutation is performed. Relative differences are changes
% against the historical run, not errors against physical truth.
% Both histories must have exactly identical times and ground kinematics.
% The operators describe an instantaneous frozen configuration; the results
% do not establish a continuously rotating/Floquet response or stability.

arguments
    oldRun (1,1) string
    newRun (1,1) string
    outCsv (1,1) string
end
oldRun=existingDirectory(oldRun);newRun=existingDirectory(newRun);
[parent,name,extension]=fileparts(outCsv);
if strlength(parent)==0,parent=string(pwd);end
parent=existingDirectory(parent);outCsv=fullfile(parent,name+extension);
if lower(string(extension))~=".csv"
    error('comparison:SeismicOutputName','The output must be a CSV file.');
end
if within(parent,oldRun)||within(parent,newRun)
    error('comparison:SeismicHistoricalOutput','Output must be outside both historical run directories.');
end
if isfile(outCsv)
    error('comparison:SeismicExistingOutput','Refusing to overwrite %s; read the existing evidence instead.',outCsv);
end
old=readSnapshots(oldRun);new=readSnapshots(newRun);
nodes=[129 130 56 92 128];components=["x" "y" "z"];
quantities=["relative_displacement" "absolute_acceleration"];
units=["m" "m/s^2"];fields=["qFull" "absoluteAccelerationFull"];
responseNames=["responseStationary" "responseRotating"];speeds=[0 12];
disclaimer="Instantaneous frozen-configuration response; not continuous rotor transport or a Floquet stability assessment.";
template=struct('speedRPM',NaN,'nodeId',NaN,'component',"",'quantity',"", ...
    'units',"",'samples',0,'startTimeS',NaN,'endTimeS',NaN,'medianTimeStepS',NaN, ...
    'identicalTimeSamples',false,'identicalGroundKinematics',false, ...
    'oldNorm2',NaN,'newNorm2',NaN,'differenceNorm2',NaN, ...
    'relativeL2',NaN,'relativeL2Percent',NaN,'oldPeakAbsolute',NaN, ...
    'newPeakAbsolute',NaN,'peakChangePercent',NaN, ...
    'maximumAbsolutePointwiseDifference',NaN,'relativeMaximumDifference',NaN, ...
    'zeroReferenceStatus',"",'frameDisclaimer',disclaimer);
rows=repmat(template,60,1);rowNumber=0;
for caseIndex=1:2
    a=old.(responseNames(caseIndex));b=new.(responseNames(caseIndex));
    if ~isfield(a,'speedRPM')||~isfield(b,'speedRPM')|| ...
            abs(double(a.speedRPM)-speeds(caseIndex))>1e-9|| ...
            abs(double(b.speedRPM)-speeds(caseIndex))>1e-9
        error('comparison:SeismicSpeed','Expected matching 0/12 RPM stored responses.');
    end
    ta=double(a.t(:));tb=double(b.t(:));
    if numel(ta)<2||~isequal(ta,tb)||any(~isfinite(ta))||any(diff(ta)<=0)
        error('comparison:SeismicTimeGrid','Time samples must be finite, increasing and exactly identical; no interpolation is applied.');
    end
    verifyGroundKinematics(a,b);
    for node=nodes
        ia=find(double(old.model.mesh.nodes.id)==node);
        ib=find(double(new.model.mesh.nodes.id)==node);
        if ~isscalar(ia)||~isscalar(ib)
            error('comparison:SeismicNode','Node %d is missing or duplicated.',node);
        end
        if max(abs(old.model.mesh.nodes.xyz(ia,:)-new.model.mesh.nodes.xyz(ib,:)))>1e-9
            error('comparison:SeismicGeometry','Reference coordinates differ at node %d.',node);
        end
        for component=1:3
            da=double(old.model.dofs.node(ia,component));
            db=double(new.model.dofs.node(ib,component));
            for quantity=1:2
                field=fields(quantity);
                if ~isfield(a,field)||~isfield(b,field)
                    error('comparison:SeismicFullRecovery','Stored %s is required; reduced indices are not physical channels.',field);
                end
                va=double(a.(field)(da,:));vb=double(b.(field)(db,:));
                if numel(va)~=numel(ta)||numel(vb)~=numel(tb)|| ...
                        any(~isfinite(va))||any(~isfinite(vb))
                    error('comparison:SeismicChannel','A response channel is nonfinite or incompatible with the time grid.');
                end
                rowNumber=rowNumber+1;r=template;
                r.speedRPM=speeds(caseIndex);r.nodeId=node;r.component=components(component);
                r.quantity=quantities(quantity);r.units=units(quantity);r.samples=numel(ta);
                r.startTimeS=ta(1);r.endTimeS=ta(end);r.medianTimeStepS=median(diff(ta));
                r.identicalTimeSamples=true;r.identicalGroundKinematics=true;
                r.oldNorm2=norm(va);r.newNorm2=norm(vb);r.differenceNorm2=norm(vb-va);
                [r.relativeL2,r.zeroReferenceStatus]=ratio(r.differenceNorm2,r.oldNorm2);
                r.relativeL2Percent=100*r.relativeL2;
                r.oldPeakAbsolute=max(abs(va));r.newPeakAbsolute=max(abs(vb));
                r.peakChangePercent=100*ratio(r.newPeakAbsolute-r.oldPeakAbsolute,r.oldPeakAbsolute);
                r.maximumAbsolutePointwiseDifference=max(abs(vb-va));
                r.relativeMaximumDifference=ratio(r.maximumAbsolutePointwiseDifference,r.oldPeakAbsolute);
                rows(rowNumber)=r;
            end
        end
    end
end
channels=struct2table(rows);
summaryTemplate=struct('speedRPM',NaN,'quantity',"",'units',"", ...
    'maximumRelativeL2Percent',NaN,'maximumL2Node',NaN,'maximumL2Component',"", ...
    'maximumAbsolutePeakChangePercent',NaN,'maximumPeakChangeNode',NaN, ...
    'maximumPeakChangeComponent',"",'maximumAbsolutePointwiseDifference',NaN);
summaries=repmat(summaryTemplate,4,1);summaryIndex=0;
for rpm=speeds
    for quantity=1:2
        summaryIndex=summaryIndex+1;s=summaryTemplate;
        subset=channels(channels.speedRPM==rpm&channels.quantity==quantities(quantity),:);
        s.speedRPM=rpm;s.quantity=quantities(quantity);s.units=units(quantity);
        [s.maximumRelativeL2Percent,index]=max(subset.relativeL2Percent,[],'omitnan');
        if isfinite(s.maximumRelativeL2Percent)
            s.maximumL2Node=subset.nodeId(index);s.maximumL2Component=subset.component(index);
        end
        [s.maximumAbsolutePeakChangePercent,index]=max(abs(subset.peakChangePercent),[],'omitnan');
        if isfinite(s.maximumAbsolutePeakChangePercent)
            s.maximumPeakChangeNode=subset.nodeId(index);s.maximumPeakChangeComponent=subset.component(index);
        end
        s.maximumAbsolutePointwiseDifference=max(subset.maximumAbsolutePointwiseDifference);
        summaries(summaryIndex)=s;
    end
end
report=struct('oldRun',oldRun,'newRun',newRun,'outputCsv',outCsv, ...
    'channels',channels,'summary',struct2table(summaries), ...
    'interpretation',"Changes relative to historical implementation, not physical accuracy errors", ...
    'normDefinition',"Euclidean norm of samples on exactly the same stored time grid", ...
    'peakDefinition',"Maximum absolute value; peakChangePercent is signed new-minus-old over old peak", ...
    'zeroReferencePolicy',"Both zero gives zero; zero historical reference with nonzero change gives NaN", ...
    'frameDisclaimer',disclaimer,'allTimeSamplesIdentical',true, ...
    'allStoredGroundKinematicsIdentical',true);
writetable(channels,outCsv);
fprintf('Compared %d seismic channels without interpolation or reintegration.\n',height(channels));
fprintf('Historical-change evidence: %s\n',outCsv);disp(report.summary);
end

function data=readSnapshots(folder)
path=fullfile(folder,'action09_matrices.mat');
if ~isfile(path),error('comparison:SeismicSnapshot','Missing %s.',path);end
data=load(path,'responseStationary','responseRotating');
if ~all(isfield(data,{'responseStationary','responseRotating'}))
    error('comparison:SeismicResponses','Both stored operating responses are required.');
end
model=load(fullfile(folder,'model_snapshot.mat'),'modelSnapshot');
data.model=model.modelSnapshot;
end

function verifyGroundKinematics(a,b)
if ~isfield(a,'accelerogram')||~isfield(b,'accelerogram')
    error('comparison:SeismicInput','Processed ground kinematics must be stored in both responses.');
end
for field=["t" "acceleration" "velocity" "displacement"]
    if ~isfield(a.accelerogram,field)||~isfield(b.accelerogram,field)|| ...
            ~isequaln(a.accelerogram.(field),b.accelerogram.(field))
        error('comparison:SeismicInputMismatch','Processed ground %s differs or is missing; a controlled comparison is not established.',field);
    end
end
end

function [value,status]=ratio(numerator,denominator)
if denominator>0
    value=numerator/denominator;status="nonzero_historical_reference";
elseif numerator==0
    value=0;status="both_zero";
else
    value=NaN;status="zero_historical_reference_nonzero_change";
end
end

function folder=existingDirectory(folder)
if ~isfolder(folder),error('comparison:SeismicDirectory','Directory does not exist: %s',folder);end
previous=pwd;restore=onCleanup(@()cd(previous));cd(folder);folder=string(pwd);clear restore
end

function tf=within(child,parent)
tf=child==parent||startsWith(child,parent+string(filesep));
end
