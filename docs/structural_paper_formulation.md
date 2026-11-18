# Structural formulation audit

The simulation source was inspected at revision `4a71d6b` on 18 November 2026. The audit did not alter solver routines or parameters.

## Main finding

There is a common beam/rigid/rotational-energy core, with two distinct operating-model paths. Their prestress closures and evidence are not interchangeable.

1. **Frozen operating tangent:** `+equilibrium/solve_static_equilibrium.m` -> `+assembly/build_operating_matrices.m` -> modal/Newmark paths. A Newton equilibrium uses a corotational small-strain energy and numerical derivatives, plus quadratic prescribed-spin loads. The equilibrium tangent already includes spin-load Jacobian; `Kg=tangentFull-Ke-embeddedAero`, `KOmega=0`. Reference-configuration inertia persists. Full D=C+G+massRate and full K=Ke+Kg+KOmega+Kaero+Ktransport. Constraint derivative terms then enter reduced D and K. This is a frozen snapshot, not an evolved LTV trajectory.
2. **Recent periodic rotor-order / aeroelastic structure:** `+aero/prepare_structure.m` -> `+aero/structural_operators.m` -> `+aero/turbine_mbc_operators.m`. Uses an elastic unit-spin static solve, recovers ONLY blade axial initial stress, scales Kg by Omega², and retains a separate energy Hessian Kspin. Physical rotating matrices and rigid-root offsets are updated for each azimuth. This is the path behind `studies/aeroelastic/run_rotor_orders.m`, including 24/48/96-mode harmonic balance. It does NOT use Newton operating tangent or gravity prestress in that study.

## Equation-to-source ledger

| Manuscript operation | Actual source and behavior |
|---|---|
| Components and legacy cleanup | `+model/build_model.m`: removes legacy type-3 penalty elements; retains nine type-4 transition members, section 20; blade elements use independent P1/P2/P3 auxiliary points. |
| Node ordering and frame | `docs/CONVENTIONS.md`, `+elements/element_rotation_matrix.m`: `[ux uy uz theta_x theta_y theta_z]`, row-local R, Te block diagonal. |
| Local strain signs | `+elements/timoshenko_B_matrices.m`, `+elements/timoshenko3d_matrices.m`: gamma2=v'-rz, gamma3=w'+ry, longitudinal and torsional derivatives, two transverse curvatures. |
| Closed stiffness | `+elements/timoshenko3d_matrices.m`, functions `closedExactStiffness`, `bendingStiffness`: diagonal sectional stiffness only; phi2=12 EIz/(GAy L²), phi3=12 EIy/(GAz L²); exact closed 4x4 Timoshenko bending blocks. |
| Interpolation | Same file, `bendingInterpolationCoefficients`/`closedKinematicMatrix`, plus public `+elements/timoshenko_kinematic_matrix.m`. Closed transverse interpolation cubic, rotations quadratic, axial/torsional linear. |
| Alternative SRI | Same file `selectiveStiffness`: complete coupled K6 supported; linear 6-field kinematics, two points axial/bending, one point shear and shear cross terms. This is a different discretization, not automatically Euler--Bernoulli. |
| Section mass / rotary inertia | `+elements/section_mass.m`: spatial 6x6 H=[mI,-mS(r);mS(r),J-mS(r)^2]; complete M6 preserved; mass physicality checked. `+model/resolve_section_mass.m` and config explicit Jx=Jy+Jz rule. |
| Consistent mass | `timoshenko3d_matrices.m`: four-point Gauss mass for closed interpolation, two-point linear mass for SRI. `cfg.elements.massIntegrationPoints=2` default does NOT override the hardcoded four-point closed mass; write actual behavior. |
| Rigid body mass | `+rigid/rigid_body_mass_matrix.m`: Jglobal=R Jbody R'; parallel-axis and translation--rotation couplings; eigenvalue/triangle checks. |
| Rigid root compatibility | `+rigid/rigid_constraint_matrix.m`: u_s=u_m-S(r)theta_m, theta_s=theta_m; full-column-rank sparse elimination; no chains; masters 129/130 explicitly cannot be tied. |
| Drivetrain | `+assembly/drivetrain_relative_kinematics.m`: delta_u=uJ-uI+S(rIJ)thetaI, delta_theta=thetaJ-thetaI. `assemble_structural_matrices` and `assemble_damping_matrix` add B'K6B and B'C6B. |
| Boundary reduction | `+rigid/reduce_system.m`: congruence then free independent column selection; dependent SPC requiring coupled equation is rejected. |
| Rotational energy | `+elements/rotating_section_operators.m`: M=Tvv, A=Tvq, G=A-A', Kspin=-Tqq, fspin=Tq; includes second-order centroid-offset and rotational-inertia curvature. |
| Spin gyro | `+assembly/rotating_mass_gyroscopic_matrix.m` and `+elements/timoshenko_gyroscopic_matrix.m`: Gc=2m B'WB+E'(JW+WJ-S(J omega))E. Distributed blades included by default. |
| Inertial transport at reference | `+assembly/transport_rotating_operators.m`: Mdot=WM-MW; Gg=Gc-MW-WM; D=Gc-2MW; Ktransport=-GcW+MW². Symmetric Mdot retained. |
| Moving root constraint | `+rigid/rotating_constraint_derivatives.m`: r=Rspin r0, rdot=W r, rddot=(Wdot+W²)r; Bdot/Bddot from -S(rdot/rddot). |
| General moving projection | `+assembly/build_operating_matrices.m`, `+aero/structural_operators.m`, `+rotor/transform_rotating_system.m`: Mz=T'MT, Dz=T'(DT+2MTdot), Kz=T'(KT+DTdot+MTddot). |
| MBC | `+rotor/mbc_transformation.m`: per component [1 cos psi_b sin psi_b]; `mbc_derivatives.m` composes H*B and all derivative cross terms; `blade_frame_transformation.m` rotates homologous local frames. |
| Newton static equilibrium | `+equilibrium/solve_static_equilibrium.m`: residual fext-fint, tangent Kint-dfext/dq, backtracking Newton; linear-extra connector/foundation stiffness preserved. |
| Corotational internal energy | `+equilibrium/total_lagrangian_internal_force.m`: despite filename, current chord and approximate rotation-vector subtraction define corotated deformation; numeric central energy derivatives at nonzero q; zero-q tangent exactly Ke. No claim of a geometrically exact beam. |
| Centrifugal force | `+equilibrium/centrifugal_loads.m`: quadratic spin-potential continuation, distributed four-point integration and rigid-body inertia; Kload=-Kspin. |
| Beam-column fallback | `+elements/geometric_stiffness.m`: N times integrated products of transverse interpolation gradients; tension stiffens, compression softens. `assemble_centrifugal_stiffness.m` takes explicitly labelled axial forces only and is skipped if already in Kg. |
| Periodic prestress | `+aero/prepare_structure.m`: qspin=T*(T'KeT)^-1*T'fspin; blade axial N=EA*(u2-u1)/L; Kg only blades; scales Omega². |
| Periodic full transport | `+aero/structural_operators.m`: M=M0-Mr+Q Mr Q'; D=C0-Cr+Q(Dc-2MrW)Q'; K=Ke-Kr+Q(Kc-DcW+Mr(W²-Wdot))Q'; base=Q(Omega²fspin-alpha bspin). |
| Damping | `+assembly/assemble_damping_matrix.m`: Rayleigh alpha M+beta Ke, optional two-frequency fit, foundation/aero/drivetrain separately; periodic driver directly uses explicit alpha,beta and omits connector/foundation damping construction. |
| Loads | `+assembly/assemble_load_vector.m`: consistent gravity, spin load, supplied aerodynamic force, applied vector and nodal loads; Kaero=-dfa/dq. |
| Frozen poles | `+modal/solve_quadratic_modes.m`; solve quadratic pencil. Conservative mode solver is separate. |
| Newmark | `+dynamics/newmark_integrate.m`: constant operators, beta=1/4 gamma=1/2 default, nonsymmetric factorization, no explicit inverse; caches constant-step effective solve. |
| Periodic harmonic response | `+dynamics/harmonic_balance.m`: FFT coefficient convolution; A_hk=-(k Omega)^2 M_(h-k)+i k Omega D_(h-k)+K_(h-k); +/- forcing harmonic B/2; algebraic convergence != stable attractor. |
| Floquet | `+dynamics/periodic_stability.m`: midpoint matrix exponentials over one period in retained ROM; independent mode/time resolution checks needed. |
| Full recovery | `+dynamics/recover_full_response.m`: moving-map v,a formulas but explicitly one snapshot applied to history; not evolved geometry. |
| Elastic force recovery | `+dynamics/recover_element_forces.m`: fLocal=KeLocal*Te*q; incremental elastic END forces about operating equilibrium, prestress excluded. Scalar derived summaries average differences of opposing end forces; use full end-force array for section-specific interpretation. |
| Seismic reactions | `+dynamics/run_seismic_analysis.m` and `recover_full_response`: full equilibrium incl inertia, velocity, elastic and base-motion loads. Base projection mass-consistent, not stiffness-only. |

## Parameters and cautions for prose

- Code node numbers differ from nonlinear campaign: linear tower top 20, nacelle 129, hub 130; blades root 21/57/93, tips 56/92/128. Nonlinear tower top 400019 (alias 4019), hub 1, nacelle 2. Do not reuse node IDs across models.
- Default `config_default.m` is geometry-only because inherited drivetrain stiffness is unverified. Explicit illustrative connector is required for analysis cases. This is material to claims about a physical turbine.
- Body JSON: nacelle 1,184,500 kg with principal inertias (14,806,000, 32,672,000, 32,672,000) kg m²; hub 196,000 kg with isotropic J=2,822,400 kg m². Both centroid offsets set to zero as assumptions. Orientation passive ZXZ (90,-5,-90) degrees converted explicitly; historical code had missing conversion. Confirm individual case does not override.
- `+model/prepare_analysis_model.m` excludes blade roots from MBC because they are dependent hub motion. Don't say all blade six-DOF blocks independently transformed.
- Recent run_rotor_orders has no gravity/aero feedback, unit hub axial forcing, illustrative Rayleigh 0.5% at 0.17 and 1 Hz. Its Campbell frequencies are sorted each speed, **not tracked branches** (explicit code comment). Avoid branch identities on such plots.
- `run_rotor_orders` 24/48/96 periodic metric is change from full AZIMUTH-AVERAGED solution, not error from full periodic solution. A difference incorporates periodic physics plus truncation. Compare successive retained modes to estimate truncation; do not equate 96-mode HB to full 804-coordinate periodic solution.
- Periodic structural `prepare_structure` does not call `apply_mass_formulation`: cannot imply HRZ option used there merely because config field exists.
- Frozen equilibrium helper is not a fully geometrically exact formulation: its rotation vector differences are not exact multiplicative relative rotations. Its own source comment calls it corotational small-strain energy; this wording is safer.
- Nominal rotation exponential in energy derivation is used only to obtain a quadratic perturbation expansion. It does not make elastic finite-rotation transient motion exact.
- No shell/solid cross-section distortion: no local buckling, ovalization, shell wrinkling. Linear stability / initial global instability is not postbuckling continuation.
- The generic `rotor.transform_rotating_system` azimuth_average operates on supplied constant M,D,K while varying its transform. True periodic study instead rebuilds physical operators via `aero.turbine_mbc_operators`. Don't imply generic average alone rebuilds turbine geometry.

## Potential issues beyond manuscript scope (do not silently fix)

- The Newton path's `localEvaluate` writes angularVelocity from cfg.rotor.speedRPM when present even if speedRadPerSec also exists; all checked normal cases use speedRPM. Could cause contradictory-config behavior but not a demonstrated current result error.
- `drivetrainOperator` stiffness validation checks finite coefficients and symmetric-part PSD but does not explicitly reject a nonsymmetric K6 before eventual global symmetry check. Assembly does reject non-symmetry, so no need to emphasize.
- The frozen and periodic paths are separate implementations with different prestress approximations; manuscript should acknowledge scope rather than claim a single identical operating tangent for all campaigns.

## Exact current baseline geometry and properties (read from versioned MAT/JSON, not historical PDF)

| Quantity | Value and provenance |
|---|---|
| Nodes / full coordinates | 138 / 828; `legacy_geometry_v0.mat` |
| Flexible elements | 133 = 19 tower + 105 blade (35 per blade) + 9 transition |
| Eliminated coordinates / analysis coordinates | 18 slave coordinates; six fixed-base coordinates; 828-18-6 = 804 |
| Tower top | global (0,0,135) m, node 20 |
| Nacelle master | global (-2.9886,0,141.54) m, node 129 |
| Hub master | global (7.9696,0,142.5) m, node 130 |
| Rotor axis | (0.996184574...,0,0.08727138...), normalized hub minus nacelle; 11.0001703278 m between masters |
| Blade 1 root / tip | (8.4915,-5.1912,139.53) / (17.185,-91.706,90.142) m |
| Blade 2 root / tip | (8.4915,5.1912,139.53) / (17.184,91.717,90.161) m |
| Blade 3 root / tip | (7.7078,-4.1782e-15,148.49) / (3.3399,-0.010592,248.4) m |
| Blade polyline lengths | 100.0820023 / 100.08213255 / 100.08994901 m; slight differences retained, no enforced artificial symmetry |
| Distributed tower mass | 859,784.7217775 kg |
| Distributed blade masses | 111,605.6077204 / 111,608.51056316 / 111,623.5158537 kg |
| Distributed transition mass | 26,488.79692805 kg |
| Nacelle / hub masses | 1,184,500 / 196,000 kg |
| Total mass | 2,601,611.152842823 kg (piecewise line masses + rigid bodies) |
| Nacelle principal inertias | (14,806,000;32,672,000;32,672,000) kg m² |
| Hub principal inertias | (2,822,400;2,822,400;2,822,400) kg m² |
| Body centroid offsets | both zero, explicit collocation assumption |
| Body orientation input | passive ZXZ (90,-5,-90) degrees, code matrix passiveZ(angle3)*passiveX(angle2)*passiveZ(angle1) |
| Periodic campaign connection | translations 1e9 N/m each; rotations 1e10 N m/rad each; `cases/config_aeroelastic_snl100.m`, explicitly illustrative and uncalibrated |
| Periodic campaign damping | Rayleigh zeta=0.005 at 0.17 and 1 Hz, coefficients set in `run_rotor_orders.m`, not identified damping |

Section properties are piecewise constant per original element. Tower/transition section ranges: m=3683.848--9281.055 kg/m, EA=9.85488e10--2.48283e11 N, GA2=GA3=1.895169230769e10--4.774511538462e10 N, GJ=3.382938461538e11--2.801965384615e12 N m², EI2=EI3=4.39782e11--3.64245e12 N m². Blade ranges: m=87.11848574--2792.46066124 kg/m, EA=1.27e9--4.1276e10 N, GA2=GA3=2.4979e7--1.0089e10 N, GJ=3.3663e6--7.6492e10 N m², EI2=6.5319e6--1.545e11 N m², EI3=1.6159e8--1.5828e11 N m². Published table should round sensible digits, preserve distinct geometry, and link code revision for full piecewise field.

## Symbolic consistency review

The fragment distinguishes global elastic K^0 from element K_e^ell, sectional 3x3 W_s from assembled W_A and global-axis 3x3 W_g, equilibrium q0 from dynamic perturbation q. Bold N is interpolation; scalar N_* is axial force. R0 rotates about a fixed nominal axis with fixed origin; no elastic yaw/pitch redefinition of the prescribed spin axis is added. Closed interpolation has cubic translations, quadratic bending rotations and linear axial/torsional fields, so products in consistent mass have polynomial degree at most six; four-point Gauss is exact for constant section H_s. This supports the integral mass formula and four-point statement.


## Final manuscript review

The final source distinguishes equilibrium trial displacement from elastic perturbations, the pure spin rotation from the oriented sectional frame, and sectional from assembled spin matrices. It explicitly includes full periodic transport with damping and angular acceleration, and identifies the spin-load Jacobian already present in the equilibrium tangent. Three root penalty links are replaced by exact linear compatibility; the fourth inherited nacelle/hub connector is replaced by the declared elastic drivetrain.
