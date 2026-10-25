function tests = test_dynamics_newmark
tests = functiontests(localfunctions);
end

function testUndampedOscillator(testCase)
t = (0:0.002:2).';
r = dynamics.newmark_integrate(1,0,4,t,zeros(size(t)),struct('q0',1));
verifyLessThan(testCase,max(abs(r.q-cos(2*t).')),2e-5);
verifyLessThan(testCase,max(abs(r.energy.balanceResidual)),1e-10);
end

function testDampedFreeVibration(testCase)
omega=3;zeta=0.04;c=2*zeta*omega;t=(0:0.002:2).';
r=dynamics.newmark_integrate(1,c,omega^2,t,zeros(size(t)),struct('q0',1));
omegaD=omega*sqrt(1-zeta^2);
exact=exp(-zeta*omega*t).*(cos(omegaD*t)+zeta/sqrt(1-zeta^2)*sin(omegaD*t));
verifyLessThan(testCase,max(abs(r.q(:)-exact)),2e-5);
end

function testHarmonicSteadyState(testCase)
m=1;c=.3;k=9;forcingFrequency=2;forceAmplitude=4;
amplitude=forceAmplitude/sqrt((k-m*forcingFrequency^2)^2+(c*forcingFrequency)^2);
phase=atan2(c*forcingFrequency,k-m*forcingFrequency^2);
t=(0:0.002:2).';F=forceAmplitude*sin(forcingFrequency*t);
q0=-amplitude*sin(phase);v0=amplitude*forcingFrequency*cos(phase);
r=dynamics.newmark_integrate(m,c,k,t,F,struct('q0',q0,'qd0',v0));
exact=amplitude*sin(forcingFrequency*t-phase);
verifyLessThan(testCase,max(abs(r.q(:)-exact)),3e-6);
end

function testTemporalConvergence(testCase)
steps=[.04 .02 .01];errors=zeros(size(steps));
for index=1:numel(steps)
    t=(0:steps(index):1).';
    r=dynamics.newmark_integrate(1,0,4,t,zeros(size(t)),struct('q0',1));
    errors(index)=abs(r.q(end)-cos(2*t(end)));
end
verifyTrue(testCase,all(diff(errors)<0));
verifyLessThan(testCase,errors(end),1e-4);
end

function testGeneralNonsymmetricMatrices(testCase)
M = eye(2); D = [0.2 0.4;-0.1 0.3]; K = [4 1;-0.2 9];
t = (0:0.01:0.5).'; F = [sin(t).'; cos(t).'];
r = dynamics.newmark_integrate(M,D,K,t,F,struct());
verifySize(testCase,r.q,[2 numel(t)]);
verifyLessThan(testCase,max(r.relativeResidual(2:end)),1e-10);
end

function testAbsoluteAcceleration(testCase)
t = (0:0.1:1).'; n = numel(t);
relative = struct('t',t,'q',zeros(2,n),'qd',zeros(2,n),'qdd',ones(2,n));
Gamma = [1;0]; ag = 2*ones(n,1);
a = dynamics.recover_absolute_response(relative,Gamma,ag);
verifyEqual(testCase,a.absoluteAcceleration(1,:),3*ones(1,n),'AbsTol',1e-14);
verifyEqual(testCase,a.absoluteAcceleration(2,:),ones(1,n),'AbsTol',1e-14);
end

function testAccelerogramUnitsBaselineInterpolation(testCase)
source = [(0:0.1:1).' (1:11).'];
record = io.load_accelerogram(source,struct('accelerationUnit','g', ...
    'baselineCorrection','mean','targetDt',0.05));
verifyEqual(testCase,mean(record.original.acceleration),6*9.80665,'AbsTol',1e-12);
verifyLessThan(testCase,abs(mean(record.processed.acceleration)),1e-12);
verifyEqual(testCase,numel(record.t),21);
end

function testRunSeismicAnalysis(testCase)
t = (0:0.01:0.2).';
cfg.seismic.record = struct('t',t,'acceleration',ones(size(t)), ...
    'accelerationUnit','m/s^2');
cfg.seismic.directions = 1;
cfg.newmark.beta = 1/4; cfg.newmark.gamma = 1/2;
ops = struct('M',1,'D',0.1,'Kt',4,'Gamma',1);
r = dynamics.run_seismic_analysis(ops,struct(),cfg);
verifySize(testCase,r.absoluteAcceleration,[1 numel(t)]);
verifyEqual(testCase,r.baseForce,-ones(1,numel(t)),'AbsTol',1e-14);
verifyLessThan(testCase,max(r.relativeResidual(2:end)),1e-10);
end

function testReducedInfluenceHonorsFixedRows(testCase)
model.dofs.node = reshape(1:12,6,2).';
model.dofs.fixed = (1:6).';
model.Tc = [zeros(6);eye(6)];
Gamma = dynamics.influence_vector(model,1,6);
verifyEqual(testCase,Gamma,[1;0;0;0;0;0],'AbsTol',1e-14);
end

function testFullReactionRecovery(testCase)
t = (0:0.01:0.1).';
cfg.seismic.record = struct('t',t,'acceleration',ones(size(t)));
cfg.seismic.directions = 1;
ops = struct('M',1,'D',0,'K',4,'Mfull',eye(2), ...
    'Dfull',zeros(2),'Kfull',diag([5 4]),'Tc',[0;1]);
model.fullFixed = 1;
r = dynamics.run_seismic_analysis(ops,model,cfg);
verifyEqual(testCase,r.Gamma,1,'AbsTol',1e-14);
verifyEqual(testCase,r.reactions(1,:),ones(1,numel(t)),'AbsTol',1e-12);
verifyLessThan(testCase,max(r.energy.relativeBalanceError),2e-2);
end

function testExistingInfluenceRespectsRequestedDirection(testCase)
model.Gamma = eye(3);
GammaY = dynamics.influence_vector(model,2,3);
verifyEqual(testCase,GammaY,[0;1;0]);
end
