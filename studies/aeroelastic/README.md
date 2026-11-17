# Maza operating-condition comparison

The later [convergence and rotor-order study](../../docs/rotor_orders.md)
extends this historical campaign with four finer 60 s integrations, spatial and
stability checks, Campbell diagrams and hub/support harmonic responses. Its
resolution claims apply to the explicitly stated channels and time window.

The comparison uses Maza et al. (2023) as another model's prediction, not as
absolute truth or an experimental calibration target. No parameter was fitted
to the published displacement. The complete numerical settings and limitations
are described in [the coupling documentation](../../docs/aeroelasticity.md).

```matlab
addpath('studies/aeroelastic');
report = run_maza_comparison();
```

This executes three operating conditions with weak coupling and prescribed
loads, two main time steps, and three additional refinements for growing twist.
The isolated blade has 35 elements, 210 free DOFs, a 6 m root radius and no gravity,
precone or tilt. The reconstructed conventional pitch is −3.223977325°; the
zero-lift reference for the adopted polars is 86.776022675°. The 10 s spin-up uses
a cubic smoothstep. These choices are recorded, not inferred to coincide exactly
with all unreported details of the publication.

## Results from 17 November 2026

| Wind (m/s) | Rotation (rad/s) | Weakly coupled result |
| --- | --- | --- |
| 1 | 0.7547 | Completed 400 s; mean tip X displacement 3.800937 m over 300–400 s; half range 0.00001314 m |
| 18.2 | 0.7547 | Reached the declared 0.2 rad rotation limit at 8.305 s with dt = 0.005 s; no long-time statistic assigned |
| 25 | 0.1 | Tip bending settles while twist grows; the rotation limit is reached between about 78.4 and 79.9 s across the tested refinements |

For context, Maza's Table 2 reports means of 1.05, 4.20 and 0.88 m for these
conditions, with amplitudes 0, 0 and 2.56 m. The complete first condition permits
an inter-model steady-response comparison. The truncated conditions do not
supply the long-time means or amplitudes needed for the same comparison. We do
not report percentages of “error against Maza”.

At 1 m/s, excluding elastic feedback gives mean 4.076420 m and half range
0.127638 m over the same window. Including feedback changes the equilibrium and
strongly reduces the late bending oscillation in this model. Zero structural
Rayleigh damping was used in both cases. This controlled contrast identifies
an effect of feedback; it does not isolate differences between UVLM and polars,
constitutive coupling, pitch calibration or structural nonlinearity.

Halving dt from 0.010 to 0.005 s changes the tip-displacement history by
0.0013135%, 0.0518856% and 0.132442%, respectively, measured as relative L2
norms on the shared saved time interval. Truncated cases are compared only up to
the shorter available history. Those scalar-channel checks do not establish
convergence of the torsional response.

The growing-twist condition illustrates the distinction:

| dt (s) | First attempted time beyond 0.2 rad (s) | Twist RMS, 50–70 s (rad) | Twist-history change relative to dt = 0.000625 s |
| --- | --- | --- | --- |
| 0.010000 | 79.000000 | 0.06470302 | 112.43% |
| 0.005000 | 79.240000 | 0.06368793 | 118.33% |
| 0.002500 | 79.317500 | 0.06321806 | 31.90% |
| 0.001250 | 79.910000 | 0.06317508 | 8.24% |
| 0.000625 | 78.414375 | 0.06316083 | Reference |

The RMS changes by approximately 0.023% between the two finest steps, while
phase-sensitive histories still differ by 8.24% through 78.4 s. The threshold
crossing time is not monotonically converged. This supports reporting growing
torsional response under the stated assumptions, but not a precise onset time,
a fully resolved torsional trajectory, or reproduction of Maza's flutter limit
cycle. The 0.2 rad cutoff is an explicit small-rotation screening choice, not a
physical instability boundary. Spatial convergence is not established by these
time-step tests.

## Saved evidence and figures

The executed campaign is in `runs/maza_comparison_20261117` on the working machine.
Its generated files are intentionally excluded from Git and reproduced by the
command above. `computed_summary.csv` records completion status separately from
statistics; `time_step_comparison.csv` and `growing_twist_refinement.csv` report
within-model numerical changes. Each MAT file contains its configuration and
source provenance. Partial runs contain only accepted samples and an explicit
termination status.

`maza_operating_conditions.pdf` is a six-panel monochrome vector figure: tip X
displacement at left and tip twist at right. Rows correspond to the three
operating conditions. Solid black denotes weak coupling at 0.005 s, grey dashed
lines 0.010 s, and dotted grey lines prescribed loads at 0.005 s. Open circles
mark the last saved weakly coupled sample before the rotation cutoff. The time
axis in the third row is restricted to the available coupled interval; its
prescribed-load run continues to 700 s. The figure shows the primary two-step
comparison; the additional refinement is quantified in the table above.

The complete 177-test MATLAB suite passed. The full-turbine path also completed
a separate 1 s run through `main`, including MAT/CSV/JSON persistence. The source
and data audit passed, including the PDF supplied by the user.

## Sandia report audit

The user-supplied SAND2011-3779 is preserved with its checksum in
[data/aerodynamics/snl100_00](../../data/aerodynamics/snl100_00/README.md).
Table 18 matches all 34 external-geometry stations exactly. The original
baseline's 2.5 m hub radius is kept distinct from Maza's 6 m isolated setup.
The inherited mass is not rescaled to the report's different FAST, PreComp or
ANSYS mass estimates. No simulation input changed after this geometry check.
