"""Compile existing multi-file projects; store diagnostics and figure-page QA."""
from common import *
from concurrent.futures import ThreadPoolExecutor
from pypdf import PdfReader
import argparse
import shutil

TECTONIC=Path(os.environ.get('TESIS_TECTONIC') or shutil.which('tectonic') or 'tectonic')
def compile_one(name):
    p=Path(name);tag=p.parent.name+'_'+p.stem;log=HERE/'logs'/('latex_'+tag+'.txt')
    r=subprocess.run([str(TECTONIC),'--keep-logs','--keep-intermediates',p.name],cwd=p.parent,capture_output=True,text=True,timeout=300)
    log.write_text(r.stdout+'\n'+r.stderr)
    pdf=p.with_suffix('.pdf');warnings=[s for s in (r.stdout+'\n'+r.stderr).splitlines() if 'warning:' in s or 'error:' in s]
    item=dict(source=str(p),pdf=str(pdf),compiler='Tectonic 0.15.0',exit_code=r.returncode,log=str(log.relative_to(HERE)),warnings=warnings)
    if r.returncode==0 and pdf.exists():
        reader=PdfReader(pdf);item['pages']=len(reader.pages);item['sha256']=sha(pdf);item['figure_pages']=[i+1 for i,q in enumerate(reader.pages) if re.search(r'(?:Figura|Figure)\s*\d+[.:]',q.extract_text() or '')]
    print(tag+': '+str(r.returncode),flush=True);return item

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--only',nargs='*');a=ap.parse_args()
    docs=json.loads((HERE/'reports/updated_documents.json').read_text())
    if a.only:docs=[x for x in docs if Path(x).stem in a.only]
    with ThreadPoolExecutor(max_workers=4) as pool:records=list(pool.map(compile_one,docs))
    path=HERE/'reports/document_checks.json';old=json.loads(path.read_text()) if path.exists() else [];merged={r['source']:r for r in old+records};dump(path,list(merged.values()))
    if any(r['exit_code'] for r in records):raise SystemExit(1)
if __name__=='__main__':main()
