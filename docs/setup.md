# Setup and migration

## MATLAB

Clone the private repository and use MATLAB R2026a (the tested release):

```sh
git clone https://github.com/Nuseche/tesis-aerogenerador-matlab-tecplot.git
cd tesis-aerogenerador-matlab-tecplot
matlab -batch "results = main();"
matlab -batch "addpath('tests'); run_all_tests();"
```

Run commands from the clone root. `main` resolves input and case paths relative
to that root. Build a fresh configuration for a new machine; stored run
configurations retain the absolute paths of their original execution.

## Python and Tecplot

Python 3.11+ is required (3.12 is used locally). Create a new environment:

```sh
python -m venv .venv
# Linux/macOS:
source .venv/bin/activate
# Windows PowerShell: .venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
python migration/preflight.py
python tools/check_repository.py
```

MATLAB and Tecplot are separately installed applications. Native Tecplot export
requires a valid license on the executing computer. Configure the executable,
not the installation directory:

```sh
export TECPLOT_EXECUTABLE='/path/to/tecplot/bin/tec360'
export GHOSTSCRIPT_EXECUTABLE='/path/to/gs'
# PowerShell uses $env:TECPLOT_EXECUTABLE = 'C:\path\tec360.exe'
```

Ghostscript converts native EPS to PDF. Transparent 3D exports use the native
Tecplot PNG in a lossless PDF container. The macro workflow does not require
PyTecplot. See [the export workflow](../postprocessing/tecplot/README.md).

## Archived runs

A clean clone contains the solver, test inputs and study drivers. Large saved
runs are optional and are distributed separately. To reproduce historical
postprocessing, download the data release with an authorized GitHub account:

```sh
gh release download migration-data-20261025 \
  --repo Nuseche/tesis-aerogenerador-matlab-tecplot \
  --pattern 'persisted-data.tar.zst' --dir .migration-cache
python migration/data_bundle.py restore --asset-dir .migration-cache
```

The manifest in `migration/data_manifest.json` records the original paths,
sizes and SHA-256 hashes. Restoration rejects different existing files and
paths outside the clone. Use a clean clone to restore a conflicting archive.
Reserve space for the approximately 1.55 GB archive and 5 GB of extracted data.

Source fingerprints change when code or tests change. Create a new sensitivity
campaign for the current implementation. Existing saved campaigns can be read
and postprocessed, but must not be relabeled or force-resumed under a different
fingerprint. The baseline tag `cleanup-baseline-20261116` preserves the previous
source tree for exact historical reconstruction.
