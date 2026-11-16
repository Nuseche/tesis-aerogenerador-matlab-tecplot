# Numerical reference evidence

`legacy_fixed_base_frequencies_v0.mat` and its CSV contain the first twenty
frequencies generated on 25 August 2026 by the unmodified Version 0 program.
That program uses Euler-Bernoulli stiffness, penalty connectors and absolute
row-sum diagonal mass. These values describe the historical implementation;
they are not a target that the current Timoshenko model must match physically.

`operating_results.json` is the compact, archived extraction of corrected
September operating and seismic cases, together with stationary ROM and
rigid-mode evidence. Tecplot uses it without rerunning the solver. The source
run identifiers and scientific scope remain embedded in the file.
`tools/export_operating_evidence.m` can produce a new extraction under `output`
from the corresponding restored MAT files.

The `source` paths inside historical artifacts retain their original spellings.
The live original source is now in `reference/original/turello_v0`; the path
change does not alter the artifact bytes or their original checksums.
