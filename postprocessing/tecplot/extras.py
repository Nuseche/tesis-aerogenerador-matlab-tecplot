from common import *
from science import HIST,MORRIS,result

def build():
    figs=[];r=readcsv(HIST/'cantilever_references.csv');c=readcsv(HIST/'cantilever_comparison.csv')
    f=result('theory_difference','Effect of beam theory',[HIST/'cantilever_references.csv'],'Mode','Relative difference [%]',legend=True)
    for i,sl in enumerate(['10','100']):f.line([[float(x['mode']),float(x['theoryDifferencePercent'])] for x in r if x['slenderness']==sl],'L/h = '+sl,i,symbols=True)
    figs.append(f)
    f=result('theory_convergence','Fourth-mode convergence',[HIST/'cantilever_comparison.csv'],'Elements','Relative error [%]',logx=False,logy=True)
    for i,sl in enumerate(['10','100']):
        for j,theory in enumerate(['Timoshenko','EulerBernoulli']):
            data=[[float(x['elements']),float(x['frequencyErrorPercent'])] for x in c if x['slenderness']==sl and x['theory']==theory and x['mode']=='4' and float(x['frequencyErrorPercent'])>0]
            if data:f.line(data,('T ' if j==0 else 'EB ')+sl,i,'SOLID' if j==0 else 'DASHED',symbols=True)
    figs.append(f)
    f=result('rom_speedup','ROM efficiency',[HIST/'global_costs.csv'],'ROM order','Speedup [-]',logx=False)
    rr=[x for x in readcsv(HIST/'global_costs.csv') if x['model']!='MHT_full']
    for i,k in enumerate(['speedupIntegration','speedupOneCaseIncludingBasis']):f.line([[float(x['dofs']),float(x[k])] for x in rr],['Integration','Whole case'][i],i,symbols=True)
    figs.append(f)
    r=readcsv(MORRIS/'morris_vertices.csv');r=sorted([x for x in r if x['trajectory']=='1'],key=lambda x:int(x['vertex']))
    f=result('morris_trajectory_factors','First trajectory',[MORRIS/'morris_vertices.csv'],'Vertex','Relative factor [-]',bounds=[-.1,3.1,.88,1.12])
    for i,k in enumerate(['factor_1','factor_2','factor_3']):f.line([[float(x['vertex']),float(x[k])] for x in r],['Mass/inertia','Stiffness','Speed'][i],[0,2,1][i],['SOLID','DASHED','DOTTED'][i],symbols=True)
    f.document=['studies/README.md'];figs.append(f)
    return figs
