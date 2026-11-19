"""Print the self-contained pgfplots figure for the damping campaign."""
import csv
from pathlib import Path

DATA = Path(__file__).resolve().parents[1] / "runs" / "periodic_loads_20261118"
SERIES = [(5, "solid"), (10, "dashed"), (20, "dashdotted"), (50, "dotted")]


def render():
    print(r"""\begin{figure}[H]\centering
\begin{tikzpicture}
\begin{axis}[width=.86\textwidth,height=6.2cm,xlabel={Prescribed rotor speed (rpm)},
ylabel={Peak-normalized 3P discrepancy (\%)},xmin=2.95,xmax=3.90,ymin=0,
xtick={3.0,3.2,3.4,3.6,3.8},grid=major,legend columns=4,
legend style={at={(0.5,1.03)},anchor=south,draw=none,font=\small,column sep=.6em}]""")
    for tag, style in SERIES:
        with (DATA / f"damping_sweep_{tag}.csv").open() as source:
            rows = sorted(csv.DictReader(source), key=lambda r: float(r["rpm"]))
        print(r"\addplot[black,thick," + style + "] coordinates {")
        for row in rows:
            print(f"({float(row['rpm']):.9g},{float(row['peakNormalizedComplexErrorPct']):.9g})")
        print(r"};\addlegendentry{" + f"{tag / 10:g}" + r"\%}")
    print(r"""\end{axis}
\end{tikzpicture}
\caption{Difference between averaged and periodic complex 3P tower-base moments under unit axial hub force on the 266-element mesh. Each curve is normalized by the largest periodic 3P moment sampled at the same damping level. Line styles identify Rayleigh damping targets at 0.17 and 1 Hz.}
\label{fig:damping-sweep}\end{figure}""")


if __name__ == "__main__":
    render()
