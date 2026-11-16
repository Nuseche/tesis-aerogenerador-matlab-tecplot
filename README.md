# Wind turbine structural solver

MATLAB implementation of a hybrid Timoshenko beam and rigid-body model.
The model includes the tower, blades, transition members, nacelle, hub,
kinematic constraints, and an explicit elastic drivetrain connection.

## Start here

From the repository root in MATLAB R2026a:

```matlab
results = main();  % Check geometry and input data.
results = main('cases/config_stationary_modal.m');
results = main('cases/config_seismic_demo.m');
```

The default case only checks geometry because the original input does not
specify a calibrated drivetrain stiffness. Numerical examples declare their
illustrative connection explicitly. All inputs use coherent SI units.

`main` accepts a configuration structure, an M-file returning one, or a MAT/JSON
configuration. Each run creates a separate `runs/run_*` directory containing
inputs, model, equilibrium, operators, results, checks, tables, and a log.

```matlab
addpath('tests');
run_all_tests();
regenerate_outputs('runs/<run-directory>');  % Re-export saved results.
```

## Repository layout

| Location | Purpose |
| --- | --- |
| `main.m`, `config_default.m` | Analysis entry point and default configuration |
| `+model`, `+io` | Model construction, data loading, configurations, persistence |
| `+elements`, `+assembly`, `+rigid` | Beam operators, global assembly, constraints and rigid bodies |
| `+equilibrium`, `+rotor`, `+modal`, `+dynamics` | Equilibrium, rotating transformations, modal and transient solutions |
| `+sensitivity`, `+validation`, `+post` | Sensitivity studies, verification, and result export |
| [cases](cases/README.md) | Executable configurations named by physical purpose |
| [data](data/README.md) | Small, versioned model inputs and reference evidence |
| [studies](studies/README.md) | Local sensitivity, Morris, parameter-grid and measured-input drivers |
| [tools](docs/verification.md) | Legacy import and numerical comparison utilities |
| [postprocessing/tecplot](postprocessing/tecplot/README.md) | Scientific datasets and native Tecplot macro generation |
| [reference](reference/README.md) | One byte-preserved original source set and its checksum manifest |
| [migration](docs/setup.md) | Optional restoration of archived numerical runs |

Generated runs, plots, native Tecplot packages, and local environments are not
source files and are excluded from Git. Manuscripts and presentation sources
are maintained in the [separate document repository](https://github.com/Nuseche/tesis-formulacion-overleaf).

## Working conventions

The physical progression follows the supplied Turello reference: geometry and
section properties, assembly, boundary conditions and connections, then solution
and output. The maintained code separates those stages into MATLAB packages.
Files and functions use descriptive English `snake_case` names; tests describe
the behavior they verify. Comments explain units, coordinate conventions,
assumptions, and numerical choices. See [code style](docs/code_style.md) and
[mechanical conventions](docs/conventions.md).

The numerical model uses linear perturbations about the selected state.
Rotating transients use local operators at frozen azimuth. Prescribed hub thrust
is not a coupled aerodynamic model. See [verification and scope](docs/verification.md)
for the references used in each comparison.

For a new computer, install dependencies and follow [setup and migration](docs/setup.md).
For the November repository reorganization and recovery of previous files, see
[repository changes](docs/repository_changes.md).
