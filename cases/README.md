# Analysis configurations

Call configurations through `main('cases/<name>.m')`. The loader resolves paths
from the repository and temporarily adds the case directory for dependencies.
For direct calls, use `addpath('cases')` first.

| Configuration | Purpose |
| --- | --- |
| `config_aeroelastic_snl100.m` | Weak section-force coupling for the full turbine |
| `config_maza_isolated_blade.m` | Isolated-blade operating conditions from Maza et al.; default U = 1 m/s, Ω = 0.7547 rad/s |
| `config_stationary_modal.m` | Fixed-base conservative modes with an explicit illustrative drivetrain |
| `config_flexible_foundation.m` | Stationary model with the original soft-foundation matrices |
| `config_rotating_campbell.m` | Prescribed rotation, equilibrium, and modal sweep |
| `config_seismic_demo.m` | Short synthetic base-acceleration example |
| `config_beam_verification.m` | Two-node Timoshenko element and beam benchmarks |
| `config_constraint_verification.m` | Exact hub/root kinematic constraints |
| `config_rigid_body_verification.m` | Spatial masses and rigid-body inertia |
| `config_mass_verification.m` | Consistent mass and explicitly selected HRZ alternative |
| `config_equilibrium_verification.m` | Gravity/rotation equilibrium and geometric stiffness |
| `config_dynamic_operator_verification.m` | Gyroscopic, transport, and rotational operators |
| `config_campbell_verification.m` | MBC, quadratic eigenproblem and branch tracking |
| `config_seismic_verification.m` | Newmark integration, physical recovery, reactions and time refinement |
| `config_integral_verification.m` | Integrated checks, including named historical acceptance runs |
| `config_sensitivity_local.m` | Study settings for local derivatives; use the sensitivity study driver |
| `config_sensitivity_morris.m` | Study settings for the three-factor Morris design; use the Morris driver |

The two sensitivity configurations return study structures, not a `main` analysis
configuration. The integral verification case requires the archived runs listed
in its `canonicalRuns` field; ordinary analyses and the unit tests do not require
that archive.

Persisted `action02` through `action10` structure fields and artifact names remain
compatible with existing run files. Public configuration and exporter filenames
now describe the physical check; see [the migration map](../docs/repository_changes.md).

See [aeroelastic coupling](../docs/aeroelasticity.md) for configurable wind,
constant pitch, rotor motion, force-transfer assumptions and study commands.
