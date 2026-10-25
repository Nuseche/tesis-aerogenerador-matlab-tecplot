"""Finite contrasts on the complete physical-factor grid, without probabilities."""
from pathlib import Path
import csv, hashlib, itertools, json, math
import numpy as np

ROOT = Path('/Users/nuseche/Desktop/Tesis_codigos')
DOCS = ROOT/'docs/sensibilidad_complementaria_20261014'
RUNS = ROOT/'runs/sensitivity/grid_completion_20261014'
OLD = ROOT/'runs/sensitivity/morris_20261006'
META = json.loads((ROOT/'docs/sensibilidad_morris_20261006/report_data.json').read_text())

def rows(path):
    with path.open(newline='') as f: return list(csv.DictReader(f))

def write(name, items):
    with (DOCS/name).open('w',newline='') as f:
        w=csv.DictWriter(f,fieldnames=list(items[0]));w.writeheader();w.writerows(items)

def sha(path):
    h=hashlib.sha256()
    with path.open('rb') as f:
        for b in iter(lambda:f.read(1048576),b''):h.update(b)
    return h.hexdigest()

def truth(x): return x in ['1','true','True']

grid=rows(RUNS/'grid_responses.csv');noise=rows(RUNS/'grid_noise.csv')
levels=np.linspace(.90,1.10,4);step=levels[1]-levels[0]
groups=[r['group'] for r in META['groups']]
names=['blade_density','blade_stiffness','rotor_speed']
nominal={r['group']:r['nominalFrequencyHz'] for r in META['groups']}
# Analytical benchmarks for the finite-contrast operators used below.
x,y,z=np.meshgrid(levels,levels,levels,indexing='ij')
def rectangle(a,i,j,level):
    other=next(k for k in range(3) if k not in [i,j]);ix=[0,0,0];ix[other]=level
    a00=a[tuple(ix)];ix[i]=3;a10=a[tuple(ix)];ix[j]=3;a11=a[tuple(ix)];ix[i]=0;a01=a[tuple(ix)]
    return a11-a10-a01+a00
for i,j in itertools.combinations(range(3),2):
    assert all(abs(rectangle(x**2+3*y**2+5*z**2,i,j,c))<1e-12 for c in range(4))
for c in range(4):assert abs(rectangle(x*y,0,1,c)-.04)<1e-12
assert np.allclose(np.diff(x**2,n=2,axis=0),2*(levels[1]-levels[0])**2,atol=1e-12)
points={};accepted={};etas={r['group']:float(r['empiricalNoiseHz']) for r in noise}
for g in groups:
    a=np.full((4,4,4),np.nan);v=np.zeros((4,4,4),bool)
    for r in grid:
        if r['group']!=g:continue
        ix=tuple(int(r[k])-1 for k in ['rhoLevel','stiffnessLevel','speedLevel'])
        assert math.isnan(a[ix]),'Duplicate grid response'
        a[ix]=float(r['frequencyHz']);v[ix]=truth(r['trackingValid'])
    assert np.isfinite(a).all()
    points[g]=a;accepted[g]=v

adjacent=[];endpoint=[];mixed=[];curvature=[];ranges=[];compensation=[]
for g in groups:
    y=points[g];good=accepted[g];eta=etas[g];closed=bool(good.all())
    ranges.append(dict(group=g,nominalFrequencyHz=nominal[g],minimumHz=float(y.min()) if closed else None,
                       maximumHz=float(y.max()) if closed else None,allGridVerticesValid=closed))
    if not closed:continue
    for axis,name in enumerate(names):
        delta=np.diff(y,axis=axis);slopes=delta/(step*nominal[g])
        ratio=np.abs(delta)/(2*eta)
        adjacent.append(dict(group=g,parameter=name,comparisons=int(delta.size),positive=int((delta>0).sum()),
                             negative=int((delta<0).sum()),zero=int((delta==0).sum()),
                             resolvedComparisons=int((ratio>=10).sum()),minimumSlope=float(slopes.min()),
                             maximumSlope=float(slopes.max()),minimumSignalToNoise=float(ratio.min())))
        wide=np.take(y,3,axis=axis)-np.take(y,0,axis=axis)
        endpoint.append(dict(group=g,parameter=name,comparisons=int(wide.size),meanNormalizedSlope=float(wide.mean()/(.20*nominal[g])),
                             meanAbsoluteNormalizedSlope=float(np.abs(wide).mean()/(.20*nominal[g])),
                             meanSignalToNoise=float(np.abs(wide).mean()/(2*eta)),
                             resolvedComparisons=int((np.abs(wide)/(2*eta)>=10).sum()),
                             meanEffectResolved=bool(np.abs(wide).mean()>=20*eta)))
        for ix in itertools.product(range(4),repeat=3):
            if ix[axis] not in [1,2]:continue
            lower=list(ix);upper=list(ix);lower[axis]-=1;upper[axis]+=1
            val=float(y[tuple(upper)]-2*y[ix]+y[tuple(lower)])
            curvature.append(dict(group=g,parameter=name,rhoLevel=ix[0]+1,stiffnessLevel=ix[1]+1,speedLevel=ix[2]+1,
                                  contrastHz=val,contrastRelativePercent=100*val/nominal[g],
                                  empiricalNoiseBoundHz=4*eta,signalToNoise=abs(val)/(4*eta),resolved=abs(val)>=40*eta))
    for axis_i,axis_j in itertools.combinations(range(3),2):
        other=next(a for a in range(3) if a not in [axis_i,axis_j])
        for lev in range(4):
            ix=[0,0,0];ix[other]=lev
            i00=tuple(ix);ix[axis_i]=3;i10=tuple(ix);ix[axis_j]=3;i11=tuple(ix);ix[axis_i]=0;i01=tuple(ix)
            val=float(y[i11]-y[i10]-y[i01]+y[i00])
            mixed.append(dict(group=g,parameter1=names[axis_i],parameter2=names[axis_j],fixedParameter=names[other],
                              fixedFactor=float(levels[lev]),contrastHz=val,contrastRelativePercent=100*val/nominal[g],
                              empiricalNoiseBoundHz=4*eta,signalToNoise=abs(val)/(4*eta),resolved=abs(val)>=40*eta))
    for c in range(4):
        vals=[float(y[a,a,c]) for a in range(4)]
        compensation.append(dict(group=g,rotorSpeedRPM=float(12*levels[c]),
                                  lowEqualFactorFrequencyHz=vals[0],highEqualFactorFrequencyHz=vals[-1],
                                  diagonalSpreadHz=max(vals)-min(vals),diagonalSpreadRelativePercent=100*(max(vals)-min(vals))/nominal[g]))

for name,items in [('adjacent_trends.csv',adjacent),('endpoint_slopes.csv',endpoint),('mixed_contrasts.csv',mixed),
                   ('pure_curvature.csv',curvature),('grid_ranges.csv',ranges),('equal_factor_compensation.csv',compensation)]:write(name,items)
status=rows(RUNS/'case_status.csv');assert len(status)==9 and all(r['status']=='success' for r in status)
source_rows=rows(OLD/'source_hashes.csv')
for r in source_rows:assert sha(ROOT/r['paths'])==r['hashes'],r['paths']
res=rows(RUNS/'grid_residuals.csv');root_values=rows(RUNS/'grid_roots.csv')
keys=['equilibriumResidual','dualMassResidual','rightQEPResidual','leftQEPResidual']
check={k:max(float(r[k]) for r in res) for k in keys}
assert check['equilibriumResidual']<=1e-8 and check['dualMassResidual']<=1e-8
assert all(not truth(r['groupExpanded']) for r in noise)
assert all(truth(r['controlsValid']) for r in noise if r['group']!='12')

summary=dict(date='2026-10-14',purpose='Complementary deterministic grid verification and finite interaction contrasts',
             reusedDistinctPoints=58,newGridPoints=6,newControls=3,newEvaluations=9,gridPoints=64,
             oldMorrisTrajectories=40,oldMorrisEvaluations=170,solverSeconds=sum(float(r['seconds']) for r in status),
             sourceHashesUnchanged=len(source_rows),historicalGroupsPreserved=True,excludedGroup='12',
             physicalRangesUnchanged=True,physicalInputProbabilityMeasureDefined=False,
             noiseInterpretation='Empirical envelope extended with controls at a newly evaluated grid point. Not a rigorous domain error bound.',
             contrastDefinitions={'mixed':'f(high_i,high_j)-f(high_i,low_j)-f(low_i,high_j)+f(low_i,low_j), with third factor fixed',
                                  'curvature':'f(next)-2*f(center)+f(previous), at equally spaced grid points',
                                  'resolutionRule':'absolute contrast >= 10 times propagated empirical bound; four terms contribute 4 eta'},
             maxResiduals=check,maximumGrowthAllReturnedRoots=max(float(r['growthPerSecond']) for r in root_values),
             frequencyRanges=ranges,adjacentTrends=adjacent,endpointSlopes=endpoint,mixedContrasts=mixed,
             compensation=[r for r in compensation if r['group']=='10+11'],noise=noise,
             originalMorrisAcceptedMean=sum(r['acceptedMean'] for r in META['statistics'] if r['response']=='frequency'),
             originalMorrisAcceptedDispersion=sum(r['acceptedDispersion'] for r in META['statistics'] if r['response']=='frequency'),
             analyticalChecks={'additiveQuadraticsGiveZeroMixedContrast':True,'productXYGivesCorrectMixedContrast':True,'quadraticCurvatureGivesTwoStepSquared':True})
(DOCS/'analysis_summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2,allow_nan=False)+'\n')
print(json.dumps({k:summary[k] for k in ['gridPoints','newEvaluations','solverSeconds','sourceHashesUnchanged','maxResiduals']},indent=2))
for r in mixed:
    if r['group']=='10+11': print(r['parameter1'],r['parameter2'],r['fixedFactor'],round(r['contrastHz'],6),round(r['signalToNoise'],2),r['resolved'])
