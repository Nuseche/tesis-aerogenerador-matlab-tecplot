# Code organization and naming

The supplied Diego Turello implementation separates geometry (`GeoTorre`),
section properties (`Secciones`), assembly, boundary conditions and the frequency
solution. Retain this physical order while keeping reusable operations in the
existing MATLAB packages. Original authorship and source bytes are preserved
under `reference/original`; the maintained implementation is English.

- Use `snake_case.m` for functions and make the first function match its filename.
- Name files by responsibility: `assemble_structural_matrices`,
  `config_seismic_verification`, `export_campbell_verification`.
- Use `test_<behavior>.m` for function-based tests and `Test<Name>.m` for test classes.
- Use short English `camelCase` local variables and structure fields. Retain
  conventional mechanical symbols such as `M`, `Ke`, `Kg`, `G`, `T`, and `q`.
- Start each public function with a help line naming its purpose. Document inputs,
  units, frames, assumptions, and output meaning where these are not obvious.
- Use `%%` sections for major stages. Explain why a calculation is needed instead
  of narrating individual assignments or referring to past implementation plans.
- Put model data in `data`, executable examples in `cases`, study drivers in
  `studies`, and generated files in `runs` or `output` (or ignored study outputs).
- Resolve paths from the source location or explicit arguments. Do not add the
  original reference tree recursively to the MATLAB path.
- Preserve input records, reference data and accepted run snapshots. A changed
  source fingerprint requires a new sensitivity campaign; never force a cached
  campaign to accept a different implementation.

The serialized `actionNN` keys, reference input filenames and historical run IDs
are compatibility identifiers. Changing them is a data-format migration, not a
cosmetic rename. New public files must not use dates or action numbers as their
primary description.
