# Numerical studies

These drivers organize numerical experiments around the same solver packages.
They follow geometry/properties, equilibrium/assembly, solution, and verification.
Run MATLAB commands from the repository root and add only the selected study
folder to the path. Do not use `genpath` on the entire repository: the preserved
original source tree contains independent historical implementations.

New runs default to `runs/studies/<study>`. Pass an absolute campaign directory
to repeat a study elsewhere. Saved campaigns are reusable only with their
original source fingerprint. The archived `runs/sensitivity/*_202610*` directories
remain available for reading after [data restoration](../docs/setup.md).

## Local sensitivity

```matlab
addpath('studies/local_sensitivity');
run_local();
run_verifications();
run_connections();
run_temporal_parameters();
postprocess_checks();
modal_energy_evidence();
make_local_sensitivity_figures();
```

The drivers separate central differences, tracking, empirical noise controls,
time-step checks and connection sensitivity. `run_equilibrium_floor_probe`
examines the equilibrium tolerance floor. `reprocess_tracking(folder)` updates
tracking summaries from saved cases without rerunning the structural solution.
Historical reconstruction uses `runs/sensitivity/initial_20261005` as `folder`.
Generated MAT, CSV, JSON and figures are not versioned.

## Morris screening

```matlab
addpath('studies/morris');
run_morris();
export_morris_results();
```

The physical-factor ranges, trajectory design, cumulative computational budget,
and numerical acceptance rules are defined in `sensitivity.config_morris`.
The export reads campaign results and writes derived tables and metadata.
`report_data.json` in this source folder is a frozen reference from the archived
campaign, used by historical Tecplot plots. A new export writes its metadata in
the campaign directory and does not replace that reference.

## Parameter-grid contrasts

This is a specific extension of the archived Morris design: 58 distinct grid
points are reused, six missing vertices and three controls are computed. It is
not a general grid generator for arbitrary Morris campaigns.

```matlab
addpath('studies/parameter_grid/scripts');
complete_grid();
```

```sh
python studies/parameter_grid/scripts/analyze_grid.py
# To read the archived completed grid instead of computing it:
python studies/parameter_grid/scripts/analyze_grid.py \
  --runs runs/sensitivity/grid_completion_20261014
```

`--morris`, `--metadata`, and `--output` select explicit source and destination
paths. The analysis verifies analytical contrast identities and saved numerical
residuals, and reports how many current sources match recorded historical
hashes. Reorganization changes source hashes; it does not change saved results.
Output defaults to `output/parameter_grid`. Plot that output with
`make_parameter_grid_figures(analysisFolder, gridFolder)` in MATLAB. Exact
historical solver reconstruction uses the baseline Git tag.

## Measured input studies

The raw earthquake records, selected wind archive member, provenance and SI
input tables are versioned. `fetch_inputs.py` downloads source records;
`prepare_earthquakes.py` and `prepare_wind.py` regenerate the SI tables. Download
and conversion are optional when using the included tables.

```matlab
addpath('studies/measured_inputs/scripts');
run_comparison();
run_aligned();
refine_local_steps();
analyze_comparison();
make_measured_input_figures();
run_refined_tangent();
analyze_refined_tangent();
make_tangent_sensitivity_figure();
```

The response drivers share a cumulative computational budget and reuse completed
cases in the selected campaign. Analyses require the relevant phases to have
completed; they do not silently fill missing results. To inspect the complete
historical campaign, pass `runs/sensitivity/real_inputs_20261020` to the analysis
and response-figure functions. Derived tables and figures are written under this
study directory and ignored by Git. `make_tangent_sensitivity_figure` reads those
derived tables and takes no campaign argument.

`verify_combination` checks superposition, `verify_kernel_identity` compares the
diagnostic force kernel against the active implementation, and `diagnose_tangent`
examines finite-difference tangent sensitivity. The diagnostic kernel is retained
because it permits controlled derivative-step changes without changing the
production element. Measured wind is a prescribed thrust proxy; it is not a
coupled aerodynamic simulation. See [scientific scope](../docs/verification.md).

## Aeroelastic operating-condition comparison

```matlab
addpath('studies/aeroelastic');
report = run_maza_comparison();
```

This study compares three isolated-blade operating conditions with Maza et al.
(2023). It contrasts weak coupling with prescribed loads and halves the time step.
Published values are another model's results, not fitting targets or absolute
truth. Partial trajectories that reach the declared rotation limit are saved and
labelled explicitly; they do not receive steady-state summary values. See
[coupling and interpretation](../docs/aeroelasticity.md).
