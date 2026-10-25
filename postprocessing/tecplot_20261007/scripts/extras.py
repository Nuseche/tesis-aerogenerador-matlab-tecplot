from common import *
from science import HIST,MORRIS,result

def build():
    figs=[];r=readcsv(HIST/'cantilever_references.csv');c=readcsv(HIST/'cantilever_comparison.csv')
    f=result('teoria_diferencia','Efecto de la teoria de viga',[HIST/'cantilever_references.csv'],'Modo','Diferencia relativa [%]',legend=True)
    for i,sl in enumerate(['10','100']):f.line([[float(x['mode']),float(x['theoryDifferencePercent'])] for x in r if x['slenderness']==sl],'L/h = '+sl,i,symbols=True)
    figs.append(f)
    f=result('teoria_convergencia','Convergencia del cuarto modo',[HIST/'cantilever_comparison.csv'],'Elementos','Error relativo [%]',logx=False,logy=True)
    for i,sl in enumerate(['10','100']):
        for j,theory in enumerate(['Timoshenko','EulerBernoulli']):
            data=[[float(x['elements']),float(x['frequencyErrorPercent'])] for x in c if x['slenderness']==sl and x['theory']==theory and x['mode']=='4' and float(x['frequencyErrorPercent'])>0]
            if data:f.line(data,('T ' if j==0 else 'EB ')+sl,i,'SOLID' if j==0 else 'DASHED',symbols=True)
    figs.append(f)
    f=result('rom_aceleracion','Eficiencia del ROM',[HIST/'global_costs.csv'],'Orden ROM','Aceleracion [-]',logx=False)
    rr=[x for x in readcsv(HIST/'global_costs.csv') if x['model']!='MHT_full']
    for i,k in enumerate(['speedupIntegration','speedupOneCaseIncludingBasis']):f.line([[float(x['dofs']),float(x[k])] for x in rr],['Integracion','Caso completo'][i],i,symbols=True)
    figs.append(f)
    r=readcsv(MORRIS/'morris_vertices.csv');r=sorted([x for x in r if x['trajectory']=='1'],key=lambda x:int(x['vertex']))
    f=result('morris_trayectoria_factores','Primera trayectoria',[MORRIS/'morris_vertices.csv'],'Vertice','Factor relativo [-]',bounds=[-.1,3.1,.88,1.12])
    for i,k in enumerate(['factor_1','factor_2','factor_3']):f.line([[float(x['vertex']),float(x[k])] for x in r],['Masa/inercia','Rigidez','Velocidad'][i],[0,2,1][i],['SOLID','DASHED','DOTTED'][i],symbols=True)
    f.document=['SECCION_MORRIS_REVISION.tex'];figs.append(f)
    return figs
