# Verification and scientific scope

The cleanup baseline and the reorganized tree both passed 160 MATLAB tests
(0 failed, 0 incomplete) with MATLAB R2026a on 2026-11-16.
The suite covers data loading, beam operators, mass, rigid bodies, kinematic
constraints, equilibrium, moving frames, QEP/MBC, Newmark, reaction recovery,
energy consistency and sensitivity calculations.

Run the suite with `addpath('tests'); run_all_tests();`. Its MAT report is a
local generated output. `python tools/check_repository.py` verifies source/input
checksums, current MATLAB filenames, local documentation links and duplicate
maintained sources without starting MATLAB or Tecplot.

## Numerical comparison tools

Add `tools` and `cases` to the MATLAB path before direct calls.

| Function | Evidence |
| --- | --- |
| `run_rom_benchmark` | Beam-theory comparisons, stationary ROM response errors and computational cost |
| `run_mesh_refinement` | Piecewise-section mesh refinement without inventing new geometry |
| `analyze_rigid_modes` | Rigid-motion and stiffness-kernel diagnostics |
| `export_rigid_mode_evidence` | Primitive/global free and fixed-base evidence |
| `export_operating_evidence` | JSON extraction from existing corrected operating and seismic snapshots |
| `compare_gyroscopic_runs` | Comparison of persisted operator and mode data |
| `compare_seismic_revision` | Comparison of persisted physical response channels |

Some historical benchmark tools use fixed historical run IDs and refuse an
existing destination. Run exact reproductions in a fresh clone, or pass an
explicit output directory where the function supports it. Do not overwrite
accepted run data to refresh figures.

## Interpretation

Mesh/time resolution, beam-theory differences and modal truncation are separate
comparisons. A ROM is compared with the same full discretized model, input and
time step. The stationary benchmark has no gravity or preload. Its accepted
orders and timing factors do not automatically apply to rotating cases.

The corrected operating sweep uses equilibrium under gravity, moving-coordinate
terms and a frozen-azimuth MBC quadratic eigenproblem. Tracking a selected set
of roots is not periodic stability analysis. Transient recovery retains the
transformation derivatives. Measured seismic/wind records are prescribed inputs;
they are not measurements validating an installed turbine. The wind proxy is a
parameterized hub thrust, without aerodynamic feedback.

Study scripts retain resolution and signal/noise checks. Unresolved derivatives
are not changed to zero or reclassified as accepted results. See
[study reproduction](../studies/README.md).

## Reorganization checks

- MATLAB syntax analysis covered the maintained function and study sources.
- A clean export of the staged tree passed all 13 data/model tests and ran
  `main()` without archived runs or the original checkout on its MATLAB path.
- All 27 manifest hashes matched; 37 retained original/evidence files were also
  compared byte for byte with the pre-cleanup inventory.
- Four seismic SI tables and the wind SI table were regenerated in a temporary
  directory and were byte-identical to the versioned inputs.
- Tecplot preparation produced 88 datasets/macros. The 87 retained numerical
  and geometry datasets match their previous numerical rows exactly; the
  remaining dataset is the reorganized Morris workflow schematic.
- The archived 64-point grid analysis and measured-input postprocessing ran
  using explicit historical campaign locations.

These checks do not constitute a new licensed Tecplot native export or a rerun
of the full sensitivity campaigns. Numerical result files were preserved.
