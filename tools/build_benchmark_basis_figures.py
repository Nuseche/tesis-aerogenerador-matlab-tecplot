"""Emit the self-contained benchmark or periodic basis figure for the manuscript."""
import argparse
import csv
from io import TextIOWrapper
from pathlib import Path
from zipfile import ZipFile

ARCHIVES = Path(__file__).resolve().parents[1] / "data/reference"


def read_table(archive, table):
    with ZipFile(ARCHIVES / archive) as data, data.open(table) as member:
        return list(csv.DictReader(TextIOWrapper(member, encoding="utf-8", newline="")))


def points(style, data):
    coords = " ".join(f"({x:g},{y:.8g})" for x, y in data)
    print(r"\addplot[" + style + "] coordinates {" + coords + "};")


def benchmark():
    frequencies = read_table("rotating-operator-checks.zip", "chung_yoo_20261119/frequencies.csv")
    rows = [r for r in frequencies if r["elements"] == "160" and float(r["hubRadiusOverLength"]) == 0]
    print(r"""\begin{figure}[tbp]\centering
\begin{tikzpicture}
\pgfplotsset{beam benchmark/.style={width=.475\textwidth,height=5.3cm,
xlabel={Spin speed $\gamma$},every axis title/.append style={at={(0.02,1.05)},anchor=south west,font=\small},
ymajorgrids=true,xmajorgrids=false}}
\begin{axis}[beam benchmark,name=flap,ylabel={Natural frequency $\omega t_b$},
title={(a) Out-of-plane bending},xmin=-.3,xmax=10.3,xtick={0,2,4,6,8,10},ymin=0,ymax=38,ytick={0,10,20,30}]""")
    for mode in ("1", "2"):
        branch = sorted((r for r in rows if r["plane"] == "flap" and r["mode"] == mode), key=lambda r: float(r["gamma"]))
        for key, style in [("calculated", "black,thick"), ("published", "only marks,mark=o,mark size=1.7pt,black")]:
            points(style, [(float(r["gamma"]), float(r[key])) for r in branch])
    print(r"""\end{axis}
\begin{axis}[beam benchmark,at={(flap.east)},anchor=west,xshift=0.93cm,
title={(b) In-plane bending},xmin=0,xmax=53,xtick={2,10,30,50},ymin=3,ymax=11.5,ytick={4,6,8,10},
legend columns=3,legend style={at={(-.08,-.30)},anchor=north,draw=none,inner sep=1.5pt,font=\footnotesize,column sep=.6em,cells={anchor=west}}]""")
    branch = sorted((r for r in rows if r["plane"] == "chord" and r["mode"] == "1"), key=lambda r: float(r["gamma"]))
    for key, style, label in [
        ("calculated", "black,thick", "Full model"),
        ("published", "only marks,mark=o,mark size=1.7pt,black", "Chung and Yoo"),
        ("frequencyWithoutGyro", "black,thick,dashed,mark=triangle,mark size=1.9pt", "Gyroscopic term omitted"),
    ]:
        points(style, [(float(r["gamma"]), float(r[key])) for r in branch])
        print(r"\addlegendentry{" + label + "}")
    print(r"""\end{axis}
\end{tikzpicture}
\caption{Rotating cantilever with zero hub radius and slenderness 70. Circles give the published frequencies \cite{chung2002}; solid lines join the 160-element predictions at those speeds. Panel (a) shows the first two bending frequencies. Panel (b) shows the lowest in-plane frequency with and without gyroscopic coupling.}
\label{fig:rotating-beam-frequencies}\end{figure}""")


def basis():
    snapshots = read_table("periodic-correction.zip", "correction_snapshot_basis.csv")
    rows = sorted((r for r in snapshots if r["training"] == "0"), key=lambda r: float(r["rpm"]))
    indices = ",".join(str(i) for i in range(1, len(rows) + 1))
    speeds = ",".join(r["rpm"] for r in rows)
    print(r"""\begin{figure}[tbp]\centering
\begin{tikzpicture}
\begin{semilogyaxis}[width=.89\textwidth,height=5.8cm,
xlabel={Test speed (rpm)},ylabel={Relative history error (\%)},
xmin=.6,xmax=9.4,ymin=.01,ymax=100,ytick={.01,.1,1,10,100},yticklabels={0.01,0.1,1,10,100},
ymajorgrids=true,xmajorgrids=false,minor y tick num=0,legend columns=2,
legend style={at={(.5,1.03)},anchor=south,font=\footnotesize,draw=none,column sep=.65em},""")
    print(f"xtick={{{indices}}},xticklabels={{{speeds}}}]")
    for key, style, label in [
        ("baseMyErrorPct", "only marks,mark=*,mark size=2.3pt,black", r"Tower-base $M_y$"),
        ("maxSevenErrorPct", "only marks,mark=square,mark size=2.4pt,black,thick", "Largest of seven output errors"),
    ]:
        points(style, [(i, float(r[key])) for i, r in enumerate(rows, 1)])
        print(r"\addlegendentry{" + label + "}")
    print(r"""\end{semilogyaxis}
\end{tikzpicture}
\caption{Error of the 20-coordinate displacement basis at the nine test speeds on the 133-element mesh. Each output history under unit axial 3P hub force is compared with its own complete periodic history over one revolution. The basis was constructed at 3.35 and 3.49 rpm; the horizontal axis lists the other speeds individually.}
\label{fig:periodic-basis-errors}\end{figure}""")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("figure", choices=("benchmark", "basis"))
    args = parser.parse_args()
    if args.figure == "benchmark":
        benchmark()
    else:
        basis()
