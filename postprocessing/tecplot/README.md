# Scientific Tecplot export

The Python modules read archived MAT/CSV/JSON results and write native Tecplot
ASCII datasets and macros. They do not call MATLAB or recompute a structural
solution. Numerical charts, mode shapes, beam frames and the illustrative turbine
envelope are retained; manuscript-only diagrams and document-copying utilities
belong to the document repository.

After restoring archived runs, prepare the datasets:

```sh
python postprocessing/tecplot/regenerate.py --prepare-only
```

Outputs go to `output/tecplot` (ignored by Git). Inspect `catalog.json`, then
export on the computer with a valid Tecplot installation:

```sh
python postprocessing/tecplot/regenerate.py --export-only --only campbell
python postprocessing/tecplot/regenerate.py --export-only
```

Set `TECPLOT_EXECUTABLE` and optionally `GHOSTSCRIPT_EXECUTABLE`; legacy
`TESIS_TECPLOT`/`TESIS_GHOSTSCRIPT` variables remain accepted for compatibility.
Set `TURBINE_TECPLOT_OUTPUT` to an absolute directory to prepare or re-export a
portable bundle elsewhere. Copy the whole generated directory: its catalog,
DAT files and macros are sufficient for `--export-only`; raw MAT files are
required only for rebuilding datasets. The wrapper retargets macro paths.

Each export can produce DAT, PLT, LAY, LPK, EPS, PNG and PDF. These are generated
formats of the same figure, not separate sources to commit. Titles and captions
stay in manuscript text. Plot labels, legends and generated filenames are English.

The outer turbine surfaces are illustrative geometry and add no model degrees
of freedom, mass or stiffness. Mode shapes are individual complex branches
with explicit phase and normalization. The stationary ROM campaign is kept
separate from the corrected rotating campaign. Source identifiers and numerical
checks are included in the generated catalog and reports.
