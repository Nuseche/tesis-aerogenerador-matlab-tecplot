"""Snapshot editorial sources and fingerprint protected physics before edits."""
from common import *
import re, zipfile

DOCS=[ROOT/'docs'/x for x in ['formulacion_revista_20260919','formulacion_matematica_20260919','manuscrito_integrado_20260919','sensibilidad_20261005','sensibilidad_morris_20261006']]+[THESIS,ROOT/'output/latex/FCEFyN_Formulacion_Bilingue']

def main():
    snapshot=HERE/'archive/editorial_before_tecplot.zip'
    inventory=[]
    if not snapshot.exists():
        with zipfile.ZipFile(snapshot,'w',zipfile.ZIP_DEFLATED) as z:
            for d in DOCS:
                for p in d.rglob('*'):
                    if p.is_file() and p.suffix.lower() in ['.tex','.cls','.bib','.bst','.md','.pdf','.json'] and 'evidence' not in p.parts:
                        base=ROOT if p.is_relative_to(ROOT) else THESIS.parent
                        z.write(p,('solver/' if base==ROOT else 'editorial/')+str(p.relative_to(base)))
    for base in [ROOT/'docs',THESIS]:
        for p in base.rglob('*.tex'):
            s=p.read_text(errors='replace')
            for block in re.findall(r'\\begin\{figure\}.*?\\end\{figure\}',s,re.S):
                labels=re.findall(r'\\label\{([^}]+)\}',block)
                graphics=re.findall(r'\\includegraphics(?:\[[^]]*\])?\{([^}]+)\}',block)
                engine='TikZ/PGFPlots' if 'tikzpicture' in block else 'external'
                inventory.append(dict(document=str(p),labels=labels,graphics=graphics,original_engine=engine,status='current_target' if any(p.is_relative_to(d) for d in DOCS) else 'historical_not_replaced'))
    dump(HERE/'reports/original_figure_inventory.json',inventory)
    target=HERE/'reports/protected_before.json'
    if not target.exists():
        files=list((ROOT/'src').rglob('*.m'))+list((ROOT/'data').rglob('*'))
        files += [p for d in [ROOT/'runs/run_20260919_182410_438_gyro_energy_corrected_20260919',ROOT/'runs/run_20260919_183052_480_gyro_corrected_seismic_20260919',ROOT/'runs/run_20260914_mecom_comparison',ROOT/'runs/sensitivity/initial_20261005',ROOT/'runs/sensitivity/morris_20261006'] for p in d.rglob('*') if p.suffix in ['.mat','.csv','.json']]
        dump(target,{str(p):sha(p) for p in files if p.is_file()})
    dump(HERE/'reports/source_relationships.json',{'formulation_article':'modular FCEFyN_ES/EN + cuerpo_es/en; distributed expanded copies','thesis':'tesis_autocontenida.tex is the current 35-figure source; older modular source had 14 figures','scope':'Base de capitulos de formulacion, no tesis institucional terminada','integrated_missing_inputs_before':['resultados_operativos.tex','apendices.tex'],'historical_reports':'Inventoried, retained and not silently promoted to corrected rotating results','new_solver_evaluations':0})
    print('Editorial snapshot and source audit saved.')

if __name__=='__main__':main()
