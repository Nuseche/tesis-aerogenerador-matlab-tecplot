function report = compare_gyroscopic_runs(oldRun,newRun,outDir)
%COMPARE_GYROSCOPIC_RUNS Compare two persisted runs without solving a model.
% report=compare_gyroscopic_runs(oldRun,newRun,outDir) reads the canonical
% configuration/model/equilibrium/operators/results MAT files. It writes
% CSV, JSON and MAT evidence only to a separate output directory. No sweep,
% assembly, structural eigensolution, integration, or source mutation occurs.
%
% Percentages are changes against a historical implementation, NOT errors
% against physical truth. Modal correspondence uses a global maximum-MAC
% assignment in common full physical coordinates, with the historical full
% mass as the single metric. Low-MAC/ambiguous/clustered matches are flagged.
% The same instantaneous shape does not establish spectral equivalence of
% different time-dependent frames. Only stored/computed roots are inspected.

arguments
    oldRun (1,1) string
    newRun (1,1) string
    outDir (1,1) string
end
oldRun=absolutePath(oldRun);newRun=absolutePath(newRun);outDir=absolutePath(outDir);
if within(outDir,oldRun)||within(outDir,newRun)
    error('comparison:HistoricalOutput','Output must be outside both source run directories.');
end
old=readRun(oldRun);new=readRun(newRun);
thresholds=struct('speedRPM',1e-9,'geometryM',1e-9,'analysisMap',1e-12, ...
    'massEquality',1e-12,'individualMAC',0.8,'assignmentMargin',0.05, ...
    'clusterRelativeFrequency',0.01,'subspaceMAC',0.95, ...
    'rootRelativeTolerance',1e-8,'frequencyZeroHz',1e-12);
[permutation,modelInfo]=alignModels(old.model,new.model,thresholds);
translation=reshape(old.model.dofs.node(:,1:3),[],1);
rotation=reshape(old.model.dofs.node(:,4:6),[],1);
[oldOps,oldSpeed]=operatingPoints(old.operators,old.configuration);
[newOps,newSpeed]=operatingPoints(new.operators,new.configuration);
operatorRows=repmat(operatorTemplate(),0,1);
equilibriumRows=repmat(equilibriumTemplate(),0,1);
warnings=strings(0,1);pointInfo=repmat(struct('speedRPM',0, ...
    'sameAnalysisMap',false,'relativeFullMassChange',NaN,'sameMass',false),0,1);
for i=1:numel(oldSpeed)
    j=findSpeed(newSpeed,oldSpeed(i),thresholds.speedRPM);
    if isempty(j)
        warnings(end+1)="No new operating point at "+oldSpeed(i)+" RPM."; %#ok<AGROW>
        continue
    end
    a=oldOps{i};b=newOps{j};rpm=oldSpeed(i);
    A=a.reduced.Tc;B=b.reduced.Tc(permutation,:);
    mapSame=isequal(size(A),size(B))&&relativeChange(A,B)<=thresholds.analysisMap;
    massChange=relativeChange(a.full.M,b.full.M(permutation,permutation));
    massSame=massChange<=thresholds.massEquality;
    pointInfo(end+1)=struct('speedRPM',rpm,'sameAnalysisMap',mapSame, ...
        'relativeFullMassChange',massChange,'sameMass',massSame); %#ok<AGROW>
    for name=["M" "K" "G" "D"]
        if ~isfield(a.full,name)||~isfield(b.full,name)
            warnings(end+1)="Missing full "+name+" at "+rpm+" RPM."; %#ok<AGROW>
            continue
        end
        operatorRows=appendOperator(operatorRows,rpm,"full",name, ...
            a.full.(name),b.full.(name)(permutation,permutation),translation,rotation);
        if mapSame&&isfield(a.reduced,name)&&isfield(b.reduced,name)
            rotColumns=find(any(abs(A(rotation,:))>0,1)).';
            transColumns=setdiff((1:size(A,2)).',rotColumns);
            operatorRows=appendOperator(operatorRows,rpm,"reduced",name, ...
                a.reduced.(name),b.reduced.(name),transColumns,rotColumns);
        elseif ~mapSame
            warnings(end+1)="Reduced operator comparison skipped: analysis maps differ at "+rpm+" RPM."; %#ok<AGROW>
        end
    end
    qa=equilibriumVector(old.equilibrium,rpm,oldSpeed,i,a,thresholds.speedRPM);
    qb=equilibriumVector(new.equilibrium,rpm,newSpeed,j,b,thresholds.speedRPM);
    if ~isempty(qa)&&~isempty(qb)
        if numel(qa)~=numel(permutation)||numel(qb)~=numel(permutation)
            error('comparison:EquilibriumSize','Full equilibrium vectors do not match the nodal DOF map.');
        end
        qb=qb(permutation);
        equilibriumRows(end+1)=equilibriumRow(rpm,"translation","m",qa(translation),qb(translation)); %#ok<AGROW>
        equilibriumRows(end+1)=equilibriumRow(rpm,"rotation","rad",qa(rotation),qb(rotation)); %#ok<AGROW>
    else
        warnings(end+1)="Full equilibrium unavailable at "+rpm+" RPM."; %#ok<AGROW>
    end
end
extra=newSpeed(~arrayfun(@(x)any(abs(oldSpeed-x)<=thresholds.speedRPM),newSpeed));
if ~isempty(extra),warnings(end+1)="New-only operating speeds are not compared: "+mat2str(extra.');end
[modalRows,macEvidence,modalWarnings]=compareModal(old,new,oldOps,oldSpeed, ...
    newOps,newSpeed,permutation,thresholds);
warnings=[warnings;modalWarnings];
report=struct();report.operatorComparison=struct2table(operatorRows);
report.equilibriumComparison=struct2table(equilibriumRows);
report.modalComparison=struct2table(modalRows);report.macEvidence=macEvidence;
report.configurationComparison=configurationComparison(old.configuration,new.configuration);
report.operatingPointComparison=struct2table(pointInfo);
report.modelComparison=modelInfo;report.thresholds=thresholds;
report.warnings=unique(warnings,'stable');
supported=false(0,1);if ~isempty(modalRows),supported=[modalRows.individualCorrespondenceSupported].';end
summary=struct('generatedUTC',string(datetime('now','TimeZone','UTC', ...
    'Format','yyyy-MM-dd''T''HH:mm:ss''Z''')),'oldRun',oldRun,'newRun',newRun, ...
    'interpretation',"Historical changes, not errors against an exact or experimentally validated solution", ...
    'matchingMethod',"Global maximum mass-weighted MAC assignment; no frequency term", ...
    'commonMetric',"Historical full physical mass, used for BOTH modal bases at each speed", ...
    'modalCoordinateConvention',"Stored instantaneous full physical coordinates; MBC and analysis maps explicitly recovered", ...
    'modalStabilityScope',"Computed/stored targeted roots only; no claim about uncomputed spectrum or Floquet stability", ...
    'relativeZeroPolicy',"Both zero gives 0; zero historical/nonzero new gives NaN (JSON null)", ...
    'operatorNormInterpretation',"Frobenius norms in numerical SI convention; whole matrices mix translational and rotational units; homogeneous blocks reported separately", ...
    'thresholds',thresholds,'modelComparison',modelInfo, ...
    'comparedOperatingPoints',numel(pointInfo),'operatorRows',numel(operatorRows), ...
    'equilibriumRows',numel(equilibriumRows),'modalRows',numel(modalRows), ...
    'supportedIndividualMatches',nnz(supported),'otherModalRows',nnz(~supported), ...
    'allComparedMassesEqual',~isempty(pointInfo)&&all([pointInfo.sameMass]), ...
    'allComparedAnalysisMapsEqual',~isempty(pointInfo)&&all([pointInfo.sameAnalysisMap]), ...
    'configurationDifferenceCount',nnz(~report.configurationComparison.equal), ...
    'warnings',report.warnings);
if ~isempty(modalRows)
    summary.maximumMatchedFrequencyChangePercent=finiteMaximum(abs([modalRows.relativeFrequencyChangePercent]));
    summary.maximumSupportedIndividualFrequencyChangePercent= ...
        finiteMaximum(abs([modalRows(supported).relativeFrequencyChangePercent]));
    summary.minimumMatchedMAC=finiteMinimum([modalRows.MAC]);
    summary.historicalPositiveRealRootRows=nnz([modalRows.oldPositiveRealRoot]);
    summary.newPositiveRealRootRows=nnz([modalRows.newPositiveRealRoot]);
end
report.summary=summary;
names=["operator_comparison.csv" "equilibrium_comparison.csv" ...
    "modal_matched_comparison.csv" "configuration_comparison.csv" ...
    "operating_point_comparison.csv" "comparison_summary.json" "comparison_report.mat"];
for name=names
    if isfile(fullfile(outDir,name))
        error('comparison:ExistingOutput','Refusing to overwrite %s. Choose a fresh output directory.',fullfile(outDir,name));
    end
end
if ~isfolder(outDir),mkdir(outDir);end
writetable(report.operatorComparison,fullfile(outDir,names(1)));
writetable(report.equilibriumComparison,fullfile(outDir,names(2)));
writetable(report.modalComparison,fullfile(outDir,names(3)));
writetable(report.configurationComparison,fullfile(outDir,names(4)));
writetable(report.operatingPointComparison,fullfile(outDir,names(5)));
text=jsonencode(summary,'PrettyPrint',true);
fid=fopen(fullfile(outDir,names(6)),'w','n','UTF-8');
if fid<0,error('comparison:WriteFailure','Cannot open summary JSON.');end
cleanup=onCleanup(@()fclose(fid));fprintf(fid,'%s\n',text);clear cleanup
report.artifacts=fullfile(outDir,names);
save(fullfile(outDir,names(7)),'report','-v7.3');
fprintf('Compared %d operating points and %d modal rows; %d supported individual matches.\n', ...
    summary.comparedOperatingPoints,summary.modalRows,summary.supportedIndividualMatches);
fprintf('Historical-change evidence: %s\n',outDir);
end

function run=readRun(folder)
if ~isfolder(folder),error('comparison:MissingRun','Run directory not found: %s',folder);end
files=["configuration.mat" "model_snapshot.mat" "equilibrium.mat" "operators.mat" "results.mat"];
variables=["configuration" "modelSnapshot" "equilibrium" "operators" "results"];
destinations=["configuration" "model" "equilibrium" "operators" "results"];
run=struct();
for i=1:numel(files)
    path=fullfile(folder,files(i));
    if ~isfile(path),error('comparison:MissingSnapshot','Required snapshot missing: %s',path);end
    value=load(path,variables(i));
    if ~isfield(value,variables(i)),error('comparison:MissingVariable','%s lacks %s.',path,variables(i));end
    run.(destinations(i))=value.(variables(i));
end
end

function [p,info]=alignModels(a,b,tol)
idsA=double(a.mesh.nodes.id(:));idsB=double(b.mesh.nodes.id(:));
if numel(unique(idsA))~=numel(idsA)||numel(unique(idsB))~=numel(idsB)
    error('comparison:NodeIdentity','Node identifiers must be unique.');
end
[found,nodeRows]=ismember(idsA,idsB);
if numel(idsA)~=numel(idsB)||~all(found)
    error('comparison:DifferentMesh','Different node sets require an explicit interpolation, not indexwise comparison.');
end
da=double(a.dofs.node);db=double(b.dofs.node);n=6*numel(idsA);
if ~isequal(size(da),[numel(idsA) 6])||~isequal(size(db),size(da))|| ...
        ~isequal(sort(da(:)),(1:n).')||~isequal(sort(db(:)),(1:n).')
    error('comparison:DOFIdentity','Expected complete six-DOF nodal maps.');
end
p=zeros(n,1);mapped=db(nodeRows,:);p(da(:))=mapped(:);
coordinateDifference=max(abs(double(a.mesh.nodes.xyz)-double(b.mesh.nodes.xyz(nodeRows,:))),[],'all');
if coordinateDifference>tol.geometryM
    error('comparison:DifferentGeometry','Node geometry differs by %.6g m; common physical coordinates are not established.',coordinateDifference);
end
info=struct('nodeCount',numel(idsA),'fullDOFCount',n, ...
    'maximumCoordinateDifferenceM',coordinateDifference, ...
    'newDOFsPermutedToHistoricalOrder',~isequal(p,(1:n).'), ...
    'identityRule',"Equal node IDs, six named nodal components and matching reference coordinates");
end

function [points,speeds]=operatingPoints(ops,cfg)
if isfield(ops,'operatingPoints')&&~isempty(ops.operatingPoints),points=ops.operatingPoints;
else,points={ops};end
if isstruct(points),points=num2cell(points);end
points=points(:);speeds=nan(numel(points),1);
fallback=fieldPath(cfg,'rotor.speedRPMGrid');
if isempty(fallback),fallback=fieldPath(cfg,'rotor.speedRPM');end
for i=1:numel(points)
    if isfield(points{i},'speedRPM'),speeds(i)=double(points{i}.speedRPM);
    elseif numel(fallback)==numel(points),speeds(i)=double(fallback(i));end
    if ~isfield(points{i},'full')||~isfield(points{i},'reduced')
        error('comparison:OperatingFormat','Canonical full/reduced operating matrices are required.');
    end
end
if any(~isfinite(speeds))||numel(unique(speeds))~=numel(speeds)
    error('comparison:SpeedIdentity','Operating speeds must be explicitly identifiable and unique.');
end
end

function j=findSpeed(speeds,rpm,tolerance)
j=find(abs(speeds-rpm)<=tolerance);
if numel(j)>1,error('comparison:AmbiguousSpeed','More than one point matches %.12g RPM.',rpm);end
end

function row=operatorTemplate()
row=struct('speedRPM',NaN,'coordinates',"",'operator',"",'block',"", ...
    'unitConvention',"",'rows',0,'columns',0,'oldFrobeniusNorm',NaN, ...
    'newFrobeniusNorm',NaN,'differenceFrobeniusNorm',NaN, ...
    'relativeHistoricalChange',NaN,'relativeHistoricalChangePercent',NaN, ...
    'maximumAbsoluteEntryChange',NaN,'zeroReferenceStatus',"");
end

function rows=appendOperator(rows,rpm,coordinates,name,A,B,trans,rot)
if ~isequal(size(A),size(B)),error('comparison:OperatorSize','%s %s sizes differ.',coordinates,name);end
if any(~isfinite(nonzeros(A)))||any(~isfinite(nonzeros(B)))
    error('comparison:NonfiniteOperator','Nonfinite coefficients in %s %s.',coordinates,name);
end
indices={1:size(A,1),trans,trans,rot,rot};other={1:size(A,2),trans,rot,trans,rot};
blocks=["all" "translation_translation" "translation_rotation" "rotation_translation" "rotation_rotation"];
for k=1:numel(blocks)
    AA=A(indices{k},other{k});BB=B(indices{k},other{k});delta=BB-AA;
    row=operatorTemplate();row.speedRPM=rpm;row.coordinates=coordinates;
    row.operator=name;row.block=blocks(k);row.unitConvention=blockUnit(name,k);
    row.rows=size(AA,1);row.columns=size(AA,2);
    row.oldFrobeniusNorm=norm(AA,'fro');row.newFrobeniusNorm=norm(BB,'fro');
    row.differenceFrobeniusNorm=norm(delta,'fro');
    [row.relativeHistoricalChange,row.zeroReferenceStatus]=relativeNorm(row.differenceFrobeniusNorm,row.oldFrobeniusNorm);
    row.relativeHistoricalChangePercent=100*row.relativeHistoricalChange;
    row.maximumAbsoluteEntryChange=maximumAbsolute(delta);
    rows(end+1)=row; %#ok<AGROW>
end
end

function unit=blockUnit(name,index)
if index==1,unit="mixed generalized SI; numerical algebraic norm";return,end
if name=="M",units=["kg" "kg*m" "kg*m" "kg*m^2"];
elseif name=="K",units=["N/m" "N/rad" "N*m/m" "N*m/rad"];
else,units=["kg/s" "kg*m/s" "kg*m/s" "kg*m^2/s"];end
unit=units(index-1);
end

function q=equilibriumVector(root,rpm,speeds,index,ops,tolerance)
q=[];state=[];
if isfield(root,'operatingPoints')&&~isempty(root.operatingPoints)
    points=root.operatingPoints;if isstruct(points),points=num2cell(points);end
    stateSpeeds=nan(numel(points),1);
    for k=1:numel(points)
        if isfield(points{k},'speedRPM'),stateSpeeds(k)=double(points{k}.speedRPM);end
    end
    if any(~isfinite(stateSpeeds))
        if isfield(root,'speedRPMGrid')&&numel(root.speedRPMGrid)==numel(points)
            stateSpeeds=double(root.speedRPMGrid(:));
        elseif numel(points)==numel(speeds),stateSpeeds=speeds;end
    end
    j=findSpeed(stateSpeeds,rpm,tolerance);if ~isempty(j),state=points{j};end
elseif numel(speeds)==1||isfield(root,'speedRPM')&&abs(double(root.speedRPM)-rpm)<=tolerance
    state=root;
elseif index==numel(speeds)&&isfield(root,'qFull')
    % Never infer which operating point a speed-less primary state belongs to.
    return
end
if isempty(state),return,end
if isfield(state,'qFull'),q=double(state.qFull(:));return,end
if isfield(state,'qReduced'),qr=state.qReduced(:);
elseif isfield(state,'q'),qr=state.q(:);else,return,end
maps={ops.reduced.Tc};
if isfield(ops.reduced,'constraintTc'),maps{end+1}=ops.reduced.constraintTc;end
for k=1:numel(maps)
    if size(maps{k},2)==numel(qr),q=maps{k}*qr;return,end
end
end

function row=equilibriumTemplate()
row=struct('speedRPM',NaN,'components',"",'units',"",'oldNorm2',NaN, ...
    'newNorm2',NaN,'differenceNorm2',NaN,'maximumAbsoluteDifference',NaN, ...
    'relativeHistoricalChange',NaN,'relativeHistoricalChangePercent',NaN,'zeroReferenceStatus',"");
end

function row=equilibriumRow(rpm,component,unit,a,b)
row=equilibriumTemplate();row.speedRPM=rpm;row.components=component;row.units=unit;
row.oldNorm2=norm(a);row.newNorm2=norm(b);row.differenceNorm2=norm(b-a);
row.maximumAbsoluteDifference=maximumAbsolute(b-a);
[row.relativeHistoricalChange,row.zeroReferenceStatus]=relativeNorm(row.differenceNorm2,row.oldNorm2);
row.relativeHistoricalChangePercent=100*row.relativeHistoricalChange;
end

function row=modalTemplate()
row=struct('speedRPM',NaN,'oldMode',NaN,'newMode',NaN,'matched',false, ...
    'oldFrequencyHz',NaN,'newFrequencyHz',NaN,'frequencyChangeHz',NaN, ...
    'relativeFrequencyChangePercent',NaN,'oldNaturalFrequencyHz',NaN, ...
    'newNaturalFrequencyHz',NaN,'oldEigenvalueReal',NaN,'newEigenvalueReal',NaN, ...
    'oldEigenvalueImaginary',NaN,'newEigenvalueImaginary',NaN, ...
    'oldDampingRatio',NaN,'newDampingRatio',NaN,'MAC',NaN, ...
    'assignmentMargin',NaN,'referenceClusterId',NaN,'referenceClusterSize',0, ...
    'clusterMinimumSubspaceMAC',NaN,'individualCorrespondenceSupported',false, ...
    'sameFullMass',false,'oldPositiveRealRoot',false,'newPositiveRealRoot',false, ...
    'oldNonoscillatoryRoot',false,'newNonoscillatoryRoot',false, ...
    'coordinateWarning',"",'spectralWarning',"");
end

function [rows,evidence,warnings]=compareModal(old,new,oldOps,oldSpeed,newOps,newSpeed,p,tol)
rows=repmat(modalTemplate(),0,1);evidence=cell(0,1);warnings=strings(0,1);
[oldSolutions,speedA]=modalSolutions(old.results,oldSpeed);
[newSolutions,speedB]=modalSolutions(new.results,newSpeed);
if isempty(oldSolutions)||isempty(newSolutions)
    warnings(end+1)="Modal results absent in at least one run; no Campbell comparison performed.";return
end
for i=1:numel(oldSolutions)
    rpm=speedA(i);j=findSpeed(speedB,rpm,tol.speedRPM);
    ia=findSpeed(oldSpeed,rpm,tol.speedRPM);ib=findSpeed(newSpeed,rpm,tol.speedRPM);
    if isempty(j)||isempty(ia)||isempty(ib)
        warnings(end+1)="Modal solution/operator pair unavailable at "+rpm+" RPM.";continue %#ok<AGROW>
    end
    a=oldSolutions{i};b=newSolutions{j};opA=oldOps{ia};opB=newOps{ib};
    [PA,frameA]=physicalModes(a,opA);[PB,frameB]=physicalModes(b,opB);PB=PB(p,:);
    M=opA.full.M;massSame=relativeChange(M,opB.full.M(p,p))<=tol.massEquality;
    MAC=massMAC(PA,PB,M);assignment=globalAssignment(MAC);
    fA=modalVector(a,{"frequencyHz","dampedFrequencyHz"},size(PA,2));
    fB=modalVector(b,{"frequencyHz","dampedFrequencyHz"},size(PB,2));
    fnA=modalVector(a,{"naturalFrequencyHz","frequencyHz"},size(PA,2));
    fnB=modalVector(b,{"naturalFrequencyHz","frequencyHz"},size(PB,2));
    lambdaA=timeEigenvalues(a,size(PA,2));
    lambdaB=timeEigenvalues(b,size(PB,2));
    dampingA=modalVector(a,{"dampingRatio"},size(PA,2));
    dampingB=modalVector(b,{"dampingRatio"},size(PB,2));
    clusters=frequencyClusters(fnA,tol.clusterRelativeFrequency);
    subQuality=nan(size(PA,2),1);clusterSizes=zeros(size(PA,2),1);
    for cluster=unique(clusters(:)).'
        members=find(clusters==cluster);clusterSizes(members)=numel(members);
        candidates=assignment(members);
        if numel(members)>1&&all(isfinite(candidates))
            subQuality(members)=minimumSubspaceMAC(PA(:,members),PB(:,candidates),M);
        end
    end
    for k=1:size(PA,2)
        row=modalTemplate();row.speedRPM=rpm;row.oldMode=k;row.oldFrequencyHz=fA(k);
        row.oldNaturalFrequencyHz=fnA(k);row.oldEigenvalueReal=real(lambdaA(k));
        row.oldEigenvalueImaginary=imag(lambdaA(k));row.oldDampingRatio=dampingA(k);
        row.sameFullMass=massSame;row.referenceClusterId=clusters(k);
        row.referenceClusterSize=clusterSizes(k);row.clusterMinimumSubspaceMAC=subQuality(k);
        [row.oldPositiveRealRoot,row.oldNonoscillatoryRoot]=rootFlags(lambdaA(k),tol);
        messages=strings(0,1);
        if ~massSame,messages(end+1)="mass_changed_common_historical_metric_only";end
        if frameA||frameB
            row.coordinateWarning="Instantaneous physical shapes recovered; a time-dependent frame change can shift spectral interpretation.";
        end
        if ~isfinite(assignment(k))
            messages(end+1)="unmatched_no_one_to_one_candidate";
        else
            l=assignment(k);row.newMode=l;row.matched=true;row.MAC=MAC(k,l);
            other=MAC(k,:);other(l)=[];
            if isempty(other),row.assignmentMargin=1;else,row.assignmentMargin=row.MAC-max(other);end
            row.newFrequencyHz=fB(l);row.frequencyChangeHz=fB(l)-fA(k);
            if abs(fA(k))>tol.frequencyZeroHz
                row.relativeFrequencyChangePercent=100*row.frequencyChangeHz/abs(fA(k));
            else,messages(end+1)="near_zero_reference_frequency_relative_change_undefined";end
            row.newNaturalFrequencyHz=fnB(l);row.newEigenvalueReal=real(lambdaB(l));
            row.newEigenvalueImaginary=imag(lambdaB(l));row.newDampingRatio=dampingB(l);
            [row.newPositiveRealRoot,row.newNonoscillatoryRoot]=rootFlags(lambdaB(l),tol);
            if row.MAC<tol.individualMAC,messages(end+1)="low_MAC_no_individual_equivalence";end
            if row.assignmentMargin<tol.assignmentMargin,messages(end+1)="ambiguous_individual_assignment";end
            if clusterSizes(k)>1
                if subQuality(k)>=tol.subspaceMAC,messages(end+1)="near_degenerate_cluster_only_subspace_correspondence_supported";
                else,messages(end+1)="near_degenerate_cluster_subspace_correspondence_not_established";end
            end
            row.individualCorrespondenceSupported=row.MAC>=tol.individualMAC&& ...
                row.assignmentMargin>=tol.assignmentMargin&&clusterSizes(k)==1;
        end
        if row.oldPositiveRealRoot,messages(end+1)="historical_computed_root_has_positive_real_part";end
        if row.newPositiveRealRoot,messages(end+1)="new_computed_root_has_positive_real_part";end
        if row.oldNonoscillatoryRoot||row.newNonoscillatoryRoot,messages(end+1)="nonoscillatory_root_frequency_is_not_an_oscillatory_branch";end
        if ~isfinite(lambdaA(k))||row.matched&&~isfinite(lambdaB(row.newMode))
            messages(end+1)="eigenvalue_unavailable_or_nonfinite";
        end
        row.spectralWarning=strjoin(messages,"; ");rows(end+1)=row; %#ok<AGROW>
    end
    evidence{end+1,1}=struct('speedRPM',rpm,'MAC',MAC,'assignment',assignment, ...
        'oldReferenceClusters',clusters,'subspaceMAC',subQuality, ...
        'oldCandidateCount',size(PA,2),'newCandidateCount',size(PB,2), ...
        'unmatchedNewModes',setdiff(1:size(PB,2),assignment(isfinite(assignment))), ...
        'commonMetric',"historical full mass",'sameFullMass',massSame); %#ok<AGROW>
end
end

function [solutions,speeds]=modalSolutions(results,operatorSpeeds)
solutions={};speeds=[];if ~isfield(results,'modal')||isempty(results.modal),return,end
m=results.modal;
if isfield(m,'solutions'),solutions=m.solutions;
elseif isfield(m,'modes'),solutions={m};else,return,end
if isstruct(solutions),solutions=num2cell(solutions);end
solutions=solutions(:);
if isfield(m,'speedRPMGrid'),speeds=double(m.speedRPMGrid(:));
elseif isfield(m,'speedRPM'),speeds=double(m.speedRPM(:));
elseif numel(solutions)==numel(operatorSpeeds),speeds=operatorSpeeds;end
if numel(solutions)~=numel(speeds)||any(~isfinite(speeds))
    error('comparison:ModalSpeedIdentity','Modal solutions cannot be mapped to unique operating speeds.');
end
end

function [Phi,hasMBC]=physicalModes(solution,ops)
hasMBC=isfield(solution,'mbc')&&isfield(solution.mbc,'transformation');
if isfield(solution,'modes')&&~isempty(solution.modes)
    T=ops.reduced.Tc;
    if hasMBC,T=T*solution.mbc.transformation.T;end
    if size(T,2)~=size(solution.modes,1)
        error('comparison:ModeRecovery','Stored modal coordinates and recovery map have incompatible sizes.');
    end
    Phi=T*solution.modes;
elseif isfield(solution,'fullModes'),Phi=solution.fullModes;
else,error('comparison:MissingModes','Stored eigenvectors are required; frequency-only comparison is not sufficient.');end
if any(~isfinite(Phi),'all'),error('comparison:NonfiniteModes','Physical eigenvectors are nonfinite.');end
end

function values=modalVector(solution,names,n)
values=nan(n,1);
for name=names
    if isfield(solution,name{1})&&~isempty(solution.(name{1}))
        v=solution.(name{1});count=min(n,numel(v));values(1:count)=v(1:count);return
    end
end
end

function values=timeEigenvalues(solution,n)
% Conservative K/M eigenvalues are squared frequencies, not time roots.
if isfield(solution,'eigenvaluesQEP')
    values=modalVector(solution,{"eigenvaluesQEP"},n);
elseif isfield(solution,'omegaRadPerSec')
    values=1i*modalVector(solution,{"omegaRadPerSec"},n);
else
    values=modalVector(solution,{"eigenvalues"},n);
end
end

function MAC=massMAC(A,B,M)
normA=real(sum(conj(A).*(M*A),1));normB=real(sum(conj(B).*(M*B),1));
if any(normA<=0)||any(normB<=0)||any(~isfinite([normA normB]))
    error('comparison:ModalMass','Modal masses must be finite and positive under the common metric.');
end
MAC=abs(A'*(M*B)).^2./(normA(:)*normB(:).');MAC=min(max(real(MAC),0),1);
end

function assignment=globalAssignment(MAC)
% Use the project's global maximum-weight assignment, never a greedy match.
assignment=nan(size(MAC,1),1);
if size(MAC,1)<=size(MAC,2)
    assignment(:)=modal.optimal_assignment(MAC);
else
    reverse=modal.optimal_assignment(MAC.');assignment(reverse)=1:size(MAC,2);
end
end

function ids=frequencyClusters(f,tolerance)
n=numel(f);ids=zeros(n,1);next=0;
for k=1:n
    if ids(k)>0,continue,end
    next=next+1;ids(k)=next;queue=k;
    while ~isempty(queue)
        current=queue(1);queue(1)=[];
        distance=abs(f-f(current))./max(max(abs(f),abs(f(current))),1e-12);
        nearby=find(distance<=tolerance&ids==0);ids(nearby)=next;queue=[queue;nearby(:)]; %#ok<AGROW>
    end
end
end

function quality=minimumSubspaceMAC(A,B,M)
GA=A'*(M*A);GB=B'*(M*B);
[VA,DA]=eig((GA+GA')/2,'vector');[VB,DB]=eig((GB+GB')/2,'vector');
if min(real(DA))<=1e-12*max(abs(DA))||min(real(DB))<=1e-12*max(abs(DB))
    quality=NaN;return
end
WA=VA*diag(1./sqrt(real(DA)))*VA';WB=VB*diag(1./sqrt(real(DB)))*VB';
sigma=svd(WA*(A'*(M*B))*WB);quality=min(min(max(real(sigma),0),1).^2);
end

function [positive,nonoscillatory]=rootFlags(lambda,tol)
threshold=tol.rootRelativeTolerance*max(1,abs(lambda));
positive=isfinite(lambda)&&real(lambda)>threshold;
nonoscillatory=isfinite(lambda)&&abs(imag(lambda))<=threshold;
end

function comparison=configurationComparison(a,b)
paths=["units" "analysis.type" "base" "rotor.speedRPM" "rotor.speedRPMGrid" ...
    "rotor.azimuthRad" "rotor.axisConvention" "rotor.mbc" "mass" "elements" ...
    "gravity" "drivetrain" "damping" "gyroscopic" "aerodynamics" "equilibrium" ...
    "seismic.directions" "seismic.record.t" "seismic.record.acceleration" ...
    "seismic.scaleFactor" "seismic.baselineCorrection" "newmark"];
same=false(numel(paths),1);oldValue=strings(numel(paths),1);newValue=oldValue;
for k=1:numel(paths)
    aa=fieldPath(a,paths(k));bb=fieldPath(b,paths(k));same(k)=isequaln(aa,bb);
    oldValue(k)=describe(aa);newValue(k)=describe(bb);
end
comparison=table(paths(:),same,oldValue,newValue, ...
    'VariableNames',{'field','equal','historicalValue','newValue'});
end

function value=fieldPath(s,path)
value=s;parts=split(string(path),'.');
for part=parts.'
    if ~isstruct(value)||~isfield(value,part),value=[];return,end
    value=value.(part);
end
end

function text=describe(value)
if isnumeric(value)&&numel(value)>30
    text="numeric size="+mat2str(size(value))+" norm="+string(norm(value,'fro'));
else
    try,text=string(jsonencode(value));
    catch,text="["+string(class(value))+"; not JSON serializable]";end
end
end

function [value,status]=relativeNorm(delta,reference)
if reference>0,value=delta/reference;status="nonzero_reference";
elseif delta==0,value=0;status="both_zero";
else,value=NaN;status="zero_reference_nonzero_change";end
end

function value=relativeChange(A,B)
if ~isequal(size(A),size(B)),value=Inf;return,end
[value,~]=relativeNorm(norm(B-A,'fro'),norm(A,'fro'));
if isnan(value),value=Inf;end
end

function value=maximumAbsolute(A)
if isempty(A),value=0;else,value=full(max(abs(A),[],'all'));end
end

function value=finiteMaximum(values)
values=values(isfinite(values));if isempty(values),value=NaN;else,value=max(values);end
end

function value=finiteMinimum(values)
values=values(isfinite(values));if isempty(values),value=NaN;else,value=min(values);end
end

function path=absolutePath(path)
% Resolve existing directories through MATLAB itself; no optional Java JRE.
% A not-yet-created output is resolved from its nearest existing ancestor.
if strlength(path)==0,error('comparison:EmptyPath','Directory paths cannot be empty.');end
if isfolder(path)
    previous=pwd;restore=onCleanup(@()cd(previous));
    cd(path);path=string(pwd);clear restore
    return
end
[parent,name,extension]=fileparts(path);leaf=string(name)+string(extension);
if strlength(parent)==0,parent=string(pwd);end
parent=absolutePath(string(parent));
if leaf==".",path=parent;
elseif leaf=="..",path=string(fileparts(parent));
else,path=string(fullfile(parent,leaf));end
end

function tf=within(child,parent)
tf=child==parent||startsWith(child,parent+string(filesep));
end
