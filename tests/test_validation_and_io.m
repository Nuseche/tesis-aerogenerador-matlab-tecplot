function tests = test_validation_and_io
tests = functiontests(localfunctions);
end

function testMatrixChecks(testCase)
ops.reduced.M = speye(8);
ops.reduced.Ke = spdiags((1:8).',0,8,8);
ops.reduced.K = ops.reduced.Ke;
ops.reduced.G = sparse([0 2;-2 0]);
checks = validation.check_matrix_properties(ops, struct());
verifyTrue(testCase, all([checks.pass]));
end

function testDetectBadGyroscopicMatrix(testCase)
ops.reduced.M = speye(2); ops.reduced.Ke = speye(2); ops.reduced.G = speye(2);
checks = validation.check_matrix_properties(ops, struct());
item = checks([checks.name] == "reduced.G.skewSymmetry");
verifyFalse(testCase, item.pass);
end

function testRunFolderIsUnique(testCase)
root = tempname; mkdir(root); cleaner = onCleanup(@() rmdir(root,'s')); %#ok<NASGU>
cfg.paths.projectRoot = root; cfg.analysis.type = "unit_test";
runA = io.create_run_folder(cfg); runB = io.create_run_folder(cfg);
verifyTrue(testCase,isfolder(runA.folder)); verifyTrue(testCase,isfolder(runB.folder));
verifyNotEqual(testCase,runA.folder,runB.folder);
end
