#!/usr/bin/env python3
"""Check bilingual equation parity, original-equation preservation and figure links."""
from pathlib import Path
import re, json, subprocess, hashlib
from pypdf import PdfReader
ROOT=Path(__file__).resolve().parents[2]
PAPER=ROOT/'docs/formulacion_revista_20260919'
if not PAPER.exists():PAPER=ROOT/'Paper_mathematical_tesis'
if not PAPER.exists():PAPER=ROOT

def equations(s):
 return [re.sub(r'\s+','',m[1]) for m in re.findall(r'\\begin\{(equation\*?|align\*?)\}(.*?)\\end\{\1\}',s,re.S)]
report={'editions':{},'new_equations_identical':False}
new=[equations((PAPER/f'sections/apriori_{lang}.tex').read_text()) for lang in ['es','en']]
assert new[0]==new[1];report['new_equations_identical']=True
for lang in ['es','en']:
 f=PAPER/f'cuerpo_{lang}.tex';s=f.read_text();core=equations(s)
 # This baseline exists in the simulation repository; no fabricated comparison in the paper clone.
 baseline=subprocess.run(['git','show',f'e91de7e:docs/formulacion_revista_20260919/cuerpo_{lang}.tex'],cwd=ROOT,text=True,capture_output=True)
 preserved=None
 if baseline.returncode==0:
  assert equations(baseline.stdout)==core, 'Existing equations were changed'
  preserved=True
 combined=s+(PAPER/f'sections/apriori_{lang}.tex').read_text()
 assert not re.search(r'\\ref\{sec:',combined), 'Unnumbered sections require named hyperref links'
 labels=re.findall(r'\\label\{([^}]+)\}',combined)
 assert len(labels)==len(set(labels))
 refs=re.findall(r'\\(?:eqref|ref)\{([^}]+)\}',combined)
 assert not set(refs)-set(labels),set(refs)-set(labels)
 paths=re.findall(r'\\includegraphics(?:\[[^\]]*\])?\{([^}]+)\}',s)
 assert len(paths)==11 and all((PAPER/p).is_file() for p in paths)
 text='\n'.join(page.extract_text() for page in PdfReader(PAPER/f'FCEFyN_{lang.upper()}.pdf').pages)
 assert '??' not in text
 log=(PAPER/f'FCEFyN_{lang.upper()}.log').read_text()
 assert not any(x in log for x in ['Overfull \\hbox','undefined references','undefined citations','! LaTeX Error'])
 report['editions'][lang]={'original_display_blocks':len(core),'original_equations_preserved':preserved,'new_display_blocks':len(new[0]),'figures':len(paths),'pages':len(PdfReader(PAPER/f'FCEFyN_{lang.upper()}.pdf').pages),'pdf_sha256':hashlib.sha256((PAPER/f'FCEFyN_{lang.upper()}.pdf').read_bytes()).hexdigest()}
(PAPER/'revision_checks.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
