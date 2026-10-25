"""Synchronize the Tecplot version; the former inline generator is archived."""
import runpy, sys
from pathlib import Path
p=Path(__file__).resolve().parents[3]/"postprocessing/tecplot_20261007/scripts/integrate_documents.py"
sys.path.insert(0,str(p.parent))
m=runpy.run_path(str(p));m["sensitivity_documents"]()
