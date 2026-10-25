function tests = test_rotor_mbc
tests = functiontests(localfunctions);
end

function testDirectInverseIdentity(testCase)
map = [1 3 5;2 4 6];
result = rotor.mbc_transformation(map,0.37,struct('nDof',8));
verifyLessThan(testCase,norm(result.Tinv*result.T-eye(8),'fro'),1e-12);
q = randn(8,1);
verifyEqual(testCase,result.T*(result.Tinv*q),q,'AbsTol',1e-12);
verifyEqual(testCase,result.T(7:8,7:8),speye(2),'AbsTol',0);
end

function testAnalyticDerivatives(testCase)
map = [1 3 5;2 4 6]; psi = 0.61; omega = -2.3; h = 1e-5;
d = rotor.mbc_derivatives(map,psi,omega,struct('nDof',6));
Tp = rotor.mbc_transformation(map,psi+omega*h,struct('nDof',6));
Tm = rotor.mbc_transformation(map,psi-omega*h,struct('nDof',6));
finiteDot = (Tp.T-Tm.T)/(2*h);
finiteDdot = (Tp.T-2*d.T+Tm.T)/(h^2);
verifyLessThan(testCase,norm(finiteDot-d.Tdot,'fro'),1e-8);
verifyLessThan(testCase,norm(finiteDdot-d.Tddot,'fro'),2e-5);
end

function testFrozenTransformationFormula(testCase)
map = [1 2 3]; psi = 0.2; omega = 1.4;
M = diag([1 2 3]); D = [0 1 0;-1 0 0;0 0 .2]; K = diag([4 5 6]);
result = rotor.transform_rotating_system(M,D,K,map,psi,omega,struct('method','frozen'));
d = rotor.mbc_derivatives(map,psi,omega,struct('nDof',3));
verifyEqual(testCase,result.M,d.T'*M*d.T,'AbsTol',1e-13);
verifyEqual(testCase,result.D,d.T'*(D*d.T+2*M*d.Tdot),'AbsTol',1e-13);
verifyEqual(testCase,result.K,d.T'*(K*d.T+D*d.Tdot+M*d.Tddot),'AbsTol',1e-13);
end

function testAzimuthAverage(testCase)
map = [1 2 3];
r = rotor.transform_rotating_system(eye(3),zeros(3),eye(3),map,0,2, ...
    struct('method','azimuth_average','nAzimuthSamples',12));
verifyEqual(testCase,numel(r.sampleAzimuths),12);
verifyLessThan(testCase,norm(r.M-r.M','fro'),1e-12);
end

function testStructuredSystemAddsGyroscopicMatrix(testCase)
map = [1 2 3];
ops = struct('M',eye(3),'C',0.1*eye(3), ...
    'G',[0 1 0;-1 0 0;0 0 0],'K',diag([4 5 6]));
r = rotor.transform_rotating_system(ops,map,0.3,1.2,struct());
expected = rotor.transform_rotating_system(ops.M,ops.C+ops.G,ops.K,map,0.3,1.2,struct());
verifyEqual(testCase,r.D,expected.D,'AbsTol',1e-13);
verifyEqual(testCase,r.K,expected.K,'AbsTol',1e-13);
end

function testInvalidAzimuthSampleCount(testCase)
verifyError(testCase,@()rotor.transform_rotating_system(eye(3),zeros(3), ...
    eye(3),[1 2 3],0,1,struct('method','azimuth_average', ...
    'nAzimuthSamples',0)),'rotor:MBC:InvalidAzimuthSamples');
end
