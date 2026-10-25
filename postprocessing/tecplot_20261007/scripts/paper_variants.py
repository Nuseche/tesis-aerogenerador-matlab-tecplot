"""Native Tecplot diagrams aligned with the formulation article's notation."""
from spatial import Scene, v, var, sub, E, greek
from common import *


def build(catalog):
    horizontal=np.array([-2**-.5,2**-.5,0])
    vertical=np.array([-np.cos(np.deg2rad(65))*2**-.5,-np.cos(np.deg2rad(65))*2**-.5,np.sin(np.deg2rad(65))])
    normal=np.cross(horizontal,vertical)
    mass=Scene('paper_masa_seccional','Geometría de la masa y la inercia seccionales',height=4.8)
    origin=np.zeros(3);center=np.array([0,1.12,.42]);particle=np.array([0,.30,1.26])
    mass.plane(origin,half=(1.65,1.50),grey=7)
    mass.basis(origin,L=2.1,labels=[v('d',i) for i in [1,2,3]],grey=4)
    mass.arrow(origin,center,grey=1).arrow(origin,particle).arrow(center,particle)
    mass.dot(origin,.035).dot(center,.045)
    mass.box(particle,half=(.035,.07,.07),grey=1)
    mass.label(origin-.29*vertical,var('O'))
    mass.label(center+.30*horizontal-.16*vertical,var('C'))
    mass.label(particle+.28*vertical,'d'+greek('m'))
    mass.label(center/2+.19*vertical,v('r','C'))
    mass.label(particle/2-.30*horizontal,v('r','P'))
    mass.label((center+particle)/2+.35*horizontal,'<b>'+greek('r')+'</b>'+sub('C'))
    mass.config.update(section_plane_error=float(max(abs(center[0]),abs(particle[0]))),position_closure_error=float(np.linalg.norm(center+(particle-center)-particle)))

    link=Scene('paper_vinculo_raiz','Compatibilidad incremental en la unión raíz–cubo',height=4.3)
    points=np.array([np.zeros(3),2.5*horizontal+.2*vertical+.1*normal,4*horizontal+2.5*vertical+.3*normal])
    for j in range(2):link.arrow(points[j],points[j+1])
    link.arrow(points[0],points[2],thickness=.28)
    link.dot(points[0],.035)
    link.label((points[0]+points[1])/2-.37*vertical,greek('d')+v('u','m'))
    link.label((points[1]+points[2])/2+.65*horizontal,greek('d')+v('u','rot'))
    link.label((points[0]+points[2])/2-.50*horizontal+.26*vertical,greek('d')+v('u','s'))
    link.basis(-1.2*horizontal-1.0*vertical+.6*normal,L=.65,labels=[E(i) for i in [1,2,3]],grey=4)
    link.config['head_to_tail_closure_error']=float(np.linalg.norm(np.diff(points,axis=0).sum(0)-(points[-1]-points[0])))
    out=[]
    for scene in [mass,link]:
        row=scene.export();row['sources']=[str(Path(__file__).resolve())]
        row['documents']=['FCEFyN_ES.tex','FCEFyN_EN.tex'];row['installed_in']=[];out.append(row)
    return out


if __name__=='__main__':
    cat=json.loads((HERE/'catalog.json').read_text());cat=[r for r in cat if not r['id'].startswith('paper_')]
    dump(HERE/'catalog.json',cat+build(cat))
