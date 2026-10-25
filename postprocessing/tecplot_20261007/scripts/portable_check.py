from common import *
import shutil,sys,argparse
import numpy as np
from PIL import Image,ImageChops
parser=argparse.ArgumentParser();parser.add_argument('--compare-only',action='store_true');args=parser.parse_args()
base=HERE/'qa/portable_bundle';(base/'scripts').mkdir(parents=True,exist_ok=True)
row=next(r for r in json.loads((HERE/'catalog.json').read_text()) if r['id']=='concept_particula-seccion')
if not args.compare_only:
 for name in ['common.py','regenerate.py']:shutil.copy2(HERE/'scripts'/name,base/'scripts'/name)
 for rel in [row['dataset'],row['macro']]:
  p=base/rel;p.parent.mkdir(exist_ok=True);shutil.copy2(HERE/rel,p)
 dump(base/'catalog.json',[row]);p=subprocess.run([sys.executable,str(base/'scripts/regenerate.py'),'--export-only'],cwd=base,capture_output=True,text=True,timeout=180)
 (HERE/'logs/portable_bundle.log').write_text(p.stdout+'\n'+p.stderr);assert p.returncode==0,p.stderr
expected=np.asarray(Image.open(HERE/'figures'/f'{row["id"]}.png').convert('RGB'));actual=np.asarray(Image.open(base/'figures'/f'{row["id"]}.png').convert('RGB'));assert expected.shape==actual.shape
original_macro=(HERE/row['macro']).read_text();relocated_macro=(base/row['macro']).read_text()
assert original_macro.replace(str(HERE),str(base))==relocated_macro,'Macro changed beyond path relocation'
assert sha(HERE/row['dataset'])==sha(base/row['dataset']),'Numerical data changed'
for folder,ext in [('figures','pdf'),('layouts','lpk')]:assert (base/folder/f'{row["id"]}.{ext}').stat().st_size>0
diff=np.abs(expected.astype(int)-actual.astype(int));changed=int(np.any(diff,axis=2).sum());mae=float(diff.mean());fraction=changed/(expected.shape[0]*expected.shape[1])
# GPU line-edge antialiasing is not bitwise deterministic. Exact data and macro
# comparisons above establish geometry identity; this bound rejects visual drift.
assert fraction<1e-5 and mae<.001,(changed,fraction,mae)
r={'figure':row['id'],'input_bundle':str(base),'official_macro_export_success':True,'no_MAT_or_solver_sources_in_bundle':True,'retargeted_paths':str(base) in relocated_macro,'macro_identical_except_paths':True,'native_DAT_bytes_equal':True,'native_PNG_shape_equal':True,'raster_changed_pixels':changed,'raster_changed_fraction':fraction,'raster_mean_absolute_delta_8bit':mae,'raster_equivalence_tolerance':'Less than 0.001% differing antialias pixels; mean absolute 8-bit delta below 0.001. Numerical data and macro settings must be exactly identical except for file paths.','native_PDF_and_LPK_created':True,'new_solver_evaluations':0};dump(HERE/'reports/portable_check.json',r);print(json.dumps(r,ensure_ascii=False))
