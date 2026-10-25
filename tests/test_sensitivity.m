function tests=test_sensitivity
tests=functiontests(localfunctions);
end
function testDensityPreservesLinkedInertias(t)
s=sensitivity.config_local();d=io.load_model_data(s.nominal);
[d2,c]=sensitivity.apply_parameters(d,s.nominal,struct('blade_density',1.1,'hub_density',0.9));
a=model.build_model(d,s.nominal);b=model.build_model(d2,c);
verifyEqual(t,[b.sections(21:end).m],1.1*[a.sections(21:end).m],'RelTol',1e-12);
verifyEqual(t,[b.sections(21:end).Jx],1.1*[a.sections(21:end).Jx],'RelTol',1e-12);
verifyEqual(t,[b.sections(21:end).Jx],[b.sections(21:end).Jy]+[b.sections(21:end).Jz],'RelTol',1e-12);
verifyEqual(t,[b.sections(1:20).m],[a.sections(1:20).m]);
verifyEqual(t,d2.sections(21).rawMassColumns,d.sections(21).rawMassColumns);
verifyEqual(t,b.rigidBodies.bodies(2).inertiaBody,0.9*a.rigidBodies.bodies(2).inertiaBody,'RelTol',1e-12);
verifyEqual(t,b.rigidBodies.bodies(2).mass,0.9*a.rigidBodies.bodies(2).mass,'RelTol',1e-12);
end
function testStiffnessScalingKeepsMass(t)
s=sensitivity.config_local();d=io.load_model_data(s.nominal);
[d2,~]=sensitivity.apply_parameters(d,s.nominal,struct('tower_stiffness',1.1));
verifyEqual(t,[d2.sections.m],[d.sections.m]);
verifyEqual(t,[d2.sections(1:20).EA],1.1*[d.sections(1:20).EA],'RelTol',1e-12);
verifyEqual(t,[d2.sections(21:end).EA],[d.sections(21:end).EA]);
end
function testRejectsInvalidAndInactiveParameters(t)
s=sensitivity.config_local();d=io.load_model_data(s.nominal);
verifyError(t,@()sensitivity.apply_parameters(d,s.nominal,struct('blade_density',-1)),'sensitivity:InvalidFactor');
verifyError(t,@()sensitivity.apply_parameters(d,s.nominal,struct('invented',1)),'sensitivity:UnknownParameter');
verifyError(t,@()sensitivity.apply_parameters(d,s.nominal,struct('foundation_stiffness',1)),'sensitivity:InactiveFoundation');
end
function testNormalizationAtZeroAndSignChange(t)
a=sensitivity.central_difference(0,-0.01,0.01,0.01,2);verifyEqual(t,a.sensitivity,0.5,'AbsTol',1e-14);
verifyEqual(t,a.normalization,"fixed_reference_scale");
b=sensitivity.central_difference(0.001,-0.009,0.011,0.01,1);verifyEqual(t,b.scale,1);
c=sensitivity.central_difference(2,1.98,2.02,0.01,2);verifyEqual(t,c.sensitivity,1,'AbsTol',1e-12);
end
function testComplexCrossingAndPhase(t)
s=sensitivity.config_local();s.branches=2;s.clusterTolerance=0.001;
a=struct('solution',struct('fullModes',eye(2),'eigenvaluesQEP',[-.1+1i;-.2+2i]),'fullMass',eye(2));
b=struct('solution',struct('fullModes',[1i*[0;1],exp(1i*.7)*[1;0]], ...
    'eigenvaluesQEP',[-.2+.8i;-.1+2.2i]),'fullMass',eye(2));
tr=sensitivity.track_modes(a,b,s);verifyEqual(t,tr.assignment,[2;1]);
verifyEqual(t,tr.individualMAC,[1;1],'AbsTol',1e-14);verifyTrue(t,all(tr.individualValid));
end
function testRepeatedComplexGroup(t)
s=sensitivity.config_local();s.branches=2;
a=struct('solution',struct('fullModes',eye(2),'eigenvaluesQEP',[-.1+1i;-.1+1i]),'fullMass',eye(2));
b=a;b.solution.fullModes=[1 1;1 -1]/sqrt(2);
tr=sensitivity.track_modes(a,b,s);verifyEqual(t,tr.subspaceMAC,[1;1],'AbsTol',1e-14);
verifyFalse(t,any(tr.individualValid));verifyEqual(t,tr.groupSize,[2;2]);
end
function testRefinementPreservesGeometryMassAndRoots(t)
s=sensitivity.config_local();a=model.build_model(io.load_model_data(s.nominal),s.nominal);
b=sensitivity.refine_model(a,2);
verifyEqual(t,b.mesh.nodes.xyz(1:size(a.mesh.nodes.xyz,1),:),a.mesh.nodes.xyz);
verifyEqual(t,numel(b.mesh.elements.id),2*numel(a.mesh.elements.id));
verifyEqual(t,b.rigidBodies.constraints,a.rigidBodies.constraints);
[M,~,~,~]=assembly.assemble_structural_matrices(a,s.nominal);
[N,~,~,~]=assembly.assemble_structural_matrices(b,s.nominal);
u=zeros(size(M,1),1);v=zeros(size(N,1),1);u(1:6:end)=1;v(1:6:end)=1;
verifyEqual(t,u'*M*u,v'*N*v,'RelTol',1e-12);
end
function testRigidShapeAuditHonorsSupports(t)
md=struct('mesh',struct('nodes',struct('xyz',[0 0 0;0 0 1])), ...
    'dofs',struct('node',reshape(1:12,6,2).','fixed',[]));
u=zeros(12,1);u([1 7])=1;M=eye(12);K=zeros(12);
a=sensitivity.rigid_audit(md,u,M,K);verifyTrue(t,a.rigidCandidate);
md.dofs.fixed=(1:6).';b=sensitivity.rigid_audit(md,u,M,K);verifyFalse(t,b.rigidCandidate);
end
function testSHA256(t)
verifyEqual(t,sensitivity.sha256('abc'), ...
    "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad");
end
function testFailuresArePersistedAndResumeRejectsChanges(t)
s=sensitivity.config_local();s.outputRoot=string(tempdir);folder=tempname;
mkdir(folder);cleanup=onCleanup(@()rmdir(folder,'s')); %#ok<NASGU>
d=struct('id',"invalid",'factors',struct('unknown',1),'options',struct());
c=sensitivity.run_campaign(s,d,folder);verifyEqual(t,c.status.status,"failed");
verifyError(t,@()sensitivity.read_case(folder,'invalid'),'sensitivity:FailedCase');
c2=sensitivity.run_campaign(s,d,folder);verifyEqual(t,c2.status.status,"failed");
s.seed=s.seed+1;verifyError(t,@()sensitivity.run_campaign(s,d,folder),'sensitivity:ResumeMismatch');
end
function testExplicitBudget(t)
s=sensitivity.config_local();s.maxCases=0;
d=struct('id',"nominal",'factors',struct(),'options',struct());
verifyError(t,@()sensitivity.run_campaign(s,d,tempname),'sensitivity:BudgetExceeded');
end

function testSpectralBoundaryRejectsTruncatedGroups(t)
s=sensitivity.config_local();s.branches=2;
a=struct('solution',struct('fullModes',eye(3), ...
    'eigenvaluesQEP',[-.1+1i;-.1+2i;-.1+2.05i]),'fullMass',eye(3));
tr=sensitivity.track_modes(a,a,s);
verifyEqual(t,tr.boundaryAmbiguous,[false;true]);
verifyTrue(t,tr.individualValid(1));verifyFalse(t,tr.individualValid(2));
end
