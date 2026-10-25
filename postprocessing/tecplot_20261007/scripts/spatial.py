"""Monochrome spatial mechanics figures: native Tecplot Cartesian3D.

Numerical geometry only; no raster illustration or imported legacy drawing.
All displayed volumes are conceptual, not a solid discretization of the solver.
"""
from common import *
from kinematics import v,var,sub,sup,e,E,greek
from body3d import ellipsoid

def unit(x):x=np.asarray(x,float);return x/np.linalg.norm(x)
def R(axis,a):
    u=unit(axis);S=np.array([[0,-u[2],u[1]],[u[2],0,-u[0]],[-u[1],u[0],0]])
    return np.eye(3)+np.sin(a)*S+(1-np.cos(a))*(S@S)
def coord(x):return np.asarray(x,dtype=float)

class Scene:
    def __init__(self,name,purpose='',width=7,height=4.8,psi=65,theta=225):
        self.name=name;self.purpose=purpose;self.width=width;self.height=height;self.psi=psi;self.theta=theta;self.zones=[];self.labels=[];self.checks=[];self.config={}
    def line(self,pts,grey=0,dashed=False,thickness=.20):
        pts=np.asarray(pts,float)
        if len(pts)==1:pts=np.vstack([pts,pts])
        assert pts.ndim==2 and pts.shape[1]==3 and np.isfinite(pts).all()
        if dashed:
            # Spatial meshes exhibit the same short-map export limitation.
            # Split exact conceptual paths into visible dashes.
            le=np.linalg.norm(np.diff(pts,axis=0),axis=1);cs=np.r_[0,np.cumsum(le)]
            for start in np.arange(0,cs[-1],.18):
                stop=min(start+.095,cs[-1]);ts=np.r_[start,cs[(cs>start)&(cs<stop)],stop]
                self.line(np.c_[*[np.interp(ts,cs,pts[:,j]) for j in range(3)]],grey,False,thickness)
        else:self.zones.append(dict(kind='line',pts=pts,grey=grey,thickness=thickness))
        return self
    def surface(self,pts,cells,grey=7,trans=0):
        self.zones.append(dict(kind='surface',pts=np.asarray(pts),cells=np.asarray(cells,int),grey=grey,trans=trans));return self
    def arrow(self,a,b,grey=0,thickness=.22):
        a=coord(a);b=coord(b);d=unit(b-a);L=np.linalg.norm(b-a);h=min(.20,L*.18);radius=h*.32
        u=unit(np.cross(d,[0,0,1]) if abs(d[2])<.95 else np.cross(d,[0,1,0]));w=np.cross(d,u);t=np.linspace(0,2*np.pi,9)[:-1]
        ring=b-h*d+radius*(np.cos(t)[:,None]*u+np.sin(t)[:,None]*w)
        self.line([a,b-h*.60*d],grey,thickness=thickness);pts=np.vstack([ring,b]);cells=[[i+1,(i+1)%8+1,9,9] for i in range(8)];self.surface(pts,cells,grey)
        return self
    def label(self,p,s,size=12,grey=0):self.labels.append((coord(p),s,size,grey));return self
    def dot(self,p,r=.045,grey=0):
        pts,cells=ellipsoid(coord(p),np.eye(3),[r]*3,n=12,m=9);self.surface(pts,cells,grey);return self
    def basis(self,o,Q=np.eye(3),L=1.2,labels=None,grey=0,offsets=None,dashed=False):
        Q=np.asarray(Q);assert np.linalg.norm(Q.T@Q-np.eye(3))<1e-12 and abs(np.linalg.det(Q)-1)<1e-12
        self.checks.append({'orthogonality':float(np.linalg.norm(Q.T@Q-np.eye(3))),'determinant':float(np.linalg.det(Q))})
        o=coord(o)
        for j in range(3):
            if labels and labels[j]=='':continue
            p=o+L*Q[:,j]
            if dashed:self.line([o,p],grey,True);self.arrow(p-.20*Q[:,j],p,grey)
            else:self.arrow(o,p,grey)
            if labels and labels[j]:self.label(p+(.28*Q[:,j] if offsets is None else offsets[j]),labels[j],grey=grey)
        return self
    def arc(self,o,normal,u,a,b,r=.65,label=None,grey=0):
        o=coord(o);normal=unit(normal);u=unit(u);w=np.cross(normal,u);t=np.linspace(a,b,81);pts=o+r*(np.cos(t)[:,None]*u+np.sin(t)[:,None]*w)
        self.line(pts,grey);self.arrow(pts[-6],pts[-1],grey)
        if label:self.label(o+(r+.30)*(np.cos((a+b)/2)*u+np.sin((a+b)/2)*w),label,grey=grey)
        return self
    def box(self,c,Q=np.eye(3),half=(1,.5,.5),grey=7,trans=0):
        c=coord(c);p=np.array([[-1,-1,-1],[1,-1,-1],[1,1,-1],[-1,1,-1],[-1,-1,1],[1,-1,1],[1,1,1],[-1,1,1]])*half
        p=c+p@np.asarray(Q).T;cells=[[1,2,3,4],[5,6,7,8],[1,2,6,5],[2,3,7,6],[3,4,8,7],[4,1,5,8]]
        self.surface(p,cells,grey,trans)
        for a,b in [(0,1),(1,2),(2,3),(3,0),(4,5),(5,6),(6,7),(7,4),(0,4),(1,5),(2,6),(3,7)]:self.line(p[[a,b]],4,thickness=.12)
        return self
    def beam(self,c,Q=None,half=(.26,.36),grey=7,dashed=False):
        c=np.asarray(c);qs=Q if Q is not None else [np.eye(3)]*len(c);rings=[]
        for p,q in zip(c,qs):rings.append(p+np.array([[0,-half[0],-half[1]],[0,half[0],-half[1]],[0,half[0],half[1]],[0,-half[0],half[1]]])@np.asarray(q).T)
        if not dashed:
            cells=[[4*j+i+1,4*j+(i+1)%4+1,4*(j+1)+(i+1)%4+1,4*(j+1)+i+1] for j in range(len(c)-1) for i in range(4)]
            cells.extend([[1,2,3,4],[4*len(c)-3,4*len(c)-2,4*len(c)-1,4*len(c)]])
            self.surface(np.vstack(rings),cells,grey,65)
        for j in range(4):self.line(np.array(rings)[:,j,:],4,dashed,.13)
        for idx in [0,len(c)-1]:self.line(np.vstack([rings[idx],rings[idx][0]]),4,dashed,.13)
        self.line(c,1,True,.16)
        return self
    def plane(self,c,Q=np.eye(3),half=(.5,.6),grey=5):
        self.box(coord(c)-.045*np.asarray(Q)[:,0],Q,(.018,*half),grey);return self
    def panel(self,p,letter):self.label(p,'('+letter+')',11)
    def export(self):
        path=HERE/'data'/f'{self.name}.dat'
        with path.open('w') as f:
            f.write('TITLE="'+txt(self.purpose)+'"\nVARIABLES="X_design" "Y_design" "Z_design"\nDATASETAUXDATA Representation="conceptual_3D_not_physical_mesh"\n')
            for i,z in enumerate(self.zones):
                p=z['pts'];assert np.isfinite(p).all()
                if z['kind']=='surface':f.write(f'ZONE T="Conceptual surface {i}", N={len(p)}, E={len(z["cells"])}, ZONETYPE=FEQUADRILATERAL, DATAPACKING=POINT\n')
                else:f.write(f'ZONE T="Geometric line {i}", I={len(p)}, DATAPACKING=POINT\n')
                np.savetxt(f,p,fmt='%.17g')
                if z['kind']=='surface':np.savetxt(f,z['cells'],fmt='%d')
        s=['#!MC 1410','$!NewLayout',f'$!FrameLayout Width = {self.width} Height = {self.height} ShowBorder = No',f"$!ReadDataSet '\"{path}\"'",'$!PlotType = Cartesian3D'];colors(s)
        s+=['$!FieldLayers ShowMesh = Yes ShowShade = Yes ShowScatter = No ShowEdge = No ShowContour = No UseTranslucency = Yes','$!GlobalThreeD LightSource { BackgroundLight = 85 Intensity = 15 IncludeSpecular = No }','$!ThreeDAxis AxisMode = XYZDependent DepXToYRatio = 1 DepXToZRatio = 1 AspectRatioLimit = 1000 BoxAspectRatioLimit = 1000 GridArea { IsFilled = No DrawBorder = No UseLightSourceToFill = No } FrameAxis { Show = No }']
        for i,z in enumerate(self.zones,1):
            if z['kind']=='surface':s.append(f'$!FieldMap [{i}] Mesh {{ Show = No }} EdgeLayer {{ Show = No }} Shade {{ Show = Yes Color = {COLORS[z["grey"]]} }} Surfaces {{ SurfacesToPlot = BoundaryFaces }} Effects {{ LightingEffect = Paneled SurfaceTranslucency = {max(1,z.get("trans",0))} }}')
            else:s.append(f'$!FieldMap [{i}] Mesh {{ Show = Yes Color = {COLORS[z["grey"]]} LineThickness = {z["thickness"]} }} Shade {{ Show = No }} EdgeLayer {{ Show = No }}')
        for axis in ['X','Y','Z']:s.append(f'$!ThreeDAxis {axis}Detail {{ ShowAxis = No }}')
        psi,theta=np.deg2rad([self.psi,self.theta]);u=np.array([np.sin(theta),-np.cos(theta),0]);vv=np.array([np.cos(psi)*np.cos(theta),np.cos(psi)*np.sin(theta),np.sin(psi)]);n=np.cross(u,vv)
        pts=np.vstack([z['pts'] for z in self.zones]);labels=np.array([p for p,t,size,col in self.labels]);allp=np.vstack([pts,labels])
        q=np.c_[allp@u,allp@vv];lo=q.min(0);hi=q.max(0);center2=(lo+hi)/2;c=center2[0]*u+center2[1]*vv
        viewwidth=max((hi[0]-lo[0])*1.22,(hi[1]-lo[1])*self.width/self.height*1.22);cam=c+100*n
        s += [f'$!ThreeDView PsiAngle = {self.psi} ThetaAngle = {self.theta} DrawInPerspective = No ViewerPosition {{ X = {cam[0]:.16g} Y = {cam[1]:.16g} Z = {cam[2]:.16g} }} ViewWidth = {viewwidth:.16g}']
        for p,t,size,col in self.labels:
            xy=np.array([(p-c)@u,(p-c)@vv]);fx=50+100*xy[0]/viewwidth;fy=50+100*xy[1]/(viewwidth*self.height/self.width)
            attach(s,fx,fy,t,size,COLORS[col],font='Times')
        exports(s,self.name);s[-3]='$!ExportSetup ImageWidth = 4000';(HERE/'macros'/f'{self.name}.mcr').write_text('\n'.join(s)+'\n')
        return dict(id=self.name,purpose=self.purpose,representation='conceptual_spatial_mechanics',sources=[str(THESIS/'tesis_autocontenida.tex')],documents=['tesis_autocontenida.tex','tesis_modelo.tex'],units={'coordinates':'dimensionless design; no physical scale'},configuration={'orthographic_3D':True,'monochrome':True,'camera_psi_deg':self.psi,'camera_theta_deg':self.theta,'original_figure_label':'fig:'+self.name.removeprefix('concept_'),'geometry_checks':self.checks,**self.config},dataset=f'data/{self.name}.dat',macro=f'macros/{self.name}.mcr',layout=f'layouts/{self.name}.lay',package=f'layouts/{self.name}.lpk',exports=[f'figures/{self.name}.{x}' for x in ['eps','pdf','png']],notes=['Original conceptual spatial drawing. Volumes are illustrative and are not solver solids.','No embedded title or caption. Grey auxiliaries, black current directions; initial/nominal lines dashed where comparison needs them.'],generator='Tecplot 360 native Cartesian3D macro export')

def build(keys):
    scenes=[];I=np.eye(3);a=.5;QA=R([0,0,1],a);qb=R([0,1,0],-.2)@QA
    horizontal=np.array([-2**-.5,2**-.5,0]);vertical=np.array([-np.cos(np.deg2rad(65))*2**-.5,-np.cos(np.deg2rad(65))*2**-.5,np.sin(np.deg2rad(65))]);normal=np.cross(horizontal,vertical)
    for f in keys:
        k=f.name.removeprefix('concept_')
        if k=='turbina' or not f.name.startswith('concept_'):continue
        s=Scene(f.name,f.title);scenes.append(s)
        if k=='rotacion-bases':
            Q=R([1,0,0],.5);av=np.array([2.,1.1,1.65]);s.height=4.5
            for j in range(2):
                o=5.8*j*horizontal;s.basis(o,I,2.2,['',e(2,'A'),e(3,'A')],4,dashed=True)
                s.basis(o,Q,2.75,[e(1,'B') if j else e(1),e(2,'B'),e(3,'B')],0);s.arc(o,[1,0,0],[0,1,0],0,.5,.8,greek('a'))
                if j:
                    s.arrow(o,o+av,0,.30);s.label(o+av+.35*vertical,v('a'));c=Q.T@av
                    for n in [1,2]:s.line([o+c[n]*Q[:,n],o+av],4,True,.12)
                s.panel(o+3.3*vertical,chr(97+j))
        elif k=='cambio-componentes':
            # Two separated spatial panels keep each set of projections readable.
            av=np.array([2.,1.1,1.65]);origins=[np.zeros(3),5.8*horizontal]
            for j,(o,Q,fr) in enumerate(zip(origins,[I,qb],['A','B'])):
                s.basis(o,Q,2.75,[e(i,fr) for i in [1,2,3]],0,offsets=[-.52*horizontal-.13*vertical,.30*horizontal-.20*vertical,.30*vertical]);s.arrow(o,o+av,0,.30);s.dot(o+av);s.label(o+av+[0,.25,.3],v('a'))
                c=Q.T@av
                for n in range(3):
                    projection=o+c[n]*Q[:,n];s.line([projection,o+av],4,True,.14);s.label(projection+(-.4*vertical if n!=2 else .35*horizontal),var('a')+sub(n+1)+sup(fr),11,1)
                s.panel(o+[0,-.7,3.0],chr(97+j));s.label(o+[0,-.30,-.25],var('O'))
            s.height=4.9
        elif k=='frames':
            A=np.zeros(3);B=np.array([-1.,3.9,.8]);P=B+[-1.8,1.3,1.9];s.basis(A,I,1.2,[e(i,'A') for i in [1,2,3]],1);s.basis(B,qb,1.25,[e(i,'B') for i in [1,2,3]])
            for u,w,l,off in [(A,B,v('c','B'),[.3,0,-.2]),(B,P,v('y'),[.3,0,.2]),(A,P,v('x'),[-.3,0,.4])]:s.arrow(u,w);s.label((u+w)/2+off,l)
            s.dot(P).label(P+[0,.25,.25],var('P'));s.label(A+[0,-.2,-.3],var('O')+sub('A'));s.label(B+.65*horizontal-.40*vertical,var('O')+sub('B'))
        elif k=='rotaciones-elementales':
            s.height=3.6
            for j,g in enumerate(['a','b','g']):
                o=5.0*j*horizontal;axis=I[:,j];Q=R(axis,a)
                initial=[e(i) if i!=j+1 else '' for i in [1,2,3]]
                s.basis(o,I,1.8,initial,4,dashed=True);s.basis(o,Q,2.25,['R'+sub(j+1)+' '+e(i) if i!=j+1 else e(i) for i in [1,2,3]],0,offsets=[.28*Q[:,n]+(.3*horizontal-.25*vertical if j==2 and n==0 else .4*horizontal+.12*vertical if j==2 and n==1 else np.zeros(3)) for n in range(3)])
                u=I[:,(j+1)%3];s.arc(o,axis,u,0,a,.75,greek(g));s.panel(o+[0,-.9,2.8],chr(97+j))
        elif k=='derivada-director':
            p=np.array([0,2.5,0]);q=R([1,0,0],.7)@p;s.basis(-2*horizontal-vertical+2*normal,I,.75,[E(i) for i in [1,2,3]],4)
            s.arrow([0,0,0],p,1).arrow([0,0,0],q,0);s.arrow(p,q,2);s.arrow(p,p+[0,0,2.0],0)
            s.arc([0,0,0],[1,0,0],[0,1,0],-.15,1.1,2.5)
            s.label(p+.5*horizontal-.35*vertical,v('e','i')+'(t)');s.label(q+.35*horizontal+.4*vertical,v('e','i')+'(t+'+greek('D')+'t)');s.label((p+q)/2-.55*horizontal,greek('D')+v('e','i'));s.label(p+[0,0,2.0]+.5*horizontal,'d'+v('e','i')+'/dt')
        elif k=='rotacion-deformacion':
            s.height=3.9
            for j,T in enumerate([I,R([0,0,1],.5),np.array([[1,.5,0],[0,1,0],[0,0,1.]])]):
                o=4.8*j*horizontal;p=np.array([[-1,-.8,-.7],[1,-.8,-.7],[1,.8,-.7],[-1,.8,-.7],[-1,-.8,.7],[1,-.8,.7],[1,.8,.7],[-1,.8,.7]])@T.T+o
                cells=[[1,2,3,4],[5,6,7,8],[1,2,6,5],[2,3,7,6],[3,4,8,7],[4,1,5,8]];s.surface(p,cells,7)
                for cell in cells:s.line(p[np.array(cell+[cell[0]])-1],0,thickness=.14)
                for t in [-.5,0,.5]:s.line(o+np.array([[-1,t,.71],[1,t,.71]])@T.T,4,thickness=.10)
                s.panel(o+[0,-1.2,1.5],chr(97+j))
        elif k=='configs':
            X=np.array([0,0,.4]);O=X-2*horizontal-2*vertical+2*normal;x=np.array([.4,4.5,.8]);
            for p,Q,fr in [(X,I,'0'),(x,qb,'t')]:
                pts,cells=ellipsoid(p,Q.T,[.9,1.1,.65],24,17);s.surface(pts,cells,7,85);s.dot(p);s.label(p+[0,-.4,1.1],var('B')+sub(fr))
            for u,w,l,off in [(O,X,v('X'),[.3,-.3,0]),(O,x,v('x'),[.4,0,-.3]),(X,x,v('u'),[0,0,.4])]:s.arrow(u,w);s.label((u+w)/2+off,l)
            s.basis(O,I,.75,[E(i) for i in [1,2,3]],1);s.label(O+[0,-.2,-.3],var('O')+sub('N'))
        elif k in ['sistemas-lateral','cadena-posiciones']:
            N=-2.5*horizontal-.8*vertical+2*normal;B=np.array([0.,0,0]);G=np.array([0,0,4]);H=np.array([2.5,0,4]);P=np.array([2.5,0,5.6]);X=np.array([2.8,.4,7])
            # Longitudinal direction of the tower is vertical.
            QT=np.c_[[0,0,1],[1,0,0],[0,1,0]];s.beam([B,G],[QT,QT],(.18,.18));s.box(G+[0,0,.1],I,(.8,.45,.4),trans=75).box(H,I,(.45,.4,.4),trans=75);s.line([G,H],1)
            if k=='sistemas-lateral':
                for o,fr in [(N,'N'),(B,'B'),(G,'G')]:s.basis(o,I,.9,[E(i) if fr=='N' else e(i,fr) for i in [1,2,3]],0);s.label(o+.35*horizontal-.65*vertical,var('O')+sub(fr))
                s.arrow(N,B).label((N+B)/2+[0,-.4,0],v('c','B')+'(t)');s.basis(H,I,.9,[e(i,'H,n') for i in [1,2,3]],1);s.label(H+[.3,0,-.6],var('O')+sub('H'))
            else:
                chain=[N,B,G,H,P,X];names=['N','B','G','H','Pb','P'];s.beam([P,X],[I,I],(.15,.15))
                for j in range(5):s.arrow(chain[j],chain[j+1]);s.label(chain[j]+[0,-.5,.15],var('O')+sub(names[j]) if j<5 else var('P'),11)
                s.arrow(N,X,1).label((N+X)/2+[-.7,0,0],v('x','b'));s.label(X+[0,0,.4],var('P'))
        elif k in ['cubo-nominal','giro-perturbacion']:
            axis=[1,0,0];Q=R(axis,.45);s.basis([0,0,0],I,2.8,['',E(2),E(3)],4,dashed=True);s.basis([0,0,0],Q,2.3,[e(i,'H,n') for i in [1,2,3]],0)
            s.arc([0,0,0],axis,[0,1,0],0,.45,.85,greek('y'));s.box([0,0,0],Q,(.30,.40,.40),7)
            if k=='giro-perturbacion':s.basis([0,0,0],R(axis,.78),2.65,['',e(2,'H'),e(3,'H')],2);s.arc([0,0,0],axis,[0,1,0],.45,.78,1.70,greek('q')+sub('H1'))
            else:s.label([0,-.4,-.4],var('O')+sub('H'))
        elif k in ['marcos','cubo-brazos']:
            s.height=5.4;s.psi=50;s.box([0,0,0],I,(.28,.38,.38),7)
            for b in [1,2,3]:
                a=2*np.pi*(b-1)/3;d1=np.array([0,-np.sin(a),np.cos(a)]);d2=np.array([0,-np.cos(a),-np.sin(a)]);Q=np.c_[d1,d2,[1,0,0]];p=2.1*d1
                s.line([[0,0,0],p],1,True);s.dot(p);s.label(p+.60*np.cross(d1,[1,0,0]),var('P')+sub(b),11)
                if k=='marcos':s.basis(p,Q,.9,[v('d',str(i)+str(b)) for i in [1,2,3]])
                else:s.label(1.05*d1+[.35,0,0],v('r',str(b)+'0','H'));s.box(p,Q,(.08,.2,.25),7)
            s.basis([0,-3.5,-2.6],I,.75,[E(i) for i in [1,2,3]],1);s.label([0,-.8,-.5],var('O')+sub('H'))
        elif k=='palas-paso':
            Q=R([1,0,0],.45);s.box([0,0,0],Q,(.12,1.3,.30),7);s.basis([0,0,0],I,2.0,['',v('d','2b','H'),v('d','3b','H')],4,dashed=True);s.basis([0,0,0],Q,2.5,[v('d',str(i)+'b','H,p') for i in [1,2,3]])
            s.arc([0,0,0],[1,0,0],[0,1,0],0,.45,.95,greek('a')+sub('p,b'))
        elif k=='arbol':
            for j,fr in enumerate(['N','B','G','H','Pb','s']):
                o=2.8*j*horizontal;s.basis(o,I,.70,[E(i) for i in [1,2,3]] if j==0 else None,1)
                s.label(o-.8*vertical,var('F')+sub(fr),14)
                if j<5:s.arrow(o+.9*horizontal+.6*vertical,o+1.9*horizontal+.6*vertical)
            s.height=2.4
        elif k in ['tresniveles','operacion']:
            s.height=3.4;t=np.linspace(0,1,55);ref=np.c_[4.0*t,np.zeros_like(t),np.zeros_like(t)];Qn=R([0,0,1],.35)
            for j in range(3):
                o=4.5*j*horizontal;nom=o+ref@Qn.T if j else o+ref;actual=nom+np.c_[np.zeros_like(t),.25*t*t,.60*t*t] if j==2 else nom
                s.beam(actual,[Qn if j else I]*len(t),(.18,.25));s.basis(o,I,.6,None,1);s.panel(o+[0,-.7,1.25],chr(97+j))
                if j==2:s.beam(nom,[Qn]*len(t),(.18,.25),dashed=True);s.arrow(nom[-1],actual[-1]).label(actual[-1]+[0,.3,.3],v('u') if k=='tresniveles' else v(greek('h')))
                s.label(o+np.array([2,0,0])-.65*vertical,[v('X'),v('x','nom'),v('x')][j],11)
        elif k in ['particula-seccion','shear','continuo-malla','elemento','interpolacion-lineal']:
            t=np.linspace(0,1,61);c=np.c_[5*t,.25*np.sin(np.pi*t),.85*t*t];qs=[R([0,1,0],-.30*x) for x in t];idx=30;p=c[idx];Q=qs[idx]
            if k=='shear':
                Q=R([0,1,0],.25);qs=[Q]*len(t)
            if k=='elemento':
                I0=np.zeros(3);J=np.array([4.5,.8,1.1]);Xa=np.array([1.2,.5,2.9]);d1=unit(J);aux=Xa-Xa@d1*d1;d3=unit(aux);d2=np.cross(d3,d1);Q=np.c_[d1,d2,d3]
                s.beam([I0,J],[Q,Q],(.17,.23));s.basis(I0,Q,1.5,[e(i) for i in [1,2,3]]);s.dot(I0).dot(J).dot(Xa);foot=(Xa@d1)*d1;s.line([I0,Xa,foot],4,True);s.arrow(I0,aux,1)
                s.label(Xa+[0,0,.3],v('X','a'));s.label(aux+[0,.3,.2],v('p'));s.label(J+[.2,0,.3],var('J'));s.label(I0+[-.4,0,-.2],var('I'))
                s.config['auxiliary_orthogonality_error']=float(d1@aux)
            else:
                s.beam(c,qs,(.30,.42));s.plane(p,Q,(.36,.50),5)
                if k not in ['continuo-malla','interpolacion-lineal']:s.basis(p,Q,1.2,[v('d',i) for i in [1,2,3]])
                if k=='shear':
                    tang=unit([5,np.pi*.25*np.cos(np.pi*t[idx]),1.7*t[idx]]);angle=np.arccos(np.clip(Q[:,0]@tang,-1,1));an=unit(np.cross(Q[:,0],tang));s.arrow(p,p+2.0*tang);s.label(p+2.35*tang,v('t'));s.arc(p,an,Q[:,0],0,angle,.7,greek('g'));s.config.update(section_normal_not_tangent=True,illustrative_shear_angle_rad=float(angle),tangent_unit_norm=float(np.linalg.norm(tang)))
                elif k=='continuo-malla':
                    for j,x in enumerate(c[::10]):s.dot(x,.055);s.label(x+[0,-.55,-.35],str(j+1),10)
                elif k=='interpolacion-lineal':
                    s.dot(c[0]).dot(c[-1]);s.label(c[0]+[-.3,0,.3],var('I'));s.label(c[-1]+[.3,0,.3],var('J'))
                    for j in [0,15,30,45,60]:s.arrow(c[j],c[j]+[0,0,.3+.55*t[j]])
                    s.label(c[-1]+[0,0,1.1],v('u','J'));s.label(c[0]+[0,0,.9],v('u','I'))
                else:
                    O=p-2.4*vertical-1.8*horizontal+2.5*normal;s.basis(O,I,.85,[E(i) for i in [1,2,3]],1);s.arrow(O,p).label((O+p)/2-.3*horizontal,v('r')+'(S,t)');s.label(p+[0,-.6,.9],var('S'))
                    if k=='particula-seccion':
                        s.panel(p+3.3*vertical,'a');o=3.5*horizontal-.6*vertical;s.plane(o,I,(1.1,1.25),7);s.basis(o,I,1.9,[v('d',i) for i in [1,2,3]]);P=o+[0,.72,.8];s.dot(P).arrow(o,P);s.label(P+[0,.25,.2],var('P'));s.line([o+[0,.72,0],P,o+[0,0,.8]],4,True);s.label(o+[0,.72,-.3],greek('x')+sub(2));s.label(o+[0,-.3,.8],greek('x')+sub(3));s.panel(o+3.3*vertical,'b');s.height=4.7
        elif k=='coordenadas-nodo':
            s.height=4.5
            for j in range(3):
                o=4.0*j*horizontal;s.box(o,I,(.18,.24,.24),7);s.basis(o,I,.7,[E(i) for i in [1,2,3]],4)
                s.arrow(o,o+1.5*I[:,j]).label(o+1.85*I[:,j],var('u')+sub(j+1));s.arc(o,I[:,j],I[:,(j+1)%3],.1,1.7,.95,greek('q')+sub(j+1));s.panel(o+[0,-1.0,2.0],chr(97+j))
        elif k in ['suma-velocidades','vinculo-raiz']:
            p=np.array([np.zeros(3),2*horizontal-.8*vertical+.3*normal,3.3*horizontal+1.8*vertical-.1*normal,5.6*horizontal+.6*vertical+.2*normal]) if k=='suma-velocidades' else np.array([np.zeros(3),2.5*horizontal+.2*vertical+.1*normal,4*horizontal+2.5*vertical+.3*normal])
            ll=['d'+v('c')+'/dt',var('Q')+sub('c')+'W '+v('y'),var('Q')+sub('c')+' d'+v('y')+'/dt'] if k=='suma-velocidades' else [v('u','H'),v('u','rot')]
            for j,l in enumerate(ll):s.arrow(p[j],p[j+1]).label((p[j]+p[j+1])/2+(-.4*vertical if j==0 else .5*vertical),l)
            s.arrow(p[0],p[-1],0,.3).label((p[0]+p[-1])/2-.65*vertical,'d'+v('x')+'/dt' if k=='suma-velocidades' else v('u','s'))
            s.basis(-1.8*horizontal-1.3*vertical+.6*normal,I,.7,[E(i) for i in [1,2,3]],4)
            s.config['head_to_tail_closure_error']=float(np.linalg.norm(np.diff(p,axis=0).sum(0)-(p[-1]-p[0])))
        elif k in ['centripeta','guia']:
            normal=np.array([1,0,0]);t=np.linspace(0,2*np.pi,101);p=np.c_[np.zeros_like(t),2*np.cos(t),2*np.sin(t)];s.line(p,4,True);P=2*unit([0,1.45,1.38]);vel=1.5*unit(np.cross(normal,P));s.config.update(radial_tangent_dot=float(P@vel),radius=float(np.linalg.norm(P)));s.arrow([0,0,0],P).label(P/2+[.3,0,0],v('r'));s.arrow(P,P+vel).label(P+1.35*vel,v('v'));s.arrow(P,.40*P).label(.70*P+[.3,0,0],v('a'));s.dot(P);s.arrow([0,0,0],[1.45,0,0]).label([1.75,0,0],v('w'))
            if k=='guia':s.box(P/2,np.c_[unit(P),[1,0,0],unit(np.cross(unit(P),[1,0,0]))],(1.4,.08,.08),7);s.dot(P,.13)
        elif k=='gravedad-giratoria':
            s.height=3.7
            for j,a in enumerate([0,.45,.90]):
                o=4.6*j*horizontal;s.basis(o,R([1,0,0],a),1.3,[e(i,'H,n') for i in [1,2,3]],0);s.arrow(o,o+[0,0,-1.6]).label(o+[0,.3,-1.85],v('g'));s.panel(o+[0,-.6,2.1],chr(97+j))
        elif k in ['centros','masa-seccional','carga-seccion','palas-paso']:
            # Thin 3D section, with the longitudinal axis visible outside it.
            o=np.array([0.,0,0]);s.plane(o,I,(1.8,1.25),7);s.basis(o,I,2.3,[v('d',i) for i in [1,2,3]],0)
            C=np.array([.10,1,.6]);A=np.array([.10,-.8,.2]);P=np.array([.10,1.4,.95]);s.dot(C);s.label(C+.35*horizontal+.3*vertical,var('C')+sub('m'));s.label(o+[0,-.25,-.3],var('O')+sub('s'))
            if k=='centros':s.dot(A);s.label(A-.3*horizontal+.4*vertical,var('C')+sub('A'));s.arrow(o,C).label(C/2+[.3,0,0],v('r','cm'))
            elif k=='masa-seccional':
                s.labels=[(pp,ss,sz,col) for pp,ss,sz,col in s.labels if ss!=var('C')+sub('m')];s.label(C-.6*horizontal,var('C')+sub('m'))
                s.box(P,I,(.06,.09,.08),1);s.label(P+.2*horizontal+.4*vertical,'dm');s.arrow(o,P).label(P/2-.3*horizontal+.25*vertical,v('r'));s.arrow(C,P).label((C+P)/2+.8*horizontal+.1*vertical,v('r')+' - '+v('r','cm'))
            else:
                s.zones=[];s.labels=[]
                for j in range(2):
                    b=4.8*j*horizontal;s.plane(b,I,(1.45,.8),7);a=b+[0,.65,.3];q=a if j==0 else b
                    s.arrow(q,q+[0,.5,1.7]).label(q+[0,.6,1.95],v('f'));s.arc(q,[1,0,0],[0,1,0],.1,2,.48,v('m','A' if j==0 else 'Os'));s.label(b+[0,-.3,-.3],var('O')+sub('s'));s.panel(b+[0,-1.5,2.7],chr(97+j))
                    s.dot(b,.028)
                    if j==0:s.dot(a,.028).label(a+.5*horizontal-.15*vertical,var('A'));s.line([b,a],4,True,.13)
                rA=np.array([0,.65,.3]);force=np.array([0,.5,1.7]);mA=np.array([1.,0,0]);s.config['force_transport_geometry']={'r_A':rA.tolist(),'f':force.tolist(),'m_A':mA.tolist(),'m_Os':(mA+np.cross(rA,force)).tolist(),'schematic_dimensionless':True}
        elif k=='rigido-centro':
            C=np.zeros(3);O=-2*horizontal-.7*vertical+.5*normal;P=1.3*horizontal+1.8*vertical+.4*normal;N=-2.8*horizontal-2*vertical+2*normal
            s.box(C+.2*P,qb,(1.6,1.8,1.5),7,88)
            for a,b,l,off in [(N,O,v('x','O'),-.4*horizontal),(N,C,v('x','C'),.4*horizontal-.4*vertical),(O,C,v('c'),-.4*vertical),(C,P,v(greek('r')),.35*horizontal),(O,P,v('r'),.5*vertical)]:s.arrow(a,b);s.label((a+b)/2+off,l)
            for q,l in [(N,'O'+sub('N')),(O,'O'),(C,'C'),(P,'P')]:s.dot(q);s.label(q+.25*horizontal+.25*vertical,var(l))
            s.config['relative_position_closure_error']=float(np.linalg.norm((C-O)+(P-C)-(P-O)))
        elif k=='conexion-elastica':
            G=np.array([0.,0,0]);H=np.array([0,5,0]);s.box(G,I,(.7,.7,.7),7,75).box(H,I,(.7,.7,.7),7,75);s.basis(G,I,1.3,[e(i,'G') for i in [1,2,3]],1);s.basis(H,I,1.3,[e(i,'H') for i in [1,2,3]])
            t=np.linspace(0,1,180);p=np.c_[.3*np.sin(14*np.pi*t),.7+3.6*t,.3*np.cos(14*np.pi*t)];s.line(p,0);s.label([0,2.5,.8],var('K')+sub('d')+', '+var('C')+sub('d'));s.label(G+[0,-.4,-1],var('G'));s.label(H+[0,.4,-1],var('H'))
        elif k=='acoplamiento-giroscopico':
            s.basis([0,0,0],I,2.1,[var('q')+sub(i) for i in [1,2,3]],4);a=unit(2*horizontal+.8*vertical+.3*normal);g=unit(np.cross(normal,a));s.arrow([0,0,0],2.8*a).label(3.2*a,'d'+v('q')+'/dt');s.arrow([0,0,0],2.8*g).label(3.2*g,var('G')+' d'+v('q')+'/dt');s.line([.3*a,.3*(a+g),.3*g],1)
            s.config['normalized_gyroscopic_dot']=float(a@g)
        else:raise ValueError(k)
    return [s.export() for s in scenes]
