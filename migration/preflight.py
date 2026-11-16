"""Read-only dependency and input checks for a relocated checkout."""
from pathlib import Path
import importlib
import json
import os
import shutil
import sys

ROOT = Path(__file__).resolve().parents[1]


def main():
    missing = []
    if sys.version_info < (3, 11):
        missing.append("Python 3.11 or newer")
    for module in ["numpy", "scipy", "h5py", "hdf5storage", "PIL", "pypdf", "zstandard"]:
        try:
            importlib.import_module(module)
        except ImportError:
            missing.append("Python module " + module)
    for name in ["main.m", "config_default.m", "data/geometry/legacy_geometry_v0.mat",
                 "data/sections/legacy_sections_v0.mat",
                 "data/reference/legacy_fixed_base_frequencies_v0.mat",
                 "data/rigid_bodies/legacy_rigid_bodies_v0.json",
                 "postprocessing/tecplot/regenerate.py"]:
        if not (ROOT / name).is_file():
            missing.append(name)
    result = {
        "checkout": str(ROOT), "required_missing": missing,
        "matlab_executable": shutil.which("matlab"),
        "tecplot_executable": os.environ.get("TECPLOT_EXECUTABLE") or os.environ.get("TESIS_TECPLOT") or shutil.which("tec360"),
        "ghostscript_executable": os.environ.get("GHOSTSCRIPT_EXECUTABLE") or shutil.which("gs") or shutil.which("gswin64c"),
        "historical_runs_present": (ROOT / "runs/sensitivity/morris_20261006/nominal.mat").is_file(),
        "license_checked": False,
    }
    print(json.dumps(result, indent=2))
    return int(bool(missing))


if __name__ == "__main__":
    sys.exit(main())
