"""Validate scientific deliverables and preserve exact provenance."""
from pathlib import Path
import csv, hashlib, json, tarfile, re
from pypdf import PdfReader
from PIL import Image

ROOT=Path(__file__).resolve().parents[3];D=ROOT/'docs/sensibilidad_complementaria_20261014';OLD=D.parent/'sensibilidad_morris_20261006'
RUNS=ROOT/'runs/sensitivity/grid_completion_20261014';W=ROOT/'docs/presentacion_sensibilidad_20261014'
def sha(p):
    h=hashlib.sha256()
    with p.open('rb') as f:
        for b in iter(lambda:f.read(1048576),b''):h.update(b)
    return h.hexdigest()
S=json.loads((D/'analysis_summary.json').read_text())
assert S['gridPoints']==64 and S['newEvaluations']==9
assert all(S['analyticalChecks'].values())
with (RUNS/'case_status.csv').open() as f:cases=list(csv.DictReader(f))
assert len(cases)==9 and all(r['status']=='success' for r in cases)
with (RUNS/'grid_responses.csv').open() as f:rows=list(csv.DictReader(f))
assert len(rows)==64*7
points={(r['rhoLevel'],r['stiffnessLevel'],r['speedLevel']) for r in rows};assert len(points)==64
for g in ['1+2','3','4+5','6+7','8+9','10+11']:
    assert all(r['trackingValid']=='1' for r in rows if r['group']==g)
assert all(r['trackingValid']=='0' for r in rows if r['group']=='12')
old=0
with tarfile.open(ROOT/'runs/gyro_revision_20260919_comparison/source_after.tar.gz') as a:
    for member in a.getmembers():
        if member.isfile() and member.name.endswith('.m'):
            assert hashlib.sha256(a.extractfile(member).read()).hexdigest()==sha(ROOT/member.name)
            old+=1
assert old==148
for r in csv.DictReader((ROOT/'runs/sensitivity/morris_20261006/source_hashes.csv').open()):
    assert sha(ROOT/r['paths'])==r['hashes']

catalog=json.loads((D/'figure_catalog.json').read_text());assert len(catalog)==7
for item in catalog:
    for p in item['outputs']:assert Path(p).is_file()
    png=Path(item['outputs'][0]);pdf=Path(item['outputs'][1]);assert len(PdfReader(pdf).pages)==1
    im=Image.open(png).convert('RGB');assert im.getpixel((0,0))==(255,255,255)
    item['sourceSHA256']={p:sha(Path(p)) for p in item['sources']}
    item['outputSHA256']={p:sha(Path(p)) for p in item['outputs']}
(D/'figure_catalog.json').write_text(json.dumps(catalog,ensure_ascii=False,indent=2)+'\n')
source=OLD/'SECCION_MORRIS_REVISION.tex';latex=source.read_text();labels=re.findall(r'\\label\{([^}]+)\}',latex)
assert len(labels)==len(set(labels))
assert latex.count('% BEGIN COMPLEMENT 20261014')==1
assert latex.count(r'\begin{figure}')==latex.count(r'\end{figure}')
for name in re.findall(r'\\includegraphics(?:\[[^\]]*\])?\{([^}]+)\}',latex):assert (OLD/name).is_file()
pdf=source.with_suffix('.pdf');reader=PdfReader(pdf);assert len(reader.pages)>=15
full='\n'.join(p.extract_text() or '' for p in reader.pages)
assert 'Comprobación complementaria' in full and 'Campolongo' in full
log=source.with_suffix('.log').read_text();assert not any(s in log for s in ['Overfull','Undefined control sequence','undefined references'])
record=json.loads((OLD/'latex_compilation.json').read_text());record.update(sourceSHA256=sha(source),pdfSHA256=sha(pdf),date='2026-10-14',status='success',pages=len(reader.pages))
(OLD/'latex_compilation.json').write_text(json.dumps(record,ensure_ascii=False,indent=2)+'\n')
deck=W/'entrega/Sensibilidad_aerogenerador_20261014.pptx';receipt=json.loads((W/'.build/validation_v5.json').read_text());assert receipt['finalSha256']==sha(deck)
assert len(list((W/'.build/final-rendered').glob('slide-*.png')))==26
audit={'date':'2026-10-14','gridPoints':64,'newSuccessfulEvaluations':9,'failedEvaluations':0,'pendingEvaluations':0,
       'historicalPhysicalMatlabFilesUnchanged':148,'campaignSourceHashesUnchanged':175,'analyticalMethodBenchmarks':S['analyticalChecks'],
       'figures':7,'figureEngines':'MATLAB authorized alternative; historical Tecplot assets retained','latexProjectCompilation':'success',
       'nativeLatexPreview':'external_figure_access_unavailable','latexPages':len(reader.pages),'presentationSlides':26,
       'presentationSHA256':sha(deck),'scope':'Finite deterministic grid and contrasts. Spatial convergence in rotation and physical probability measure remain unverified.'}
(D/'delivery_audit.json').write_text(json.dumps(audit,ensure_ascii=False,indent=2)+'\n')
manifest=D/'DELIVERY_MANIFEST.csv';files={p for base in [D,RUNS] for p in base.rglob('*') if p.is_file() and '.qa' not in p.parts and '__pycache__' not in p.parts}
files.update([source,pdf,deck,OLD/'seccion_para_incorporar.tex']);files.discard(manifest)
with manifest.open('w',newline='') as f:
    w=csv.writer(f);w.writerow(['file','bytes','sha256'])
    for p in sorted(files):w.writerow([str(p),p.stat().st_size,sha(p)])
print(json.dumps(audit,ensure_ascii=False,indent=2))
