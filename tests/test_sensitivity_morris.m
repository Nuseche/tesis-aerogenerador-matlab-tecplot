function tests=test_sensitivity_morris
tests=functiontests(localfunctions);
end
function testDesignBoundsStepsAndReproducibility(t)
s=sensitivity.config_morris();[d,v,e]=sensitivity.morris_design(s);
verifyEqual(t,numel(d),170);verifyEqual(t,height(v),160);verifyEqual(t,height(e),120);
verifyTrue(t,all(v.unitCoordinate(:)>=-1e-14&v.unitCoordinate(:)<=1+1e-14));
verifyTrue(t,all(v.factor(:)>=0.90-1e-14&v.factor(:)<=1.10+1e-14));
verifyEqual(t,abs(e.deltaX),repmat(2/3,120,1),'AbsTol',1e-14);
for j=1:height(e)
    a=v.unitCoordinate(v.caseId==e.fromCase(j),:);b=v.unitCoordinate(v.caseId==e.toCase(j),:);
    verifyEqual(t,nnz(abs(b-a)>1e-12),1);
end
[d2,v2,e2]=sensitivity.morris_design(s);verifyEqual(t,d2,d);verifyEqual(t,v2,v);verifyEqual(t,e2,e);
s.morris.trajectories=10;[~,v3,~]=sensitivity.morris_design(s);verifyEqual(t,v3,v(1:40,:));
end
function testSignedEffectsRecoverLinearAndInteractingFunction(t)
s=sensitivity.config_morris();[~,v,e]=sensitivity.morris_design(s);
coeff=[2 -3 0.5];
for j=1:height(e)
    a=v.unitCoordinate(v.caseId==e.fromCase(j),:);b=v.unitCoordinate(v.caseId==e.toCase(j),:);
    p=find(s.parameters.name==e.parameter(j));
    ee=((b-a)*coeff.')/e.deltaX(j);verifyEqual(t,ee,coeff(p),'AbsTol',1e-12);
    ya=a(1)*a(2);yb=b(1)*b(2);
    if p<3,expected=a(3-p);else,expected=0;end
    verifyEqual(t,(yb-ya)/e.deltaX(j),expected,'AbsTol',1e-12);
end
end
function testStatisticsRejectMissingAndNoiseDominatedEffects(t)
x=ones(40,1);b=1e-4*x;valid=true(40,1);
a=sensitivity.morris_statistics(x,b,valid,[10 20 40],0.10,10);
verifyTrue(t,a.acceptedMean(end));verifyEqual(t,a.muStar,ones(3,1));verifyEqual(t,a.sigma,zeros(3,1));
valid(1)=false;c=sensitivity.morris_statistics(x,b,valid,[10 20 40],.10,10);
verifyTrue(t,all(isnan(c.muStar)));verifyFalse(t,any(c.acceptedMean));
d=sensitivity.morris_statistics(x,0.2*x,true(40,1),[10 20 40],.10,10);
verifyFalse(t,any(d.acceptedMean));
end
function testDispersionAndNonconvergence(t)
x=repmat([-1;1],20,1);a=sensitivity.morris_statistics(x,1e-5*ones(40,1),true(40,1),[10 20 40],.10,10);
verifyEqual(t,a.mu,zeros(3,1));verifyTrue(t,a.acceptedDispersion(end));
x=[ones(20,1);10*ones(20,1)];b=sensitivity.morris_statistics(x,1e-5*ones(40,1),true(40,1),[10 20 40],.10,10);
verifyFalse(t,b.acceptedMean(end));
end
function testWallBudgetKeepsPendingCase(t)
s=sensitivity.config_morris();s.maximumWallSeconds=0;s.checkpointCases=[];
folder=tempname;cleanup=onCleanup(@()rmdir(folder,'s')); %#ok<NASGU>
d=struct('id',"pending",'factors',struct(),'options',struct());
c=sensitivity.run_campaign(s,d,folder);verifyFalse(t,c.completed);verifyTrue(t,c.budgetStopped);
verifyEqual(t,c.status.status,"pending");verifyFalse(t,isfile(fullfile(folder,'pending.mat')));
end
