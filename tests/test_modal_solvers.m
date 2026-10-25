function tests = test_modal_solvers
tests = functiontests(localfunctions);
end

function testConservativeMassNormalization(testCase)
M = diag([2 1]); K = diag([8 9]);
result = modal.solve_conservative_modes(M,K,struct('number',2));
verifyEqual(testCase,result.frequencyHz,[2;3]/(2*pi),'AbsTol',1e-12);
verifyEqual(testCase,result.modes'*M*result.modes,eye(2),'AbsTol',1e-12);
verifyLessThan(testCase,max(result.residual),1e-12);
end

function testQuadraticPairAndMetrics(testCase)
M = 2; D = 0.4; K = 8;
result = modal.solve_quadratic_modes(M,D,K,struct('number',1));
verifyEqual(testCase,real(result.eigenvalues),-0.1,'AbsTol',1e-10);
verifyEqual(testCase,result.naturalFrequencyHz,2/(2*pi),'AbsTol',1e-10);
verifyEqual(testCase,result.dampingRatio,0.05,'AbsTol',1e-10);
verifyLessThan(testCase,result.conjugatePairRelativeError,1e-12);
verifyLessThan(testCase,result.residual,1e-12);
end

function testMACComplexAndMassWeighted(testCase)
M = diag([2 3 4]);
A = [1 0; 0 1; 0 0]; B = [1 0;0 0;0 1];
MAC = modal.modal_assurance_criterion(A,B,M);
verifyEqual(testCase,MAC(1,1),1,'AbsTol',1e-14);
verifyEqual(testCase,MAC(1,2),0,'AbsTol',1e-14);
verifyEqual(testCase,MAC(2,1),0,'AbsTol',1e-14);
end

function testCampbellSpeedFactory(testCase)
cfg.modal.number = 2;
cfg.rotor.speedRPMGrid = [0 10 20];
results = modal.run_analysis(@speedSystem,struct(),cfg);
verifySize(testCase,results.campbell.frequencyHz,[3 2]);
verifyEqual(testCase,results.campbell.speedRPM,[0;10;20]);
verifyGreaterThan(testCase,min(results.campbell.trackingMAC(2:end,:),[],'all'),0.96);
end

function testNestedOperatingMatricesAndFullModeRecovery(testCase)
ops.full.M = eye(3);
ops.reduced = struct('M',eye(2),'D',zeros(2),'K',diag([4 9]), ...
    'Tc',[1 0;0 1;0 0]);
cfg.modal.enabled = true; cfg.modes.number = 1; cfg.rotor.speedRPM = 0;
r = modal.run_analysis(ops,struct(),cfg);
verifyEqual(testCase,numel(r.frequencyHz),1);
verifySize(testCase,r.fullModes,[3 1]);
end

function testModeClassificationFromGroups(testCase)
model.modalGroups = struct('tower',[1 2],'blade',[3 4]);
options.M = eye(4);
c = modal.classify_modes([1 0;0 0;0 0;0 1],model,options);
verifyEqual(testCase,c.labels,["tower";"blade"]);
end

function testOverlappingClassificationIsPartitioned(testCase)
model.modalGroups=struct('structure',[1 2 3],'rotation',[2 3]);
c=modal.classify_modes([1;2;3],model,struct('M',eye(3)));
verifyEqual(testCase,sum(c.participation,2),1,'AbsTol',2e-15);
verifyEqual(testCase,c.overlapPolicy,"equal-share partition");
end

function testQuadraticMixedOscillatoryAndOverdampedSpectrum(testCase)
M = eye(2); D = diag([4 0.2]); K = diag([1 100]);
r = modal.solve_quadratic_modes(M,D,K,struct('number',2));
verifyEqual(testCase,numel(r.eigenvalues),2);
verifyEqual(testCase,r.naturalFrequencyHz,[1;10]/(2*pi),'AbsTol',1e-10);
verifyEqual(testCase,r.dampingRatio,[2;0.01],'AbsTol',1e-10);
verifyEqual(testCase,r.pairType,["real-root-pair";"complex-conjugate"]);
end

function testSparseConservativeFilteringStillReturnsRequestedCount(testCase)
M = speye(60); K = spdiags([1e-14*(1:6) 1:54].',0,60,60);
r = modal.solve_conservative_modes(M,K,struct('number',10, ...
    'includeRigidModes',false,'rigidTolerance',1e-9));
verifyEqual(testCase,numel(r.frequencyHz),10);
verifyGreaterThan(testCase,min(r.frequencyHz),0.1);
end

function testJeffcottGyroscopicSplitting(testCase)
m=3;k=120;gyro=1.8;omegaSpin=7;
G=omegaSpin*[0 gyro;-gyro 0];
r=modal.solve_quadratic_modes(m*eye(2),G,k*eye(2),struct('number',2));
rootForward=(sqrt((gyro*omegaSpin)^2+4*m*k)-gyro*omegaSpin)/(2*m);
rootBackward=(sqrt((gyro*omegaSpin)^2+4*m*k)+gyro*omegaSpin)/(2*m);
verifyEqual(testCase,sort(r.dampedFrequencyHz), ...
    sort([rootForward;rootBackward]/(2*pi)),'RelTol',2e-10);
end

function ops = speedSystem(speed)
theta = speed*pi/180;
R = [cos(theta) -sin(theta);sin(theta) cos(theta)];
ops = struct('M',eye(2),'D',zeros(2),'Kt',R*diag([4 9])*R');
end
