"""Compare the stationary reference pulse replay with case 00 on common times."""
from pathlib import Path
import argparse
import csv
import numpy as np
from scipy.optimize import minimize_scalar
from audit_nonlinear_reference import read_history


def source_signal(folder, kind, node, channel):
    parts=[]
    for stage in range(1,6):
        ids,t,q=read_history(folder/f'snl.@{stage}.{kind}')
        parts.append(np.column_stack((t,q[:,list(ids).index(node),channel])))
    return np.vstack(parts)


def dominant_transfer(t,x,m):
    # Windowed sinusoidal component at the strongest tower-X frequency.
    elapsed=t-t[0]
    w=np.hanning(len(t))
    vector=w*(x-np.average(x,weights=w))
    def component(freq):
        return np.exp(-2j*np.pi*freq*elapsed)
    # Optimizer may settle on a weak sidelobe in long windows: bracket by grid first.
    grid=np.linspace(.157,.179,89)
    peak=grid[np.argmax([abs(vector@component(f)) for f in grid])]
    step=grid[1]-grid[0]
    result=minimize_scalar(lambda f:-abs(vector@component(f)),bounds=(peak-step,peak+step),method="bounded")
    h=component(result.x)
    gain=((w*(m-np.average(m,weights=w)))@h)/(vector@h)
    return result.x,abs(gain),np.angle(gain,deg=True)


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("source",type=Path)
    args=p.parse_args()
    out=Path(__file__).resolve().parents[1]/'runs/case00_decay'
    linear=np.genfromtxt(out/'linear_replay.csv',delimiter=',',names=True)
    t=linear['t'];u=source_signal(args.source,'p11',400019,0)
    b=source_signal(args.source,'p12',400000,4)
    x=np.interp(t,u[:,0],u[:,1]);m=-np.interp(t,b[:,0],b[:,1])
    rows=[]
    for lo,hi in ((20,25),(21,1100),(25,125),(100,200),(200,300),(600,800),(900,1100)):
        i=(t>=lo)&(t<hi)
        xl=linear['towerX'][i];ml=linear['baseMy'][i]
        metrics=[lo,hi,max(abs(xl)),max(abs(x[i])),max(abs(ml)),max(abs(m[i])),
                 100*np.linalg.norm(xl-x[i])/np.linalg.norm(x[i]),
                 100*np.linalg.norm(ml-m[i])/np.linalg.norm(m[i])]
        if hi-lo>=90:
            metrics.extend(dominant_transfer(t[i],xl,ml))
            metrics.extend(dominant_transfer(t[i],x[i],m[i]))
        rows.append(metrics)
    with (out/'linear_comparison.csv').open('w') as f:
        w=csv.writer(f);w.writerow('start,end,maxXLinear,maxXSimpact,maxMyLinear,maxMySimpact,xErrorPct,myErrorPct,frequencyLinearHz,gainLinearNmPerM,phaseLinearDeg,frequencySimpactHz,gainSimpactNmPerM,phaseSimpactDeg'.split(','));w.writerows(rows)
    print('reference frame and transposed peak; measured orientation peak',*[max(abs(linear[v])) for v in ('towerXnominal','towerXtranspose','towerX')])
    print('strongest moment orientation change effect on X',max(abs(linear['towerX']-linear['towerXnominal'])))
if __name__=='__main__':
    main()
