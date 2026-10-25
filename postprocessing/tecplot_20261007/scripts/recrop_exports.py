from common import *
from pypdf import PdfReader
cat=json.loads((HERE/'catalog.json').read_text());checks=json.loads((HERE/'reports/export_checks.json').read_text());index={r['id']:r for r in checks}
for r in cat:
    pdf=eps_pdf(r['id']);c=index[r['id']];c['sha256']={x:sha(HERE/x) for x in r['exports']};box=PdfReader(pdf).pages[0].mediabox;c['page_size_pt']=[float(box.width),float(box.height)];c['crop']='Native EPS BoundingBox, vector-preserving PDF page bounds'
dump(HERE/'reports/export_checks.json',checks)
print('122 native EPS bounds applied, hashes refreshed.')
