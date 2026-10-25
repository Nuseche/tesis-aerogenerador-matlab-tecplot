"""One entry point; no MATLAB, assembly, eigenproblem or new campaign calls."""
from common import *
import argparse, time
from pypdf import PdfReader

def retarget_macro(path):
    """Allow export-only from a copied bundle of the already converted data."""
    s=path.read_text();m=re.search(r'ReadDataSet\s+\'"([^"\n]+)"\'',s)
    if not m:raise ValueError('Missing dataset path: '+str(path))
    previous=Path(m.group(1)).parents[1]
    if previous!=HERE:path.write_text(s.replace(str(previous),str(HERE)))

def main():
    p=argparse.ArgumentParser();p.add_argument('--prepare-only',action='store_true');p.add_argument('--export-only',action='store_true');p.add_argument('--only',nargs='*');a=p.parse_args()
    if not a.export_only:
        import concepts,kinematics,spatial,science,body3d,extras
        originals=concepts.build();schematic=spatial.build(originals);charts,native=science.build();cat=schematic+[write_figure(f) for f in charts+extras.build()]+native+body3d.build()
        import paper_variants
        cat+=paper_variants.build(cat)
        dump(HERE/'catalog.json',cat)
    else:cat=json.loads((HERE/'catalog.json').read_text())
    if a.prepare_only:return
    checks=[]
    for i,f in enumerate(cat):
        if a.only and f['id'] not in a.only:continue
        t=time.time();retarget_macro(HERE/f['macro']);log=run_macro(HERE/f['macro']);pdf=eps_pdf(f['id']);r=PdfReader(pdf)
        assert len(r.pages)==1
        checks.append(dict(id=f['id'],engine='Tecplot 2025.2.2.88532',seconds=round(time.time()-t,3),export_status='verified_files',log=str(log.relative_to(HERE)),sha256={x:sha(HERE/x) for x in f['exports']},page_size_pt=list(map(float,r.pages[0].mediabox[2:4]))))
        print(f"{i+1}/{len(cat)} {f['id']}",flush=True)
    target=HERE/'reports/export_checks.json';old=json.loads(target.read_text()) if target.exists() else [];new={r['id']:r for r in old+checks};dump(target,list(new.values()))
    # At most three screensful of human-facing metadata, never raw engine logs.
    dump(HERE/'reports/engine.json',{'installed_application':str(TEC),'engine_version':'2025.2.2.88532, 17-Apr-2026','PyTecplot_version':'1.7.3','PyTecplot_status':'TecplotLicenseError: License Expired','connected_mode_status':'TecPLUS service expired','macro_batch_status':'export verified','active_GUI_trial_expiration':'2026-10-13','native_formats':['ASCII .dat','binary .plt','layout .lay','package .lpk','EPS','PNG'],'PDF_conversion':'Vector EPS: Ghostscript and native bounding-box crop. Translucent 3D: lossless Tecplot PNG in PDF container; no scientific redraw. EPS does not preserve translucency.','new_solver_evaluations':0})

if __name__=='__main__':main()
