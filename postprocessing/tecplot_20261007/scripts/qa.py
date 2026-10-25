"""Review montages only; never draws final scientific figures."""
from common import *
from PIL import Image,ImageDraw,ImageFont
import argparse

def main():
    a=argparse.ArgumentParser();a.add_argument('--prefix',default='sheet');opt=a.parse_args()
    cat=json.loads((HERE/'catalog.json').read_text());items=[r for r in cat if (HERE/'figures'/f'{r["id"]}.png').exists()]
    for j in range(0,len(items),4):
        canvas=Image.new('RGB',(1800,1400),'white');d=ImageDraw.Draw(canvas)
        for k,r in enumerate(items[j:j+4]):
            im=Image.open(HERE/'figures'/f'{r["id"]}.png').convert('RGB');im.thumbnail((870,625))
            x=(k%2)*900;y=(k//2)*700;canvas.paste(im,(x+(900-im.width)//2,y+35))
            d.text((x+20,y+10),r['id'],fill='black');d.text((x+20,y+674),r['representation'],fill='black')
        canvas.save(HERE/'qa'/f'{opt.prefix}_{j//4+1:02d}.png')
    print(f'{len(items)} figures in {(len(items)+3)//4} review sheets.')

if __name__=='__main__':main()
