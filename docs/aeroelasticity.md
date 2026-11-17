# Weakly coupled section aerodynamics

The new driver exchanges structural motion and aerodynamic force once per time
step. Section loads therefore respond to the predicted displacement and velocity;
they are not a fixed thrust history. The mechanical solve uses implicit
average-acceleration Newmark without aerodynamic subiterations. Explicit load
exchange does not inherit Newmark's unconditional stability for prescribed loads.

## Running and changing inputs

```matlab
addpath('cases');
cfg = config_aeroelastic_snl100();   % Complete turbine, short smoke case.
cfg.aerodynamics.windVelocity = [8 0 0];  % Inertial m/s; choose your condition.
cfg.rotor.speedRPM = 6;
cfg.rotor.rampSeconds = 10;
cfg.aerodynamics.pitchRad = 0;      % Constant collective pitch, radians.
cfg.aeroelastic.duration = 10;
cfg.aeroelastic.dt = 0.005;
result = main(cfg);
```

Wind can also be a function `@(time, positions)` returning one inertial velocity
per section, an N-by-3 array. Density, constant pitch, rotor speed, ramp duration,
initial azimuth, Rayleigh damping and time step are configurable. A custom
`cfg.rotor.motionFcn` must return mutually consistent `azimuth`, `omega` and
`alpha` in rad, rad/s and rad/s². Time-dependent pitch actuation is rejected
because its structural and aerodynamic velocity terms are not implemented.

`cfg.aeroelastic.feedback = false` provides a controlled comparison: loads still
change with wind and prescribed rotation, but elastic motion is excluded from
the velocity triangles. `true` includes that motion at every step. Neither
setting is a UVLM or dynamic-stall model. An optional
`inducedVelocityFcn(time, positions)` can prescribe an inertial N-by-3 velocity
increment; it does not solve for an induced wake.

Run the isolated reference conditions with:

```matlab
cfg = config_maza_isolated_blade(1, 0.7547); % m/s and rad/s respectively.
result = run_aeroelastic(cfg);
addpath('studies/aeroelastic');
report = run_maza_comparison();
```

The campaign runs U = 1 and 18.2 m/s at Ω = 0.7547 rad/s for 400 s, and
U = 25 m/s at Ω = 0.1 rad/s for 700 s. Each condition uses weak coupling at
0.010 and 0.005 s and prescribed loads at 0.005 s. The growing-twist condition additionally uses
0.0025, 0.00125 and 0.000625 s through 100 s or the declared rotation limit, whichever occurs first.
Generated histories, summaries
and monochrome vector figures are saved under `runs/`. For a single run,
`runFolder/aeroelastic_results.mat`, `response.csv` and `summary.json` contain
the configuration, input provenance and output. No Tecplot licence is needed.
These outputs have their own schema; the older `regenerate_outputs` utility
is for the existing structural campaigns.

## Motion, forces and their transfer

Two Gauss stations per blade element evaluate the velocity triangle. This is a
consistent integration of distributed forces onto the structural nodes rather
than a point-force approximation at each node. The same Timoshenko interpolation
maps nodal displacements to section motion and transfers section forces back by
its transpose.

Let e_s denote the outward span, e_c the leading-to-trailing-edge chord direction,
and e_n = e_c × e_s. The default rotor axis for the isolated blade is +X; a
positive rotation moves its initially +Z tip towards −Y. Positive collective
pitch rotates the nominal chord about −e_s. The geometric twist is added to
that pitch. Elastic rotation uses E = exp([θ]×), with the corresponding left
Jacobian J, so the elastic angular velocity is J θdot.

At each aerodynamic centre, the relative velocity is the prescribed wind minus
the velocity from rotor spin, elastic translation and elastic rotation of the
chordwise offset. Its spanwise component is removed. The angle of attack is
atan2(Vrel·e_n, Vrel·e_c). Lift acts along (Vrel/|Vrel|) × e_s and drag along
Vrel/|Vrel|. Per unit span,

- lift = ρ |Vrel|² c Cl / 2;
- drag = ρ |Vrel|² c Cd / 2;
- pitching moment = ρ |Vrel|² c² Cm / 2 about e_s.

The centre defaults to 25% chord. Its offset from the structural reference axis
uses the published pitch-axis fraction; identifying those two axes is an explicit
model assumption. The transferred moment includes offset × force. Multiplication
by J transpose maps that physical moment to the elastic rotation coordinates.
This preserves virtual work for the stated interpolation; it does not assert
that an explicitly partitioned time step conserves total aeroelastic energy.

## Structural approximation

The isolated model is a straight, 100 m cantilever with 35 Timoshenko elements
and 210 free DOFs, built from the inherited section stiffness and mass data. Its
root is 6 m from the horizontal rotor axis. Geometric twist and collective pitch
orient the section frames; precone, pretilt and gravity are absent. The complete
turbine retains its inherited centreline and constraints, with constant
collective pitch also applied to the material frames. The complete-turbine
example retains the explicitly illustrative drivetrain stiffness used by the
existing stationary example.

The rotating-frame linear equations contain elastic stiffness Ke, consistent
mass M, gyroscopic matrix ΩG, spin Hessian Ω²Ks, Euler stiffness Ωdot A and
forcing Ω²fs − Ωdot b. A = T_vq and b = T_v at zero elastic state are obtained
from the existing quadratic kinetic-energy operators. Centrifugal prestress is
approximated by solving the elastic unit-spin problem, recovering blade axial
forces and scaling its geometric stiffness Kg by Ω². Thus the blade stiffness
is Ke + Ω²(Ks + Kg) + Ωdot A. This is a quasistatic prestress approximation during
spin-up; it does not update a geometrically nonlinear equilibrium at each step.

For the complete turbine, rotor operators are transported together into inertial
nodal components and projected through the time-dependent root constraints,
including Tdot and Tddot. Fixed tower and drivetrain operators remain in inertial
axes. This driver is distinct from the older frozen-azimuth transient driver.
It supports explicit Rayleigh coefficients; other damper matrices are rejected.

Finite section orientations in the aerodynamic calculation do not turn the
linear structural model into GEBT. A configurable 0.2 rad elastic-rotation limit
terminates runs outside the adopted small-rotation domain. The limit is a declared
screening choice, not a proven error bound. A stopped run is not labelled flutter. The campaign sets
`returnPartialOnDomainExit = true`: it stores only accepted samples, the first
attempted time beyond the limit and an explicit `rotation_limit` status. No
full-duration mean or amplitude is assigned to such a case. The generic solver
raises an error by default when this option is absent.

## What the Maza comparison means

[Maza, Turello, Preidikman and Flores (2023)](https://amcaonline.org.ar/ojs/index.php/mc/article/download/6643/6706)
use nonlinear GEBT and UVLM, including wake history. Their results describe that
model and its assumptions. Agreement or disagreement with the present model is
an inter-model observation; it is neither a standalone accuracy measure nor a
reason to tune parameters to their curves.

Their isolated blade has no gravity or tower interaction. Wind starts at t = 0
and rotor speed rises smoothly over 10 s. We adopt a cubic smoothstep because
the paper does not specify its ramp function. Air density 1.225 kg/m³ and zero
structural Rayleigh damping are stated choices; the exact material viscosity
used in their simulations is not given in the article.

Their q = 90° is relative to a rigid, stationary zero-lift orientation, whose
conventional pitch is not reported. `maza_pitch_reference` reconstructs that
orientation using zero integrated lift from our adopted polars, then subtracts
90°. This is model-dependent and is never adjusted to match tip motion. The
external geometry is documented; exact equivalence of the full constitutive
matrix, material damping, reference axis and aerodynamic discretization has
not been established.

Interpret results in this order:

1. Check units, frames, load transfer, rotation kinematics and mechanical residuals.
2. Refine the time step within the same model. Compare full histories and
   late-window statistics separately; a small algebraic residual alone is insufficient.
3. Contrast prescribed loads with weak coupling at the same time step to identify
   the influence of structural feedback.
4. Discuss how model assumptions can change equilibrium, damping, frequency and
   instability. Quasi-steady viscous polars and UVLM represent different effects;
   neither model is automatically superior in every operating regime.

The campaign reports the last 25% of each history as mean and half range, without
automatically declaring steady state. A spectral peak in an almost vanishing
residual is not an identified physical mode. Published zero-amplitude cases
cannot supply a steady oscillation frequency for a direct FFT comparison. Flutter
would require sustained evidence, time/space checks and a model capable of the
relevant unsteady and nonlinear mechanisms.

## Audit against the user-supplied Sandia report

The original [SAND2011-3779 report](../data/aerodynamics/snl100_00/sand2011_3779.pdf)
corroborates all 34 geometric stations without changing the numerical inputs.
Its baseline hub radius is 2.5 m, versus the deliberate 6 m isolated case in Maza.
It reports multiple mass estimates from different discretizations; the inherited
mass is retained rather than calibrated to one reported total. The report does
not establish that the inherited section matrices are the exact v2 matrices used
by Maza. See [the source audit](../data/aerodynamics/snl100_00/README.md).

## Checks

`tests/test_aeroelastic_coupling.m` checks velocity-triangle signs, zero relative
flow, eccentric virtual work against position finite differences, the rotation
Jacobian, wind callbacks, rotor-ramp derivatives, stationary structural limits,
Euler terms, feedback sensitivity, time-dependent constraints and the corrected
state's rotation guard. A damped oscillator with state-dependent exchanged loads
provides an independent time-refinement check. Both isolated and complete-turbine
paths are exercised. Input hashes are checked by `tools/check_repository.py`.
