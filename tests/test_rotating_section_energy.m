function tests=test_rotating_section_energy
% Independent energy, Euler-equation, and frame-transport comparisons.
tests=functiontests(localfunctions);
end

function testExactEnergyHessiansWithAnisotropyAndOffsets(testCase)
R=expm(skew([.3;.1;-.2]));
cases={ ...
    {2.3,diag([2 3 4]),zeros(3,1),[1.2;0;0],zeros(3,1)}, ...
    {2.3,R*diag([2 3 4])*R.',[.2;-.3;.1],[1.2;-.7;.9],[.4;.2;-.5]}, ...
    {1.7,zeros(3),[-.4;.2;.3],[.7;.9;-.2],[.3;-.1;.6]}, ...
    {1.7,diag([.2 .3 .4]),[.1;.2;-.2],zeros(3,1),[.3;-.1;.6]}};
for k=1:numel(cases)
    args=cases{k};ops=elements.rotating_section_operators(args{:});
    energy=@(z)exactKineticEnergy(z,args{:});
    % Richardson extrapolation uses only the exact finite-rotation energy;
    % no formula from the implementation enters the derivative oracle.
    [gradientCoarse,hessianCoarse]=centralDerivatives(energy,2e-3);
    [gradientFine,hessianFine]=centralDerivatives(energy,1e-3);
    gradient=(4*gradientFine-gradientCoarse)/3;
    hessian=(4*hessianFine-hessianCoarse)/3;
    expectedM=hessian(7:12,7:12);
    expectedA=hessian(7:12,1:6);
    expectedK=-hessian(1:6,1:6);
    assertScaledClose(testCase,ops.M,expectedM,2e-7);
    assertScaledClose(testCase,ops.A,expectedA,2e-7);
    assertScaledClose(testCase,ops.G,expectedA-expectedA.',2e-7);
    assertScaledClose(testCase,ops.Kcentrifugal,expectedK,2e-7);
    assertScaledClose(testCase,ops.forceCentrifugal,gradient(1:6),2e-7);
    assertScaledClose(testCase,ops.G,ops.A-ops.A.',1e-14);
    assertScaledClose(testCase,ops.G,-ops.G.',1e-14);
    assertScaledClose(testCase,ops.Kcentrifugal,ops.Kcentrifugal.',1e-14);
end
end

function testMeirovitchExample44CoriolisAndSpinSoftening(testCase)
% Meirovitch (1997), Example 4.4: the translational linearization has
% Gxy=[0,-2*m*Omega;2*m*Omega,0] and Kxy=diag(kx,ky)-m*Omega^2*I
% at the zero equilibrium, with nonlinear/circulatory terms suppressed.
m=3.7;omega=1.4;kx=17;ky=23;
ops=elements.rotating_section_operators(m,zeros(3),zeros(3,1),[0;0;omega]);
verifyEqual(testCase,ops.M(1:2,1:2),m*eye(2),'AbsTol',1e-14);
verifyEqual(testCase,ops.G(1:2,1:2),[0 -2*m*omega;2*m*omega 0], ...
    'AbsTol',1e-14);
verifyEqual(testCase,diag([kx ky])+ops.Kcentrifugal(1:2,1:2), ...
    diag([kx-m*omega^2,ky-m*omega^2]),'AbsTol',1e-14);
end

function testPrincipalRigidBodyMatchesLinearizedEuler(testCase)
J=diag([4 3 3]);omega=[7;0;0];
ops=elements.rotating_section_operators(2,J,zeros(3,1),omega);
theta=[.13;-.27;.19];velocity=[-.31;.23;.17];acceleration=[.29;-.11;.07];
deltaOmega=velocity+cross(omega,theta);
deltaOmegaDot=acceleration+cross(omega,velocity);
deltaEuler=J*deltaOmegaDot+cross(deltaOmega,J*omega)+cross(omega,J*deltaOmega);
linearized=ops.M(4:6,4:6)*acceleration+ ...
    ops.G(4:6,4:6)*velocity+ops.Kcentrifugal(4:6,4:6)*theta;
verifyEqual(testCase,linearized,deltaEuler,'AbsTol',5e-14);
% Euler's transverse perturbations expressed in nominal rotating axes
% have positive frequencies Omega and abs(Jp/Jd-1)*Omega (rad/s).
Mr=ops.M(5:6,5:6);Gr=ops.G(5:6,5:6);Kr=ops.Kcentrifugal(5:6,5:6);
lambda=eig([zeros(2),eye(2);-Mr\Kr,-Mr\Gr]);
frequencies=sort(imag(lambda(imag(lambda)>1e-9)));
verifyEqual(testCase,frequencies,[7/3;7],'AbsTol',2e-12);
verifyLessThan(testCase,max(abs(real(lambda))),1e-12);
verifyEqual(testCase,ops.centroidalHoldingTorque,zeros(3,1),'AbsTol',0);
end

function testNonprincipalSpinNeedsHoldingTorqueLoadTangent(testCase)
J=diag([2 3 4]);omega=[1.2;-.7;.9];
ops=elements.rotating_section_operators(2,J,zeros(3,1),omega);
theta=[.13;-.27;.19];velocity=[-.31;.23;.17];acceleration=[.29;-.11;.07];
deltaOmega=velocity+cross(omega,theta);
deltaOmegaDot=acceleration+cross(omega,velocity);
deltaEuler=J*deltaOmegaDot+cross(deltaOmega,J*omega)+cross(omega,J*deltaOmega);
torque=cross(omega,J*omega);
% A holding torque constant in BODY components has generalized-load
% derivative -skew(torque)/2 in exponential coordinates.
effectiveK=ops.Kcentrifugal(4:6,4:6)+skew(torque)/2;
linearized=J*acceleration+ops.G(4:6,4:6)*velocity+effectiveK*theta;
verifyEqual(testCase,linearized,deltaEuler,'AbsTol',2e-14);
verifyEqual(testCase,ops.forceCentrifugal(4:6),-torque,'AbsTol',1e-14);
verifyGreaterThan(testCase,norm(torque),.1);
end

function testTransportToInertialAxesRemovesCoordinateCoriolis(testCase)
m=2;omega=[0;0;1.3];W=skew(omega);W6=blkdiag(W,W);
ops=elements.rotating_section_operators(m,zeros(3),zeros(3,1),omega);
D=ops.G-2*ops.M*W6;
K=ops.Kcentrifugal-ops.G*W6+ops.M*W6*W6;
verifyEqual(testCase,D,zeros(6),'AbsTol',1e-14);
verifyEqual(testCase,K,zeros(6),'AbsTol',1e-14);
% For a centered axisymmetric body, inertial tilt coordinates retain
% the usual -skew(J*omega) term, with no inertial rotational stiffness.
J=diag([3 3 4]);ops=elements.rotating_section_operators(m,J,zeros(3,1),omega);
D=ops.G-2*ops.M*W6;
K=ops.Kcentrifugal-ops.G*W6+ops.M*W6*W6;
verifyEqual(testCase,D(4:6,4:6),-skew(J*omega),'AbsTol',1e-14);
verifyEqual(testCase,K,zeros(6),'AbsTol',1e-14);
end

function testInertialTransportSeparatesMassDerivativeAndSkew(testCase)
omega=[1.2;-.7;.9];W6=blkdiag(skew(omega),skew(omega));
ops=elements.rotating_section_operators(2,diag([2 3 4]), ...
    [.2;-.3;.1],omega,[.4;.2;-.5]);
D=ops.G-2*ops.M*W6;
massDerivative=W6*ops.M-ops.M*W6;
gyroscopic=D-massDerivative;
assertScaledClose(testCase,gyroscopic,-gyroscopic.',1e-14);
assertScaledClose(testCase,(D+D.')/2,massDerivative,1e-14);
% Independent derivative of the physical, rotating spatial mass.
h=1e-5;Ep=expm(h*W6);Em=expm(-h*W6);
massDerivativeFD=(Ep*ops.M*Ep.'-Em*ops.M*Em.')/(2*h);
assertScaledClose(testCase,massDerivative,massDerivativeFD,2e-9);
end

function testInvalidPhysicalPropertiesAreRejected(testCase)
valid=@(m,J,r,w,a)elements.rotating_section_operators(m,J,r,w,a);
z=zeros(3,1);prefix='elements:rotating_section_operators:';
verifyError(testCase,@()valid(-1,eye(3),z,z,z),[prefix 'InvalidMass']);
verifyError(testCase,@()valid(1,diag([-1 2 2]),z,z,z),[prefix 'InvalidInertia']);
verifyError(testCase,@()valid(1,diag([1 1 3]),z,z,z),[prefix 'NonPhysicalInertia']);
verifyError(testCase,@()valid(1,[1 .2 0;0 1 0;0 0 1],z,z,z), ...
    [prefix 'InvalidInertia']);
verifyError(testCase,@()valid(1,eye(3),[Inf;0;0],z,z),[prefix 'InvalidOffset']);
verifyError(testCase,@()valid(1,eye(3),z,[0;0;0;0],z), ...
    [prefix 'InvalidAngularVelocity']);
verifyError(testCase,@()valid(1,eye(3),z,z,[NaN;0;0]),[prefix 'InvalidPosition']);
end

function T=exactKineticEnergy(z,m,J,r,omega,position)
u=z(1:3);theta=z(4:6);udot=z(7:9);thetadot=z(10:12);
% The upper-right block of exp([A B;0 A]) is the Frechet derivative
% Dexp(A)[B], independently evaluating the exact exponential Jacobian.
expBlock=expm([skew(theta),skew(thetadot);zeros(3),skew(theta)]);
Q=expBlock(1:3,1:3);Qdot=expBlock(1:3,4:6);
velocity=cross(omega,position+u+Q*r)+udot+Qdot*r;
bodySpin=Q.'*omega+vee(Q.'*Qdot);
T=(m*(velocity.'*velocity)+bodySpin.'*J*bodySpin)/2;
end

function [gradient,H]=centralDerivatives(fun,h)
n=12;zero=zeros(n,1);f0=fun(zero);gradient=zeros(n,1);H=zeros(n);
for i=1:n
    ei=zero;ei(i)=h;plus=fun(ei);minus=fun(-ei);
    gradient(i)=(plus-minus)/(2*h);H(i,i)=(plus-2*f0+minus)/h^2;
    for j=1:i-1
        ej=zero;ej(j)=h;
        H(i,j)=(fun(ei+ej)-fun(ei-ej)-fun(-ei+ej)+fun(-ei-ej))/(4*h^2);
        H(j,i)=H(i,j);
    end
end
end

function assertScaledClose(testCase,actual,expected,tolerance)
error=norm(actual-expected,'fro')/max(1,norm(expected,'fro'));
verifyLessThanOrEqual(testCase,error,tolerance);
end

function v=vee(S)
v=[S(3,2)-S(2,3);S(1,3)-S(3,1);S(2,1)-S(1,2)]/2;
end

function S=skew(v)
S=[0 -v(3) v(2);v(3) 0 -v(1);-v(2) v(1) 0];
end
