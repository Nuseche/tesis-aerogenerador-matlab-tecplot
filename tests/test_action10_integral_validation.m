function tests=test_action10_integral_validation
tests=functiontests(localfunctions);
end

function testExtendedMatrixPropertiesAndIdentities(testCase)
[ops,~,cfg]=baseFixture();
checks=validation.check_matrix_properties(ops,cfg);
verifyTrue(testCase,all([checks.pass]));
verifyTrue(testCase,any([checks.name]=="reduced.D.componentIdentity"));
verifyTrue(testCase,any([checks.name]=="reduced.K.componentIdentity"));
verifyTrue(testCase,any([checks.name]=="reduced.Cpassive.semidefinite"));
verifyTrue(testCase,any([checks.name]=="transformation.Tc.conditioning"));
end

function testNonsymmetricAerodynamicTangentsAreNotAltered(testCase)
[ops,~,cfg]=baseFixture();
KaeroBefore=ops.reduced.Kaero;CaeroBefore=ops.reduced.Caero;
checks=validation.check_matrix_properties(ops,cfg);
verifyTrue(testCase,all([checks.pass]));
verifyEqual(testCase,ops.reduced.Kaero,KaeroBefore);
verifyEqual(testCase,ops.reduced.Caero,CaeroBefore);
verifyGreaterThan(testCase,norm(KaeroBefore-KaeroBefore.','fro'),0);
verifyGreaterThan(testCase,norm(CaeroBefore-CaeroBefore.','fro'),0);
end

function testBadDIdentityAndRankDeficientTcAreDetected(testCase)
[ops,~,cfg]=baseFixture();
ops.reduced.D=ops.reduced.D+sparse(1,1,1,3,3);
ops.reduced.Tc=sparse([1 0;0 0;0 0]);
checks=validation.check_matrix_properties(ops,cfg);
dIdentity=checks([checks.name]=="reduced.D.componentIdentity");
rankCheck=checks([checks.name]=="transformation.Tc.fullColumnRank");
verifyFalse(testCase,dIdentity.pass);
verifyFalse(testCase,rankCheck.pass);
end

function testUnverifiedRequiredActionDoesNotPass(testCase)
[ops,results,cfg]=baseFixture();
cfg.action10.requiredActions=9;
cfg.action10.requireCanonicalArtifacts=false;
cfg.action10.requireModalEvidence=false;
cfg.action10.requireTimeHistory=false;
suite=validation.run_integral_acceptance_suite( ...
    struct(),ops,results,cfg);
item=suite.checks([suite.checks.name]=="action09.specializedSuite");
verifyEqual(testCase,item.status,"unverified");
verifyFalse(testCase,item.pass);
verifyFalse(testCase,suite.passed);
end

function testInMemorySuiteDoesNotImplyCanonicalArtifact(testCase)
[ops,results,cfg]=baseFixture();
cfg.action10.requiredActions=2;
cfg.action10.requireCanonicalArtifacts=true;
cfg.action10.requireModalEvidence=false;
cfg.action10.requireTimeHistory=false;
results.action02=passedSuite("action02.core");
suite=validation.run_integral_acceptance_suite( ...
    struct(),ops,results,cfg);
suiteItem=suite.checks([suite.checks.name]=="action02.specializedSuite");
artifact=suite.checks([suite.checks.name]=="action02.canonicalArtifact");
verifyEqual(testCase,suiteItem.status,"passed");
verifyEqual(testCase,artifact.status,"unverified");
verifyFalse(testCase,suite.passed);
end

function testIntegralFixturePassesWithExplicitAction08And09Evidence(testCase)
[ops,results,cfg]=positiveFixture();
suite=validation.run_integral_acceptance_suite( ...
    struct(),ops,results,cfg);
verifyTrue(testCase,suite.passed);
verifyEqual(testCase,suite.unverifiedCount,0);
verifyTrue(testCase,all(ismember(unique(suite.requirementTable.status), ...
    ["passed";"not_applicable"])));
spectrum=suite.checks([suite.checks.name]=="modal.spectrumScopeDeclared");
verifyTrue(testCase,spectrum.pass);
verifyEqual(testCase,spectrum.value,0); % Explicitly partial is acceptable.
end

function testCanonicalRunIsReloadedAndHashed(testCase)
folder=tempname;mkdir(folder);cleanup=onCleanup(@()rmdir(folder,'s')); %#ok<NASGU>
results=struct('action02',passedSuite("action02.core")); %#ok<NASGU>
save(fullfile(folder,'results.mat'),'results');
manifest=struct('schemaVersion',"1.0.0",'hasAction02',true, ...
    'action02Passed',true); %#ok<NASGU>
save(fullfile(folder,'manifest.mat'),'manifest');
schemaVersion="1.0.0";action02Results=results.action02; %#ok<NASGU>
save(fullfile(folder,'action02_matrices.mat'), ...
    'schemaVersion','action02Results');
fid=fopen(fullfile(folder,'SUCCESS'),'w');
assert(fid>=0);fprintf(fid,'SUCCESS\n');fclose(fid);

[ops,current,cfg]=baseFixture();
cfg.action10.requiredActions=2;
cfg.action10.requireCanonicalArtifacts=true;
cfg.action10.requireHashes=true;
cfg.action10.requireModalEvidence=false;
cfg.action10.requireTimeHistory=false;
evidence.runFolders.action02=string(folder);
suite=validation.run_integral_acceptance_suite( ...
    struct(),ops,current,cfg,evidence);
verifyTrue(testCase,suite.passed);
row=suite.artifactTable(suite.artifactTable.action==2,:);
verifyTrue(testCase,row.complete);
verifyTrue(testCase,row.hashVerified);
verifyEqual(testCase,strlength(row.resultsSha256),64);
verifyEqual(testCase,strlength(row.manifestSha256),64);
verifyEqual(testCase,strlength(row.matricesSha256),64);
source=suite.evidenceTable(suite.evidenceTable.action==2,:);
verifyEqual(testCase,source.source,"canonical_run");
end

function testAction10ExporterWritesReloadableTables(testCase)
[ops,results,cfg]=positiveFixture();
suite=validation.run_integral_acceptance_suite( ...
    struct(),ops,results,cfg);
folder=tempname;mkdir(folder);cleanup=onCleanup(@()rmdir(folder,'s')); %#ok<NASGU>
artifacts=post.export_action10(struct('folder',folder),suite);
files=["action10_requirement_matrix.csv","action10_matrix_properties.csv", ...
    "action10_evidence.csv","action10_artifacts.csv"];
for index=1:numel(files)
    verifyTrue(testCase,isfile(fullfile(folder,files(index))));
end
reloaded=readtable(fullfile(folder,files(1)),'TextType','string');
verifyEqual(testCase,height(reloaded),height(artifacts.requirements));
verifyTrue(testCase,any(reloaded.name=="time.energyBalance"));
end

function testAction10CasePinsAcceptedCanonicalAction09(testCase)
root=fileparts(fileparts(mfilename('fullpath')));
cfg=io.load_configuration(fullfile(root,'cases', ...
    'config_action10_full_acceptance.m'));
verifyEqual(testCase,cfg.analysis.type,"action10_full_acceptance");
verifyTrue(testCase,endsWith(cfg.action10.canonicalRuns.action09, ...
    "run_20260831_163238_997_action09_seismic_newmark"));
verifyEqual(testCase,cfg.action10.status, ...
    "ready_for_action10_integration_and_run");
verifyTrue(testCase,cfg.action10.requireHashes);
end

function testPhasedGlobalValidationSeparatesSolveEvidence(testCase)
[ops,results,cfg]=baseFixture();
ops.reduced=rmfield(ops.reduced,'Tc');
cfg.analysis.type="action03"; % Skip the unrelated rigid-mode gate.
badResults=results;badResults.time=struct('q',NaN,'qd',0,'qdd',0, ...
    'energy',struct('relativeBalanceError',0));
pre=validation.run_validation_suite(struct(),ops,badResults,cfg,"preflight");
post=validation.run_validation_suite( ...
    struct(),struct(),badResults,cfg,"postflight");
verifyTrue(testCase,pre.passed);
verifyFalse(testCase,post.passed);
verifyFalse(testCase,any(startsWith([pre.checks.name],"time.")));
verifyTrue(testCase,any(startsWith([post.checks.name],"time.")));
end

function [ops,results,cfg]=positiveFixture()
[ops,results,cfg]=baseFixture();
cfg.action10.requiredActions=[8 9];
cfg.action10.requireCanonicalArtifacts=false;
cfg.action10.requireModalEvidence=true;
cfg.action10.requireTimeHistory=true;
results.action08=passedSuite([ ...
    "qep.maximumRightResidual","qep.maximumLeftResidual", ...
    "qep.conjugatePairs","qep.biorthogonality", ...
    "tracking.minimumEffectiveMAC","tracking.minimumSubspaceMAC", ...
    "mbc.zeroSpeedConservativeEquivalence"]);
results.action09=passedSuite([ ...
    "response.absoluteKinematics","constraints.projectedEquilibrium", ...
    "constraints.supportRowsSeparated", ...
    "elements.localGlobalBackwardError","elements.globalAssembly", ...
    "response.energyBalance","convergence.monotoneWaveformDifference", ...
    "convergence.modelTemporalOrder", ...
    "convergence.fineRelativeDifference", ...
    "convergence.fineMaximumDifference"]);
labelsA=struct('labels',["tower";"blade"]);
labelsB=struct('labels',["tower";"drivetrain"]);
results.modal=struct('frequencyHz',[1 2;1.1 2.1], ...
    'classification',{{labelsA,labelsB}}, ...
    'solutions',{{struct('spectrumComplete',false), ...
    struct('spectrumComplete',false)}});
results.time=struct('q',zeros(2,3),'qd',zeros(2,3), ...
    'qdd',zeros(2,3), ...
    'energy',struct('relativeBalanceError',zeros(1,3)));
end

function [ops,results,cfg]=baseFixture()
n=3;M=spdiags([2;3;4],0,n,n);
Cpassive=spdiags([.1;.2;.3],0,n,n);
Caero=sparse([0 .04 0;-.01 0 0;0 0 0]);
C=Cpassive+Caero;G=sparse([0 2 0;-2 0 .3;0 -.3 0]);
Ke=spdiags([10;12;14],0,n,n);Kg=sparse(n,n);
KOmega=spdiags([.2;.3;.4],0,n,n);
Kaero=sparse([0 .5 0;-.2 0 0;0 0 0]);
ops.reduced=struct('M',M,'C',C,'G',G,'D',C+G, ...
    'Ke',Ke,'Kg',Kg,'KOmega',KOmega,'Kaero',Kaero, ...
    'Caero',Caero,'K',Ke+Kg+KOmega+Kaero,'Tc',speye(n));
results=struct('input',struct('validation',struct('passed',true)));
cfg=struct();cfg.validation=struct('failOnCritical',false, ...
    'matrixTolerance',1e-12,'skewTolerance',1e-12, ...
    'positiveTolerance',1e-12,'matrixIdentityTolerance',1e-12, ...
    'transformationRcondTolerance',1e-12, ...
    'requireSparseOperators',true,'requireEnergyBalance',true, ...
    'energyTolerance',1e-8);
cfg.action10=struct('requiredActions',[],'requireCanonicalArtifacts',false, ...
    'requireHashes',false,'requireModalEvidence',false, ...
    'requireTimeHistory',false,'canonicalRuns',struct());
cfg.drivetrain.calibrationStatus="numerical_benchmark_not_physical";
cfg.damping.calibrationStatus="numerical_benchmark_not_physical";
cfg.aerodynamics.status="zero_unprovided_physical_coefficients";
end

function suite=passedSuite(names)
names=string(names(:));
checks=repmat(struct('name',"",'pass',true,'value',0, ...
    'tolerance',1,'message',"fixture",'critical',true),numel(names),1);
for index=1:numel(names),checks(index).name=names(index);end
suite=struct('schemaVersion',"1.0.0",'checks',checks, ...
    'passed',true,'criticalFailures',checks([]));
end
