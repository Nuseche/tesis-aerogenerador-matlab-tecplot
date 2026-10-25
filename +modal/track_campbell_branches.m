function result = track_campbell_branches(previous,current,metric,options)
%TRACK_CAMPBELL_BRANCHES Optimal MAC/frequency assignment with subspaces.

if nargin<4,options=struct();end
PhiA=previous.modes;PhiB=current.modes;
n=min(size(PhiA,2),size(PhiB,2));PhiA=PhiA(:,1:n);
if size(PhiA,1)~=size(PhiB,1)||n==0
    error('modal:Tracking:DimensionMismatch','Modal bases are incompatible.');
end
PhiB=PhiB(:,1:size(PhiB,2));
MAC=modal.modal_assurance_criterion(PhiA,PhiB,metric);
fA=frequencies(previous,n);fB=frequencies(current,size(PhiB,2));
frequencyScale=option(options,'trackingFrequencyScale',0.25);
macWeight=option(options,'trackingMacWeight',0.85);
if macWeight<0||macWeight>1
    error('modal:Tracking:InvalidWeight','trackingMacWeight must lie in [0,1].');
end
frequencyChange=abs(fA(:)-fB(:).') ./ ...
    max(max(fA(:),fB(:).'),1e-8);
frequencyScore=1-min(frequencyChange/frequencyScale,1);
score=macWeight*MAC+(1-macWeight)*frequencyScore;
[assignment,totalScore]=modal.optimal_assignment(score);
rows=(1:n).';individual=MAC(sub2ind(size(MAC),rows,assignment(:)));
assignedFrequencyChange=frequencyChange( ...
    sub2ind(size(frequencyChange),rows,assignment(:)));

degenerateTolerance=option(options,'degenerateFrequencyTolerance',0.01);
clusterId=frequencyClusters(fA,degenerateTolerance);
subspaceQuality=nan(n,1);effective=individual;
clusterTable=repmat(struct('clusterId',0,'previousModes',[], ...
    'currentModes',[],'minimumMAC',NaN,'meanMAC',NaN),0,1);
for id=unique(clusterId(:)).'
    members=find(clusterId==id);
    if numel(members)<2,continue,end
    currentMembers=assignment(members);
    sub=modal.subspace_mac(PhiA(:,members),PhiB(:,currentMembers),metric);
    subspaceQuality(members)=sub.minimumMAC;
    effective(members)=max(effective(members),sub.minimumMAC);
    clusterTable(end+1,1)=struct('clusterId',id, ...
        'previousModes',members(:).','currentModes',currentMembers(:).', ...
        'minimumMAC',sub.minimumMAC,'meanMAC',sub.meanMAC); %#ok<AGROW>
end
result=struct('assignment',assignment,'individualMAC',individual(:).', ...
    'effectiveMAC',effective(:).','subspaceMAC',subspaceQuality(:).', ...
    'relativeFrequencyChange',assignedFrequencyChange(:).', ...
    'scoreMatrix',score,'macMatrix',MAC,'frequencyChangeMatrix', ...
    frequencyChange,'totalScore',totalScore,'clusterId',clusterId(:).', ...
    'clusters',clusterTable,'method', ...
    "global minimum-cost assignment; MAC plus frequency; degenerate subspace MAC");
end

function f=frequencies(solution,n)
names={'naturalFrequencyHz','frequencyHz','dampedFrequencyHz'};f=[];
for index=1:numel(names)
    if isfield(solution,names{index})&&~isempty(solution.(names{index}))
        f=double(solution.(names{index})(:));break
    end
end
if numel(f)<n,error('modal:Tracking:MissingFrequency', ...
        'Solutions require one frequency per tracked mode.');end
f=f(1:n);
end

function ids=frequencyClusters(f,tolerance)
n=numel(f);ids=zeros(n,1);next=0;
for index=1:n
    if ids(index)~=0,continue,end
    next=next+1;queue=index;ids(index)=next;
    while ~isempty(queue)
        current=queue(1);queue(1)=[];
        relative=abs(f-f(current))./max(max(abs(f),abs(f(current))),1e-8);
        neighbors=find(relative<=tolerance&ids==0);
        ids(neighbors)=next;queue=[queue;neighbors(:)]; %#ok<AGROW>
    end
end
end

function result=option(options,name,fallback)
result=fallback;
if isstruct(options)&&isfield(options,name)&&~isempty(options.(name))
    result=double(options.(name));
end
if ~isscalar(result)||~isfinite(result)||result<=0
    error('modal:Tracking:InvalidOption','%s must be positive and finite.',name);
end
end
