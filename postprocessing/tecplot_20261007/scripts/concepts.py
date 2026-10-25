"""Explicit schematic geometry for the existing formulation figures.

Coordinates are dimensionless design coordinates, never a solver mesh. Each
line, arrow and label is rendered by Tecplot from numeric zones and macros.
"""
from common import *
import re

def concept(key,title):
    f=Figure('concept_'+key,title,source=[THESIS/'tesis_autocontenida.tex'],document=['tesis_autocontenida.tex','tesis_modelo.tex'],bounds=[0,10,0,6],legend=False)
    f.notes=['Esquema conceptual, sin escala fisica. Tecplot.']
    return f

def turbine(f,english=False):
    f.line([[6,.5],[6,3.8]],color=6).rect(5.8,3.8,1.4,.45).ellipse(5.6,4,.16)
    c=np.array([5.6,4.]);
    for a in [90,210,330]:
        v=np.array([math.cos(math.radians(a)),math.sin(math.radians(a))]);w=np.array([-v[1],v[0]])
        f.line([c+.15*v-.08*w,c+1.45*v,c+.15*v+.08*w,c+.15*v-.08*w],color=0)
    f.rect(5.5,.25,1,.3).arrow([6.7,4],[4.7,4],1).label(4.7,4.3,'Rotor axis' if english else 'Eje del rotor',10,1)
    f.label(7.9,4.1,'Nacelle' if english else 'Gondola').label(7,2,'Tower' if english else 'Torre').label(4.5,5.5,'Blades' if english else 'Palas').label(4.7,3.55,'Hub' if english else 'Cubo').label(5.2,.45,'Base')
    f.basis(1,.7,labels=('x','z'));f.arrow([1,3.9],[3.2,3.9],2).label(2,4.2,'Wind' if english else 'Viento nominal',10,2)
    f.rect(1,1.8,.8,.6).rect(3.3,1.8,.8,.6).label(1.4,2.1,'N').label(3.7,2.1,'H');spring(f,[1.8,2.15],[3.3,2.15]);f.label(2.55,2.7,'kd, cd');f.arrow([5.3,.05],[6.8,.05],2).label(7.3,.12,'ag(t)',10,2)
    return f

def spring(f,a,b,color=6):
    a=np.asarray(a,float);b=np.asarray(b,float);v=b-a;w=np.array([-v[1],v[0]]);w/=max(np.linalg.norm(w),1e-9)
    t=np.linspace(0,1,17);p=a+t[:,None]*v;p[1:-1]+=((np.arange(1,16)%2)*2-1)[:,None]*.10*w
    f.line(p,color=color);return f

def grid(f,origin,matrix,color):
    o=np.array(origin);m=np.array(matrix)
    for t in np.linspace(0,1,5):
        f.line([o+m@np.array([t,0]),o+m@np.array([t,1])],color=color)
        f.line([o+m@np.array([0,t]),o+m@np.array([1,t])],color=color)

def vector_bases(f,origin=(3,2.5),angle=.55):
    o=np.array(origin);f.basis(*o,0,2,1,('A1','A2')).basis(*o,angle,2,0,('B1','B2'));p=o+np.array([2,1.5]);f.arrow(o,p,2).label(*(p+[.3,.2]),'v',11,2)
    for a in [0,angle]:
        e=np.array([math.cos(a),math.sin(a)]);projection=o+np.dot(p-o,e)*e
        f.line([p,projection],color=7,pattern='DASHED')

def rotor(f,psi=0,roots=True):
    o=np.array([5,3]);f.ellipse(*o,.3,color=6)
    if not roots:f.basis(*o,0,2.1,1,('E2','E3')).basis(*o,psi,1.5,0,('H2','H3'))
    if roots:
        for b,a in enumerate([np.pi/2,7*np.pi/6,11*np.pi/6],1):
            a+=psi;v=np.array([np.cos(a),np.sin(a)]);p=o+1.8*v;f.line([o,p],color=6);f.basis(*p,a,.7,2,('d1'+str(b),'d2'+str(b)))
    f.label(7.8,1,'Vista desde +E1',10)

def build():
    s=(THESIS/'tesis_autocontenida.tex').read_text()
    figure_blocks=re.findall(r'\\begin\{figure\}.*?\\end\{figure\}',s,re.S)
    names={}
    for b in figure_blocks:
        key=re.search(r'\\label\{fig:([^}]+)',b).group(1)
        short=re.search(r'\\caption\[([^]]+)\]',b)
        names[key]=short.group(1) if short else key
    # Titles in plain ASCII avoid EPS font substitution for mathematical macros.
    titles={'turbina':'Componentes y movimiento nominal','configs':'Configuraciones de una particula','cambio-componentes':'Un vector en dos bases','frames':'Cambio de origen y de base','rotaciones-elementales':'Rotaciones elementales positivas','rotacion-bases':'Rotacion de ejes y componentes','derivada-director':'Derivada temporal de un director','rotacion-deformacion':'Rotacion rigida y deformacion','sistemas-lateral':'Base, torre y gondola','cubo-nominal':'Rotacion nominal del cubo','marcos':'Marcos de las tres raices','palas-paso':'Paso de una seccion de pala','arbol':'Relaciones entre marcos','cadena-posiciones':'Composicion de posiciones','tresniveles':'Referencia, nominal y perturbacion','particula-seccion':'Posicion de una particula de viga','shear':'Normal seccional y tangente','giro-perturbacion':'Giro prescrito y perturbacion','suma-velocidades':'Composicion de velocidades','centripeta':'Velocidad y aceleracion nominal','gravedad-giratoria':'Gravedad fija y bases giratorias','operacion':'Equilibrio relativo y vibracion','centros':'Centros de area y masa','masa-seccional':'Integracion de masa seccional','rigido-centro':'Particula de cuerpo rigido','continuo-malla':'Descripcion continua y elementos','coordenadas-nodo':'Seis coordenadas nodales','interpolacion-lineal':'Interpolacion de dos nodos','elemento':'Orientacion local del elemento','cubo-brazos':'Vinculos geometricos cubo-raices','vinculo-raiz':'Desplazamiento compatible de raiz','conexion-elastica':'Conexion elastica N-H','guia':'Equilibrio en una guia giratoria','acoplamiento-giroscopico':'Acoplamiento giroscopico antisimetrico','carga-seccion':'Transferencia de cargas seccionales'}
    figs=[]
    for key in names:
        if key not in titles:continue
        f=concept(key,titles[key]);f.config['original_figure_label']='fig:'+key
        if key=='turbina':turbine(f)
        elif key=='configs':
            f.ellipse(3,3,1,.8,color=1).ellipse(7,3,1.3,.9,color=0);f.label(3,4.1,'Referencia B0');f.label(7,4.2,'Actual Bt')
            f.arrow([.8,.6],[3,3],1).arrow([.8,.6],[7.3,3.2],0).arrow([3,3],[7.3,3.2],2);f.label(2,2,'X');f.label(5,1.8,'x');f.label(5.1,3.6,'u = x - X');f.label(.8,.3,'O')
        elif key in ['cambio-componentes','rotacion-bases']:vector_bases(f)
        elif key=='frames':
            f.basis(1,1,0,1.3,1,('A1','A2')).basis(5,3,.45,1.4,0,('B1','B2'));f.arrow([1,1],[5,3],6).arrow([5,3],[7.5,4.5],2).arrow([1,1],[7.5,4.5],1);f.label(3,2.4,'cB');f.label(6.4,4.4,'QB y');f.label(4.8,1.5,'x = cB + QB y')
        elif key=='rotaciones-elementales':
            for j,(u,v,k) in enumerate([('e2','e3','R1'),('e3','e1','R2'),('e1','e2','R3')]):
                x=1+3*j;f.basis(x,2,0,1.3,1,(u,v)).basis(x,2,.55,1.3,0,(u+" rot",v+" rot"));f.label(x+1,4.5,k+'(alpha)',11)
        elif key=='derivada-director':
            o=[3,2];a=np.array([5,2]);b=np.array([4.65,3.13]);f.arrow(o,a,1).arrow(o,b,0).arrow(a,b,2).label(5.5,2,'e(t)').label(4.5,3.7,'e(t+dt)').label(6,3.1,'Delta e');f.arrow(b,b+np.array([-.7,1]),2).label(3.5,4.7,'de/dt = omega x e')
        elif key=='rotacion-deformacion':
            for o,m,c,l in [((.8,2),[[1.8,0],[0,1.8]],1,'Referencia'),((4,2),[[1.55,-.9],[.9,1.55]],0,'Rotacion'),((7,2),[[1.8,.9],[0,1.8]],2,'Cortante')]:grid(f,o,m,c);f.label(o[0]+1,1,l)
        elif key=='sistemas-lateral':
            f.line([[4,1],[4,4]],color=6).rect(3.8,4,2,.4);f.basis(1,1,color=1,labels=('E1','E3')).basis(4,1,color=0,labels=('B1','B3')).basis(4,4,color=2,labels=('N1','N3'));f.arrow([1,1],[4,1],6).label(2.5,.6,'cB(t)');f.label(7,3,'E2 entra al plano',10)
        elif key in ['cubo-nominal','marcos','cubo-brazos']:
            rotor(f,.5 if key=='cubo-nominal' else 0,roots=key!='cubo-nominal')
            if key=='cubo-brazos':f.label(2,5.3,'us = uH - S(r) thetaH');f.notes.append('Brazos: vinculos geometricos; no son elementos de viga.')
        elif key=='palas-paso':
            f.ellipse(5,3,1.7,.45,color=7);f.basis(5,3,0,1.8,1,('d2(0)','d3(0)')).basis(5,3,.5,1.8,0,('d2(beta)','d3(beta)'));f.label(3,1,'Vista desde +d1');f.label(7.5,5,'beta: paso positivo')
        elif key=='arbol':
            points=[(1,3,'N'),(3,3,'B'),(5,3,'G'),(7,3,'H')]
            for x,y,l in points:f.rect(x-.5,y-.4,1,.8).label(x,y,l)
            for a,b in zip(points,points[1:]):f.arrow([a[0]+.5,a[1]],[b[0]-.5,b[1]],0)
            for y,b in [(1,3),(3,2),(5,1)]:f.rect(8.7,y-.3,.8,.6).label(9.1,y,'P'+str(b));f.arrow([7.5,3],[8.7,y],2)
        elif key in ['cadena-posiciones','suma-velocidades','vinculo-raiz']:
            p=np.array([[1,1],[3,1.6],[5,2.8],[7,3.1],[8.5,4.8]])
            if key=='vinculo-raiz':p=np.array([[2,1],[4,1],[7,3]])
            labels={'cadena-posiciones':['cB','rN/B','rH/N','rP/H'],'suma-velocidades':['vB','vtransp','vrot','vrel'],'vinculo-raiz':['uH','thetaH x r']}[key]
            for j,(a,b,l) in enumerate(zip(p,p[1:],labels)):f.arrow(a,b,j).label(*((a+b)/2+[0,.45]),l)
            f.arrow(p[0],p[-1],6).label(5,.8,{'cadena-posiciones':'xP = suma de posiciones','suma-velocidades':'vP = suma de velocidades','vinculo-raiz':'us = uH + thetaH x r'}[key])
        elif key=='tresniveles':
            for j in range(3):
                x=1+3*j;t=np.linspace(0,1,50);f.line(np.c_[x+.2*t,1+3*t],color=j)
                if j==2:f.line(np.c_[x+.2*t+.5*t*t,1+3*t],color=2);f.line([[x,1],[x+.2,4]],color=7,pattern='DASHED')
                f.label(x+1,4.8,['(a) Referencia','(b) Nominal','(c) Actual'][j])
        elif key=='particula-seccion':
            f.line([[1,2],[4,2.7],[7,3.4]],color=6).basis(4,2.7,.23,1.6,0,('d1','d2'));f.arrow([4,2.7],[4.6,4],2).label(5.2,4.5,'P = r(s) + Q(s) rho');f.label(2,1,'Linea de referencia');f.label(3,5,'Coordenadas seccionales: rho2, rho3')
        elif key=='shear':
            f.line([[1,2],[8,3.6]],color=6).line([[4,1.6],[4.4,4.6]],color=0);f.arrow([4.2,3.1],[6.2,3.55],2).arrow([4.2,3.1],[6.1,2.85],1);f.label(7,4,'Tangente t');f.label(7,2.6,'Normal d1');f.label(2,4.8,'gamma != 0')
        elif key=='giro-perturbacion':
            f.basis(3,3,.45,1.7,0,('H2 nominal','H3 nominal')).basis(7,3,.53,1.7,2,('H2 actual','H3 actual'));f.label(3,1,'psi prescrito');f.label(7,1,'theta pequena');f.arrow([4.3,3],[5.5,3],6)
        elif key in ['centripeta','guia']:
            f.ellipse(5,3,1.8,color=7);p=np.array([6.27,4.27]);f.arrow([5,3],p,0).arrow(p,p+[-1,.95],2).arrow(p,[5.3,3.3],1);f.label(7.8,4.8,'v = omega x r').label(3,1,'a = omega x (omega x r)').label(7.5,3,'r0 constante' if key=='guia' else 'r nominal')
        elif key=='gravedad-giratoria':
            for j,a in enumerate([0,.55,1.1]):
                x=1.5+3*j;f.basis(x,3,a,1.2,0,('H2','H3'));f.arrow([x,3],[x,1.5],1);f.label(x,4.9,'psi = '+str(round(a,2)));f.label(x+.5,1.2,'g')
        elif key=='operacion':
            t=np.linspace(0,8,201);q0=2;f.line(np.c_[t+1,np.zeros_like(t)+q0],name='',color=6,pattern='DASHED').line(np.c_[t+1,q0+.6*np.sin(2*t)*np.exp(-.12*t)],color=0);f.arrow([1,.8],[9,.8],6).label(9,1.1,'t');f.label(2,4.5,'q(t) = q0 + eta(t)').label(8.4,2.35,'q0')
            f.notes.append('Curva ilustrativa; no es una respuesta calculada del solver.')
        elif key in ['centros','masa-seccional']:
            f.ellipse(5,3,2,1.2,color=6);pts=[(3.8,2.5,'Os'),(5,3,'CA'),(5.6,3.2,'Cm')]
            for x,y,l in pts:f.ellipse(x,y,.05,color=6).label(x,y-.4,l)
            if key=='masa-seccional':f.rect(6.1,3.3,.2,.2,color=2).label(7.2,3.7,'dm = rho dA');f.arrow([5.6,3.2],[6.2,3.4],0).label(6,4.2,'rho - rho_cm')
            else:f.label(5,5,'Geometria y densidad heterogenea')
        elif key=='rigido-centro':
            f.ellipse(6,3,1.6,1,color=6);f.arrow([1,1],[5.8,2.8],1).arrow([5.8,2.8],[6.8,3.6],0).arrow([1,1],[6.8,3.6],2);f.label(5.4,2.3,'C').label(7.3,3.6,'P').label(4.7,4.8,'xP = xC + Q rho')
        elif key=='continuo-malla':
            t=np.linspace(0,1,70);xy=np.c_[1+8*t,3+.4*np.sin(np.pi*t)];f.line(xy,color=6);ix=np.linspace(0,len(t)-1,7).astype(int);f.line(xy[ix],color=0,symbols=True);f.label(5,4.6,'Continuo y aproximacion de viga');f.rect(4.7,2.7,.6,1,color=2).label(5,1.5,'Seccion rigida; sin malla de cascaron')
        elif key=='coordenadas-nodo':
            for j in range(3):
                x=1.5+3*j;f.ellipse(x,3.8,.12,color=7).arrow([x,3.8],[x+.8,4.3],0).label(x+.4,4.9,'u'+str(j+1));f.ellipse(x,1.7,.5,color=1).label(x,1,'theta'+str(j+1));f.arrow([x+.5,1.7],[x+.4,2.05],1)
        elif key=='interpolacion-lineal':
            f.line([[1,1],[4,4]],color=0).line([[1,4],[4,1]],color=1).label(2,4.7,'N1 = 1 - xi').label(3,1,'N2 = xi');f.line([[6,1.8],[9,3.8]],color=2,symbols=True).label(7.5,4.8,'u = N1 uI + N2 uJ').label(6,1,'I').label(9,3,'J')
        elif key=='elemento':
            p=np.array([2,2]);q=np.array([7,3.4]);a=np.array([3,4.8]);f.line([p,q],color=6,symbols=True).basis(*p,.273,1.7,0,('e1: I a J','e3 proy. auxiliar')).line([p,a],color=7,pattern='DASHED');f.label(2,1.4,'I').label(7.3,3.6,'J').label(3.1,5.2,'Xa');f.label(6,1,'e2 = e3 x e1; base derecha')
        elif key=='conexion-elastica':
            f.rect(1,2,2,1).rect(7,2,2,1).label(2,2.5,'N: gondola').label(8,2.5,'H: rotor');spring(f,[3,2.8],[7,2.8],0);f.line([[3,2.2],[4.8,2.2],[4.8,2],[5.4,2],[5.4,2.4],[4.8,2.4]],color=2).line([[5.1,2.2],[7,2.2]],color=2);f.label(5,4.1,'F, M = Kd Delta q + Cd Delta qdot').label(5,1,'Movimiento relativo de seis componentes')
        elif key=='acoplamiento-giroscopico':
            f.basis(4,2,0,2,6,('qdot1','qdot2'));f.arrow([4,2],[5.5,3.5],0).arrow([4,2],[2.5,3.5],2);f.label(6.5,3.5,'qdot').label(2,4.1,'G qdot');f.label(6,5,'G^T = -G; qdot^T G qdot = 0')
        elif key=='carga-seccion':
            for j in range(2):
                x=2+5*j;f.ellipse(x,3,1.5,.6,color=6).label(x,2,'Os');f.arrow([x+.5,3.3],[x+1.2,4.4],0).label(x+1.3,4.8,'f')
                if j==0:f.label(x+.5,2.8,'A')
                else:f.ellipse(x,3,.3,color=1).label(x-1,4.5,'mOs = mA + r x f')
            f.arrow([4.2,3],[5,3],2)
        else:raise ValueError('unimplemented concept '+key)
        figs.append(f)
    for lang in ['es','en']:
        f=concept('article_'+lang,'Structural model' if lang=='en' else 'Modelo estructural')
        turbine(f,lang=='en');f.name='esquema_'+lang;f.document=['FCEFyN_'+lang.upper()+'.tex'];f.source=[ROOT/'docs/formulacion_revista_20260919/figures/esquema_dibujo.tex']
        if lang=='en':f.notes=['Conceptual schematic. No physical scale. Tecplot.']
        figs.append(f)
    return figs
