function tests=test_rotating_frame_constraints
tests=functiontests(localfunctions);
end

function testConstraintDerivativesMatchFiniteDifferences(testCase)
[model,bodies]=rotatingConstraintModel();
psi=.37;omega=1.7;alpha=-.23;
options=struct('angularAcceleration',alpha);
result=rigid.rotating_constraint_derivatives( ...
    model,bodies,psi,omega,options);

h1=2e-6;
plus=rigid.rotating_constraint_derivatives(model,bodies, ...
    psi+omega*h1+.5*alpha*h1^2,omega+alpha*h1,options);
minus=rigid.rotating_constraint_derivatives(model,bodies, ...
    psi-omega*h1+.5*alpha*h1^2,omega-alpha*h1,options);
finiteFirst=(plus.T-minus.T)/(2*h1);
firstError=norm(finiteFirst-result.Tdot,'fro')/max(norm(result.Tdot,'fro'),1);
verifyLessThanOrEqual(testCase,firstError,2e-10);

h2=2e-4;
plus=rigid.rotating_constraint_derivatives(model,bodies, ...
    psi+omega*h2+.5*alpha*h2^2,omega+alpha*h2,options);
minus=rigid.rotating_constraint_derivatives(model,bodies, ...
    psi-omega*h2+.5*alpha*h2^2,omega-alpha*h2,options);
finiteSecond=(plus.T-2*result.T+minus.T)/(h2^2);
secondError=norm(finiteSecond-result.Tddot,'fro')/ ...
    max(norm(result.Tddot,'fro'),1);
verifyLessThanOrEqual(testCase,secondError,2e-8);
end

function testZeroAzimuthMatchesStaticConstraint(testCase)
[model,bodies]=rotatingConstraintModel();
[staticT,staticInfo]=rigid.rigid_constraint_matrix(model,bodies,struct());
result=rigid.rotating_constraint_derivatives(model,bodies,0,0,struct());
verifyEqual(testCase,result.T,staticT,'AbsTol',0);
verifyEqual(testCase,result.Tdot,sparse(size(staticT,1),size(staticT,2)),'AbsTol',0);
verifyEqual(testCase,result.Tddot,sparse(size(staticT,1),size(staticT,2)),'AbsTol',0);
verifyEqual(testCase,result.independentDofs,staticInfo.independentDofs);
end

function testEmptyConstraintsReturnIdentityWithoutDeclaredAxis(testCase)
model.mesh.nodes=struct('id',[1;2],'xyz',[0 0 0;1 0 0]);
model.mesh.elements=struct('id',zeros(0,1));
model.dofs.node=reshape(1:12,6,2).';model.dofs.number=12;
result=rigid.rotating_constraint_derivatives( ...
    model,struct(),.8,[.2;-.4;.7],struct());
verifyEqual(testCase,result.T,speye(12),'AbsTol',0);
verifyEqual(testCase,result.Tdot,sparse(12,12),'AbsTol',0);
verifyEqual(testCase,result.Tddot,sparse(12,12),'AbsTol',0);
verifyEqual(testCase,result.axis,[.2;-.4;.7]/norm([.2;-.4;.7]), ...
    'AbsTol',2e-15);
end

function testTimeDependentReductionReproducesFullResidual(testCase)
[model,bodies]=rotatingConstraintModel();
r=rigid.rotating_constraint_derivatives(model,bodies,.42,-1.3, ...
    struct('angularAcceleration',.17));
nf=size(r.T,1);nr=size(r.T,2);
A=reshape(sin((1:nf^2)/11),nf,nf);
M=A.'*A+eye(nf);D=reshape(cos((1:nf^2)/13),nf,nf);
K=reshape(sin((1:nf^2)/17),nf,nf)+3*eye(nf);
z=sin((1:nr).'/7);zd=cos((1:nr).'/9);zdd=sin((1:nr).'/5);
q=r.T*z;qd=r.T*zd+r.Tdot*z;
qdd=r.T*zdd+2*r.Tdot*zd+r.Tddot*z;
fullResidual=M*qdd+D*qd+K*q;

Mr=r.T.'*M*r.T;
Dr=r.T.'*(D*r.T+2*M*r.Tdot);
Kr=r.T.'*(K*r.T+D*r.Tdot+M*r.Tddot);
reducedResidual=Mr*zdd+Dr*zd+Kr*z;
errorValue=norm(reducedResidual-r.T.'*fullResidual)/ ...
    max(norm(r.T.'*fullResidual),1);
verifyLessThanOrEqual(testCase,errorValue,5e-14);
end

function testBladeFrameDerivativesMatchFiniteDifferences(testCase)
[frameData,n]=bladeFrames();psi=-.29;omega=2.1;alpha=.31;
options=struct('nDof',n,'angularAcceleration',alpha);
base=rotor.blade_frame_transformation(frameData,psi,omega,options);
h1=2e-6;
plus=rotor.blade_frame_transformation(frameData, ...
    psi+omega*h1+.5*alpha*h1^2,omega+alpha*h1,options);
minus=rotor.blade_frame_transformation(frameData, ...
    psi-omega*h1+.5*alpha*h1^2,omega-alpha*h1,options);
first=(plus.H-minus.H)/(2*h1);
verifyLessThanOrEqual(testCase,norm(first-base.Hdot,'fro')/ ...
    max(norm(base.Hdot,'fro'),1),2e-10);
h2=2e-4;
plus=rotor.blade_frame_transformation(frameData, ...
    psi+omega*h2+.5*alpha*h2^2,omega+alpha*h2,options);
minus=rotor.blade_frame_transformation(frameData, ...
    psi-omega*h2+.5*alpha*h2^2,omega-alpha*h2,options);
second=(plus.H-2*base.H+minus.H)/(h2^2);
verifyLessThanOrEqual(testCase,norm(second-base.Hddot,'fro')/ ...
    max(norm(base.Hddot,'fro'),1),2e-8);
end

function [model,bodies]=rotatingConstraintModel()
model.mesh.nodes=struct('id',[130;21;57;129], ...
    'xyz',[0 0 0;0 2 .4;0 -.7 1.6;-3 0 0]);
model.mesh.elements=struct('id',zeros(0,1));
model.dofs.node=reshape(1:24,6,4).';model.dofs.number=24;
model.rotorAxis=struct('point',[0;0;0],'direction',[1;0;0]);
hub=struct('name',"hub",'masterNode',130,'rotating',true);
nacelle=struct('name',"nacelle",'masterNode',129,'rotating',false);
bodies=struct('bodies',[hub;nacelle], ...
    'constraints',struct('name',"hub_roots",'masterNode',130, ...
    'slaveNodes',[21;57]));
model.rigidBodies=bodies;
end

function [frameData,n]=bladeFrames()
n=18;map=reshape(1:n,6,3);referenceR=zeros(3,3,1,3);
for blade=1:3
    angle=2*pi*(blade-1)/3;
    referenceR(:,:,1,blade)=[1 0 0;0 cos(angle) -sin(angle); ...
        0 sin(angle) cos(angle)];
end
frameData=struct('map',map,'referenceR',referenceR, ...
    'rotorAxis',[1;0;0],'nDof',n);
end
