# Periodic response and modal enrichment campaigns

Run MATLAB from the repository root with the project inputs available. The study uses fixed-base structural equations and prescribed mechanical loads. The archived comparison is relative to the discretized linear turbine.

```matlab
addpath('tools')
run_periodic_load_campaign('all')
run_periodic_load_campaign('angular')
run_periodic_load_campaign('sweep')
summarize_periodic_interaction
verify_periodic_load_recovery
% Generate the stationary full histories once if global_raw_data.mat is absent.
% run_rom_benchmark("all")
run_load_enrichment_benchmark
check_load_enrichment_transfer
check_support_moment_mesh
```

Run `python3 tools/build_periodic_load_figure.py` after the speed sweep. Generated results live under `runs/periodic_loads_20261118` and `runs/load_enrichment_20261118`. For a new configuration use a separate output folder or regenerate the operator cache. The speed sweep uses H=6 and the five comparison points use H=12 for the full reference and H=9 for reduced periodic solutions.

Periodic output channel numbers are 1 hub axial displacement, 2 nacelle axial displacement, 3 blade-1 tip displacement projected onto the shaft direction, 4 base moment about global Y, 5 base moment about global X, 6 and 7 incremental elastic root end moments about blade-1 sectional axes 2 and 3. Load numbers 1 and 2 denote unit 3P hub force along the shaft and global Y, respectively. Displacements have units m/N and moments N m/N. All physical recovery maps retain their angular dependence. The averaging experiment changes the equations of motion. Averaged-only errors near a vanishing output are sensitive to normalization.

In errors.csv historyErrorPercent always uses the periodic full reference. averagedROMErrorPercent compares the averaged member of that basis family with the full averaged model. interaction.csv contains the signed factorial contrast evaluated before taking norms. verification_collocation.csv reports relative differences as fractions. angular_check.csv and harmonic_convergence.csv report percentages. The angular refinement and independent collocation use selected speeds. The pole diagnostic is a direct harmonic calculation for a stationary beam assembly. Reported timings in the manuscript come from the repeated stationary campaign. The full periodic per-run timing log is diagnostic.

The [archived numerical results](../data/reference/structural-load-campaigns-20261118.zip) contain the CSV tables, stationary response histories, repeated timings and verification results for the manuscript.

### Rotating-mesh check at the 3P reaction peak

From MATLAB run `run_periodic_load_campaign('mesh_closure')` with the tools directory on the path. Each parent beam is bisected with the same section, and corresponding new stations on the three blades enter the multiblade transformation. Geometry, hub loading, mechanical interfaces and Rayleigh coefficients are common to both meshes. The check records the mass under rigid translation and the number of rotating nodes. At each speed the two complete spatial models use the same angular sampling and harmonic resolution. The direct comparison at 3.4445 rpm also uses the H=12 reference.

Run `python3 tools/summarize_rotating_mesh.py` to generate the band table. Peak locations are sampled speeds. Each half-power crossing is linearly interpolated in amplitude at the maximum divided by the square root of two. The width is a rotor-speed interval. The reaction phase is relative to the axial cosine hub force. In rotating_mesh_sweep.csv, channel 4 is the base reaction about global Y and historyErrorPercent is relative to the complete periodic solution on the same mesh.

The additional MATLAB mode `run_periodic_load_campaign('mesh_532')` applies a second bisection, sweeps the averaged equations at 0.002 rpm intervals from 3.30 to 3.80 rpm and solves the periodic equations at 3.394 and 3.4445 rpm with H=6 and 12. The 532-element periodic data are individual checks; only the two coarser meshes provide a periodic peak location and bandwidth.

### Correction of the 3P base moment near resonance

The [correction tables](../data/reference/periodic-correction.zip) report three distinct tests under prescribed axial hub forcing. The source tables vary one family of transformed operators at a time. The response-order tables retain the full spatial system and vary the set of coupled response orders. The snapshot tables retain the full harmonic system and reduce the spatial basis. History errors use the norm over one revolution relative to the complete periodic H=12 solution on the same mesh. The dense sweep checks the 3P phasor against the archived H=6 sweep. Timing excludes Fourier preprocessing.

After the rotating mesh sweep, run the following from the repository root in MATLAB with the project paths initialized.

```matlab
for mode = ["correct_266","correct_532","correct_peak532","correct_source266","correct_source532","correct_sweep266"]
    run_periodic_load_campaign(mode);
end
out = fullfile(pwd,'runs','periodic_loads_20261118');
check_3p_response_orders();
for n = [266 532]
    data = load(fullfile(out,sprintf('correctionOperators%d.mat',n)),'F');
    check_3p_response_orders(data.F,n,out);
end
data = load(fullfile(out,'correctionOperators266.mat'),'F');
check_3p_response_orders(data.F,266,out,"sweep");
check_3p_response_orders(data.F,266,out,"timing");
check_periodic_snapshot_basis(133);
check_periodic_snapshot_basis(266);
check_periodic_snapshot_basis(133,1e-12);
```

On 266 elements at 3.4445 rpm, averaging only the transformed elastic stiffness reproduces the 199.96% error. Restoring its periodic coefficients in the averaged equations gives 0.626%. Retaining the complete periodic operators and five response orders around positive 3P gives 0.000043% after conjugate reconstruction. These figures quantify the effect of the approximation on the base moment for this excitation.
