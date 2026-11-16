# Repository reorganization — 2026-11-16

The tracked working tree decreased from 2,047 files (202.54 MB) to 287 files
(11.68 MB). These sizes exclude Git history, local runs and environments.

The maintained tree separates solver packages, executable cases, numerical
studies, inputs, original reference sources, tests and Tecplot postprocessing.
Geometry and section data precede assembly, constraints and solution, following
the organization of the supplied Turello code. Existing MATLAB package names
and the public `main` entry point are retained.

## Source names and compatibility

Numbered development actions now have physical names. For example:

| Previous entry point | Current entry point |
| --- | --- |
| `config_action02_timoshenko` | `config_beam_verification` |
| `config_action03_rigid_constraints` | `config_constraint_verification` |
| `config_action04_rigid_bodies` | `config_rigid_body_verification` |
| `config_action05_mass_formulation` | `config_mass_verification` |
| `config_action06_equilibrium` | `config_equilibrium_verification` |
| `config_action07_dynamic_operators` | `config_dynamic_operator_verification` |
| `config_action08_mbc_qep_campbell` | `config_campbell_verification` |
| `config_action09_seismic_newmark` | `config_seismic_verification` |
| `config_action10_full_acceptance` | `config_integral_verification` |
| `run_mecom_comparison2026` | `run_rom_benchmark` |
| `run_mecom_mesh_refinement2026` | `run_mesh_refinement` |
| `analyze_rigid_modes_mecom2026` | `analyze_rigid_modes` |
| `generate_comprehensive_evidence` | `export_rigid_mode_evidence` |
| `extract_journal_operating_evidence` | `export_operating_evidence` |

Related test and export functions use the same physical terminology. Serialized
`actionNN` fields, saved result filenames and historical run IDs retain their
original schema so that existing MAT/CSV data remain readable. Use the new case
filenames for new analyses. The integral verification status is now
`configured_integral_verification`.

Study scripts formerly embedded in dated documentation folders now live in
`studies/local_sensitivity`, `studies/morris`, `studies/parameter_grid` and
`studies/measured_inputs`. Drivers accept explicit campaign locations, and new
runs default to `runs/studies`. The original source mirrors were consolidated
into one checksum-protected `reference/original` tree. Original source bytes,
filenames inside that tree, and source-record metadata preserve their provenance.
Maintained filenames, comments and plot labels are English.

## Removed material and recovery

The active tree no longer stores manuscript or slide copies, old delivery
reports, nested source archives, duplicate originals, or rendered figure formats
that can be generated from the retained scripts. Numerical run archives and
machine-specific environments remain local and ignored. Tecplot data, macros
and exports are generated in `output/tecplot`.

The tag `cleanup-baseline-20261116` preserves the complete previous tracked tree.
Inspect it without changing the working tree:

```sh
git ls-tree -r --name-only cleanup-baseline-20261116
git show cleanup-baseline-20261116:path/to/previous/file
```

This is a working-tree cleanup, not a rewrite of Git history. Earlier large files
remain in repository history. The [separate manuscript repository](https://github.com/Nuseche/tesis-formulacion-overleaf)
continues to hold the documents.

## Verification

The baseline MATLAB suite passed all 160 tests. The reorganized tree is checked
with the same suite, MATLAB syntax analysis, input/source checksums and Python
source checks. Tecplot preparation is verified independently of licensed native
export. See [verification](verification.md) and [setup](setup.md).
