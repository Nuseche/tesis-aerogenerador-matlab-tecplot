"""Publication schematics, rendered entirely as Tecplot data and annotations.

Design coordinates have no physical units. Every indexed direction follows the
existing thesis (local 1 longitudinal); the literature supplies presentation
principles, never a replacement set of indices or model assumptions.
"""
from common import *
from concepts import spring,grid

def m(s):return s
def var(s):return '<i>'+s+'</i>'
def sub(s):return '<sub>'+str(s)+'</sub>'
def sup(s):return '<sup>'+str(s)+'</sup>'
def v(s,index='',frame=''):
    return '<b><i>'+s+'</i></b>'+(sub(index) if index!='' else '')+(sup(frame) if frame else '')
def greek(s):return '<greek>'+s+'</greek>'
def e(i,frame=''):return v('e',i,frame)
def E(i):return v('E',i)
def lab(f,p,s,color=6,size=12):f.label(*np.asarray(p),m(s),size,color)
def text(f,p,s,size=10,color=6):f.label(*np.asarray(p),s,size,color)
def point(f,p,color=6,filled=True):f.line([p],color=color,symbols=True,only=True,filled=filled)
def direction(a):return np.array([np.cos(a),np.sin(a)])
def rot(a):return np.array([[np.cos(a),-np.sin(a)],[np.sin(a),np.cos(a)]])
def out(f,p,index='',color=6,inside=False):
    p=np.asarray(p);f.ellipse(*p,.085,color=color)
    if inside:
        for t in [-1,1]:f.line([p+[-.055,t*.055],p+[.055,-t*.055]],color=color)
    else:point(f,p,color)
    if index:lab(f,p+[-.25,-.38],index,color)
def axis(f,o,a,l,s,color=0,offset=None,pattern='SOLID'):
    o=np.asarray(o);d=direction(a);p=o+l*d
    f.arrow(o,p,color);f.zones[-2]['pattern']=pattern
    lab(f,p+(np.asarray(offset) if offset is not None else .32*d),s,color)
def pair(f,o,a,l,labels,color=0,pattern='SOLID'):
    axis(f,o,a,l,labels[0],color,pattern=pattern)
    axis(f,o,a+np.pi/2,l,labels[1],color,pattern=pattern)
def arc(f,o,r,a,b,color=6,label=None,label_r=None):
    o=np.asarray(o);t=np.linspace(a,b,61);p=o+r*np.c_[np.cos(t),np.sin(t)]
    f.line(p,color=color);f.arrow(p[-3],p[-1],color)
    if label:lab(f,o+(label_r or r+.35)*direction((a+b)/2),label,color)
def segment(f,a,b,s,color=6,offset=(0,.3)):
    a=np.asarray(a);b=np.asarray(b);f.arrow(a,b,color);lab(f,(a+b)/2+offset,s,color)
def panel(f,p,l):text(f,p,'('+l+')',11)

def vector_bases(f,o=(0,0),indices=(1,2),frameB='B',panel_label=None):
    o=np.array(o,float);a=np.deg2rad(28);L=2.8;vv=np.array([1.3,2.05]);p=o+vv
    pair(f,o,0,L,[e(i,'A') for i in indices],1)
    pair(f,o,a,L,[e(i,frameB) for i in indices],0)
    for angle,frame,color in [(0,'A',1),(a,frameB,0)]:
        for j,i in enumerate(indices):
            d=direction(angle+j*np.pi/2);q=o+np.dot(vv,d)*d
            f.line([q,p],color=color,pattern='DASHED')
            shift=-.33*direction(angle+(np.pi/2 if j==0 else 0))
            lab(f,q+shift,var('a')+sub(i)+sup(frame),color,11)
    f.arrow(o,p,6);point(f,p);lab(f,p+[.23,.18],v('a'))
    lab(f,o+[-.18,-.28],var('O'))
    if panel_label:panel(f,o+[-1,3.5],panel_label)

def rotor(f,frames=True):
    o=np.array([0.,0.]);f.ellipse(*o,.24,color=7);out(f,o)
    lab(f,[.50,-.23],var('O')+sub('H'))
    for b,a in enumerate([np.pi/2,7*np.pi/6,11*np.pi/6],1):
        d=direction(a);p=2.1*d;f.line([.24*d,p],color=7,pattern='DASHED' if not frames else 'SOLID');point(f,p,0)
        if frames:
            pair(f,p,a,.92,[v('d','1'+str(b)),v('d','2'+str(b))],0)
            out(f,p,color=0);lab(f,p+.36*direction(a-np.pi/2),var('P')+sub(b),6,11)
        else:lab(f,p+.4*d,var('P')+sub(b),0)
        if not frames:lab(f,1.15*d+.27*direction(a-np.pi/2),v('r',str(b)+'0','H'),6,11)
    pair(f,[-3.9,-2.3],0,.65,[E(2),E(3)],1);out(f,[-3.9,-2.3],E(1),1)

def redesign(figures):
    for f in figures:
        k=f.name.removeprefix('concept_')
        if k=='turbina' or not f.name.startswith('concept_'):continue
        f.zones=[];f.labels=[];f.width=7;f.height=4;f.bounds=None
        f.config.update(style_revision='2026-10-08 scientific kinematics',equal_design_coordinate_scale=True,
                        math_font='Times, italic scalars and bold italic vectors',embedded_title=False,embedded_caption=False)
        f.notes=['Esquema conceptual sin escala física; nomenclatura del texto conservada.','N: newtoniano; B: base; G: góndola; H: cubo; P_b: raíz.','El superíndice H,n identifica la orientación nominal que el texto denota mediante una barra superior.']
        if k=='configs':
            f.height=3.8;o=np.array([0.,-1.8]);X=np.array([-2.5,1.]);x=np.array([3.,1.1])
            f.ellipse(-2.7,1,1.1,.8,color=1).ellipse(2.8,1.05,1.35,.9,color=0)
            point(f,X,1);point(f,x,0)
            segment(f,o,X,v('X'),1,(-.25,0));segment(f,o,x,v('x'),0,(.35,-.10));segment(f,X,x,v('u'),2,(0,.28))
            lab(f,[-2.7,2.2],var('B')+sub(0),1);lab(f,[2.8,2.35],var('B')+sub('t'),0)
            lab(f,o+[0,-.28],var('O')+sub('N'));pair(f,o,0,.7,[E(1),E(3)],6)
        elif k=='cambio-componentes':vector_bases(f)
        elif k=='frames':
            f.height=3.5;A=np.array([0.,0.]);B=np.array([4.,.55]);P=np.array([5.9,3.])
            pair(f,A,0,1.25,[e(1,'A'),e(2,'A')],1);pair(f,B,.45,1.25,[e(1,'B'),e(2,'B')],0)
            segment(f,A,B,v('c','B'),6,(0,-.35));segment(f,B,P,v('y'),2,(.42,0));segment(f,A,P,v('x'),6,(-.35,.22))
            point(f,P);lab(f,P+[.15,.3],var('P'));lab(f,A+[-.32,-.35],var('O')+sub('A'));lab(f,B+[0,-.35],var('O')+sub('B'))
        elif k=='rotaciones-elementales':
            f.height=2.9
            for j,(i,u,w,g) in enumerate([(1,2,3,'a'),(2,3,1,'b'),(3,1,2,'g')]):
                o=np.array([4.4*j,0.]);pair(f,o,0,1.75,[e(u),e(w)],1);pair(f,o,.55,1.75,['R'+sub(i)+' '+e(u),'R'+sub(i)+' '+e(w)],0)
                arc(f,o,.78,0,.55,label=greek(g),label_r=1.15);out(f,o,e(i))
                panel(f,o+[-.7,2.5],chr(97+j))
        elif k=='rotacion-bases':
            f.height=3.5;pair(f,[0,0],0,2.2,[e(2,'A'),e(3,'A')],1);pair(f,[0,0],.49,2.2,[e(2,'(1)'),e(3,'(1)')],0)
            arc(f,[0,0],.85,0,.49,label=greek('a'));out(f,[0,0],e(1));panel(f,[-1,3.35],'a');vector_bases(f,[5.3,0],(2,3),panel_label='b')
        elif k=='derivada-director':
            f.height=3.7;o=np.array([0.,0.]);p=2.4*direction(.12);q=2.4*direction(.69)
            f.line(2.4*np.c_[np.cos(np.linspace(-.15,1.6,80)),np.sin(np.linspace(-.15,1.6,80))],color=7,pattern='DASHED')
            f.arrow(o,p,1);f.arrow(o,q,0);f.arrow(p,q,2);f.arrow(p,p+1.55*direction(.12+np.pi/2),2)
            lab(f,p+[.60,-.20],v('e','i')+'(t)',1);lab(f,q+[-.13,.40],v('e','i')+'(t+'+greek('D')+'t)',0)
            lab(f,(p+q)/2+[-.60,0],greek('D')+v('e','i'),2)
            lab(f,p+1.55*direction(.12+np.pi/2)+[.5,.18],'d'+v('e','i')+'/dt',2)
            out(f,o,v('w'),6);arc(f,p,.25,.12,.12+np.pi/2,color=7)
        elif k=='rotacion-deformacion':
            f.height=2.9
            for j,(mat,c) in enumerate([(np.eye(2),1),(rot(.40),0),(np.array([[1,.42],[0,1]]),2)]):
                grid(f,[4*j,0],1.8*mat,c);panel(f,[4*j-.45,2.8],chr(97+j))
        elif k=='sistemas-lateral':
            f.height=4.5;N=np.array([0.,-.8]);B=np.array([3.,0.]);G=np.array([3.,3.6]);H=np.array([5.3,3.6])
            f.line([[2.65,0],[2.82,3.38],[3.18,3.38],[3.35,0],[2.65,0]],color=7).rect(2.25,3.34,1.8,.52,7).line([[4.05,3.6],H],color=7).ellipse(*H,.19,color=7).line([H+[0,-1.5],H+[0,1.5]],color=7)
            pair(f,N,0,.85,[E(1),E(3)],1);out(f,N,inside=True,color=1);lab(f,N+[-.3,-.35],var('O')+sub('N'))
            for o,fr in [(B,'B'),(G,'G')]:
                pair(f,o,0,1.15,[e(1,fr),e(3,fr)],0);out(f,o,inside=True,color=0);lab(f,o+[.30,-.40],var('O')+sub(fr))
            axis(f,H,0,.85,e(1,'H,n'),0);lab(f,H+[.4,-.4],var('O')+sub('H'))
            segment(f,N,B,v('c','B')+'(t)',6,(0,-.38))
        elif k in ['cubo-nominal','giro-perturbacion']:
            a=.45;pair(f,[0,0],0,3.15,[E(2),E(3)],1,'DASHED');pair(f,[0,0],a,2.9,[e(2,'H,n'),e(3,'H,n')],0)
            arc(f,[0,0],.90,0,a,label=greek('y'),label_r=1.27);out(f,[0,0],E(1))
            if k=='giro-perturbacion':
                pair(f,[0,0],a+.28,3.15,[e(2,'H'),e(3,'H')],2);arc(f,[0,0],2.05,a,a+.28,2,greek('q')+sub('H1'),2.5)
            else:f.ellipse(0,0,1.9,color=7);lab(f,[.40,-.25],var('O')+sub('H'))
        elif k in ['marcos','cubo-brazos']:rotor(f,k=='marcos');f.height=4.9
        elif k=='palas-paso':
            a=.47;pair(f,[0,0],0,2.5,[v('d','2b','H'),v('d','3b','H')],1);pair(f,[0,0],a,2.4,[v('d','2b','H,p'),v('d','3b','H,p')],0)
            t=np.linspace(0,2*np.pi,120);profile=np.c_[1.7*np.cos(t),.32*np.sin(t)*(1-.25*np.cos(t))]@rot(a).T
            f.line(profile,color=7);arc(f,[0,0],1.05,0,a,label=greek('a')+sub('p,b'),label_r=1.53);out(f,[0,0],v('d','1b','H'))
        elif k=='arbol':
            f.height=3.7;pos=[(0,2,'N'),(3,2,'B'),(6,2,'G'),(6,-.1,'H'),(3,-.1,'P'+sub('b')),(0,-.1,'s')]
            for x,y,fr in pos:f.rect(x-.7,y-.38,1.4,.76,7);lab(f,[x,y],var('F')+sub(fr),0)
            for a,b in zip(pos,pos[1:]):
                u=np.array(a[:2]);w=np.array(b[:2]);d=(w-u)/np.linalg.norm(w-u);f.arrow(u+d*(.7 if d[0] else .38),w-d*(.7 if d[0] else .38),6)
            lab(f,[7,1],var('R')+sub(1)+'('+greek('y')+')',6,11)
            lab(f,[4.5,-.8],var('Q')+sup('H')+sub('P'+sub('b')),6,11);text(f,[1.5,-.8],'Deformación',10)
        elif k=='cadena-posiciones':
            f.height=4.4;p=np.array([[0,0],[1.3,.4],[1.3,3.5],[3.6,3.5],[4.6,4.5],[6.2,5.1]])
            names=[var('O')+sub('N'),var('O')+sub('B'),var('O')+sub('G'),var('O')+sub('H'),var('O')+sub('P'+sub('b')),var('P')]
            labels=[v('c','B'),v('c','G')+' - '+v('c','B'),v('c','H')+' - '+v('c','G'),var('Q')+sub('H')+' '+v('r','b0','H'),var('Q')+sub('P'+sub('b'))+' '+v('y','b')]
            offsets=[(0,-.4),(-.8,0),(0,-.5),(-.6,.2),(.25,-.5)]
            for j in range(5):segment(f,p[j],p[j+1],labels[j],0,offsets[j])
            f.arrow(p[0],p[-1],2);lab(f,[3.1,1.5],v('x','b'),2)
            for j,x in enumerate(p):point(f,x);lab(f,x+([-0.40,.15] if j in [0,2,4] else [.25,.3]),names[j],6,11)
        elif k=='tresniveles':
            f.height=3.4
            for j in range(3):
                o=np.array([4*j,0.]);t=np.linspace(0,1,80);xy=o+np.c_[.12*t,2.6*t];a=[0,.33,.33][j];nom=xy@rot(a).T+o-o@rot(a).T
                f.line(nom,color=j if j<2 else 7,pattern='DASHED' if j==2 else 'SOLID')
                actual=nom+np.c_[.30*t*t,.1*t*t] if j==2 else nom
                if j==2:f.line(actual,color=2);segment(f,nom[-1],actual[-1],v('u'),2,(.5,.1))
                f.arrow(o+[-.8,-.2],actual[-1],j);lab(f,o+[.25,1.1],[v('X'),v('x','nom'),v('x')][j],j)
                panel(f,o+[-.8,3.25],chr(97+j))
        elif k=='particula-seccion':
            f.height=3.6;t=np.linspace(0,1,90);xy=np.c_[.7+4*t,.8+.8*t+1.4*t*t];f.line(xy,color=7);c=xy[44]
            f.line([c+[-.15,-.7],c+[.17,-.56],c+[.25,.70],c+[-.07,.56],c+[-.15,-.7]],color=0)
            segment(f,[0,-.2],c,v('r')+'(S,t)',6,(.2,-.25));point(f,c);lab(f,c+[0,.95],var('S'));panel(f,[-.3,3.4],'a')
            o=np.array([6.7,.2]);P=o+[1.85,1.6];f.ellipse(*(o+[.8,.8]),1.65,1.20,color=7)
            pair(f,o,0,2.65,[v('d',2),v('d',3)],0);out(f,o,v('d',1));point(f,P);lab(f,P+[.15,.3],var('P'))
            f.arrow(o,P,6);f.line([o+[1.85,0],P,o+[0,1.6]],color=7,pattern='DASHED');lab(f,o+[1.85,-.3],greek('x')+sub(2));lab(f,o+[-.3,1.6],greek('x')+sub(3));panel(f,[5.8,3.4],'b')
        elif k=='shear':
            f.height=3.5;ang=.20;a=-.25;t=np.linspace(-2.5,2.5,100);xy=np.c_[t,np.tan(ang)*t+.018*t*t*t];f.line(xy,color=7)
            pair(f,[0,0],a,1.85,[v('d',1),v('d',2)],0);axis(f,[0,0],ang,2.55,v('t'),2)
            normal=direction(a+np.pi/2);f.line([-1.0*normal,1.0*normal],color=0);arc(f,[0,0],.90,a,ang,color=6,label=greek('g'),label_r=1.30)
            out(f,[0,0],v('d',3));lab(f,[-1.9,-.8],v('r')+'(S,t)',7)
        elif k=='suma-velocidades':
            f.height=3.2;p=np.array([[0.,0.],[2.6,.25],[4.7,.9],[5.5,3.1]])
            for a,b,s,c,off in zip(p,p[1:],['d'+v('c')+'/dt',var('Q')+sub('c')+'W '+v('y'),var('Q')+sub('c')+' d'+v('y')+'/dt'],[1,2,0],[(0,-.35),(0,-.40),(.55,0)]):segment(f,a,b,s,c,off)
            segment(f,p[0],p[-1],'d'+v('x')+'/dt',6,(-.6,.25))
        elif k in ['centripeta','guia']:
            f.height=4.2;o=np.array([0.,0.]);a=.68;P=2.1*direction(a);f.ellipse(0,0,2.1,color=7);out(f,o,v('w'))
            segment(f,o,P,v('r'),0,(.20,-.3));axis(f,P,a+np.pi/2,1.55,v('v'),2);axis(f,P,a+np.pi,1.4,v('a'),1,offset=[-.25,.28]);point(f,P);lab(f,P+[.33,.28],var('P'))
            arc(f,o,1.05,-.30,.25,6,label=greek('y'),label_r=1.45)
            if k=='guia':f.line([-2.65*direction(a),2.65*direction(a)],color=7);lab(f,[-1.1,-1.1],var('r')+sub(0))
        elif k=='gravedad-giratoria':
            f.height=2.95
            for j,a in enumerate([0,.55,1.10]):
                o=np.array([4*j,0.]);pair(f,o,a,1.35,[e(2,'H,n'),e(3,'H,n')],0);f.arrow(o,o+[0,-1.5],1);lab(f,o+[.25,-1.55],v('g'),1)
                out(f,o);panel(f,o+[-.8,2.2],chr(97+j))
        elif k=='operacion':
            f.height=2.9;t=np.linspace(0,7,180);q0=1.5;f.line(np.c_[t,np.full_like(t,q0)],color=7,pattern='DASHED');f.line(np.c_[t,q0+.40*np.exp(-.08*t)*np.sin(2.7*t)],color=0)
            f.arrow([0,0],[7.5,0],6).arrow([0,0],[0,2.35],6);lab(f,[7.7,0],var('t'));lab(f,[-.2,2.6],var('q'));lab(f,[7.6,1.5],var('q')+sub(0));segment(f,[3.8,q0],[3.8,q0+.40*np.exp(-.08*3.8)*np.sin(2.7*3.8)],greek('h')+'(t)',2,(.5,0));f.notes.append('Respuesta ilustrativa, no una historia calculada.')
        elif k in ['centros','masa-seccional']:
            f.height=3.6;f.ellipse(0,0,2.7,1.6,color=7);O=np.array([-1.7,-.7]);CA=np.array([0.,0.]);CM=np.array([.55,.35]);P=np.array([1.7,.9]);pair(f,O,0,1.15,[var('x')+sub(2),var('x')+sub(3)],0)
            out(f,O);lab(f,O+[-.2,-.4],var('O')+sub('s'));point(f,CM,2);lab(f,CM+[.2,-.4],var('C')+sub('m'),2)
            if k=='centros':point(f,CA,1);lab(f,CA+[-.35,.4],var('C')+sub('A'),1);segment(f,O,CM,v('r','cm'),2,(.10,.30))
            else:
                f.rect(*P,.18,.18,1);lab(f,P+[.40,.30],'dm',1);segment(f,O,P,v('r'),0,(-.1,.30));segment(f,CM,P,v('r')+' - '+v('r','cm'),2,(.6,-.30));segment(f,O,CM,v('r','cm'),6,(.2,-.4))
        elif k=='rigido-centro':
            f.height=3.5;N=np.array([0.,0.]);O=np.array([3.,.45]);C=np.array([4.2,1.45]);P=np.array([5.7,2.2]);f.ellipse(4.3,1.5,2.2,1.2,color=7)
            for a,b,s,c,off in [(N,O,v('x','O'),1,(0,-.3)),(N,C,v('x','C'),6,(-.2,.3)),(O,C,v('c'),2,(-.3,.2)),(C,P,v('r'),0,(0,.3)),(O,P,v('r'),6,(.4,-.3))]:segment(f,a,b,s,c,off)
            # rho is the vector from the mass centre to P; r is measured from O.
            f.labels[-2]=(*f.labels[-2][:2],m(v(greek('r'))),12,0)
            for x,s in [(N,'O'+sub('N')),(O,'O'),(C,'C'),(P,'P')]:point(f,x);lab(f,x+[.10,-.35],var(s))
        elif k=='continuo-malla':
            f.height=3.0;t=np.linspace(0,1,90);xy=np.c_[6*t,.5*np.sin(np.pi*t)];f.line(xy,color=7);ix=np.linspace(0,89,7).astype(int);f.line(xy[ix],color=0,symbols=True,filled=True)
            c=xy[45];f.rect(c[0]-.18,c[1]-.6,.36,1.2,2);lab(f,[2.1,1.1],var('S'));lab(f,[3,-.7],var('A')+'(S)',2)
            for j,x in enumerate(xy[ix]):lab(f,x+[0,-.35],str(j+1),0,10)
        elif k=='coordenadas-nodo':
            f.height=4.3
            for j,i in enumerate([1,2,3]):
                o=np.array([3.5*j,2.1]);point(f,o,7,False);f.arrow(o,o+[1.5,0],0);point(f,o+[1.5,0],0);lab(f,o+[.75,.45],var('u')+sub(i),0);axis(f,o,-np.pi/2,.65,E(i),7);panel(f,o+[-.35,1.15],chr(97+j))
                p=np.array([3.5*j+.45,-.40]);u,w=[(2,3),(3,1),(1,2)][j];pair(f,p,0,.85,[E(u),E(w)],7);arc(f,p,.55,.35,2.1,1,greek('q')+sub(i),.90);out(f,p,E(i));panel(f,p+[-.8,-1.1],chr(100+j))
        elif k=='interpolacion-lineal':
            f.height=2.9;f.arrow([0,0],[2.7,0],6).arrow([0,0],[0,2.2],6);f.line([[0,1.7],[2.2,0]],color=1).line([[0,0],[2.2,1.7]],color=0);lab(f,[.70,1.45],var('N')+sub(1),1);lab(f,[1.6,1.5],var('N')+sub(2),0);lab(f,[2.9,0],greek('x'));lab(f,[-.18,1.7],'1',6,10);lab(f,[2.2,-.23],'1',6,10);panel(f,[-.4,2.7],'a')
            f.arrow([4,0],[6.7,0],6).arrow([4,0],[4,2.2],6);f.line([[4,.7],[6.2,1.6]],color=2,symbols=True,filled=True);lab(f,[4,.35],var('I'));lab(f,[6.2,1.95],var('J'));lab(f,[6.9,0],greek('x'));lab(f,[3.85,2.5],var('u'));panel(f,[3.7,2.7],'b')
        elif k=='elemento':
            f.height=3.6;I=np.array([0.,0.]);J=np.array([4.8,1.25]);Xa=np.array([1.2,3.3]);d1=(J-I)/np.linalg.norm(J-I);p=Xa-I-np.dot(Xa-I,d1)*d1;d3=p/np.linalg.norm(p);foot=I+np.dot(Xa-I,d1)*d1
            f.line([I,J],color=7,symbols=True,filled=True);f.line([I,Xa,foot],color=7,pattern='DASHED');f.arrow(I,p,2);lab(f,p+[-.35,.15],v('p'),2)
            axis(f,I,np.arctan2(d1[1],d1[0]),1.6,e(1),0,offset=[.2,-.35]);axis(f,I,np.arctan2(d3[1],d3[0]),1.8,e(3),0,offset=[-.3,-.1]);out(f,I,e(2),inside=True)
            point(f,Xa,2);lab(f,Xa+[.20,.4],v('X','a'),2);lab(f,I+[-.35,.15],var('I'));lab(f,J+[.28,.2],var('J'))
            f.line([foot-.15*d1,foot-.15*d1+.15*d3,foot+.15*d3],color=7)
        elif k=='vinculo-raiz':
            f.height=3.0;p=np.array([[0.,0.],[2.8,.3],[4.,2.1]])
            segment(f,p[0],p[1],v('u','H'),0,(0,-.4));segment(f,p[1],p[2],v(greek('q'),'H')+' <math>\u00b4</math> '+v('r'),2,(.85,0));segment(f,p[0],p[2],v('u','s'),6,(-.35,.3))
            for x in p:point(f,x)
        elif k=='conexion-elastica':
            f.height=2.9;f.rect(0,0,1.7,1.4,7).rect(5,0,1.7,1.4,7);lab(f,[.85,.7],var('G'),0);lab(f,[5.85,.7],var('H'),0)
            spring(f,[1.7,1.05],[5,1.05],0);f.line([[1.7,.35],[2.8,.35],[2.8,.05],[3.7,.05],[3.7,.65],[2.8,.65]],color=2);f.line([[3.15,.08],[3.15,.62]],color=2).line([[3.15,.35],[5,.35]],color=2)
            lab(f,[3.35,1.6],var('K')+sub('d'),0);lab(f,[3.35,-.45],var('C')+sub('d'),2)
            f.arrow([1.7,2.15],[5,2.15],6);lab(f,[3.35,2.55],greek('D')+v('q'),6)
        elif k=='acoplamiento-giroscopico':
            f.height=3.5;pair(f,[0,0],0,2.1,[var('q')+sub(1),var('q')+sub(2)],7);axis(f,[0,0],.46,2.25,'d'+v('q')+'/dt',0);axis(f,[0,0],.46+np.pi/2,2.25,var('G')+' d'+v('q')+'/dt',2)
            a=.46;f.line([.22*direction(a),.22*(direction(a)+direction(a+np.pi/2)),.22*direction(a+np.pi/2)],color=6);arc(f,[0,0],1.1,a,a+np.pi/2,7)
        elif k=='carga-seccion':
            f.height=3.2
            for j in range(2):
                o=np.array([4.8*j,0.]);A=o+[1,.35];f.ellipse(*o,1.8,.7,color=7);point(f,o);lab(f,o+[0,-.4],var('O')+sub('s'))
                f.arrow(A if j==0 else o,(A if j==0 else o)+[.55,1.6],0);lab(f,(A if j==0 else o)+[.9,1.6],v('f'),0)
                if j==0:point(f,A,2);lab(f,A+[.30,-.15],var('A'));arc(f,A,.42,.5,2.5,1,v('m','A'),.78)
                else:arc(f,o,.40,.5,2.5,1,v('m','Os'),.9)
                panel(f,o+[-1.6,2.45],chr(97+j))
        else:raise ValueError('Missing scientific redesign: '+k)
    validate()
    return figures

def validate():
    checks={}
    for a in [.40,.45,.47,.49,.55,.69,1.1]:
        Q=rot(a);checks['SO2_'+str(a)]={'orthogonality':float(np.linalg.norm(Q.T@Q-np.eye(2))),'determinant':float(np.linalg.det(Q))}
    a=np.deg2rad(28);vec=np.array([1.3,2.05]);Q=rot(a);checks['components']={'reconstruction_error':float(np.linalg.norm(Q@(Q.T@vec)-vec)),'orthogonal_projection_error':float(max(abs(np.dot(vec-np.dot(vec,Q[:,i])*Q[:,i],Q[:,i])) for i in range(2)))}
    checks['director']={'tangent_dot_director':float(direction(.12)@direction(.12+np.pi/2))}
    for b in range(3):
        a=2*np.pi*b/3;d1=np.array([0,-np.sin(a),np.cos(a)]);d2=np.array([0,-np.cos(a),-np.sin(a)]);d3=np.array([1.,0,0]);D=np.c_[d1,d2,d3]
        checks['root_'+str(b+1)]={'right_hand_error':float(np.linalg.norm(np.cross(d1,d2)-d3)),'orthogonality':float(np.linalg.norm(D.T@D-np.eye(3))),'determinant':float(np.linalg.det(D))}
    I=np.zeros(3);J=np.array([4.8,0,1.25]);Xa=np.array([1.2,0,3.3]);e1=J/np.linalg.norm(J);p=Xa-Xa@e1*e1;e3=p/np.linalg.norm(p);e2=np.cross(e3,e1);D=np.c_[e1,e2,e3]
    checks['element']={'e2_y':float(e2[1]),'e1_dot_p':float(e1@p),'orthogonality':float(np.linalg.norm(D.T@D-np.eye(3))),'determinant':float(np.linalg.det(D))}
    for key,x in checks.items():
        for name,value in x.items():
            if name not in ['determinant','e2_y']:assert abs(value)<1e-12,(key,name,value)
            elif name=='determinant':assert abs(value-1)<1e-12
    assert checks['element']['e2_y']>0 # E2 points into the side-view plane.
    dump(HERE/'reports/kinematics_geometry_checks.json',checks)
