# Evidence extraction for the structural-model manuscript

The manuscript repository contains only its self-contained LaTeX source. This
repository retains the extraction procedure; generated numerical tables belong
in `output/structural_paper`, which is ignored by Git. The extractor reads
existing runs and the audited nonlinear streams without running external scripts,
changing model parameters, or overwriting accepted campaign data.

## Reproduce

Use Python 3.12 with NumPy and SciPy (the existing `.venv-tecplot` has both):

```sh
.venv-tecplot/bin/python tools/build_structural_paper_evidence.py \
  --nonlinear-source /path/to/nonlinear/campaign/parent \
  --archive /path/to/previous/manuscript/data
```

`--archive` is optional. When supplied it verifies the SHA-256 hashes of used
historical source files against the previous manuscript's provenance ledger.
The source data themselves are read from this code repository's restored runs,
not silently substituted from the old manuscript. `--output` selects another
output directory. Restore historical runs as described in [setup](setup.md).

The output contains CSV tables, equivalent `.pgfdata` table bodies for embedding
inside `main.tex`, compact stationary-condition metadata, and `provenance.json`.
The latter records each consumed file's SHA-256, each table's operation and row
count, the extraction commit, and hash comparison outcomes. Generated plots must
retain the distinction between the campaigns below.

## Campaign boundaries

| Campaign | Conditions and admissible claims |
| --- | --- |
| Stationary, 14 September | Fixed base, 804 independent coordinates; zero spin, gravity and prestress; inherited illustrative drivetrain; Rayleigh damping of 1% at 0.2 and 2 Hz; prescribed synthetic support motion over 8 s at dt=0.0025 s. Beam, mesh, response and ROM-cost evidence. |
| Morris, 6 October | Frozen-azimuth MBC quadratic eigenproblem; gravity equilibrium recalculated; 10.8--13.2 rpm; blade mass/inertia and all sectional stiffness factors 0.9--1.1. Historical frequency-group sensitivity, with original source fingerprints and acceptance flags. |
| Rotor orders, 17 November | Current periodic structural construction; no aerodynamic feedback or gravity prestress; Rayleigh damping 0.5% at 0.17 and 1 Hz; inherited illustrative drivetrain; unit axial hub force. Full 804-coordinate azimuth-averaged response, periodic 24/48/96-mode harmonic-balance checks and selected Floquet checks. |
| External nonlinear campaign, audited 18 November | Fixed base; gravity/aerodynamics inactive; prescribed spin removed at 5 s and followed by driving torque; six-component nacelle pulse during 20--21 s; source viscosity/dashpots. Binary support displacement spectra and excursions, not a matched infinitesimal validation test. |

The 96-mode periodic response is not an 804-coordinate periodic reference.
Its convergence checks do not validate the weakly coupled aeroelastic transient
solver. The stationary ROM timing ratios cannot be transferred to rotation or
nonlinear-model comparisons. The saved nonlinear CPU logs cover stage 5 only and
use no demonstrated common workload/hardware protocol.

## Plot data and fidelity

- `beam_Timoshenko` and `beam_EulerBernoulli`: original fourth-bending-mode
  discretization errors at slenderness 10, each against its own theory reference.
  `beam_theory_difference` compares the theories; do not conflate the two errors.
- `campbell`: all 72 speed samples and 16 sorted frequencies. Curves are sorted
  spectral branches, not tracked identities. Plot only the band needed for the
  accompanying discussion. Order frequencies are k*n/60 Hz.
- `receptance_1P`, `receptance_3P`, `receptance_6P`: original coarse sweep united
  with refined neighborhoods, with no amplitude adjustment. Axial output is
  projected onto the tilted rotor axis. Values have units m/N. `phase_deg` is the
  hub axial phase. `resolved_peaks` contains refined peak coordinates.
- `stationary_response_full`: all 3201 times of the selected full-model channels.
  `stationary_response_plot`: original subset retaining every eighth time,
  endpoints and every channel extremum. Maximum pointwise deviations from the
  original when linearly interpolated are 0.22%, 0.42%, 0.54%, 0.40%, and 0.65%
  of the respective maximum amplitudes (nacelle X, tips 1--3 X, base My).
  Full data remain available if these bounds are inappropriate for a figure.
- `morris_frequency_all`: retains original acceptance flags; 14 of 21 mean
  frequency effects pass. Parameter-specific plotting tables use NaN for rejected
  results. There are two accepted frequency-effect dispersions; rejected
  dispersion must not be plotted as validated uncertainty/error bars.
- `rom_errors`: original channelwise relative L2 errors; `rom_costs` separates
  integration, basis construction and projection. Costs exclude physical output
  reconstruction. Operator-plus-basis bytes are not peak process memory.
- `nonlinear_history_00` and `_07`: original binary tower-top global-X samples
  during 15--80 s, retaining each tenth sample plus endpoints/extrema. Maximum
  pointwise interpolation deviations are 0.167% and 0.149% of channel maximum.
  `_full` files retain all 6500 original samples in the window.
- `nonlinear_spectra`: all original frequency bins from 0.1 to 0.5 Hz for the
  selected case 00 and 07 tower-X response. The audit uses 25.01--1099.99 s,
  0.01 s uniform interpolation, mean removal, rectangular window, and normalized
  one-sided amplitudes. This is neither an FRF nor an eigenmode identification.

No local extrema are replaced by averages. None of the plotting subsets is used
to compute scientific error metrics, which remain the original full-history
measurements. Captions should mention plotting subsets if temporal figures use
them. All ten selected nonlinear binary files are checked against the earlier
audit before extraction; the case-07 velocity ASCII mismatch is avoided.

## Checks performed on 18 November 2026

- Three nonlinear-reader unit tests passed using the existing Python 3.12 venv.
- Repository checker passed: 39 input hashes, 260 maintained sources and 20
  existing documents; no errors before adding this extraction documentation.
- Eleven used historical sources matched the prior manuscript SHA-256 ledger.
- Ten selected nonlinear p11 streams matched the earlier audit hashes.
- The extractor generated 33 tables and recorded 36 consumed sources in its
  initial run; these counts may grow if the evidence set is explicitly extended.

System Python 3.9 lacks SciPy and cannot parse two existing Python-3.12 sources;
those initial environment failures were resolved by selecting the documented
runtime, not by changing solver or postprocessing code.


## Self-contained manuscript figures

Run `.venv-tecplot/bin/python tools/build_structural_paper_figures.py` after extraction.
The optional `--output` selects the destination for all nine figure snippets.
The source uses TikZ/PGFPlots; embed each generated snippet literally in main.tex.
No external graphics, data files or shell escape are needed to compile the manuscript.

Figure order follows the evidence chain: (1) actual-coordinate oblique assembly
and upper constraints, (2) nominal/elastic kinematics and moving offsets,
(3) mesh versus beam assumptions, (4) audited nonlinear pulse/spectra,
(5) current Campbell/orders, (6) hub/support receptance, (7) accepted historical
sensitivity, (8) stationary component histories, (9) channel-wise ROM error/cost.
The geometry view is an orthographic projection of the versioned coordinates,
with schematic body labels and connection symbols; it is not recovered CAD.
The kinematics drawing is explanatory and does not represent a solved displacement.

The MATLAB regression suite was rerun on 18 November 2026 at simulation baseline
4a71d6b: 184 passed, zero failed, zero incomplete. No solver files or numerical
parameters were changed for the manuscript. Equation-to-routine mapping is in
[the formulation audit](structural_paper_formulation.md).
