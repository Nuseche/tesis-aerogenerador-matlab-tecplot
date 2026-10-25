"""Data conversion and Tecplot macro authoring. No Python graphics renderer."""
from pathlib import Path
import csv, hashlib, json, math, subprocess, os
import numpy as np
import re
import shutil

HERE = Path(__file__).resolve().parents[1]
ROOT = HERE.parents[1]
THESIS = Path(os.environ.get('TESIS_DOCUMENTS', str(ROOT/'docs/tesis_cinematica_20260929')))
TEC = Path(os.environ.get('TESIS_TECPLOT') or shutil.which('tec360') or shutil.which('tec360.exe') or '/Applications/Tecplot 360 EX 2025 R2/Tecplot 360 EX 2025 R2.app/Contents/MacOS/Tecplot 360 EX 2025 R2')
GHOSTSCRIPT = os.environ.get('TESIS_GHOSTSCRIPT') or shutil.which('gs') or shutil.which('gswin64c') or 'gs'
for d in ['data','macros','layouts','figures','logs','qa','reports','archive','packages']:
    (HERE/d).mkdir(exist_ok=True)
COLORS = ['CUSTOM1','CUSTOM2','CUSTOM3','CUSTOM4','CUSTOM5','CUSTOM6','CUSTOM7','CUSTOM8']
RGB = [(20,20,20),(90,90,90),(45,45,45),(115,115,115),(150,150,150),(175,175,175),(30,30,30),(200,200,200)]

def sha(path):
    h=hashlib.sha256()
    with open(path,'rb') as f:
        for b in iter(lambda:f.read(1048576),b''):h.update(b)
    return h.hexdigest()

def readcsv(path):
    return list(csv.DictReader(Path(path).open()))

def dump(path,obj):
    Path(path).write_text(json.dumps(obj,indent=2,ensure_ascii=False,allow_nan=False)+'\n')

def number(x):
    try:return float(x)
    except (ValueError,TypeError):return float('nan')

def txt(s):
    return str(s).replace("'"," ").replace('"',' ').replace('\n',' ')

class Figure:
    def __init__(self,name,title='',kind='conceptual',source=None,document=None,xlabel='',ylabel='',bounds=None,logx=False,logy=False,legend=True,width=7,height=4.4):
        self.name=name;self.title=title;self.kind=kind;self.source=source or [];self.document=document or []
        self.xlabel=xlabel;self.ylabel=ylabel;self.bounds=bounds;self.logx=logx;self.logy=logy;self.legend=legend;self.width=width;self.height=height
        self.zones=[];self.labels=[];self.notes=[];self.config={}
    def line(self,xy,name='',color=0,pattern='SOLID',symbols=False,only=False,filled=False):
        a=np.asarray(xy,dtype=float)
        if a.ndim!=2 or a.shape[1]!=2:raise ValueError((self.name,a.shape))
        if not np.isfinite(a).all():raise ValueError((self.name,'nonfinite zone',name))
        if len(a)==1:a=np.vstack([a,a])
        self.zones.append(dict(xy=a,name=name,color=color,pattern=pattern,symbols=symbols,only=only,filled=filled));return self
    def label(self,x,y,s,size=11,color=6):self.labels.append((x,y,s,size,color));return self
    def arrow(self,a,b,color=0,name=''):
        a=np.array(a,float);b=np.array(b,float);self.line([a,b],name,color)
        v=b-a;n=np.linalg.norm(v)
        if n>0:
            v=v/n;w=np.array([-v[1],v[0]]);d=min(.14,n*.2)
            self.line([b-d*v+.5*d*w,b,b-d*v-.5*d*w],color=color)
        return self
    def rect(self,x,y,w,h,color=6):return self.line([[x,y],[x+w,y],[x+w,y+h],[x,y+h],[x,y]],color=color)
    def ellipse(self,x,y,rx,ry=None,color=6):
        t=np.linspace(0,2*np.pi,81);return self.line(np.c_[x+rx*np.cos(t),y+(ry or rx)*np.sin(t)],color=color)
    def basis(self,x,y,angle=0,length=1,color=0,labels=('e1','e2')):
        for v,l in zip([(math.cos(angle),math.sin(angle)),(-math.sin(angle),math.cos(angle))],labels):
            p=np.array([x,y])+length*np.array(v);self.arrow([x,y],p,color);self.label(*(p+.15*np.array(v)),l,10,color)
        return self

def attach(s,x,y,text,size=11,color='BLACK',anchor='CENTER',font='Helvetica'):
    s.append(f"$!AttachText AnchorPos {{ X = {x:.8g} Y = {y:.8g} }} Anchor = {anchor} TextShape {{ FontFamily = '{font}' SizeUnits = POINT Height = {size} IsBold = No }} Color = {color} Text = '{txt(text)}'")

def colors(s):
    for i,(r,g,b) in enumerate(RGB,1):s.append(f'$!BasicColor CUSTOM{i} {{ R = {r} G = {g} B = {b} }}')
    # Color export preserves the deliberately equal R/G/B custom greys.
    # Monochrome print mode maps line objects, including grey grids, to black.
    s.append('$!PrintSetup Palette = Color')

def exports(s,name):
    f=HERE/'figures'/name;l=HERE/'layouts'/name;d=HERE/'data'/name
    s += [f"$!WriteDataSet '{d}.plt' Binary = Yes IncludeText = Yes IncludeGeom = Yes",f"$!SaveLayout '{l}.lay' UseRelativePaths = Yes",f"$!SaveLayout '{l}.lpk' IncludeData = Yes IncludePreview = Yes",'$!ExportSetup ExportFormat = EPS',f"$!ExportSetup ExportFName = '{f}.eps'",'$!Export ExportRegion = CurrentFrame','$!ExportSetup ExportFormat = PNG','$!ExportSetup ImageWidth = 2100',f"$!ExportSetup ExportFName = '{f}.png'",'$!Export ExportRegion = CurrentFrame']

def write_figure(fig):
    def typography(t):
        t=t.replace('^2','<sup>2</sup>').replace('sigma_max','<greek>s</greek><sub>max</sub>').replace('sigma','<greek>s</greek>').replace('mu*','<greek>m</greek>*').replace('mu /','<greek>m</greek> /')
        return t
    fig.xlabel=typography(fig.xlabel);fig.ylabel=typography(fig.ylabel)
    for z in fig.zones:
        z['name']={'massPerLength':'m','EIy':'EI<sub>y</sub>','EIz':'EI<sub>z</sub>','GAy':'GA<sub>y</sub>','GAz':'GA<sub>z</sub>','Jx':'J<sub>x</sub>','Jy':'J<sub>y</sub>','Jz':'J<sub>z</sub>','blade_density':'Masa/inercia de palas','blade_stiffness':'Rigidez de palas','rotor_speed':'Velocidad','damping':'Amortiguamiento','hub_density':'Masa/inercia del cubo','nacelle_density':'Masa/inercia de gondola','tower_density':'Masa/inercia de torre','tower_stiffness':'Rigidez de torre'}.get(z['name'],z['name'])
    if len([z for z in fig.zones if z['name']])==1:fig.legend=False
    name=fig.name
    if not fig.zones:raise ValueError(name+' no data')
    # This installation stores LinePattern correctly but exports short XY maps
    # as solid lines. Represent conceptual dashes by disjoint exact segments.
    # No physical result is resampled: only dimensionless schematic geometry.
    if fig.kind=='conceptual':
        pts=np.vstack([z['xy'] for z in fig.zones]);step=max(np.ptp(pts,axis=0))*.014
        render=[]
        for z in fig.zones:
            if z['pattern']=='SOLID':render.append(z);continue
            xy=z['xy'];lengths=np.linalg.norm(np.diff(xy,axis=0),axis=1);cum=np.r_[0,np.cumsum(lengths)]
            if cum[-1]==0:render.append(z);continue
            for start in np.arange(0,cum[-1],2*step):
                stop=min(start+step,cum[-1]);ts=np.r_[start,cum[(cum>start)&(cum<stop)],stop]
                path=np.c_[np.interp(ts,cum,xy[:,0]),np.interp(ts,cum,xy[:,1])]
                render.append({**z,'xy':path,'pattern':'SOLID','symbols':False})
        fig.zones=render
        fig.config['dash_rendering']='Disjoint Tecplot zones on exact conceptual polylines, 1.4% of design span.'
    dat=HERE/'data'/f'{name}.dat'
    with dat.open('w') as f:
        f.write('TITLE = "'+txt(fig.title)+'"\nVARIABLES = "x" "y"\n')
        f.write('DATASETAUXDATA Representation = "'+fig.kind+'"\n')
        for z in fig.zones:
            f.write(f'ZONE T="{txt(z["name"])}", I={len(z["xy"])}, DATAPACKING=POINT\n')
            np.savetxt(f,z['xy'],fmt='%.17g')
    if fig.bounds is None:
        a=np.vstack([z['xy'] for z in fig.zones]);lo=a.min(axis=0);hi=a.max(axis=0);pad=np.maximum((hi-lo)*.08,1e-10);lo-=pad;hi+=pad
        if fig.logx:lo[0]=a[:,0].min()*.7;hi[0]=a[:,0].max()*1.4
        if fig.logy:lo[1]=a[:,1].min()*.6;hi[1]=a[:,1].max()*1.8
        bounds=[lo[0],hi[0],lo[1],hi[1]]
    else:bounds=fig.bounds
    if fig.kind=='conceptual':
        points=np.vstack([z['xy'] for z in fig.zones]);lo=points.min(0);hi=points.max(0)
        for x,y,t,size,col in fig.labels:
            plain=re.sub(r'<[^>]+>','',t)
            w=len(plain)*size*.45/72*10/(fig.width*.88)
            lo=np.minimum(lo,[x-w/2,y-.16]);hi=np.maximum(hi,[x+w/2,y+.16])
        pad=np.maximum((hi-lo)*.07,.25);lo-=pad;hi+=pad
        ratio=(fig.width*.88)/(fig.height*.86)
        cy,cx=(lo[1]+hi[1])/2,(lo[0]+hi[0])/2
        dy=max(hi[1]-lo[1],(hi[0]-lo[0])/ratio);dx=dy*ratio
        bounds=[cx-dx/2,cx+dx/2,cy-dy/2,cy+dy/2]
    if fig.kind=='computational_beam_mesh':
        ratio=(fig.width*.81)/(fig.height*.78)
        x0,x1,y0,y1=bounds;cx=(x0+x1)/2;cy=(y0+y1)/2
        dy=max(y1-y0,(x1-x0)/ratio);dx=dy*ratio
        bounds=[cx-dx/2,cx+dx/2,cy-dy/2,cy+dy/2]
    x0,x1,y0,y1=bounds
    s=['#!MC 1410','$!NewLayout',f'$!FrameLayout Width = {fig.width} Height = {fig.height} ShowBorder = No',f"$!ReadDataSet '\"{dat}\"'",'$!PlotType = XYLine','$!DeleteLineMaps']
    colors(s)
    for i,z in enumerate(fig.zones,1):
        thickness=.20 if fig.kind=='conceptual' else .30
        s += ['$!CreateLineMap',f"$!LineMap [{i}] Name = '{txt(z['name'])}' Assign {{ Zone = {i} XAxisVar = 1 YAxisVar = 2 ShowInLegend = {'Always' if z['name'] and fig.legend else 'Never'} }} Lines {{ Show = {'No' if z['only'] else 'Yes'} Color = {COLORS[z['color']%8]} LineThickness = {thickness} LinePattern = {z['pattern']} PatternLength = 2 }} Symbols {{ Show = {'Yes' if z['symbols'] else 'No'} Color = {COLORS[z['color']%8]} FillColor = {COLORS[z['color']%8] if z['filled'] else 'WHITE'} FillMode = UseSpecificColor Size = 0.85 SymbolShape {{ IsASCII = No GeomShape = {(["Circle","Square","Diamond","Del","Grad","RTri","LTri","Circle"][z["color"]%8])} }} }}"]
    conceptual=fig.kind=='conceptual'
    longest=max((len(re.sub(r'<[^>]*>','',z['name'])) for z in fig.zones),default=0)
    vx2=(58 if longest>=18 else 70) if fig.legend and not conceptual else 94
    vx1,vy1,vy2=(6,7,93) if conceptual else (13,16,94)
    s += [f'$!ActiveLineMaps = [1-{len(fig.zones)}]',f'$!XYLineAxis ViewportPosition {{ X1 = {vx1} X2 = {vx2} Y1 = {vy1} Y2 = {vy2} }}']
    s += ['$!XYLineAxis GridArea { DrawBorder = No }']
    for which,lo,hi,title,log in [('X',x0,x1,fig.xlabel,fig.logx),('Y',y0,y1,fig.ylabel,fig.logy)]:
        s += [f"$!XYLineAxis {which}Detail 1 {{ ShowAxis = {'No' if conceptual else 'Yes'} AxisLine {{ Show = {'No' if conceptual else 'Yes'} }} RangeMin = {lo:.16g} RangeMax = {hi:.16g} CoordScale = {'Log' if log else 'Linear'} Title {{ TitleMode = UseText Offset = {9 if which=='Y' else 6} Text = '{txt(title)}' TextShape {{ SizeUnits = POINT Height = 11 IsBold = No }} }} TickLabel {{ TextShape {{ SizeUnits = POINT Height = 10 IsBold = No }} }} GridLines {{ Show = {'No' if conceptual else 'Yes'} Color = CUSTOM8 LineThickness = 0.06 }} }}"]
    s += ['$!LinePlotLayers ShowSymbols = Yes',f'$!GlobalLinePlot Legend {{ Show = {"Yes" if fig.legend and not conceptual else "No"} TextShape {{ SizeUnits = POINT Height = 10 IsBold = No }} XYPos {{ X = 99 Y = 87 }} }}']
    # Titles, provenance and scientific limitations belong in LaTeX captions.
    for x,y,t,size,col in fig.labels:
        # annotations share the explicitly declared data viewport
        fx=vx1+(vx2-vx1)*(x-x0)/(x1-x0);fy=vy1+(vy2-vy1)*(y-y0)/(y1-y0)
        attach(s,fx,fy,t,size,COLORS[col%8],font='Times' if conceptual else 'Helvetica')
    exports(s,name)
    (HERE/'macros'/f'{name}.mcr').write_text('\n'.join(s)+'\n')
    return dict(id=name,purpose=fig.title,representation=fig.kind,sources=[str(x) for x in fig.source],documents=fig.document,units=dict(x=fig.xlabel,y=fig.ylabel),configuration=dict(bounds=bounds,logx=fig.logx,logy=fig.logy,**fig.config),dataset=f'data/{name}.dat',macro=f'macros/{name}.mcr',layout=f'layouts/{name}.lay',package=f'layouts/{name}.lpk',exports=[f'figures/{name}.{e}' for e in ['eps','pdf','png']],notes=fig.notes,generator='Tecplot 360 EX 2025 R2, official batch macros; EPS to PDF by Ghostscript without scientific redraw')

def run_macro(path):
    if not TEC.is_file():
        raise FileNotFoundError('Set TESIS_TECPLOT to the licensed Tecplot executable: '+str(TEC))
    for ext in ['png','eps','pdf']:
        (HERE/'figures'/f'{Path(path).stem}.{ext}').unlink(missing_ok=True)
    p=subprocess.run([str(TEC),'-b','-quiet',str(path)],cwd=HERE/'logs',capture_output=True,text=True,timeout=180)
    log=HERE/'logs'/(Path(path).stem+'.log');log.write_text(p.stdout+'\n'+p.stderr)
    # Tecplot may exit zero even for macro syntax errors: require files too.
    err=('Error occurred' in p.stdout or 'Invalid macro' in p.stdout or 'Error occurred' in p.stderr)
    name=Path(path).stem
    expected=[HERE/'figures'/f'{name}.{e}' for e in ['png','eps']]+[HERE/'layouts'/f'{name}.{e}' for e in ['lay','lpk']]+[HERE/'data'/f'{name}.plt']
    if p.returncode or err or any(not f.exists() or f.stat().st_size==0 for f in expected):raise RuntimeError(str(log)+'; export missing or engine error')
    return log

def eps_pdf(name):
    src=HERE/'figures'/f'{name}.eps';dst=src.with_suffix('.pdf')
    # EPS has no translucency. For native 3D scenes, preserve Tecplot's lossless
    # PNG pixels in a PDF container, without another drawing engine. Ordinary
    # charts and beam centerlines retain their native vector EPS conversion.
    if 'UseTranslucency = Yes' in (HERE/'macros'/f'{name}.mcr').read_text():
        from PIL import Image
        from pypdf import PdfWriter
        from pypdf.generic import DictionaryObject,NameObject,NumberObject,DecodedStreamObject
        bounds=re.search(r'^%%BoundingBox:\s+([\d.\-]+)\s+([\d.\-]+)\s+([\d.\-]+)\s+([\d.\-]+)',src.read_text(),re.M)
        x0,y0,x1,y1=map(float,bounds.groups());w,h=x1-x0,y1-y0
        im=Image.open(src.with_suffix('.png')).convert('RGB');writer=PdfWriter();page=writer.add_blank_page(w,h)
        pixels=DecodedStreamObject();pixels.set_data(im.tobytes())
        pixels.update({NameObject('/Type'):NameObject('/XObject'),NameObject('/Subtype'):NameObject('/Image'),NameObject('/Width'):NumberObject(im.width),NameObject('/Height'):NumberObject(im.height),NameObject('/BitsPerComponent'):NumberObject(8),NameObject('/ColorSpace'):NameObject('/DeviceRGB')})
        ref=writer._add_object(pixels.flate_encode());page[NameObject('/Resources')]=DictionaryObject({NameObject('/XObject'):DictionaryObject({NameObject('/Im0'):ref})})
        stream=DecodedStreamObject();stream.set_data(f'q {w} 0 0 {h} 0 0 cm /Im0 Do Q'.encode());page[NameObject('/Contents')]=writer._add_object(stream.flate_encode());writer.write(dst)
        return dst
    subprocess.run([GHOSTSCRIPT,'-q','-dSAFER','-dBATCH','-dNOPAUSE','-sDEVICE=pdfwrite','-dEPSCrop','-dEmbedAllFonts=true','-dCompatibilityLevel=1.5',f'-sOutputFile={dst}',str(src)],check=True,capture_output=True)
    # Tecplot's PostScript sets PageSize after Ghostscript processes EPSCrop.
    # Preserve the vector drawing and use the native EPS bounding box as the
    # PDF page boundary; otherwise LaTeX scales a full Letter sheet instead.
    from pypdf import PdfReader,PdfWriter
    from pypdf.generic import RectangleObject
    bbox=re.search(r'^%%BoundingBox:\s+([\d.\-]+)\s+([\d.\-]+)\s+([\d.\-]+)\s+([\d.\-]+)',src.read_text(),re.M)
    if not bbox:raise ValueError('Missing native EPS bounding box: '+name)
    reader=PdfReader(dst);writer=PdfWriter()
    for page in reader.pages:
        page.mediabox=RectangleObject(list(map(float,bbox.groups())))
        page.cropbox=page.mediabox;writer.add_page(page)
    writer.write(dst)
    return dst
