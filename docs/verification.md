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

## Nonlinear reference campaign received on 18 November 2026

The six external `12_NG_NA_NS_R_*_DASHPOT` folders are read in place, without
executing their MATLAB or batch scripts. Reproduce the inventory and signal audit:

```sh
python tools/audit_nonlinear_reference.py --source /path/to/Downloads
python -m unittest discover -s tests -p 'test_nonlinear_reference_reader.py'
```

The default destination is `output/nonlinear_reference`. `audit.json` records
source hashes, record dimensions and comparisons with existing ASCII exports;
`case_summary.csv` records speed statistics, tower-top excursions and stage-5
CPU times. `support_spectral_peaks.csv` and `support_spectra.npz` contain
consistently processed tower-top, nacelle and hub spectra. Original external
datasets and derived outputs are not copied into the source repository.

All six decks share the active model except the initial spin amplitude and
subsequent driving torque. Nominal speeds are 0, 0.3, 0.5, 0.6, 0.7 and 0.9 rad/s.
The tower base (400000) is fixed in all six coordinates. Gravity and aerodynamic
activation are commented out. A one-second pulse at nacelle node 2 starts at
20 s; all six point-load entries are `1e7`. The last three entries belong to
rotational coordinates; their frame convention must be matched before load
replay. This is a substantial transient, not an infinitesimal modal test:
maximum tower-top X excursions range from 4.19 to 4.77 m across these cases.

The initial prescribed velocity is removed at 5 s. A constant torque then acts
at hub node 1. Its magnitude is `6.65e6` times the nominal speed; the generator
section has `RDAMPI = 6.65e6`. The deck also specifies material `VISCO = 9e8`
for tower/transition and `1.5274e9` for blades, plus stage-dependent `DAMP_SET`
entries for tower/transition. These are not the existing MHT Rayleigh law;
matching their operators requires the SIMPACT constitutive and damping
definitions, not equating these input numbers to a modal damping ratio.

| Nominal speed (rad/s) | Mean hub spin output component, 100--1100 s (rad/s) |
| --- | --- |
| 0.0 | 0.00002775 |
| 0.3 | -0.29992789 |
| 0.5 | -0.50001289 |
| 0.6 | -0.59999126 |
| 0.7 | -0.69997703 |
| 0.9 | -0.89988767 |

The spin component fluctuates: standard deviations are 0.000345--0.000473 rad/s.
Its sign is the source convention. Constant-speed MHT calculations therefore
constitute a nearby operating-state approximation, not identical rotor motion.

### Node and signal interpretation

| Source node | Physical point | Current MHT node |
| --- | --- | --- |
| 400000 | Tower base | 1 |
| 400019 (file alias 4019) | Tower top, initially (0, 0, 135) m | 20 |
| 2 | Nacelle master | 129 |
| 1 | Hub master | 130 |
| 100035, 200035, 300035 | Blade tips (aliases 1035, 2035, 3035) | 56, 92, 128 |

This is a physical-point mapping, not yet an equivalence proof for geometry,
section operators, rigid offsets or output frames. In particular, files labelled
4019 must not be presented as hub displacement. Blade global displacements
contain gross rotor motion; their FFT peaks cannot all be identified as elastic
natural frequencies. Euler parameters in `p11` must not be subtracted directly
or interpreted as infinitesimal elastic rotations.

The sequential binary streams contain displacement/Euler output (`p11`),
velocity (`p19`), acceleration (`p20`) at ten nodes, and internal output (`p12`)
at eight nodes. Each has 110001 samples over 0--1100 s, with output spacing near
0.01 s. This is output sampling, not the explicit integration time step.
The reader checks every Fortran record boundary and preserves source node order.
All 115 available nodal-displacement ASCII exports agree to their printed
precision. Of ten hub-velocity exports, eight agree; case 07 `v4.dat` and
`v5.dat` do not match the corresponding binary histories. Use binary output for
this audit. The missing blade-2 ASCII histories in case 03 are present in `p11`;
no additional export is needed. Internal-output signs and reaction interpretation
remain separate from identifying its numeric record layout.

### Spectral processing and use in the article

The supplied FFT scripts use `1/(t_end-t_start)` as their frequency spacing,
whereas a uniformly sampled DFT uses `1/(N*dt)`. They also retain the forcing
interval in their 20--1100 s window. The new support spectra use a common
25.01--1099.99 s grid at 0.01 s, linear interpolation of the slight timestamp
jitter, mean removal, a rectangular window and explicit DFT normalization.
The bin spacing is approximately 0.00093024 Hz. These are response spectra,
not force-normalized FRFs or automatically tracked eigenmodes. Differences
between windows, printed frequency rounding and preprocessing must not be
reported as structural-model discrepancies.

The manuscript's main contribution is the assembled structural model: beam
kinematics and constitutive law, rigid bodies and nodal compatibility, prescribed
rotor motion and consistent transport terms, then solution and recovery.
Verification supports that construction before Campbell/order analyses,
sensitivity, forced response and ROM efficiency demonstrate its use. Matching
frequencies supports the effective stiffness--inertia description at matched
states; modal participation, damping and representative time histories provide
additional evidence for forced responses. Neither frequency agreement nor
agreement with another numerical model validates every parameter range.

These six folders supply structural spin/pulse cases, not the gravity/wind
startup case in the separate nonlinear article. CPU logs cover the fifth stage
only (2916--3030 s); without common hardware, solver workload and output policy,
they do not establish an MHT/nonlinear speedup. The audit changes no MHT physical
parameters and introduces no fitted agreement or nonlinear comparison claims
into the manuscript.
