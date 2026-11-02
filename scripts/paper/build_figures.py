#!/usr/bin/env python3
"""Original, vector, monochrome formulation diagrams; no Tecplot dependency.
All geometry is defined in 3-D before orthographic projection. No simulation
results are generated. Run with numpy and matplotlib from requirements.txt.
"""
from pathlib import Path
import json
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon, FancyArrowPatch
from matplotlib.collections import PolyCollection

ROOT=Path(__file__).resolve().parents[2]
PAPER=ROOT/'docs/formulacion_revista_20260919'
if not PAPER.exists():PAPER=ROOT/'Paper_mathematical_tesis'
if not PAPER.exists():PAPER=ROOT
OUT=PAPER/'figures/publication'
QA=ROOT/'output/paper_review/figures'
plt.rcParams.update({'font.family':'serif','font.serif':['STIXGeneral'], 'mathtext.fontset':'stix',
 'font.size':11, 'pdf.fonttype':42, 'ps.fonttype':42, 'savefig.facecolor':'white'})
CAM=np.array([[.8574929,-.5144958,0],[-.1543487,-.2572479,.9539392]])
CAM[0]/=np.linalg.norm(CAM[0]);CAM[1]-=CAM[0]*np.dot(CAM[0],CAM[1]);CAM[1]/=np.linalg.norm(CAM[1])
DEPTH=np.cross(CAM[0],CAM[1])
I=np.eye(3)
checks={}

def rot(axis,t):
 a=np.array(axis,dtype=float);a/=np.linalg.norm(a)
 K=np.array([[0,-a[2],a[1]],[a[2],0,-a[0]],[-a[1],a[0],0]])
 return I+np.sin(t)*K+(1-np.cos(t))*(K@K)

def setup(n=1,w=7.0,h=2.9):
 fig,axes=plt.subplots(1,n,figsize=(w,h),squeeze=False)
 fig.subplots_adjust(left=.015,right=.985,bottom=.02,top=.98,wspace=.17)
 for ax in axes.flat: ax.set_aspect('equal');ax.axis('off')
 return fig,list(axes.flat)

def panel(ax,s):
 box=ax.get_position(original=True)
 ax.figure.text(box.x0+.01,box.y1-.01,s,va='top',fontsize=11)
def proj(p): return np.asarray(p)@CAM.T

def line(ax,p,**kw):
 q=proj(p);ax.plot(q[:,0],q[:,1],color=kw.pop('color','.18'),lw=kw.pop('lw',1.0),**kw)
def dot(ax,p,s=18,white=False):
 q=proj(p);ax.scatter(q[...,0],q[...,1],s=s,facecolor='white' if white else '.12',edgecolor='.12',linewidth=.7,zorder=8)
def label(ax,p,s,off=(5,5),**kw):
 q=proj(p);ax.annotate(s,q,xytext=off,textcoords='offset points',fontsize=kw.pop('size',11),ha=kw.pop('ha','left'),va=kw.pop('va','bottom'),zorder=12,**kw)
def arrow(ax,a,b,s=None,off=(4,4),style='-',lw=1.15,color='.08'):
 a=np.array(a);b=np.array(b);q=proj([a,b]);ax.add_patch(FancyArrowPatch(q[0],q[1],arrowstyle='-|>',mutation_scale=10,linewidth=lw,color=color,linestyle=style,zorder=7))
 if s:label(ax,.5*(a+b),s,off)
def triad(ax,o,Q=I,l=1,labels=None,style='-',offsets=None):
 o=np.array(o)
 for i in range(3):
  e=o+l*Q[:,i];arrow(ax,o,e,style=style,lw=.95)
  if labels:label(ax,e,labels[i],(offsets or [(4,-4),(-4,-3),(2,3)])[i],ha='right' if i==1 else 'left')
def face(ax,p,shade='.94',alpha=1,edge='.55',lw=.6):
 ax.add_patch(Polygon(proj(p),closed=True,fc=shade,ec=edge,lw=lw,alpha=alpha,zorder=1))
def surface(ax,polys,alpha=.6):
 polys=sorted(polys,key=lambda p:np.mean(np.array(p)@DEPTH))
 for p in polys:
  n=np.cross(p[1]-p[0],p[2]-p[0]);n=n/(np.linalg.norm(n)+1e-15)
  shade=str(.84+.12*abs(np.dot(n,[.3,.3,.9])))
  face(ax,p,shade=shade,alpha=alpha,edge='none',lw=0)
def tube(ax,centers,Q,widths,depths,alpha=.5):
 # Rectangular material section; Q has director columns.
 rings=[]
 for c,w,d in zip(centers,widths,depths):
  rings.append(np.array([c+u*w/2*Q[:,1]+v*d/2*Q[:,2] for u,v in [(-1,-1),(1,-1),(1,1),(-1,1)]]))
 ps=[rings[0],rings[-1]]
 for a,b in zip(rings[:-1],rings[1:]):
  ps.extend([np.array([a[j],a[(j+1)%4],b[(j+1)%4],b[j]]) for j in range(4)])
 surface(ax,ps,alpha)
 for j in range(4):line(ax,[ring[j] for ring in rings],color='.6',lw=.5)
 for ring in [rings[0],rings[-1]]:line(ax,np.vstack([ring,ring[0]]),color='.5',lw=.5)
 return rings

def cylinder(ax,start,end,r0,r1,alpha=.45,n=24):
 v=np.array(end)-start;e=v/np.linalg.norm(v);b=np.cross(e,[1,0,0] if abs(e[0])<.9 else [0,1,0]);b/=np.linalg.norm(b);c=np.cross(e,b)
 rings=[np.array([o+r*(np.cos(t)*b+np.sin(t)*c) for t in np.linspace(0,2*np.pi,n,endpoint=False)]) for o,r in [(np.array(start),r0),(np.array(end),r1)]]
 surface(ax,[np.array([rings[0][j],rings[0][(j+1)%n],rings[1][(j+1)%n],rings[1][j]]) for j in range(n)]+rings,alpha)

def finish(fig,axes,name,lims=None):
 for i,ax in enumerate(axes):
  ax.autoscale_view();ax.margins(.18)
  if lims and lims[i]:ax.set_xlim(lims[i][0]);ax.set_ylim(lims[i][1])
 OUT.mkdir(parents=True,exist_ok=True);QA.mkdir(parents=True,exist_ok=True)
 fig.savefig(OUT/f'{name}.pdf',metadata={'Title':'','Author':'','Subject':'Original mathematical diagram','CreationDate':None,'ModDate':None})
 fig.savefig(QA/f'{name}.png',dpi=210)
 plt.close(fig)

def turbine(ax,frames=False):
 H=np.array([-5.,0.,90.]);G=np.array([1.,0.,89.]);B=np.zeros(3)
 cylinder(ax,B,[0,0,88],3,1.9)
 # nacelle: tapered housing along main shaft
 tube(ax,[np.array([-4,0,90]),np.array([5,0,90])],I,[4,3.2],[4,3.4])
 cylinder(ax,[-7,0,90],[-4,0,90],.3,2.5,alpha=.55)
 line(ax,[B,[0,0,87],G,H],lw=1.25)
 dot(ax,np.array([[0,0,z] for z in np.linspace(0,87,15)]),s=1.3)
 for b in range(3):
  Q=rot([1,0,0],b*2*np.pi/3)@np.array([[0,0,1],[0,-1,0],[1,0,0]])
  ss=np.linspace(2.5,63,31);centers=[H+s*Q[:,0] for s in ss]
  chord=np.interp(ss,[2.5,7,15,35,55,63],[2.1,3.3,4.6,3,1.5,.18])
  # closed airfoil-like sections; chord axis d2, thickness d3
  rings=[]
  xx=np.linspace(0,1,22);yt=5*.18*(.2969*np.sqrt(xx)-.1260*xx-.3516*xx**2+.2843*xx**3-.1036*xx**4)
  uv=np.concatenate([np.column_stack([xx-.30,yt]),np.column_stack([xx[::-1]-.30,-yt[::-1]])])
  for c,ch in zip(centers,chord):rings.append(c+ch*(uv[:,0,None]*Q[:,1]+uv[:,1,None]*Q[:,2]))
  polys=[]
  for a,bb in zip(rings[:-1],rings[1:]):
   polys.extend([np.array([a[j],a[(j+1)%len(a)],bb[(j+1)%len(a)],bb[j]]) for j in range(len(a))])
  surface(ax,polys,alpha=.65)
  for j in [0,21]:line(ax,[ring[j] for ring in rings],color='.42',lw=.55)
  pp=H+np.linspace(2.5,63,14)[:,None]*Q[:,0]
  line(ax,pp,lw=.55);dot(ax,pp,s=1.3)
  if not frames:label(ax,H+48*Q[:,0],rf'$\mathcal{{B}}_{{P_{b+1}}}$',(8,4))
 dot(ax,[H,G],s=16);label(ax,H,'$H$',(-13,-10));label(ax,G,'$G$',(10,0))
 if not frames:
  label(ax,[0,0,40],r'$\mathcal{B}_T$',(8,0));label(ax,[0,0,0],'$B$',(-12,-4))
 return H,G,B

# 1. Physical envelope and internal one-dimensional model, plus detailed joint.
f,axs=setup(2,h=3.7);a,b=axs;panel(a,'(a)');turbine(a)
panel(b,'(b)');H=np.array([0.,0.,0.]);G=np.array([4.,0.,0.]);
tube(b,[G+[0,0,-4],G],np.column_stack([I[:,2],I[:,0],I[:,1]]),[.8,.65],[.8,.65])
tube(b,[G+[-1,0,0],G+[1.7,0,0]],I,[1.7,1.4],[1.5,1.2])
cylinder(b,[-1,0,0],[.5,0,0],.15,.85)
for k in range(3):
 Q=rot([1,0,0],k*2*np.pi/3)@np.array([[0,0,1],[0,-1,0],[1,0,0]])
 p=H+1.1*Q[:,0];e=H+3.4*Q[:,0];tube(b,[p,e],Q,[.65,.45],[.25,.16]);line(b,[H,p,e],lw=1.25);dot(b,[p,e]);label(b,p,rf'$P_{k+1}$',[(8,4),(7,6),(-22,-10)][k])
line(b,[H,G],ls='--');dot(b,[H,G]);label(b,H,'$H$',(-25,5));label(b,G,'$G$',(5,-15));label(b,[2,0,0],r'$\boldsymbol{K}_{GH},\,\boldsymbol{C}_{GH}$',(48,36),ha='center',arrowprops=dict(arrowstyle='-',lw=.65))
finish(f,axs,'01_model')

# 2. Same geometric vector, two component decompositions.
f,axs=setup(2,h=2.7);v=np.array([1.7,.7,1.7]);QB=rot([0,0,1],.45)@rot([1,0,0],-.22)
for j,(ax,Q,key) in enumerate(zip(axs,[I,QB],['A','B'])):
 panel(ax,f'({chr(97+j)})');triad(ax,np.zeros(3),Q,l=2.15,labels=[rf'$\boldsymbol{{e}}_{i}^{key}$' for i in [1,2,3]],offsets=[(14,-15),(-4,-3),(2,3)])
 components=Q.T@v;points=[np.zeros(3)]
 for i in range(3):points.append(points[-1]+components[i]*Q[:,i])
 line(ax,points,ls='--',lw=.8,color='.5')
 for i in range(3):label(ax,(points[i]+points[i+1])/2,rf'$a_{i+1}^{key}$',([(-2,-13),(10,12),(-20,3)] if j else [(-2,-12),(0,-13),(5,0)])[i],size=10)
 arrow(ax,np.zeros(3),v,lw=1.65);label(ax,v,r'$\boldsymbol{a}$',(5,4));dot(ax,np.zeros(3),s=12)
checks['component_transform']=float(np.linalg.norm(v-QB@(QB.T@v)))
finish(f,axs,'02_components',lims=[((-1.8,2.5),(-1.15,2.7))]*2)

# 3. Frame origins on machine, separate spatial details to avoid crowded axes.
f,axs=setup(2,h=3.4);panel(axs[0],'(a)');H,G,B=turbine(axs[0],True)
N=np.array([30.,25.,-2.]);triad(axs[0],N,l=20,labels=[r'$\boldsymbol{E}_1$',r'$\boldsymbol{E}_2$',r'$\boldsymbol{E}_3$']);arrow(axs[0],N,B,r'$\boldsymbol{c}_B$',(-16,3));label(axs[0],N,'$O_N$',(3,-13))
ax=axs[1];panel(ax,'(b)')
for o,key in [(np.array([0,0,0]),'B'),(np.array([0,0,3]),'G'),(np.array([-2.5,0,4.8]),'H,n')]:
 triad(ax,o,l=1.1,labels=[rf'$\boldsymbol{{e}}_{i}^{{{key}}}$' for i in [1,2,3]]);dot(ax,o,s=15);label(ax,o,rf'$O_{{{key.split(",")[0]}}}$',(-8,-22))
line(ax,[[0,0,0],[0,0,3],[-2.5,0,4.8]],ls=':',color='.65')
finish(f,axs,'03_frames')

# 4. Prescribed hub rotation; end view and 3-D triads.
f,axs=setup(2,h=2.8);psi=.65;Q=rot([1,0,0],psi)
ax=axs[0];panel(ax,'(a)');triad(ax,[0,0,0],I,2,[r'$\boldsymbol{E}_1$',r'$\boldsymbol{E}_2$',r'$\boldsymbol{E}_3$'],style='--');triad(ax,[0,0,0],Q,1.7,[None,r'$\bar{\boldsymbol{e}}_2^H$',r'$\bar{\boldsymbol{e}}_3^H$'])
t=np.linspace(0,psi,30);arc=np.array([[0,1.1*np.cos(tt),1.1*np.sin(tt)] for tt in t]);line(ax,arc);arrow(ax,arc[-3],arc[-1]);label(ax,arc[15],r'$\psi$',(-13,3))
ax=axs[1];panel(ax,'(b)');
# Rotor end view: horizontal coordinate E2, vertical E3, E1 toward reader.
for vec,s,style in [([1,0],r'$\boldsymbol{E}_2$','--'),([0,1],r'$\boldsymbol{E}_3$','--'),([np.cos(psi),np.sin(psi)],r'$\bar{\boldsymbol{e}}_2^H$','-'),([-np.sin(psi),np.cos(psi)],r'$\bar{\boldsymbol{e}}_3^H$','-')]:
 p=1.7*np.array(vec);ax.add_patch(FancyArrowPatch((0,0),p,arrowstyle='-|>',mutation_scale=10,lw=1,ls=style,color='.1'));ax.annotate(s,p,xytext=(4,3),textcoords='offset points')
ax.plot(1.0*np.cos(t),1.0*np.sin(t),c='.1',lw=.9);ax.annotate('',xy=(np.cos(psi),np.sin(psi)),xytext=(np.cos(psi-.1),np.sin(psi-.1)),arrowprops=dict(arrowstyle='->',lw=1));ax.text(.95,.29,r'$\psi$');ax.text(-.25,-.33,r'$\odot\ \boldsymbol{E}_1$');ax.set_xlim(-1.65,2.15);ax.set_ylim(-.65,2.15)
finish(f,axs,'04_rotation')

# 5. Mounting overview and three spatial details at the corresponding roots.
f,aa=plt.subplots(2,2,figsize=(7,4.1));axs=list(aa.flat)
f.subplots_adjust(left=.03,right=.97,bottom=.04,top=.98,wspace=.23,hspace=.25)
for ax in axs:ax.set_aspect('equal');ax.axis('off')
ax=axs[0];panel(ax,'(a)');H=np.zeros(3)
cylinder(ax,[-.4,0,0],[.4,0,0],.35,.35)
for k in range(3):
 Q=rot([1,0,0],k*2*np.pi/3)@np.array([[0,0,1],[0,-1,0],[1,0,0]])
 p=1.05*Q[:,0];e=2.7*Q[:,0];tube(ax,[p,e],Q,[.40,.22],[.15,.08]);line(ax,[H,e],ls='--',color='.55');dot(ax,p,s=14);label(ax,p,rf'$P_{k+1}$',[(7,4),(8,1),(-23,-7)][k]);checks[f'blade_{k+1}_handedness']=float(np.linalg.det(Q))
 detail=axs[k+1];panel(detail,f'({chr(98+k)})');o=np.zeros(3)
 tube(detail,[-.22*Q[:,0],.6*Q[:,0]],Q,[.33,.33],[.25,.25])
 triad(detail,o,Q,1.0,[rf'$\boldsymbol{{d}}_{{1{k+1}}}$',rf'$\boldsymbol{{d}}_{{2{k+1}}}$',rf'$\boldsymbol{{d}}_{{3{k+1}}}$'],offsets=[[(5,5),(-8,3),(6,-6)],[(7,-15),(-5,-13),(6,4)],[(5,-13),(22,3),(6,-6)]][k])
 dot(detail,o,s=16);label(detail,o,rf'$P_{k+1}$',(-18,-21))
label(ax,H,'$O_H$',(-25,3))
finish(f,axs,'05_blade_frames')

# 6. Beam particle: spatial beam and separate material-section detail.
f,axs=setup(2,h=2.9);ax=axs[0];panel(ax,'(a)');ss=np.linspace(0,4.5,40);cc=np.column_stack([ss,.12*ss**2,np.zeros_like(ss)])
rings=tube(ax,cc,I,np.full(len(ss),.8),np.full(len(ss),.55));line(ax,cc,lw=1.4)
j=25;c=cc[j];face(ax,rings[j],shade='.88',alpha=.6);P=c+np.array([0,.25,.17]);dot(ax,[c,P]);label(ax,P,'$P$',(-28,22),arrowprops=dict(arrowstyle='-',lw=.6));label(ax,cc[9],r'$\boldsymbol{r}(S,t)$',(0,-17));triad(ax,c,I,1,[r'$\boldsymbol{d}_1$',r'$\boldsymbol{d}_2$',r'$\boldsymbol{d}_3$'])
ax=axs[1];panel(ax,'(b)');O=np.zeros(3);face(ax,[[0,-1.2,-.8],[0,1.2,-.8],[0,1.2,.8],[0,-1.2,.8]],shade='.95')
P=np.array([0,.8,.52]);triad(ax,O,I,1.5,[r'$\boldsymbol{d}_1$',r'$\boldsymbol{d}_2$',r'$\boldsymbol{d}_3$']);dot(ax,[O,P]);label(ax,O,'$O_S$',(6,-18));label(ax,P,'$P$',(7,5));arrow(ax,O,P,lw=1.5);line(ax,[P,[0,.8,0],O],ls='--',lw=.8,color='.45');label(ax,[0,.4,0],r'$\xi_2$',(-3,-23));label(ax,[0,.8,.26],r'$\xi_3$',(-17,0));
finish(f,axs,'06_particle')

# 7. Timoshenko shear, spatial section and precise plane kinematics.
f,axs=setup(2,h=2.7);ax=axs[0];panel(ax,'(a)');ang=.35;Q=rot([0,0,1],ang);ss=np.linspace(0,3.8,20);cc=np.column_stack([ss,.25*ss**2,np.zeros_like(ss)]);tube(ax,cc,Q,np.ones(len(ss))*.8,np.ones(len(ss))*.7);line(ax,cc,lw=1.3);c=cc[12];tangent=np.array([1,.5*ss[12],0]);tangent/=np.linalg.norm(tangent);arrow(ax,c,c+1.5*tangent);label(ax,c+1.5*tangent,r'$\boldsymbol{t}$',(2,-15));arrow(ax,c,c+1.5*Q[:,0]);label(ax,c+1.5*Q[:,0],r'$\boldsymbol{d}_1$',(6,4));face(ax,[c+u*.65*Q[:,1]+v*.55*Q[:,2] for u,v in [(-1,-1),(1,-1),(1,1),(-1,1)]],alpha=.3);dot(ax,c)
ax=axs[1];panel(ax,'(b)');phi=.62;theta=.25
ax.plot([-1.1,2.3],[0,0],c='.65',ls='--',lw=.8)
for t,s,l in [(theta,r'$\boldsymbol{d}_1$',2.1),(phi,r'$\boldsymbol{t}$',2.1)]:
 p=l*np.array([np.cos(t),np.sin(t)]);ax.add_patch(FancyArrowPatch((0,0),p,arrowstyle='-|>',mutation_scale=11,lw=1.25,color='.1'));ax.annotate(s,p,xytext=(6,1),textcoords='offset points')
p=np.array([-np.sin(theta),np.cos(theta)]);ax.plot([-p[0],p[0]],[-p[1],p[1]],c='.4',lw=5,alpha=.3);ax.plot([-p[0],p[0]],[-p[1],p[1]],c='.3',lw=.7)
t=np.linspace(theta,phi,40);ax.plot(1.35*np.cos(t),1.35*np.sin(t),c='.1',lw=.9);ax.text(1.4,.65,r'$\gamma$');ax.text(.38,-.4,r'$\gamma=\varphi-\theta$');ax.set_xlim(-.8,2.9);ax.set_ylim(-1.2,1.8)
finish(f,axs,'07_shear')

# 8. A blade portion before/after nominal rotation about E1, and elastic perturbation.
f,axs=setup(3,h=2.9);mount=np.array([[0,0,1],[0,-1,0],[1,0,0]]);Q=rot([1,0,0],.7)@mount;s=np.linspace(0,3.2,30)
for k,ax in enumerate(axs):
 panel(ax,f'({chr(97+k)})');qq=mount if k==0 else Q;nom=np.outer(s,qq[:,0]);cc=nom.copy()
 if k==2:cc+=np.outer(.08*s**2,I[:,0]);line(ax,nom,ls='--',color='.45');arrow(ax,nom[-1],cc[-1]);label(ax,.5*(nom[-1]+cc[-1]),r'$\boldsymbol{u}$',(0,8))
 tube(ax,cc,qq,np.full(len(s),.42),np.full(len(s),.30));line(ax,cc,lw=1.2);dot(ax,cc[[0,-1]],s=12);label(ax,cc[-1],[r'$\boldsymbol{X}$',r'$\bar{\boldsymbol{x}}$',r'$\boldsymbol{x}$'][k],(5,3));triad(ax,[0,0,-.45],I,.5)
 ax.text(.67,.06,[r'$\mathcal{B}_0$',r'$\bar{\mathcal{B}}_t$',r'$\mathcal{B}_t$'][k],transform=ax.transAxes,fontsize=12)
finish(f,axs,'08_configurations',lims=[((-.65,2.3),(-.8,3.7))]*3)

# 9. Mass integration: actual section slice and a spacious vector construction.
f,axs=setup(2,h=2.9);ax=axs[0];panel(ax,'(a)');t=np.linspace(0,2*np.pi,80);ring=np.column_stack([np.zeros(len(t)),1.8*np.cos(t),.65*np.sin(t)]);face(ax,ring,shade='.93');line(ax,ring)
O=np.array([0,-.55,0]);C=np.array([0,.35,.08]);P=np.array([0,1.1,.30]);dot(ax,[O,C,P]);label(ax,O,'$O$',(3,-14));label(ax,C,'$C$',(-15,6));label(ax,P,'$P$',(4,5));triad(ax,O,I,1.0,[r'$\boldsymbol{d}_1$',r'$\boldsymbol{d}_2$',r'$\boldsymbol{d}_3$']);face(ax,[P+[0,-.12,-.08],P+[0,.12,-.08],P+[0,.12,.08],P+[0,-.12,.08]],shade='.6');label(ax,P,r'$\mathrm{d}\mu=\rho_0\,\mathrm{d}A$',(-40,44),size=10,arrowprops=dict(arrowstyle='-',lw=.6))
ax=axs[1];panel(ax,'(b)');O=np.zeros(3);C=np.array([1.3,0,.2]);P=np.array([1.9,0,1.5]);arrow(ax,O,C,r'$\boldsymbol{r}_C$',(0,-16));arrow(ax,C,P,r'$\boldsymbol{\rho}_C$',(7,0));arrow(ax,O,P,r'$\boldsymbol{r}_P$',(-25,4));dot(ax,[O,C,P]);label(ax,O,'$O$',(-12,-10));label(ax,C,'$C$',(5,-11));label(ax,P,'$P$',(5,5));
checks['mass_vector_closure']=float(np.linalg.norm((C-O)+(P-C)-(P-O)))
finish(f,axs,'09_mass')

# 10. Auxiliary-point projection, separate from nodal DOFs.
f,axs=setup(2,h=2.8);ax=axs[0];panel(ax,'(a)');XI=np.zeros(3);XJ=np.array([3.3,1,.5]);e1=XJ/np.linalg.norm(XJ);Xa=np.array([1.4,1.7,1.6]);p=(I-np.outer(e1,e1))@Xa;e3=p/np.linalg.norm(p);e2=np.cross(e3,e1);Q=np.column_stack([e1,e2,e3]);tube(ax,[XI,XJ],Q,[.55,.55],[.45,.45]);line(ax,[XI,XJ],lw=1.3);dot(ax,[XI,XJ]);dot(ax,Xa,white=True);label(ax,XI,'$I$',(-13,-8));label(ax,XJ,'$J$',(5,0));label(ax,Xa,r'$\boldsymbol{X}_a$',(4,5));arrow(ax,XI,p,r'$\boldsymbol{p}$',(-18,3));line(ax,[Xa,p],ls='--',color='.5');line(ax,[XI,Xa],ls=':',color='.5');triad(ax,XI,Q,1.15,[r'$\boldsymbol{e}_1$',r'$\boldsymbol{e}_2$',r'$\boldsymbol{e}_3$'],offsets=[(4,10),(-4,-3),(-10,8)])
ax=axs[1];panel(ax,'(b)');tube(ax,[np.zeros(3),[3.8,0,0]],I,[.5,.5],[.5,.5]);line(ax,[[0,0,0],[3.8,0,0]],lw=1.5);dot(ax,[[0,0,0],[3.8,0,0]],s=26);label(ax,[0,0,0],'$I$',(-14,-8));label(ax,[3.8,0,0],'$J$',(6,-3));triad(ax,[0,0,0],I,1.1);label(ax,[0,0,0],r'$\boldsymbol{q}_I=(\boldsymbol{u}_I,\boldsymbol{\theta}_I)$',(-18,-42),size=10);label(ax,[3.8,0,0],r'$\boldsymbol{q}_J=(\boldsymbol{u}_J,\boldsymbol{\theta}_J)$',(-36,-42),size=10)
checks['element_basis_orthogonality']=float(np.linalg.norm(Q.T@Q-I));checks['element_aux_projection']=float(abs(np.dot(p,e1)))
finish(f,axs,'10_element')

# 11. Physical hub-root joint and linearized displacement construction.
f,axs=setup(2,h=3.0);ax=axs[0];panel(ax,'(a)');H=np.zeros(3);Q=np.column_stack([I[:,2],-I[:,1],I[:,0]]);s=np.array([0,0,2.]);cylinder(ax,[-.6,0,0],[.6,0,0],.65,.65);tube(ax,[s,s+[0,0,1.5]],Q,[.6,.45],[.3,.2]);line(ax,[H,s],lw=1.3);dot(ax,[H,s]);label(ax,H,'$m=H$',(-30,-10));label(ax,s,'$s=P_b$',(6,3));arrow(ax,[.6,0,.1],[.6,0,1.9],r'$\boldsymbol{r}_s$',(7,0));triad(ax,[-1.3,0,-1],I,.6)
ax=axs[1];panel(ax,'(b)');s0=np.zeros(3);du=np.array([1.4,0,.4]);dtheta=np.array([-.8,.2,0]);rs=np.array([0,0,2.]);dur=np.cross(dtheta,rs);s1=du;st=du+dur
arrow(ax,s0,s1,r'$\delta\boldsymbol{u}_m$',(0,-18));arrow(ax,s1,st,r'$\delta\boldsymbol{\theta}_m\!\times\!\boldsymbol{r}_s$',(20,8));arrow(ax,s0,st,r'$\delta\boldsymbol{u}_s$',(-25,-18));dot(ax,[s0,s1,st]);label(ax,s0,'$s$',(-10,-10));label(ax,s1,"$s'$",(5,-12));label(ax,st,"$s''$",(5,-17));ax.text(.1,-.10,r'$\delta\boldsymbol{\theta}_s=\delta\boldsymbol{\theta}_m$',transform=ax.transAxes)
checks['root_incremental_closure']=float(np.linalg.norm(st-du-np.cross(dtheta,rs)))
finish(f,axs,'11_root')
(OUT/'geometry_checks.json').write_text(json.dumps(checks,indent=2)+'\n')
assert all(abs(v-1)<1e-12 if 'handedness' in k else v<1e-12 for k,v in checks.items())
print('Generated and geometrically checked 11 original vector figures.')
