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
