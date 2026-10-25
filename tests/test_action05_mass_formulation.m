function tests=test_action05_mass_formulation
tests=functiontests(localfunctions);
end

function testHrzConservesThreeRigidTranslationMasses(testCase)
dofMap=reshape(1:12,6,2).';
M=speye(12);
for direction=1:3
    dofs=dofMap(:,direction);
    M(dofs,dofs)=sparse([2 .5;.5 3]);
end
[Mh,diagnostics]=assembly.hrz_lump_mass(M,dofMap);
verifyTrue(testCase,isdiag(Mh));
verifyGreaterThanOrEqual(testCase,min(diag(Mh)),0);
verifyLessThanOrEqual(testCase,diagnostics.translationMassRelativeError,1e-15);
for direction=1:3
    t=zeros(12,1);t(dofMap(:,direction))=1;
    verifyEqual(testCase,t.'*Mh*t,t.'*M*t,'AbsTol',2e-15);
end
verifyFalse(testCase,diagnostics.usesAbsoluteValue);
end

function testHrzMustBeSelectedExplicitly(testCase)
M=speye(12);cfg.mass.formulation="hrz";
verifyError(testCase,@()assembly.apply_mass_formulation(M,cfg), ...
    'assembly:apply_mass_formulation:MissingDofMap');
dofMap=reshape(1:12,6,2).';
[Mh,diagnostics]=assembly.apply_mass_formulation(M,cfg,dofMap);
verifyTrue(testCase,isdiag(Mh));
verifyEqual(testCase,diagnostics.method,"hrz");
end

function testHrzRejectsNegativeMaterialDiagonal(testCase)
M=speye(12);M(4,4)=-1;
dofMap=reshape(1:12,6,2).';
verifyError(testCase,@()assembly.hrz_lump_mass(M,dofMap), ...
    'assembly:hrz_lump_mass:NegativeDiagonal');
end

function testSpatialBodyMassIsAddedAfterHrz(testCase)
modelData.mesh.nodes=struct('id',[1;2],'xyz',zeros(2,3));
modelData.dofs.node=reshape(1:12,6,2).';
distributed=speye(12);
body=struct('name',"offset",'masterNode',2,'mass',10, ...
    'cgOffsetBody',[0;2;0],'inertiaBody',diag([3 4 5]), ...
    'orientationBodyToGlobal',eye(3));
[total,report]=rigid.add_body_masses(distributed,modelData,body);
verifyFalse(testCase,isdiag(total));
verifyGreaterThan(testCase,norm(report.spatialMassMatrix(1:3,4:6),'fro'),0);
verifyEqual(testCase,full(total(modelData.dofs.node(2,:),modelData.dofs.node(2,:))), ...
    eye(6)+report.spatialMassMatrix,'AbsTol',1e-14);
end

function testCanonicalAction05Suite(testCase)
root=fileparts(fileparts(mfilename('fullpath')));
cfg=io.load_configuration(fullfile(root,'cases','config_action05_mass_formulation.m'));
data=io.load_model_data(cfg);modelData=model.build_model(data,cfg);
[Ma,Ke]=assembly.assemble_structural_matrices(modelData,cfg);
[Mcd,dc]=assembly.apply_mass_formulation(Ma,cfg,modelData);
hrzCfg=cfg;hrzCfg.mass.formulation="hrz";
[Mhd,dh]=assembly.apply_mass_formulation(Ma,hrzCfg,modelData);
[Mc,bc]=rigid.add_body_masses(Mcd,modelData,modelData.rigidBodies);
[Mh,bh]=rigid.add_body_masses(Mhd,modelData,modelData.rigidBodies);
[Tc,ci]=rigid.rigid_constraint_matrix(modelData,modelData.rigidBodies,cfg);
rc=rigid.reduce_system(Tc,Mc,Ke,modelData,cfg);
rh=rigid.reduce_system(Tc,Mh,Ke,modelData,cfg);
pc=rigid.compute_mass_properties(modelData,Mc,Tc);
ph=rigid.compute_mass_properties(modelData,Mh,Tc);
suite=validation.run_mass_formulation_suite(modelData,Ma,Mcd,Mhd,Mc,Mh, ...
    Ke,Tc,rc,rh,bc,bh,pc,ph,dc,dh,cfg);
verifyTrue(testCase,suite.passed);
verifyTrue(testCase,all([suite.checks.pass]));
verifyLessThanOrEqual(testCase,suite.metrics.hrzTranslationMassError,1e-12);
verifyLessThanOrEqual(testCase,suite.metrics.maxFrequencyRelativeDifference,.02);
verifyGreaterThanOrEqual(testCase,suite.metrics.minimumMatchedMAC,.9);
verifyLessThanOrEqual(testCase,suite.metrics.maximumModalResidual,1e-8);
verifyEqual(testCase,ci.slaveNodeIds,[21;57;93]);
end
