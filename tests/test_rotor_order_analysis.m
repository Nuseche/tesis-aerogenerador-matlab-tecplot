function tests=test_rotor_order_analysis
tests=functiontests(localfunctions);
end
function setupOnce(~)
root=fileparts(fileparts(mfilename('fullpath')));addpath(root);addpath(fullfile(root,'cases'));
end
function testCentralTangentAgainstAnalyticalDerivative(t)
q=[.3;-.2];v=[.1;.4];f=@(q,v)[q(1)^2+.3*v(2);q(1)*q(2)+sin(v(1))];
[Q,V]=aero.force_tangent(f,q,v,1e-5);
verifyEqual(t,full(Q),[.6 0;-.2 .3],'AbsTol',1e-10);
verifyEqual(t,full(V),[0 .3;cos(.1) 0],'AbsTol',1e-10);
end
function testMeshSubdivisionPreservesMassAndFrames(t)
cfg=config_maza_isolated_blade();data=aero.load_snl100();a=aero.build_isolated_blade(cfg,data);b=aero.refine_isolated_mesh(a,4);
ma=0;mb=0;
for e=1:numel(a.mesh.elements.id)
 L=norm(diff(a.mesh.nodes.xyz([e e+1],:)));ma=ma+L*a.sections(a.mesh.elements.section(e)).m;
 [Ra,~,~]=elements.element_rotation_matrix(a.mesh.nodes.xyz(e,:),a.mesh.nodes.xyz(e+1,:),a.mesh.elements.auxPoint(e,:));
 for k=1:4
  j=(e-1)*4+k;[Rb,~,LL]=elements.element_rotation_matrix(b.mesh.nodes.xyz(j,:),b.mesh.nodes.xyz(j+1,:),b.mesh.elements.auxPoint(j,:));
  mb=mb+LL*b.sections(b.mesh.elements.section(j)).m;verifyEqual(t,Rb,Ra,'AbsTol',1e-12);
 end
end
verifyEqual(t,mb,ma,'RelTol',1e-12);verifyEqual(t,b.mesh.nodes.xyz(end,:),a.mesh.nodes.xyz(end,:));
end
function testMbcFrameConventionAndTransport(t)
cfg=config_aeroelastic_snl100();cfg.gravity.enabled=false;
md=model.build_model(io.load_model_data(cfg),cfg);s=aero.prepare_structure(md,cfg);
o=aero.turbine_mbc_operators(s,.3,.7);P=o.transformation.T;Pd=o.transformation.Tdot;Pdd=o.transformation.Tddot;a=o.physicalOperators;
z=sin((1:s.n).');v=cos((1:s.n).');acc=.3*z;
expected=P.'*(a.M*(P*acc+2*Pd*v+Pdd*z)+a.D*(P*v+Pd*z)+a.K*P*z);
actual=o.M*acc+o.D*v+o.K*z;verifyLessThan(t,norm(actual-expected)/norm(expected),1e-12);
zero=aero.turbine_mbc_operators(s,0,0);indices=zero.map(1:3,1);
verifyEqual(t,full(zero.transformation.frame.H(indices,indices)),md.bladeDofMap.frameR(:,:,1,1),'AbsTol',1e-12);
end
function testConstantHarmonicOscillator(t)
N=48;M=ones(1,1,N);D=.3*M;K=9*M;w=.7;n=3;
r=dynamics.harmonic_balance(M,D,K,w,n,1,6);
actual=2*r.coefficients(:,r.orders==n);expected=1/(9-(n*w)^2+1i*.3*n*w);
verifyEqual(t,actual,expected,'AbsTol',1e-13);verifyLessThan(t,r.residual,1e-12);
end
function testPeriodicHarmonicResidual(t)
N=64;psi=reshape((0:N-1)*2*pi/N,1,1,[]);M=ones(1,1,N);D=.4*M;K=9+.3*cos(2*psi);
r=dynamics.harmonic_balance(M,D,K,.7,3,1,12);
angle=(0:255)*2*pi/256;orders=r.orders.';E=exp(1i*orders*angle);z=r.coefficients(:).';
q=real(z*E);v=real((z.*(1i*.7*r.orders))*E);a=real((z.*(-(.7*r.orders).^2))*E);
residual=a+.4*v+(9+.3*cos(2*angle)).*q-cos(3*angle);
verifyLessThan(t,max(abs(residual)),1e-8);
end
function testFloquetDampedOscillator(t)
M=ones(1,1,16);D=.2*M;K=4*M;r=dynamics.periodic_stability(M,D,K,1,32);
verifyEqual(t,r.spectralRadius,exp(-.1*2*pi),'AbsTol',1e-12);
end
function testThreeBladeOrderSelection(t)
% Independent analytical selection rule used to interpret the load study.
psi=(0:127)'*2*pi/128;offsets=(0:2)*2*pi/3;
loads=2*cos(psi+offsets)+.1*cos(3*(psi+offsets));c=fft(sum(loads,2))/128;
verifyLessThan(t,2*abs(c(2)),1e-14);verifyEqual(t,2*abs(c(4)),.3,'AbsTol',1e-14);
end
