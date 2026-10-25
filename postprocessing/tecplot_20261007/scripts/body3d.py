"""Illustrative 3D envelopes with the unchanged 1D computational mesh inside.

Tower annuli are reconstructed under the circular tube assumption from A and I.
Blade dimensions use equivalent mass ellipses, with an illustrative smooth
symmetric airfoil outline. They are NOT recovered airfoils or finite elements
geometry. Nacelle, hub and pedestal are explicitly illustrative envelopes.
"""
from common import *
from science import EVID,LOCAL,MODAL,field
import hdf5storage
from scipy.interpolate import PchipInterpolator

def blade_skin(c,u,v,a,b,n=72):
    """Smooth visual silhouette only; exact beam coordinates remain separate."""
    s=np.r_[0,np.cumsum(np.linalg.norm(np.diff(c,axis=0),axis=1))]
    q=np.linspace(0,s[-1],180)
    cc=np.array([np.interp(q,s,c[:,j]) for j in range(3)]).T
    uu=np.array([np.interp(q,s,u[:,j]) for j in range(3)]).T;uu/=np.linalg.norm(uu,axis=1)[:,None]
    vv=np.array([np.interp(q,s,v[:,j]) for j in range(3)]).T
    vv-=np.sum(vv*uu,axis=1)[:,None]*uu;vv/=np.linalg.norm(vv,axis=1)[:,None]
    aa=PchipInterpolator(s,a)(q);bb=PchipInterpolator(s,b)(q)
    th=np.linspace(0,2*np.pi,n,endpoint=False);x=(1+np.cos(th))/2
    yt=.2969*np.sqrt(x)-.126*x-.3516*x*x+.2843*x**3-.1036*x**4
    yt=np.sign(np.sin(th))*yt/np.max(yt)
    blend=np.clip((q/s[-1]-.035)/.16,0,1);blend=blend*blend*(3-2*blend)
    # Last profile closes smoothly, rather than ending in a blunt cylinder.
    taper=np.where(q/s[-1]>.97,np.sqrt(np.clip((1-q/s[-1])/.03,0,1)),1)
    pts=[]
    for p,e2,e3,h,k,w,t in zip(cc,uu,vv,aa,bb,blend,taper):
        px=h*np.cos(th)*t;py=k*((1-w)*np.sin(th)+w*yt)*t
        pts.extend(p+px[:,None]*e2+py[:,None]*e3)
    cells=[[j*n+i+1,j*n+(i+1)%n+1,(j+1)*n+(i+1)%n+1,(j+1)*n+i+1] for j in range(len(q)-1) for i in range(n)]
    return np.array(pts),np.array(cells)

def nacelle_box(center,basis,length=14,width=9,height=10,n=72):
    """Rounded industrial housing, purely illustrative."""
    t=np.linspace(0,2*np.pi,n,endpoint=False);cs=np.sign(np.cos(t))*np.abs(np.cos(t))**.45;sn=np.sign(np.sin(t))*np.abs(np.sin(t))**.45
    xx=np.linspace(-length/2,length/2,32);pts=[]
    for x in xx:
        # Rounded end caps, constant cross section in the central housing.
        w=np.sqrt(max(0,1-(max(0,abs(x)-length/2+1.7)/1.7)**2))
        local=np.c_[np.full(n,x),w*width/2*cs,w*height/2*sn]
        pts.extend(center+local@basis)
    cells=[[j*n+i+1,j*n+(i+1)%n+1,(j+1)*n+(i+1)%n+1,(j+1)*n+i+1] for j in range(len(xx)-1) for i in range(n)]
    return np.array(pts),np.array(cells)

def surface_rings(centers,e2,e3,a,b,n=48):
    t=np.linspace(0,2*np.pi,n,endpoint=False);pts=[]
    for p,u,v,aa,bb in zip(centers,e2,e3,a,b):pts.extend(p+aa*np.cos(t)[:,None]*u+bb*np.sin(t)[:,None]*v)
    cells=[]
    for j in range(len(centers)-1):
        for i in range(n):cells.append([j*n+i+1,j*n+(i+1)%n+1,(j+1)*n+(i+1)%n+1,(j+1)*n+i+1])
    return np.asarray(pts),np.asarray(cells)

def ellipsoid(center,basis,radii,n=48,m=25):
    ph=np.linspace(-np.pi/2,np.pi/2,m);th=np.linspace(0,2*np.pi,n,endpoint=False);pts=[]
    for a in ph:
        local=np.c_[np.cos(a)*np.cos(th),np.cos(a)*np.sin(th),np.full(n,np.sin(a))]*radii
        pts.extend(center+local@basis)
    cells=[]
    for j in range(m-1):
        for i in range(n):cells.append([j*n+i+1,j*n+(i+1)%n+1,(j+1)*n+(i+1)%n+1,(j+1)*n+i+1])
    return np.asarray(pts),np.asarray(cells)

def build():
    j=json.loads(EVID.read_text());xyz=np.asarray(j['geometry']['nodeCoordinates_m']);els=np.asarray(j['geometry']['elements'],int);raw=field(hdf5storage.loadmat(ROOT/'data/geometry/legacy_geometry_v0.mat')['geometry']);sec=readcsv(LOCAL/'local/nominal_sections.csv');axis=np.asarray(j['geometry']['rotorAxis']['direction']);byid={int(r['sectionId']):r for r in sec}
    axis2=np.array([0.,1.,0.]);axis3=np.cross(axis,axis2);basis=np.array([axis,axis2,axis3]);surfaces=[]
    # Only a visualization surface: nodal radii interpolate section midpoints.
    A=np.array([float(r['EA_N'])/2.1e11 for r in sec[:19]]);I=np.array([float(r['EIy_Nm2'])/2.1e11 for r in sec[:19]])
    Ro=np.sqrt((4*I/A+A/np.pi)/2);Ri=np.sqrt((4*I/A-A/np.pi)/2)
    mid=(xyz[:19,2]+xyz[1:20,2])/2;r=np.interp(xyz[:20,2],mid,Ro)
    tower=surface_rings(xyz[:20],np.tile([1,0,0],(20,1)),np.tile([0,1,0],(20,1)),r,r)
    surfaces.append(('Torre: envolvente tubular',*tower,7))
    root_radii=[];blade_parts=[]
    for b in [1,2,3]:
        el=els[els[:,4]==b];nodes=np.r_[el[:,1],el[-1,2]];centers=xyz[nodes-1];e2=[];e3=[];a=[];bb=[]
        aux=np.asarray(raw['coorP'+str(b)+'aux'])
        for i,e in enumerate(el):
            p=xyz[e[1]-1];v=xyz[e[2]-1]-p;v/=np.linalg.norm(v);w=aux[i]-p;w-=np.dot(w,v)*v;w/=np.linalg.norm(w);u=np.cross(w,v);e2.append(u);e3.append(w)
            s=byid[e[3]];mass=float(s['massPerLength_kg_m']);a.append(2*np.sqrt(float(s['Jz_kg_m'])/mass));bb.append(2*np.sqrt(float(s['Jy_kg_m'])/mass))
        e2=np.vstack([e2,e2[-1]]);e3=np.vstack([e3,e3[-1]]);a=np.r_[a,a[-1]];bb=np.r_[bb,bb[-1]]
        surf=blade_skin(centers,e2,e3,a,bb);surfaces.append((f'Pala {b}: perfil visual suavizado',*surf,7));root_radii.append([a[0],bb[0]]);blade_parts.append((centers,e2,e3,a,bb))
    # Hub centered at the actual master; cross dimensions follow actual root arms.
    arms=xyz[np.array([21,57,93])-1]-xyz[129];rad=float(np.max(np.linalg.norm(arms,axis=1)))
    # Nose is extended along the real tilted shaft, not the global X axis.
    surfaces.append(('Cubo: carenado ilustrativo',*ellipsoid(xyz[129]+1.5*axis,basis,np.array([5.8,rad+.3,rad+.3])),7))
    # An envelope around the actual transition/master nodes, NOT inferred CAD.
    trans=xyz[np.r_[np.arange(130,138),128]];local=(trans-xyz[128])@basis.T;lo=local.min(0)-[2,4,2];hi=local.max(0)+[2,4,2];c=(lo+hi)/2;rr=(hi-lo)/2
    surfaces.append(('Gondola: carcasa ilustrativa',*nacelle_box(xyz[128]-2*axis-1.4*axis3,basis),7))
    ped=surface_rings(np.array([[0,0,-3],[0,0,0.]]),np.array([[1,0,0],[1,0,0]]),np.array([[0,1,0],[0,1,0]]),[r[0]*1.25]*2,[r[0]*1.25]*2)
    surfaces.append(('Base: envolvente ilustrativa',*ped,7))
    specs=[]
    for detail in [False,True]:
        name='turbina_conexiones_3d' if detail else 'turbina_3d'
        title='Cubo, raices y gondola: vigas y nodos interiores' if detail else 'Turbina: envolvente 3D y modelo de vigas interior'
        ss=surfaces
        use=els
        if detail:
            ss=[]
            ts=surface_rings(xyz[18:20],np.tile([1,0,0],(2,1)),np.tile([0,1,0],(2,1)),r[18:20],r[18:20]);ss.append(('Torre: extremo superior',*ts,7))
            for b,(c,u,v,a,z) in enumerate(blade_parts,1):
                p,t=blade_skin(c,u,v,a,z)
                span=np.r_[0,np.cumsum(np.linalg.norm(np.diff(c,axis=0),axis=1))]
                keep=int(np.ceil(span[2]/span[-1]*179))*72
                ss.append((f'Pala {b}: raiz',p[:keep+72],t[:keep],7))
            ss.extend(surfaces[4:6]);use=np.vstack([els[18:19],els[els[:,0]>=125]]+[els[els[:,4]==b][:2] for b in [1,2,3]])
        path=HERE/'data'/f'{name}.dat';styles=[]
        with path.open('w') as f:
            f.write('TITLE="'+title+'"\nVARIABLES="X [m]" "Y [m]" "Z [m]" "NodeID"\nDATASETAUXDATA Representation="visual_envelope_plus_actual_1D_beams"\n')
            for label,pts,cells,col in ss:
                f.write(f'ZONE T="VISUAL ONLY: {label}", N={len(pts)}, E={len(cells)}, DATAPACKING=POINT, ZONETYPE=FEQUADRILATERAL\n');np.savetxt(f,np.c_[pts,np.zeros(len(pts))],fmt='%.17g');np.savetxt(f,cells,fmt='%d');styles.append(('surface',col))
            for b in range(5):
                ee=np.array([e for e in use if (int(e[4]) if e[4] else (0 if e[0]<20 else 4))==b])
                if not len(ee):continue
                ns=np.unique(ee[:,1:3]);mapping={int(n):i+1 for i,n in enumerate(ns)};connect=np.array([[mapping[int(e[1])],mapping[int(e[2])]] for e in ee])
                f.write(f'ZONE T="PHYSICAL 1D: {b}", N={len(ns)}, E={len(ee)}, DATAPACKING=POINT, ZONETYPE=FELINESEG\n');np.savetxt(f,np.c_[xyz[ns-1],ns],fmt='%.17g');np.savetxt(f,connect,fmt='%d');styles.append(('beam',[6,0,0,0,6][b]))
            active_nodes=np.unique(use[:,1:3]);pts=xyz[active_nodes-1]
            f.write(f'ZONE T="PHYSICAL NODES", I={len(pts)}, DATAPACKING=POINT\n');np.savetxt(f,np.c_[pts,active_nodes],fmt='%.17g');styles.append(('node',6))
            f.write('ZONE T="MASTER AND ROOT NODES", I=5, DATAPACKING=POINT\n');np.savetxt(f,np.c_[xyz[np.array([21,57,93,129,130])-1],[21,57,93,129,130]],fmt='%.17g');styles.append(('master',1))
            for n in [21,57,93]:
                f.write('ZONE T="MPC geometric link, NOT beam", I=2, DATAPACKING=POINT\n');np.savetxt(f,np.c_[xyz[[129,n-1]],[130,n]],fmt='%.17g');styles.append(('mpc',1))
            f.write('ZONE T="ACTUAL ROTOR AXIS 129-130", I=2, DATAPACKING=POINT\n');np.savetxt(f,np.c_[np.vstack([xyz[128]-5*axis,xyz[129]+10*axis]),[0,0]],fmt='%.17g');styles.append(('axis',2))
            if detail:
                offsets={21:[1,-5,-4],57:[1,5,-4],93:[0,0,6],129:[-3,-5,4],130:[4,5,3]}
                for node,off in offsets.items():
                    points=np.array([xyz[node-1],xyz[node-1]+off]);f.write(f'ZONE T="Leader node {node}", I=2, DATAPACKING=POINT\n');np.savetxt(f,np.c_[points,[0,0]],fmt='%.17g');styles.append(('leader',7))
        s=['#!MC 1410','$!NewLayout',f'$!FrameLayout Width = {8 if detail else 7} Height = {6 if detail else 7.6} ShowBorder = No',f"$!ReadDataSet '\"{path}\"'",'$!PlotType = Cartesian3D'];colors(s)
        s+=['$!FieldLayers ShowMesh = Yes ShowShade = Yes ShowScatter = Yes ShowEdge = Yes ShowContour = No UseTranslucency = Yes','$!ThreeDAxis AxisMode = XYZDependent DepXToYRatio = 1 DepXToZRatio = 1 AspectRatioLimit = 1000 BoxAspectRatioLimit = 1000 GridArea { IsFilled = No UseLightSourceToFill = No DrawBorder = No } FrameAxis { Show = Yes Size = 5 XYPos { X = 9 Y = 12 } }']
        for i,(kind,c) in enumerate(styles,1):
            if kind=='surface':
                s += [f'$!FieldMap [{i}] Mesh {{ Show = No }} Shade {{ Show = Yes Color = {COLORS[c]} }} Scatter {{ Show = No }} EdgeLayer {{ Show = No }} Surfaces {{ SurfacesToPlot = BoundaryFaces }} Effects {{ LightingEffect = Smooth SurfaceTranslucency = {85 if detail else 67} }}']
            else:
                if kind=='node':c=6
                only=kind in ['node','master'];s += [f'$!FieldMap [{i}] Mesh {{ Show = {"No" if only else "Yes"} Color = {COLORS[c]} LineThickness = {0.30 if kind=="beam" else 0.2} LinePattern = {"DASHED" if kind=="mpc" else "SOLID"} }} Shade {{ Show = No }} EdgeLayer {{ Show = No }} Scatter {{ Show = {"Yes" if only else "No"} Color = {COLORS[c]} FillColor = {COLORS[c]} FillMode = UseSpecificColor FrameSize = {(0.7 if detail else .6) if kind=="master" else (.38 if detail else .23)} SymbolShape {{ GeomShape = Sphere }} }}']
        for axisname in ['X','Y','Z']:
            s.append(f"$!ThreeDAxis {axisname}Detail {{ ShowAxis = No }}")
        s += [f'$!ThreeDView PsiAngle = {73 if detail else 87} ThetaAngle = {230 if detail else 258} DrawInPerspective = No','$!View Fit',f'$!ThreeDView ViewWidth *= {1.25 if detail else 1.12}']
        if detail:
            for node in [21,57,93,129,130]:
                x,y,z=xyz[node-1]+offsets[node];s.append(f"$!AttachText PositionCoordSys = Grid3D AnchorPos {{ X = {x} Y = {y} Z = {z} }} TextShape {{ FontFamily = 'Helvetica' SizeUnits = POINT Height = 9 }} Color = Black Text = '{node}'")
        exports(s,name);s[-3]='$!ExportSetup ImageWidth = 4200';(HERE/'macros'/f'{name}.mcr').write_text('\n'.join(s)+'\n')
        specs.append(dict(id=name,purpose=title,representation='illustrative_3D_envelope_with_actual_1D_mesh',sources=[str(EVID),str(MODAL/'model_snapshot.mat'),str(LOCAL/'local/nominal_sections.csv'),str(ROOT/'data/geometry/legacy_geometry_v0.mat')],documents=['tesis_autocontenida.tex','FORMULACION_MATEMATICA.tex','MANUSCRITO_INTEGRADO.tex'],units={'coordinates':'m'},configuration={'uniform_scale':True,'surface_translucency_percent':85 if detail else 67,'beam_elements_unchanged':True,'tower_shape':'circular annulus from A and I; nodal radii interpolated only for visualization','blade_shape':'smooth symmetric illustrative airfoil outline, section bounds derived from mass ellipses, root circular transition; NOT recovered aerodynamic profile or inertia-equivalent surface','nacelle_hub_base':'illustrative envelopes, no measured CAD dimensions','detail':detail},dataset=f'data/{name}.dat',macro=f'macros/{name}.mcr',layout=f'layouts/{name}.lay',package=f'layouts/{name}.lpk',exports=[f'figures/{name}.{e}' for e in ['eps','pdf','png']],notes=['Surface tessellation is only a visualization dataset; no change to solver mesh.'],generator='Tecplot 360 batch macros'))
    dump(HERE/'reports/envelope_geometry.json',{'tower_A_m2':A.tolist(),'tower_I_m4':I.tolist(),'tower_outer_radius_m':Ro.tolist(),'tower_inner_radius_m':Ri.tolist(),'annulus_A_relative_error':float(np.max(np.abs(np.pi*(Ro**2-Ri**2)/A-1))),'annulus_I_relative_error':float(np.max(np.abs(np.pi/4*(Ro**4-Ri**4)/I-1))),'blade_root_equivalent_ellipse_semiaxes_m':root_radii,'original_geometry_unchanged':True,'blade_airfoil_geometry_available':False})
    return specs
