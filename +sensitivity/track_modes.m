function tr=track_modes(reference,current,study)
%TRACK_MODES Match complex modes in one physical space with nominal mass.
A=reference.solution;B=current.solution;n=study.branches;
if size(A.fullModes,2)<n||size(B.fullModes,2)<n
    error('sensitivity:MissingModes','Insufficient modal buffer.');
end
PA=A.fullModes(:,1:n);PB=B.fullModes;W=reference.fullMass;
if size(PA,1)~=size(PB,1)
    error('sensitivity:DifferentSpaces','Use common-node projection for mesh studies.');
end
mac=modal.modal_assurance_criterion(PA,PB,W);
la=A.eigenvaluesQEP(1:n);lb=B.eigenvaluesQEP;
distance=abs(la(:)-lb(:).')./max(max(abs(la(:)),abs(lb(:).')),1e-8);
score=0.85*mac+0.15*(1-min(distance/0.25,1));
[assignment,~]=modal.optimal_assignment(score);
quality=mac(sub2ind(size(mac),(1:n).',assignment(:)));
margin=zeros(n,1);
for j=1:n
    alt=score(j,:);alt(assignment(j))=-Inf;
    margin(j)=score(j,assignment(j))-max(alt);
end
fa=abs(imag(la))/(2*pi);fb=abs(imag(lb(assignment)))/(2*pi);
% Union of neighboring eigenvalue groups on BOTH sides; complex distance.
adj=false(n);
for j=1:n
    for k=1:n
        da=abs(la(j)-la(k))/max([abs(la(j)),abs(la(k)),1e-8]);
        dc=abs(lb(assignment(j))-lb(assignment(k)))/ ...
            max([abs(lb(assignment(j))),abs(lb(assignment(k))),1e-8]);
        adj(j,k)=min(da,dc)<=study.clusterTolerance;
    end
end
ids=zeros(n,1);next=0;
for j=1:n
    if ids(j)>0,continue,end
    next=next+1;queue=j;ids(j)=next;
    while ~isempty(queue)
        k=queue(1);queue(1)=[];found=find(adj(k,:).'&ids==0);
        ids(found)=next;queue=[queue;found]; %#ok<AGROW>
    end
end
boundary=false(n,1);
excludedReference=(n+1:numel(A.eigenvaluesQEP)).';
excludedCurrent=setdiff((1:numel(lb)).',assignment(:));
for j=1:n
    if ~isempty(excludedReference)
        extra=A.eigenvaluesQEP(excludedReference);
        delta=abs(la(j)-extra)./max(max(abs(la(j)),abs(extra)),1e-8);
        boundary(j)=any(delta<=study.clusterTolerance);
    end
    if ~isempty(excludedCurrent)
        extra=lb(excludedCurrent);target=lb(assignment(j));
        delta=abs(target-extra)./max(max(abs(target),abs(extra)),1e-8);
        boundary(j)=boundary(j)||any(delta<=study.clusterTolerance);
    end
end
sub=nan(n,1);groupSize=ones(n,1);valid=quality>=study.minimumMAC&margin>=study.minimumMargin;
for g=1:next
    members=find(ids==g);groupSize(members)=numel(members);
    boundary(members)=any(boundary(members));
    valid(members)=valid(members)&~boundary(members);
    if numel(members)>1
        q=modal.subspace_mac(PA(:,members),PB(:,assignment(members)),W);
        sub(members)=q.minimumMAC;valid(members)=false;
    end
end
tr=struct('assignment',assignment(:),'individualMAC',quality, ...
    'margin',margin,'clusterId',ids,'groupSize',groupSize, ...
    'subspaceMAC',sub,'individualValid',valid,'boundaryAmbiguous',boundary,'matchedFrequencyHz',fb, ...
    'referenceFrequencyHz',fa,'matchedEigenvalues',lb(assignment), ...
    'macMatrix',mac,'scoreMatrix',score,'metric',"nominal full physical mass");
end
