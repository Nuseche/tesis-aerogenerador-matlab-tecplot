"""Case 00: hold out entire tower oscillations and predict the raw INTERNAL channel.
Run with the original case directory as the only argument. No filtering or lag fitting.
"""
import csv
import sys
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
from audit_nonlinear_reference import read_history

OUT = Path(__file__).resolve().parents[1] / "runs" / "case00_decay"


def signal(folder, kind, node, component):
    blocks = []
    for stage in range(1, 6):
        nodes, t, values = read_history(folder / f"snl.@{stage}.{kind}")
        blocks.append(np.column_stack((t, values[:, list(nodes).index(node), component])))
    return np.concatenate(blocks)


def main(folder):
    OUT.mkdir(exist_ok=True, parents=True)
    t, x = signal(folder, "p11", 400019, 0).T
    tv, v = signal(folder, "p19", 400019, 0).T
    tc, c = signal(folder, "p12", 400000, 4).T
    assert np.array_equal(t, tv) and np.array_equal(t, tc)
    train = (t >= 900) & (t < 1000)
    design = np.column_stack((np.ones_like(x), x, v))
    coeff = np.linalg.lstsq(design[train], c[train], rcond=None)[0]
    predicted = design @ coeff
    # From the first positive-going crossing after force removal to the last
    # complete cycle. Reject extra crossings instead of stitching partial cycles.
    cross = 1 + np.flatnonzero((x[:-1] <= 0) & (x[1:] > 0) & (t[:-1] > 21))
    rows = []
    for i, j in zip(cross[:-1], cross[1:]):
        if not 4 < t[j] - t[i] < 8:
            continue
        amp = np.ptp(x[i:j]) / 2
        err = 100*np.linalg.norm(c[i:j]-predicted[i:j])/np.linalg.norm(c[i:j])
        rows.append((t[i], t[j], amp, err))
    with (OUT/"waveform_cycles.csv").open("w",newline="") as f:
        w=csv.writer(f)
        w.writerow(["start_s","end_s","half_range_tower_x_m","raw_C5_prediction_error_pct"])
        w.writerows(rows)
    a=np.array(rows)
    print("coefficients [offset, X, Xdot]",coeff)
    for lo,hi in ((21,900),(900,1000),(1000,1100)):
        keep=(a[:,0]>=lo)&(a[:,1]<=hi)
        print(lo,hi,"cycles",keep.sum(),"amplitudes", a[keep,2].min(),a[keep,2].max(),
              "percent median/max",np.median(a[keep,3]),a[keep,3].max())
    fig,axes=plt.subplots(2,1,figsize=(7.4,5.7),layout="constrained")
    axes[0].plot(t[::5],x[::5],color="0.25",lw=.48)
    axes[0].axvspan(900,1000,color="0.83",label="Ajuste de referencia",zorder=-1)
    axes[0].set(xlim=(20,1100),ylabel="Desplazamiento X (m)",xlabel="Tiempo (s)")
    axes[0].legend(loc="upper right",frameon=False)
    for mask,marker,label in [(a[:,1]<=900,".","Ciclos anteriores"),((a[:,0]>=1000),"s","Verificación tardía")]:
        axes[1].scatter(a[mask,2],a[mask,3],s=13,marker=marker,c="0.22",label=label)
    axes[1].axhline(5,color="0.35",ls="--",lw=.8,label="Criterio del 5 %")
    axes[1].set(xlabel="Semiamplitud de X en la cima (m)",ylabel="Error relativo en C5 (%)",ylim=(0,None))
    axes[1].legend(frameon=False,loc="upper left",fontsize=8)
    fig.savefig(OUT/"waveform_check.png",dpi=180)
    plt.close(fig)


if __name__=="__main__":
    main(Path(sys.argv[1]))
