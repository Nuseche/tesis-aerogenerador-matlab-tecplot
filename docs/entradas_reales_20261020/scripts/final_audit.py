"""Read-only delivery verification plus a reproducible file manifest."""
from pathlib import Path
import csv
import hashlib
import json
import math
import zipfile
from PIL import Image, ImageChops
from pypdf import PdfReader

ROOT=Path('/Users/nuseche/Desktop/Tesis_codigos')
DOCS=ROOT/'docs/entradas_reales_20261020'
DECK=Path('/Users/nuseche/Documents/ChatGPT/Tesis/output/presentacion_comparativa_20261020')
PPTX=DECK/'entrega/Resultados_comparativos_20261020.pptx'
TEX=ROOT/'docs/sensibilidad_morris_20261006/SECCION_MORRIS_REVISION.tex'
PDF=TEX.with_suffix('.pdf')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(name):return json.loads((DOCS/name).read_text())
def table(p):return list(csv.DictReader(p.open()))
def flag(v):return str(v).lower() in ['true','1']


def main():
    frozen=table(ROOT/'runs/sensitivity/morris_20261006/source_hashes.csv')
    changed=[r['paths'] for r in frozen if sha(ROOT/r['paths'])!=r['hashes']]
    assert len(frozen)==175 and not changed
    s=read('analysis_summary.json');ref=read('refined_tangent_summary.json');values=read('report_values.json')
    assert values['sourceSha256']==sha(TEX)
    assert s['caseCount']==114 and ref['successfulCases']==54
    kernel=read('kernel_identity_verification.json');assert max(max(x) for x in kernel['checks'])<1e-13
    combined=read('combined_load_verification.json')
    assert max(combined[k] for k in ['historyQ','historyA','historyR'])<1e-7
    local=table(DOCS/'tables/refined_local_sensitivities.csv')
    assert len(local)==90 and sum(flag(r['accepted']) for r in local)==ref['accepted']
    assert sum(flag(r['stepConverged']) for r in local)==ref['stepConverged']
    diagnostic=table(DOCS/'tables/tangent_diagnostic.csv')
    diagnostic_failed=[r for r in diagnostic if r['status']!='success']
    assert len(diagnostic_failed)==1  # retained, explicitly reported
    for path in ['case_status.csv','aligned_status.csv','refinement_status.csv']:
        rr=table(ROOT/'runs/sensitivity/real_inputs_20261020'/path)
        key='status';assert all(r[key].startswith('success') for r in rr),path
    rr=table(ROOT/'runs/sensitivity/real_inputs_20261020/refined_tangent/case_status.csv')
    assert len(rr)==54 and all(r['status'].startswith('success') for r in rr)
    p=table(DOCS/'tables/arrival_phase_comparison.csv');assert len(p)==41*29*6
    assert all(math.isfinite(float(r['combinedPeak'])) for r in p)
    assert max(float(r['earthquakeArrivalSeconds']) for r in p)+39.98<=599.96+1e-10
    assert all(float(r['combinedPeak'])<=float(r['sumOfSeparatePeaks'])*(1+1e-12) for r in p)
    amp=table(DOCS/'tables/input_amplitude_sensitivities.csv')
    assert all(r['S_meanThrust']=='NaN' for r in amp if not flag(r['thrustNormalizationDefined']))
    image_checks=[]
    catalog=read('figure_catalog.json')
    for item in catalog:
        assert item['engine']=='MATLAB R2026a'
        path=DOCS/'figures'/(item['id']+'.png');assert path.exists() and path.with_suffix('.pdf').exists()
        with Image.open(path) as image:
            rgb=image.convert('RGB');r,g,b=rgb.split()
            assert ImageChops.difference(r,g).getbbox() is None
            assert ImageChops.difference(r,b).getbbox() is None
            image_checks.append({'id':item['id'],'size':list(image.size),'sha256':sha(path),'grayscale':True})
    log=TEX.with_suffix('.log').read_text()
    assert not any(t in log for t in ['Overfull','undefined references','Undefined control sequence','! LaTeX Error'])
    pages=len(PdfReader(PDF).pages);assert pages==25
    with zipfile.ZipFile(PPTX) as z:
        slides=[n for n in z.namelist() if n.startswith('ppt/slides/slide') and n.endswith('.xml')]
        assert len(slides)==14
    receipt=json.loads((DECK/'.build/validation_v3.json').read_text())
    assert receipt['finalSha256']==sha(PPTX)
    assert receipt['packageIntegrity']['status']=='pass'
    native=read('native_compilation.json')
    assert native['status']=='compile-failed' and native['projectTectonicCompilationSucceeded']
    result=dict(date='2026-10-20',frozenSourcesChecked=175,changedSources=changed,
        comparisonCases=114,refinedHessianCases=54,diagnosticSuccesses=6,diagnosticFailures=diagnostic_failed,
        stableSlopes=ref['stepConverged'],fullyAcceptedSlopes=ref['accepted'],localIndicators=90,
        directlyVerifiedCombinedLoad=combined,kernelIdentity=kernel,figures=image_checks,
        pdf={'path':str(PDF),'pages':pages,'sha256':sha(PDF),'projectCompilation':'success',
             'nativeEditorCompilation':'external figure unavailable'},
        pptx={'path':str(PPTX),'slides':14,'sha256':sha(PPTX),'validatedBy':'Artifact Tool; native PowerPoint not inspected'},
        scope='independent real records; prescribed mean thrust parameter; frozen operators; no global mechanical ranking')
    (DOCS/'delivery_audit.json').write_text(json.dumps(result,ensure_ascii=False,indent=2))
    included=[p for p in DOCS.rglob('*') if p.is_file() and '.qa' not in p.parts and '__pycache__' not in p.parts and p.name!='DELIVERY_MANIFEST.csv']+[TEX,PDF,PPTX]
    with (DOCS/'DELIVERY_MANIFEST.csv').open('w') as f:
        w=csv.writer(f);w.writerow(['path','bytes','sha256']);w.writerows((str(p),p.stat().st_size,sha(p)) for p in sorted(included))
    print(json.dumps({k:result[k] for k in ['comparisonCases','refinedHessianCases','stableSlopes','fullyAcceptedSlopes','pdf','pptx']},indent=2))


if __name__=='__main__':main()
