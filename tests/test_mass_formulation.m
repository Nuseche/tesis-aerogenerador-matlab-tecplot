function tests = test_mass_formulation
tests = functiontests(localfunctions);
end

function testConsistentIsDefault(testCase)
M = sparse([2 1;1 2]);
[actual,diagnostics] = assembly.apply_mass_formulation(M,struct());
verifyEqual(testCase,actual,M); verifyEqual(testCase,diagnostics.method,"consistent");
verifyFalse(testCase,diagnostics.usesAbsoluteValue);
end

function testRowSumIsExplicit(testCase)
M = sparse([2 1;1 2]); cfg.mass.formulation="row_sum";
actual = assembly.apply_mass_formulation(M,cfg);
verifyEqual(testCase,actual,sparse(diag([3 3])));
end

function testNegativeRowSumIsRejected(testCase)
M = sparse([1 -2;-2 5]); cfg.mass.formulation="row_sum";
verifyError(testCase,@() assembly.apply_mass_formulation(M,cfg), ...
    'assembly:apply_mass_formulation:NegativeRowSum');
end
