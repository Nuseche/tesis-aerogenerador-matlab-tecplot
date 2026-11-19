"""Plot independent tower histories and the within-SIMPACT transfer diagnostic."""
from pathlib import Path
import sys
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
from analyze_case00_decay import channel

out = Path(__file__).resolve().parents[1] / "runs" / "case00_decay"
t, x = channel(Path(sys.argv[1]), "p11", 400019, 1)
linear = np.genfromtxt(out/"linear_replay.csv", delimiter=",", names=True, usecols=("t","towerX"))
cycles = np.genfromtxt(out/"case00_decay_windows.csv", delimiter=",", names=True)
cycles = cycles[(cycles["crossing_sign"]==1)&(cycles["cycles"]==1)]
fig, ax = plt.subplots(2,1,figsize=(7.8,5.8),layout="constrained")
i=(t>=20)&(t<=80)
j=(linear["t"]>=20)&(linear["t"]<=80)
ax[0].plot(t[i],x[i],color="black",lw=1.2,label="SIMPACT, caso 00")
ax[0].plot(linear["t"][j],linear["towerX"][j],color="0.4",ls="--",lw=1.2,label="Modelo lineal, Rayleigh")
ax[0].axvspan(20,21,color="0.83",label="Pulso en la góndola")
ax[0].set(xlim=(20,80),xlabel="Tiempo (s)",ylabel="Desplazamiento X de la cima (m)")
ax[0].legend(frameon=False,ncol=3,loc="upper center",bbox_to_anchor=(.5,1.23),fontsize=9)
a=cycles["x_fundamental_m"]
err=cycles["transfer_change_percent"]
for k,label,marker in [(cycles["t1_s"]<800,"Antes del ajuste","."),((cycles["t0_s"]>=800)&(cycles["t1_s"]<=950),"Ajuste tardío","x"),(cycles["t0_s"]>=950,"Verificación tardía","+")]:
    ax[1].scatter(a[k],err[k],s=19,marker=marker,color="0.2",label=label)
ax[1].axhline(5,ls="--",lw=1,color="0.45",label="Criterio del 5 %")
ax[1].set(yscale="log",ylim=(.002,8),xlabel="Amplitud fundamental de X por ciclo en SIMPACT (m)",ylabel="Variación de C5/X (%)")
ax[1].legend(frameon=False,ncol=2,loc="upper center",bbox_to_anchor=(.5,.85),fontsize=8)
fig.savefig(out/"case00_comparison.png",dpi=180)
