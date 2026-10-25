"""Render the two revised article editions without repeating unchanged QA."""
from common import *
from document_qa import render
from concurrent.futures import ThreadPoolExecutor
from PIL import Image,ImageDraw


def main():
    docs=json.loads((HERE/'reports/document_checks.json').read_text())
    selected=[d for d in docs if Path(d['source']).parent==ROOT/'docs/formulacion_revista_20260919']
    jobs=[(d,p) for d in selected for p in range(1,d['pages']+1)]
    with ThreadPoolExecutor(max_workers=4) as pool:paths=list(pool.map(render,jobs))
    sheets=[]
    for j in range(0,len(paths),4):
        out=Image.new('RGB',(1680,2360),'#e4e4e4');dr=ImageDraw.Draw(out)
        for k,path in enumerate(paths[j:j+4]):
            im=Image.open(path).convert('RGB');im.thumbnail((820,1120));x=(k%2)*840;y=(k//2)*1180
            out.paste(im,(x+(840-im.width)//2,y+35));dr.text((x+8,y+8),Path(path).parent.name+' '+Path(path).stem,fill='black')
        dest=HERE/'qa/documents'/f'paper_review_{j//4+1:02d}.png';out.save(dest);sheets.append(str(dest))
    dump(HERE/'reports/paper_visual_pages.json',{'page_renders':paths,'sheets':sheets,'pdf_hashes':{d['pdf']:sha(d['pdf']) for d in selected},'status':'rendered_pending_visual_inspection'})
    print(f'{len(paths)} article pages rendered in {len(sheets)} contact sheets.')

if __name__=='__main__':main()
