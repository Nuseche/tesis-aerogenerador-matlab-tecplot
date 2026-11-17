function tests=test_aeroelastic_coupling
tests=functiontests(localfunctions);
end
function setupOnce(testCase)
root=fileparts(fileparts(mfilename('fullpath')));addpath(root);addpath(fullfile(root,'cases'));
cfg=config_maza_isolated_blade();data=aero.load_snl100();md=aero.build_isolated_blade(cfg,data);
testCase.TestData.cfg=cfg;testCase.TestData.data=data;testCase.TestData.md=md;
testCase.TestData.system=aero.prepare_structure(md,cfg);
testCase.TestData.sections=aero.prepare_sections(md,cfg,data);
end
function testPublishedGeometryAndRoot(testCase)
d=testCase.TestData;verifyEqual(testCase,height(d.data.geometry),34);
verifyEqual(testCase,d.md.mesh.nodes.xyz([1 end],3),[6;106],'AbsTol',1e-12);
verifyEqual(testCase,sum(d.sections.weight),100,'AbsTol',1e-10);
verifyEqual(testCase,size(d.system.T,2),210);
end
function testPeriodicPolarAndInvalidThickness(testCase)
d=testCase.TestData.data;
a=aero.polar_coefficients(d,[.1;.1+2*pi],[.3;.3]);
verifyEqual(testCase,a(1,:),a(2,:),'AbsTol',1e-12);
verifyError(testCase,@()aero.polar_coefficients(d,0,NaN),'aero:PolarInput');
end
function testZeroIntegratedLiftReference(testCase)
d=testCase.TestData.data;[~,beta]=aero.maza_pitch_reference(d,90);
c=aero.polar_coefficients(d,(90-beta-d.geometry.twist_deg)*pi/180,d.geometry.thickness);
verifyLessThan(testCase,abs(trapz(d.geometry.span_m,d.geometry.chord_m.*c(:,1))),1e-8);
end
function testRotationJacobianFiniteDifference(testCase)
q=[.1;-.05;.03];v=[.4;-.2;.1];h=1e-6;
[R,J]=aero.rotation(q);Rp=aero.rotation(q+h*v);Rm=aero.rotation(q-h*v);
verifyLessThan(testCase,norm((Rp-Rm)/(2*h)*R.'-aero.skew(J*v),'fro'),1e-9);
end
function testVelocityTriangleLiftAndDrag(testCase)
[s,d,cfg,m]=singleSection();m.omega=2;cfg.aerodynamics.windVelocity=[3 0 0];
[f,r]=aero.section_loads(s,d,zeros(6,1),zeros(6,1),0,m,cfg);
V=[3 20 0];speed=norm(V);drag=V/speed;lift=cross(drag,[0 0 1]);
expected=.5*cfg.aerodynamics.density*speed^2*s.chord*(lift+.1*drag)*s.weight;
verifyEqual(testCase,r.relativeSpeed,speed,'AbsTol',1e-12);
verifyEqual(testCase,r.alphaRad,atan2(3,20),'AbsTol',1e-12);
verifyEqual(testCase,f(1:3),expected.','AbsTol',1e-10);
end
function testNoRelativeFlowNoForce(testCase)
[s,d,cfg,m]=singleSection();cfg.aerodynamics.windVelocity=[3 4 0];
[f,r]=aero.section_loads(s,d,zeros(6,1),[3;4;0;0;0;0],0,m,cfg);
verifyEqual(testCase,f,zeros(6,1),'AbsTol',1e-14);verifyEqual(testCase,r.relativeSpeed,0);
end
function testEccentricLoadVirtualWork(testCase)
[s,d,cfg,m]=singleSection();s.pitchAxis=.4;cfg.aerodynamics.windVelocity=[3 10 0];
q=[.2;-.1;.05;.08;-.03;.06];v=[.4;.2;-.1;.03;-.04;.02];h=1e-6;
[f,r]=aero.section_loads(s,d,q,v,0,m,cfg);
[~,rp]=aero.section_loads(s,d,q+h*v,zeros(6,1),0,m,cfg);
[~,rm]=aero.section_loads(s,d,q-h*v,zeros(6,1),0,m,cfg);
power=sum(r.forcePerLength.*((rp.positions-rm.positions)/(2*h)))*s.weight;
verifyEqual(testCase,f.'*v,power,'RelTol',1e-8);
verifyEqual(testCase,r.nodalPower,r.sectionPower,'AbsTol',1e-12);
end
function testWindCallbackAndInducedVelocity(testCase)
[s,d,cfg,m]=singleSection();cfg.aerodynamics.windVelocity=@(t,x) repmat([t 4 0],size(x,1),1);
cfg.aerodynamics.inducedVelocityFcn=@(~,x) repmat([0 -1 0],size(x,1),1);
[~,r]=aero.section_loads(s,d,zeros(6,1),zeros(6,1),3,m,cfg);
verifyEqual(testCase,r.relativeSpeed,sqrt(18),'AbsTol',1e-12);
end
function testRampKinematicConsistency(testCase)
cfg=testCase.TestData.cfg;h=1e-5;t=4;
a=aero.rotor_motion(t,cfg);p=aero.rotor_motion(t+h,cfg);m=aero.rotor_motion(t-h,cfg);
verifyEqual(testCase,(p.azimuth-m.azimuth)/(2*h),a.omega,'AbsTol',1e-10);
verifyEqual(testCase,(p.omega-m.omega)/(2*h),a.alpha,'AbsTol',1e-10);
a=aero.rotor_motion(10,cfg);verifyEqual(testCase,a.omega,.7547,'AbsTol',1e-14);verifyEqual(testCase,a.alpha,0);
end
function testStationaryStructuralLimit(testCase)
s=testCase.TestData.system;o=aero.structural_operators(s,0);
verifyEqual(testCase,o.M,s.T.'*s.M*s.T,'AbsTol',1e-9);
verifyEqual(testCase,o.K,s.T.'*s.Ke*s.T,'AbsTol',1e-6);
verifyEqual(testCase,o.D,sparse(s.n,s.n),'AbsTol',1e-12);
verifyLessThan(testCase,norm(s.G+s.G.','fro'),1e-9);
verifyGreaterThan(testCase,min(s.axialForceUnitSpin),0);
end
function testEulerForcingAtRamp(testCase)
s=testCase.TestData.system;o=aero.structural_operators(s,5);m=o.motion;
verifyEqual(testCase,o.baseForce,s.T.'*(m.omega^2*s.fspin-m.alpha*s.bspin),'AbsTol',1e-10);
verifyGreaterThan(testCase,norm(s.T.'*s.bspin),0);
end
function testFeedbackActuallyChangesLoads(testCase)
d=testCase.TestData;s=d.system;o=aero.structural_operators(s,12);q=zeros(s.n,1);v=.1*ones(s.n,1);
[f0,~]=aero.evaluate_force(s,d.sections,d.data,12,q,zeros(s.n,1),o);
[f1,~]=aero.evaluate_force(s,d.sections,d.data,12,q,v,o);
verifyGreaterThan(testCase,norm(f1-f0),1);
s.cfg.aeroelastic.feedback=false;
[f2,~]=aero.evaluate_force(s,d.sections,d.data,12,q,v,o);
verifyEqual(testCase,f2,f0,'AbsTol',1e-10);
end
function testExplicitExchangeConvergesToDampedOscillator(testCase)
errors=zeros(1,3);steps=[.04 .02 .01];zeta=.4/(2*sqrt(4.2));wn=sqrt(4.2);wd=wn*sqrt(1-zeta^2);
for k=1:3
 t=(0:steps(k):2).';opts=struct('q0',1,'v0',0,'outputStride',1,'maxElasticRotation',Inf);
 op=@(~)struct('M',1,'D',0,'K',4,'baseForce',0);
 r=dynamics.weak_coupling_integrate(op,@oscillatorLoad,t,opts);
 exact=exp(-zeta*wn*t).*(cos(wd*t)+zeta/sqrt(1-zeta^2)*sin(wd*t));
 errors(k)=max(abs(r.q(:)-exact));
 verifyEqual(testCase,r.aerodynamicEvaluations,numel(t));
 verifyLessThan(testCase,r.maximumMechanicalResidual,1e-11);
end
verifyTrue(testCase,all(diff(errors)<0));verifyLessThan(testCase,errors(3),2e-4);
end
function testTurbineStationaryLimitAndTimeVaryingConstraints(testCase)
cfg=config_aeroelastic_snl100();cfg.gravity.enabled=false;
md=model.build_model(io.load_model_data(cfg),cfg);s=aero.prepare_structure(md,cfg);
o=aero.structural_operators(s,0);verifyEqual(testCase,o.K,s.T.'*s.Ke*s.T,'AbsTol',1e-5);
h=1e-5;p=aero.structural_operators(s,5+h);m=aero.structural_operators(s,5-h);o=aero.structural_operators(s,5);
verifyLessThan(testCase,norm((p.T-m.T)/(2*h)-o.Tdot,'fro'),1e-8);
verifyGreaterThan(testCase,norm(o.Tdot,'fro'),0);
end
function testTurbineRunAndPitchValidation(testCase)
cfg=config_aeroelastic_snl100();cfg.aeroelastic.duration=.05;cfg.aeroelastic.saveResults=false;
r=run_aeroelastic(cfg);verifyEqual(testCase,r.aerodynamicEvaluations,6);
verifyTrue(testCase,all(isfinite(r.q),'all'));verifyGreaterThan(testCase,norm(r.aerodynamicForce,'fro'),0);
cfg.aerodynamics.pitchRad=@(~)0;verifyError(testCase,@()run_aeroelastic(cfg),'aero:PrescribedPitch');
end
function testCorrectedStateRotationGuard(testCase)
opts=struct('q0',0,'v0',0,'outputStride',1,'maxElasticRotation',.001,'rotationMap',[1;0;0]);
op=@(~)struct('M',1,'D',0,'K',1,'baseForce',100);
verifyError(testCase,@()dynamics.weak_coupling_integrate(op,@zeroLoad,[0;.1],opts),'dynamics:CouplingRange');
end
function testPartialRunIsExplicitlyLabelled(testCase)
opts=struct('q0',0,'v0',0,'outputStride',1,'maxElasticRotation',.001, ...
    'rotationMap',[1;0;0],'returnPartialOnDomainExit',true);
op=@(~)struct('M',1,'D',0,'K',1,'baseForce',100);
r=dynamics.weak_coupling_integrate(op,@zeroLoad,[0;.1;.2],opts);
verifyEqual(testCase,r.status,"rotation_limit");verifyEqual(testCase,r.terminationTime,.1);
verifyEqual(testCase,r.integrationSteps,0);verifyEqual(testCase,r.aerodynamicEvaluations,2);
verifyEqual(testCase,r.t,0);verifySize(testCase,r.q,[1 1]);
end
function [f,r]=oscillatorLoad(~,q,v,~)
f=-.4*v-.2*q;r=struct('maxElasticRotation',0,'alphaRad',0);
end
function [f,r]=zeroLoad(~,~,~,~)
f=0;r=struct('maxElasticRotation',0,'alphaRad',0);
end
function [s,d,cfg,m]=singleSection()
s=struct('B',speye(6),'weight',2,'position',[0 0 10],'axis',[1;0;0], ...
 'axisPoint',zeros(3,1),'span',[0 0 1],'zeroPitchChord',[0 1 0], ...
 'twist',0,'pitchAxis',.25,'chord',3,'thickness',.3);
d.thickness=[.18 1];d.lookup={@(a)[ones(size(a)) .1*ones(size(a)) zeros(size(a))], ...
 @(a)[ones(size(a)) .1*ones(size(a)) zeros(size(a))]};
cfg.aerodynamics=struct('pitchRad',0,'density',1.225,'aerodynamicCenterFraction',.25,'windVelocity',[0 0 0]);
m=struct('azimuth',0,'omega',0,'alpha',0);
end
