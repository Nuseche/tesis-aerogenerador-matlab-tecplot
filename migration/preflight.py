"""Read-only checks of a relocated checkout; no solver or Tecplot invocation."""
from pathlib import Path
import importlib, json, os, shutil, sys
ROOT=Path(__file__).resolve().parents[1]
LIB=ROOT/'postprocessing/tecplot_20261007'

def main():
    missing=[]
    for module in ['numpy','scipy','h5py','hdf5storage','PIL','pypdf']:
        try:importlib.import_module(module)
        except ImportError:missing.append('Python module '+module)
    for name in ['main.m','config_default.m','data/geometry/legacy_geometry_v0.mat','data/sections/legacy_sections_v0.mat','data/reference/legacy_fixed_base_frequencies_v0.mat','data/rigid_bodies/legacy_rigid_bodies_v0.json']:
        if not (ROOT/name).is_file():missing.append(name)
    catalog=json.loads((LIB/'catalog.json').read_text())
    for row in catalog:
        for key in ['dataset','macro','package']:
            if not (LIB/row[key]).is_file():missing.append(row[key])
    old='/Users/nuseche/Desktop/Tesis_codigos/'
    sources=set(p for row in catalog for p in row['sources'])
    raw_missing=[]
    for path in sources:
        if path.startswith(old):p=ROOT/path[len(old):]
        elif '/tesis_cinematica_20260929/' in path:p=ROOT/'docs/tesis_cinematica_20260929'/path.split('/tesis_cinematica_20260929/',1)[1]
        else:p=Path(path)
        if not p.is_file():raw_missing.append(str(p.relative_to(ROOT)) if p.is_relative_to(ROOT) else str(p))
    print(json.dumps({'checkout':str(ROOT),'native_figures':len(catalog),'required_missing':missing,'raw_sources_missing_restore_release':sorted(raw_missing),'matlab_executable':shutil.which('matlab'),'tecplot_executable':os.environ.get('TESIS_TECPLOT') or shutil.which('tec360'),'license_checked':False},indent=2))
    return 1 if missing else 0

if __name__=='__main__':sys.exit(main())
