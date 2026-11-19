"""Print the signed 3P moment over one excitation cycle from archived phasors."""
import csv
from io import TextIOWrapper
from pathlib import Path
from zipfile import ZipFile

ARCHIVE = Path(__file__).resolve().parents[1] / "data/reference/structural-load-campaigns-20261118.zip"


def render():
    with ZipFile(ARCHIVE) as data, data.open("periodic_loads_20261118/rotating_mesh_sweep.csv") as member:
        source = TextIOWrapper(member, encoding="utf-8", newline="")
        row, = (r for r in csv.DictReader(source)
                if (int(r["elements"]), float(r["rpm"]), int(r["channel"])) == (266, 3.4445, 4))
    print(r"""\begin{figure}[htbp]\centering
\begin{tikzpicture}
\begin{axis}[width=.81\textwidth,height=5.5cm,xmin=0,xmax=120,ymin=-5.5,ymax=5.5,
xtick={0,30,60,90,120},ytick={-4,-2,0,2,4},
xlabel={Rotor azimuth $\psi$ (deg)},ylabel={3P base moment per unit force (kN\,m/N)},
legend columns=2,legend style={at={(0.5,1.04)},anchor=south,column sep=1em}]
\addplot[gray,thin,forget plot] coordinates {(0,0) (120,0)};""")
    for prefix, label, style in (("periodic", "Periodic", "solid"), ("average", "Averaged", "dashed")):
        amplitude = float(row[prefix + "Abs"]) / 1000
        phase = float(row[prefix + "Phase"])
        print(r"\addplot[black,thick," + style + r",domain=0:120,samples=121] "
              + f"{{{amplitude:.10g}*cos(3*x+{phase:.10g})}};")
        print(r"\addlegendentry{" + label + "}")
    print(r"""\end{axis}\end{tikzpicture}
\caption{Signed 3P component of the tower-base bending moment at 3.4445 rpm on the 266-element mesh. The unit axial force reaches its positive maximum at zero azimuth. One force cycle occupies $120^\circ$ of rotor rotation.}
\label{fig:moment-phase-history}\end{figure}""")


if __name__ == "__main__":
    render()
