"""Poppler page renders and review montages, separate from final figure exports."""
from common import *
from PIL import Image,ImageDraw
from concurrent.futures import ThreadPoolExecutor

def render(job):
    doc,page=job;pdf=Path(doc['pdf']);tag=pdf.parent.name+'_'+pdf.stem;dest=HERE/'qa/documents'/tag;dest.mkdir(parents=True,exist_ok=True)
    out=dest/f'page_{page:03d}'
    subprocess.run(['pdftoppm','-f',str(page),'-l',str(page),'-r','110','-png','-singlefile',str(pdf),str(out)],check=True,capture_output=True)
    return str(out.with_suffix('.png'))
def main():
    docs=json.loads((HERE/'reports/document_checks.json').read_text());unique=[d for d in docs if Path(d['source']).stem!='tesis_modelo' and Path(d['source']).parent.name not in ['FCEFyN_Formulacion_Bilingue','FCEFyN_Overleaf']]
    jobs=[]
    for d in unique:
        pages=set(d['figure_pages'])
        if Path(d['source']).stem.startswith('FCEFyN'):pages.update(range(1,d['pages']+1))
        if Path(d['source']).stem=='MANUSCRITO_INTEGRADO':pages.update([4,5,12,15,17])
        for p in sorted(pages):jobs.append((d,p))
    with ThreadPoolExecutor(max_workers=4) as pool:paths=list(pool.map(render,jobs))
    sheets=[]
    for j in range(0,len(paths),4):
        out=Image.new('RGB',(1680,2360),'#e4e4e4');dr=ImageDraw.Draw(out)
        for k,path in enumerate(paths[j:j+4]):
            im=Image.open(path).convert('RGB');im.thumbnail((820,1120));x=(k%2)*840;y=(k//2)*1180;out.paste(im,(x+(840-im.width)//2,y+35));dr.text((x+8,y+8),Path(path).parent.name+' '+Path(path).stem,fill='black')
        dest=HERE/'qa/documents'/f'review_{j//4+1:02d}.png';out.save(dest);sheets.append(str(dest))
    dump(HERE/'reports/document_visual_pages.json',{'page_renders':paths,'sheets':sheets,'status':'rendered_pending_visual_inspection'});print(f'{len(paths)} pages; {len(sheets)} sheets.')
if __name__=='__main__':main()
