"""Validate provenance, installed graphics, equivalent editions and monochrome."""
from common import *
from PIL import Image,ImageChops
from pypdf import PdfReader
from collections import Counter
import shutil

def expand(p,seen=None):
    seen=seen or set();p=Path(p)
    if p in seen:return ''
    seen.add(p);s=p.read_text()
    return re.sub(r'\\input\{([^}]+)\}',lambda m:expand(p.parent/(m.group(1)+('.tex' if not m.group(1).endswith('.tex') else '')),seen),s)
def normalized_pdf(p):return re.sub(r'\s+','', ''.join(q.extract_text() or '' for q in PdfReader(p).pages))
def main():
    catalog=json.loads((HERE/'catalog.json').read_text());exports=json.loads((HERE/'reports/export_checks.json').read_text());ex={r['id']:r for r in exports};docs=json.loads((HERE/'reports/document_checks.json').read_text());byhash={sha(HERE/'figures'/f'{r["id"]}.pdf'):r['id'] for r in catalog};installed=[]
    for r in catalog:r['installed_in']=[]
    byid={r['id']:r for r in catalog}
    for d in docs:
        p=Path(d['source']);s=expand(p)
        for m in re.finditer(r'\\includegraphics(?:\[[^]]*\])?\{([^}]+)\}',s):
            f=p.parent/m.group(1);f=f.with_suffix('.pdf') if not f.suffix else f
            if not f.exists():continue
            key=byhash.get(sha(f))
            if key:
                row={'document':str(p),'installed_file':str(f),'sha256':sha(f)};byid[key]['installed_in'].append(row);installed.append({'figure':key,**row})
    imagechecks=[]
    for r in catalog:
        im=Image.open(HERE/'figures'/f'{r["id"]}.png').convert('RGB');a,b,c=im.split();mono=ImageChops.difference(a,b).getbbox() is None and ImageChops.difference(b,c).getbbox() is None
        assert mono,r['id'];imagechecks.append({'id':r['id'],'pixel_size':im.size,'exact_grayscale':mono})
        native='UseTranslucency = Yes' in (HERE/r['macro']).read_text();r['publication_export']={'pdf_content':'lossless native Tecplot PNG' if native else 'native Tecplot vector EPS converted to PDF','native_png_width':im.width,'EPS_limitation':'Vector EPS makes translucent surfaces opaque; use the supplied PNG/PDF for this scene.' if native else None}
        for f in [r['dataset'],r['macro'],r['layout'],r['package'],*r['exports'],'data/'+r['id']+'.plt']:assert (HERE/f).stat().st_size>0,f
        ex[r['id']]['sha256']={f:sha(HERE/f) for f in r['exports']};box=PdfReader(HERE/'figures'/f'{r["id"]}.pdf').pages[0].mediabox;ex[r['id']]['page_size_pt']=[float(box.width),float(box.height)];ex[r['id']]['pdf_content']=r['publication_export']['pdf_content']
        r['source_fingerprints']={p:sha(p) for p in r['sources'] if Path(p).is_file()}
    protected=json.loads((HERE/'reports/protected_before.json').read_text());changed=[p for p,h in protected.items() if not Path(p).is_file() or sha(p)!=h];assert not changed,changed
    equivalence=[]
    for a,b in [(THESIS/'tesis_autocontenida.pdf',THESIS/'tesis_modelo.pdf')]+[(ROOT/f'docs/formulacion_revista_20260919/FCEFyN_{lang}.pdf',ROOT/f'output/latex/{edition}/FCEFyN_{lang}.pdf') for edition in ['FCEFyN_Formulacion_Bilingue','FCEFyN_Overleaf'] for lang in ['ES','EN']]:
        same=normalized_pdf(a)==normalized_pdf(b);assert same,(a,b);equivalence.append({'sources':[str(a),str(b)],'extracted_text_equivalent':same})
    for d in docs:
        log=Path(d['source']).with_suffix('.log').read_text(errors='replace');assert not re.search(r'(?:Reference|Citation).*undefined|multiply defined',log),d['source']
    dump(HERE/'catalog.json',catalog);dump(HERE/'reports/export_checks.json',list(ex.values()));dump(HERE/'reports/installed_figures.json',installed)
    dump(HERE/'reports/final_checks.json',{'figures':len(catalog),'representation_counts':dict(Counter(r['representation'] for r in catalog)),'exact_grayscale_all':True,'image_checks':imagechecks,'protected_files_checked':len(protected),'protected_files_changed':changed,'new_solver_evaluations':0,'equivalent_editions':equivalence,'documents_compiled':len(docs),'unresolved_references':0,'installed_graphic_references':len(installed),'vector_figures':sum(r['publication_export']['pdf_content'].startswith('native') for r in catalog),'translucent_3D_lossless_PDFs':sum(r['publication_export']['pdf_content'].startswith('lossless') for r in catalog)})
    # Keep superseded drawings recoverable, outside the current figure library.
    ids=set(byid)
    for folder in ['figures','macros','layouts','data']:
        for p in (HERE/folder).iterdir():
            if p.is_file() and p.suffix in ['.png','.pdf','.eps','.mcr','.lay','.lpk','.dat','.plt'] and p.stem not in ids:
                dst=HERE/'archive'/('superseded_'+folder);dst.mkdir(exist_ok=True);shutil.move(p,dst/p.name)
    failed=HERE/'qa/reference_documents/Simo_VuQuoc_1986.pdf'
    if failed.exists() and failed.stat().st_size==0:failed.unlink()
    engine=json.loads((HERE/'reports/engine.json').read_text());engine['PDF_conversion']='Vector EPS: Ghostscript and native bounding-box crop. Translucent 3D: lossless native Tecplot PNG in PDF container; no scientific redraw.';dump(HERE/'reports/engine.json',engine)
    print(f'{len(catalog)} grayscale figures; {len(protected)} protected files unchanged; {len(installed)} installed graphic references; {len(equivalence)} equivalent edition pairs.')
if __name__=='__main__':main()
