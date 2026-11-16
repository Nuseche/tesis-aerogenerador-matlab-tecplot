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
        return dict(id=self.name,purpose=self.purpose,representation='conceptual_spatial_mechanics',sources=[],documents=[],units={'coordinates':'dimensionless design; no physical scale'},configuration={'orthographic_3D':True,'monochrome':True,'camera_psi_deg':self.psi,'camera_theta_deg':self.theta,'original_figure_label':'fig:'+self.name.removeprefix('concept_'),'geometry_checks':self.checks,**self.config},dataset=f'data/{self.name}.dat',macro=f'macros/{self.name}.mcr',layout=f'layouts/{self.name}.lay',package=f'layouts/{self.name}.lpk',exports=[f'figures/{self.name}.{x}' for x in ['eps','pdf','png']],notes=['Original conceptual spatial drawing. Volumes are illustrative and are not solver solids.','No embedded title or caption. Grey auxiliaries, black current directions; initial/nominal lines dashed where comparison needs them.'],generator='Tecplot 360 native Cartesian3D macro export')
