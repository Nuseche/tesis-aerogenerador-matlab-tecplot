"""Print the article figure for the 266-element rotating operator comparison."""
import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "runs/rotating_term_study/term_sweep_266_5.csv"
STYLES = [
    ("complete", "solid", "Complete"),
    ("omitG", "dashed", "Gyroscopic term omitted"),
    ("omitKg", "dashdotted", "Prestress omitted"),
    ("omitBoth", "dotted", "Both omitted"),
]


def render():
    with DATA.open() as source:
        rows = list(csv.DictReader(source))
    print(r"""\begin{figure}[H]\centering
\begin{tikzpicture}
\begin{axis}[width=.86\textwidth,height=6.3cm,xmin=3.32,xmax=3.48,ymin=0,
xlabel={Prescribed rotor speed (rpm)},ylabel={$|M_{y,3\mathrm P}/F_{3\mathrm P}|$ (kN\,m/N)},
xtick={3.32,3.36,3.40,3.44,3.48},xticklabel style={/pgf/number format/fixed,/pgf/number format/precision=2},
legend columns=2,legend style={at={(.5,1.03)},anchor=south,draw=none,font=\small,column sep=1em}]""")
    for variant, style, label in STYLES:
        series = sorted((float(r["rpm"]), float(r["amplitude"]) / 1000)
                        for r in rows if r["variant"] == variant and 3.32 <= float(r["rpm"]) <= 3.48)
        print(r"\addplot[black,thick," + style + "] coordinates {")
        for rpm, amplitude in series:
            print(f"({rpm:.9g},{amplitude:.9g})")
        print(r"};\addlegendentry{" + label + "}")
    print(r"""\end{axis}\end{tikzpicture}
\caption{Effect of the material gyroscopic operator and centrifugal blade prestress on the magnitude of the 3P bending reaction about global $Y$ at the tower base. Each curve uses the periodic equations on the 266-element mesh, unit axial hub force and 0.5\% target damping.}
\label{fig:rotating-terms}\end{figure}""")


if __name__ == "__main__":
    render()
