"""Emit the two-panel transfer plot from the original and refined mesh sweeps."""
import csv
from io import TextIOWrapper
from pathlib import Path
from zipfile import ZipFile

ARCHIVES = Path(__file__).resolve().parents[1] / "data/reference"


def read(archive, filename):
    with ZipFile(ARCHIVES / archive) as data:
        member, = [name for name in data.namelist() if Path(name).name == filename]
        with data.open(member) as stream:
            return list(csv.DictReader(TextIOWrapper(stream, encoding="utf-8", newline="")))


def curve(rows, amplitude, phase, lo, hi):
    data = {float(r["rpm"]): (float(r[amplitude]) / 1000, float(r[phase])) for r in rows}
    return [(n, *data[n]) for n in sorted(data) if lo <= n <= hi]


def render():
    old = "structural-load-campaigns-20261118.zip"
    fine = "rotating-refinement.zip"
    paired = read(old,"rotating_mesh_sweep.csv")
    mesh = {n: [r for r in paired if int(r["elements"]) == n and r["channel"] == "4"] for n in (133,266)}
    native532 = [r for r in read(old,"rotating_mesh_532_average.csv") if r["channel"] == "4"]
    native1064 = read(fine,"review_1064_average_survey.csv") + read(fine,"review_1064_average_peak.csv")
    curves = [
        ("Periodic, 266", "black,thick", curve(mesh[266],"periodicAbs","periodicPhase",3.32,3.54)),
        ("Mean, 133", "black,thick,dashed", curve(mesh[133],"averageAbs","averagePhase",3.32,3.54)),
        ("Mean, 266", "black,thick,dashdotted", curve(mesh[266],"averageAbs","averagePhase",3.32,3.54)),
        ("Mean, 532", "black!65,thick,mark=o,mark repeat=10,mark size=1.5pt",curve(native532,"averageAbs","averagePhase",3.32,3.76)),
        ("Mean, 1064", "black!70,thick,mark=triangle,mark repeat=9,mark size=1.8pt",curve(native1064,"amplitudeNmPerN","phaseDeg",3.32,3.76)),
    ]
    print(r"\begin{figure}[tbp]\centering\pgfplotslegendfromname{momentMeshLegend}\par\smallskip")
    for index, (ylabel, limits) in enumerate([
        (r"$|M_{y,3\mathrm P}/F_{3\mathrm P}|$ (kN\,m/N)", "ymin=0,ymax=15,ytick={0,3,6,9,12,15}"),
        (r"$\arg(M_{y,3\mathrm P}/F_{3\mathrm P})$ (deg)", "ymin=0,ymax=180,ytick={0,45,90,135,180}"),
    ], start=1):
        print(r"\begin{tikzpicture}\begin{axis}[width=.48\textwidth,height=5.6cm,")
        print("xmin=3.32,xmax=3.76,xtick={3.35,3.45,3.55,3.65,3.75},xlabel={Rotor speed (rpm)},")
        legend = ",legend columns=3,legend to name=momentMeshLegend" if index == 1 else ""
        print(f"ylabel={{{ylabel}}},{limits}{legend}]")
        for label, style, points in curves:
            coords = " ".join(f"({pt[0]:g},{pt[index]:.9g})" for pt in points)
            print(r"\addplot[" + style + "] coordinates {" + coords + "};")
            if index == 1:
                print(r"\addlegendentry{" + label + "}")
        print(r"\end{axis}\end{tikzpicture}%")
        if index == 1:
            print(r"\hfill")
    print(r"""\caption{Tower-base moment per unit axial hub force at 3P, in magnitude and phase. The mean uses each blade's own section axes. Legend numbers denote beam elements. Curves span their sampled speed intervals. Table~\ref{tab:meshrotation} gives separate checks on the periodic peak.}\label{fig:campaignsweep}\end{figure}""")


if __name__ == "__main__":
    render()
