# Numerical convergence, stability and rotor orders

This study separates three questions: whether a computed history is numerically
resolved, whether an autonomous aeroelastic perturbation grows, and whether a
periodic rotor load excites a structural resonance. Agreement with another
model is not used as a convergence criterion or a fitting target.

## Reproduce the studies

From the repository root, in MATLAB R2026a:

```matlab
addpath('studies/aeroelastic');
convergence = run_convergence_study();
orders = run_rotor_orders();
periodicity = verify_rotor_periodicity();
timeScale = assess_aerodynamic_time_scale();
```

Then render the monochrome vector figures:

```sh
python studies/aeroelastic/make_order_figures.py
python tools/audit_supplied_aerodynamics.py
python tools/check_repository.py
```

The defaults save complete numerical evidence in
`runs/aeroelastic_convergence_20261117` and `runs/rotor_orders_20261117`.
Generated runs and figures are excluded from Git; the drivers and source inputs
are tracked. The examples deliberately prescribe their wind, pitch, speed,
damping and shear. They do not constrain the configurable operating inputs of
`run_aeroelastic`. No Tecplot installation is needed for these figures.

## Time resolution of the growing-twist case

The isolated 100 m blade uses the previously declared reference polars,
25 m/s axial wind, final rotation 0.1 rad/s, a 10 s spin-up, no gravity,
and the reconstructed conventional pitch −3.223977325 degrees. These are the
conditions of the existing model comparison, not a parameter fit to Maza.
The 35-element mesh has 210 free structural DOFs.

The study uses steps 0.000625, 0.0003125, 0.00015625 and 0.000078125 s on a
common 0–60 s interval, saving at identical 0.01 s times. Histories are compared
without phase shifting. Forces and moments are evaluated separately to avoid
mixing N and N m in one norm. In addition to full-history L2 and maximum
differences, the late difference is normalized by the reference fluctuation
about its mean over 20–60 s. This prevents a large steady load from concealing
an unresolved oscillation.

The final comparison, dt = 0.00015625 against 0.000078125 s, gives:

| Channel | Full-history L2 change (%) | Maximum difference / reference maximum (%) | Late difference / reference fluctuation (%) |
| --- | ---: | ---: | ---: |
| Tip X displacement | 0.0001172 | 0.0002969 | 0.02977 |
| Tip twist | 0.49456 | 0.85454 | 0.51530 |
| Generalized aerodynamic forces | 0.004836 | 0.025838 | 0.33764 |
| Generalized aerodynamic moments | 0.005822 | 0.026645 | 0.44336 |

All three measures pass the declared 1% successive-refinement criterion in
these channels and this time window. This is a numerical resolution criterion,
not an exact-error bound, a proof of asymptotic order, convergence of every
state variable, or a converged time of first crossing of the 0.2 rad screening
limit. The latter lies outside this 60 s window. The earlier longer-window
results remain historical evidence, not overwritten convergence claims.

The weak integrator now solves the algebraically equivalent acceleration form
of average-acceleration Newmark. It avoids obtaining acceleration by subtracting
nearly equal displacements and dividing by dt². It retains the single
aerodynamic evaluation per step and the original weak predictor. It does not
introduce aerodynamic subiterations or remove the growing response.

## Why the growing torsion is not a 1P/3P forced resonance

After spin-up, the isolated problem with uniform axial wind is autonomous in
the rotating frame. At 0.1 rad/s, 1P = 0.0159155 Hz and 3P = 0.0477465 Hz.
The observed growing oscillation is near 3.347 Hz, far from those forcing orders.

An independent equilibrium solve balances structural and aerodynamic forces.
Central differences of the aerodynamic force give Fq and Fv, and the local
quadratic eigenproblem uses M, D−Fv and K−Fq. The reported eigenvalue branch is
the growing oscillatory branch near 3.35 Hz; this is not an exhaustive search
for every unstable eigenvalue.

| Blade elements | Oscillation frequency (Hz) | Growth rate (1/s) | Growth estimated from cycle work (1/s) |
| --- | ---: | ---: | ---: |
| 35 | 3.3474 | 0.040012 | 0.040080 |
| 70 | 3.3461 | 0.040014 | 0.040082 |
| 140 | 3.3460 | 0.040011 | 0.040080 |

The equilibrium relative residual stays below 9e−12. Changing the force
difference step from 1e−4 to 1e−6 gives the same reported pole at 35 elements.
Subdivision preserves each parent's section properties and material frame;
it refines spatial discretization without inventing a new section dataset.
Both structural interpolation and aerodynamic quadrature are refined together.

The positive real part corresponds to an amplitude e-folding time of about
25 s. The time-history fit over 20–50 s independently gives approximately
0.03996/s and 3.3474 Hz. Its residual is about 8.47%, so the entire transient
is not claimed to be a pure single mode. The positive cycle-averaged work of
the linearized aerodynamic force is consistent with the eigenvalue growth:
power divided by twice the modal energy is about 0.04008/s.

Together, these checks support a self-excited oscillatory instability of the
adopted quasi-steady section-force model. They do not establish the flutter
boundary of the physical turbine, reproduce Maza's UVLM limit cycle, or transfer
the conclusion to a different coefficient law. In particular, the subsequently
supplied [linear aerodynamic scripts](../data/aerodynamics/snl100_00/supplied_linear_model/README.md)
were not used in these calculations.

## Campbell screening and hub/support response

For a speed n in rpm, the excitation order kP has frequency kn/60 Hz. The
Campbell plot overlays 1P, 3P, 6P and 9P on the assembled turbine frequencies
over 0.5–7.44 rpm. Frequencies are sorted at each speed; crossings are not
assigned persistent mode identities without mode-shape tracking.

Physical operators are rebuilt at each azimuth before transformation to
multiblade coordinates (MBC), including both transformation derivatives.
Azimuth-averaged matrices provide the Campbell screening and an initial
full-order frequency response. The full model has 804 free DOFs. The response
input is a harmonic **unit axial force at the hub**, with outputs at the hub,
nacelle, tower top and base. The force-to-displacement map is a receptance in
m/N, not a displacement prediction for an unspecified wind field.

The strongest resolved 3P axial-hub peak occurs at **3.444465 rpm**, or
**0.172223 Hz**. The averaged model gives 4.24985e−5 m/N and approximately
−89.66 degrees phase, with a dynamic/static amplification of 97.96. The
near-quarter-cycle phase, direct forced response and local peak refinement
support resonance identification; the Campbell crossing alone would not.
The 6P response has a corresponding low-frequency peak at 1.726294 rpm.
No 1P axial-hub peak appears in the sampled range. This is not a claim that
every load direction and every narrow peak has been exhaustively resolved.

The figures show axial response at the hub, nacelle and tower top. The hub and
nacelle curves nearly coincide because their axial motions are tightly linked
by the assembled constraints. The tower-top response is also strongly amplified.
The CSV additionally contains lateral and vertical hub displacement, hub pitch
rotation and base pitching reaction. A large individual mode amplitude does
not imply a large measured channel if its forcing or observation participation
is small.

These structural transfer calculations exclude aerodynamic feedback and gravity
prestress. They retain the inherited illustrative drivetrain and use Rayleigh
damping corresponding to 0.5% at 0.17 and 1 Hz. Thus the peak is a property of
this declared numerical configuration. At the same speed, halving/doubling the
damping gives about 8.4993e−5/2.1250e−5 m/N. A real operational amplitude cannot
be assigned without specifying the excitation and the physical damping.

## Periodic verification of the 3P peak

The verification retains periodic MBC matrices and harmonic coupling, rather
than assuming that azimuth averaging is exact. Harmonic balance uses 48 angular
samples, 24/48/96 conservative modes and Fourier half-widths 3/6/9. The final
3P hub amplitude is **4.22148e−5 m/N**. At 96 modes, half-width 6 to 9 changes
the amplitude by about 0.003%; at half-width 9, 48 to 96 modes changes it by
about 0.0064%. Algebraic residuals are of order 1e−14. The separate
`periodic_complex_convergence.csv` retains phase and checks complex channel
changes against the finest periodic approximation.
At half-width 9, increasing 48 to 96 modes changes the complex hub response by
0.0610%; at 96 modes, increasing half-width 6 to 9 changes it by 0.0232%.
The final periodic 3P phase is approximately −95.88 degrees.

The periodic solution differs from the full averaged solution by approximately
10.8% in complex hub response, mostly through phase, while its amplitude differs
by about 0.67%. The 10.8% is an averaging-model difference, not a modal-truncation
error. Angular averaging with 12/24/48 points changes the channel vector by
less than 2e−8 relative to the 48-point mean.

A periodic forced solution need not be attracting. A separate Floquet check
with 24/48 modes and 96/192 time intervals gives maximum multiplier modulus
about **0.910668**, below one, and largest growth rate about **−0.005372/s**.
This supports a stable periodic structural response at this selected peak with
the stated damping. It is neither a full aeroelastic Floquet analysis nor a
stability claim over the entire speed sweep.

## Which blade orders reach the hub?

A separate load experiment uses the prescribed rigid rotor at 0.7547 rad/s,
1 m/s hub-height axial wind, zero conventional pitch, no gravity, and either
uniform inflow or a power-law shear exponent of 0.2. These deliberately declared
conditions isolate order generation; they are not the 3.444465 rpm resonant
condition and are not a flexible-turbine coupled response.

For three identical blades separated by 120 degrees, summing an axial scalar
harmonic multiplies it by the sum of exp(ik 2πb/3), for b = 0,1,2. This is zero
unless k is a multiple of three. Therefore substantial 1P on an individual
blade can cancel in the hub thrust, while 3P survives. This selection rule
must not be applied indiscriminately to rotating vector components or moments.

With shear, the inherited geometry gives approximately 7,562 N of blade-1
axial 1P force, 2.37 N of hub axial 1P force, and 488.5 N of hub axial 3P force.
Hub pitching-moment amplitudes are approximately 2,216 N m at 1P and
109,474 N m at 3P. Uniform flow removes the blade axial oscillation, but the
inherited geometry still gives a 1P hub pitching moment near 2,307 N m.

An exact cyclic copy of blade 1 provides a geometric control. The inherited
blade coordinates differ from that copy by up to **0.01942 m**. The control
removes the residual hub 1P to numerical roundoff while preserving shear-driven
3P. The residual 1P in the inherited model is therefore an asymmetry effect in
this test, not evidence of resonance or an automatically meaningful physical
manufacturing imperfection. Production geometry is not changed by this control.

Angular sampling is refined from 96 to 192 to 384 points. Between the last two,
the largest relative change among inherited blade-1 thrust, hub thrust and hub
pitch moment at orders 1,3,6 is about 0.0229%. Roundoff-level cancelled orders
are interpreted in absolute units, not by unstable relative percentages.

## Physical interpretation and the strength of the evidence

The computed results support specific physical properties, not a single blanket
claim of turbine fidelity. Numerical convergence establishes resolution of the
adopted equations. Analytical identities and controlled changes establish
mechanism consistency. Matched model comparisons and measurements establish
quantitative accuracy in a stated domain. A nonlinear comparator is another
model, not experimental truth by virtue of being nonlinear.

**Rotor symmetry and load transmission.** The observed cancellation of the
scalar axial 1P contribution and survival of multiples of 3P reproduce the
three-blade symmetry identity. This demonstrates the phase and summation
structure of the implemented blade-to-hub map. It does not demonstrate that a
pure blade 1P signal is converted to axial 3P. A nonlinear shear/load relation
can generate several blade harmonics; their axial sum selects multiples of
three. Tilt and yaw moments additionally involve azimuth-dependent moment arms
and therefore have different harmonic mappings. This distinction follows the
collective and cyclic MBC components in
[Bir (2008), NREL/CP-500-42553](https://digital.library.unt.edu/ark:/67531/metadc898093/m2/1/high_res_d/922553.pdf)
and the harmonic discussion in
[Hummel et al. (2025), section 2.1](https://wes.copernicus.org/articles/10/2005/2025/).
Only the prescribed shear and geometry effects were exercised here; tower
shadow and turbulent inflow should not be claimed from these cases.

**Symmetry breaking.** Removing the inherited geometric differences removes
the residual hub 1P without tuning aerodynamic coefficients. This causal control
is stronger evidence than merely finding a peak in a spectrum. It is physically
consistent with fixed-frame 1P signatures of rotor imbalance discussed by
[Bertelè, Bottasso and Cacciola (2018)](https://wes.copernicus.org/articles/3/791/2018/).
Their perturbation is pitch misalignment, while ours is a coordinate asymmetry;
the common mechanism is broken cyclic symmetry, not identical fault severity
or an equivalent pitch error. The origin of the inherited coordinate differences
is unknown. No real manufacturing defect or fatigue-life reduction is inferred.

**Forced resonance and structural coupling.** The 3P crossing, forced-response
peak, near-quadrature phase and damping sensitivity jointly support a
resonant response of the assembled model. A forcing frequency can cross a
natural frequency with little response if the corresponding modal forcing or
observation participation is small. The hub, nacelle and tower-top outputs
test load transmission through the assembled system. NREL's
[design-load guidance, section 3.4.5](https://www.nrel.gov/docs/fy25osti/91458.pdf)
likewise evaluates assembly modes and rotor orders together. The calculated
3.444465 rpm is conditional on the present stiffness, mass, connections and
operating state; it is not a literature-validated critical speed for SNL100-00.
The illustrative Rayleigh damping supports a sensitivity study, not a measured
energy-loss model. Periodic verification is relevant because MBC averaging
changes the complex response by about 10.8% at the examined peak.

**Feedback and energy exchange.** The force depends on section motion, and its
work-dual transfer preserves instantaneous virtual power between the stated
section interpolation and structural coordinates. This is an implementation
property checked independently; it does not imply that partitioned time
integration exactly conserves aeroelastic energy. The growing mode has a
positive aerodynamic cycle work and a positive real eigenvalue. Agreement of
the eigenvalue, energy estimate and refined transient supports self-excitation
within the selected coefficient model. It does not identify classical
flap-torsion flutter solely from the existence of a growing twist component.

**Additional aerodynamic time-scale diagnostic, 17 November 2026.** Running
`assess_aerodynamic_time_scale` on the 140-element equilibrium computes
k = omega*c/(2*Vrel), using the 3.345960 Hz growing-mode frequency and the local
equilibrium relative speed. Over the 20--90 m span interval, k ranges from
**1.3932 to 3.1855** and the calculated incidence ranges from **71.12 to
74.96 degrees**. These are local diagnostics, not modal-work-weighted averages.
The results are saved in `aerodynamic_time_scale.csv` and the companion MAT file.

Thus this particular instability is not in a small-reduced-frequency regime
that would justify neglecting aerodynamic memory. Its very high incidence
also precludes identifying it with attached-flow classical flutter on that
basis. [Chetan, Yao and Griffith (2022)](https://wes.copernicus.org/articles/7/1731/2022/)
include unsteady aerodynamic amplitude/phase and reduced-frequency dependence
when studying flexible blades, including the SNL100 family. Their attached-flow
assumptions are not automatically applicable to this operating point.
[AeroDyn's unsteady-aerodynamics theory](https://openfast.readthedocs.io/en/v4.0.5/source/user/aerodyn/theory_ua.html)
also distinguishes steady coefficients from time-dependent separation dynamics.
Neither a static polar nor an unqualified linear Cl slope supplies those dynamics.
Accordingly, the 3.346 Hz mode remains evidence of mathematical aeroelastic
feedback in the current model, not a validated physical flutter prediction.
This qualification does not invalidate the separate structural unit-force
resonance or symmetry tests, which do not rely on this unstable operating point.

The evidence supports preservation of rotor symmetry, load-transfer kinematics,
structural resonance and motion-dependent aerodynamic feedback in the examined
configurations. These mechanisms are not exclusive to MHT. A comparison intended
to establish the benefit of its beam assumptions or reduced basis must additionally
isolate shear/rotary-inertia effects and quantify errors in frequencies, mode
shapes, channel amplitudes and phases versus computational cost. Matching
geometry, damping, load definitions and aerodynamic laws in the nonlinear
comparison separates structural approximation error from aerodynamic-model
differences. Experimental data would supply a further, independent validation.

## Figures and references

The rendering script produces `numerical_convergence.pdf`, `campbell_orders.pdf`,
`hub_and_support_orders.pdf` and `blade_to_hub_orders.pdf`, plus PNG previews.
Figures contain axes, units and legends, with descriptions kept outside the
artwork. The numerical convergence figure shows L2 changes; the stricter maximum
and fluctuation measures are retained in the table above and the CSV.

The Campbell screening follows the excitation-order interpretation in
[NREL's design-load guidance, section 3.4.5](https://www.nrel.gov/docs/fy25osti/91458.pdf).
Azimuth-dependent linearization and MBC are also described in the
[OpenFAST linearization documentation](https://openfast.readthedocs.io/en/dev/source/user/glue-code/linearization.html).
The independent comparison source remains
[Maza et al. (2023)](https://amcaonline.org.ar/ojs/index.php/mc/article/download/6643/6706).
Neither source is treated as experimental ground truth for this implementation.

The complete MATLAB suite passed: **184 tests, zero failures**. It includes
analytical force derivatives, mesh mass/frame preservation, the MBC transport
identity, constant and periodic harmonic-balance checks, an analytical damped
oscillator Floquet multiplier, and three-blade harmonic cancellation.
