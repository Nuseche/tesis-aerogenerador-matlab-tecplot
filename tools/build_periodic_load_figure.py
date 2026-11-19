"""Render publication TeX from the full spatial-order speed sweep."""
import csv
from pathlib import Path

folder = Path(__file__).resolve().parents[1] / "runs" / "periodic_loads_20261118"
with (folder / "speed_sweep.csv").open() as stream:
    records = sorted((line for line in csv.DictReader(stream)
                      if line["load"] == "1"), key=lambda line: float(line["rpm"]))

parts = [r"\begin{figure}[tbp]\centering"]
for channel, factor, label in [(1, 1e6, r"Hub displacement ($\mu$m/N)"),
                               (4, 1e-3, r"Base moment (kN m/N)")]:
    parts.extend([r"\begin{tikzpicture}",r"\begin{axis}[width=.47\textwidth,height=5.8cm,xmin=3.26,xmax=3.58,xlabel={Rotor speed (rpm)},ylabel={" + label + r"},legend style={at={(.5,1.04)},anchor=south},legend columns=2]"])
    for field, style, name in [("periodicAbs","solid","Periodic"),("averageAbs","dashed","Averaged")]:
        xy = " ".join(f"({float(r['rpm']):.5f},{factor*float(r[field]):.8g})"
                      for r in records if int(r["channel"])==channel and 3.23<float(r["rpm"])<3.61)
        parts.append(r"\addplot[black,thick,"+style+"] coordinates {"+xy+r"};\addlegendentry{"+name+"}")
    parts.append(r"\end{axis}\end{tikzpicture}")
parts.append(r"\caption{Fundamental forcing component (3P) of the steady periodic displacement and base reaction per unit axial hub force. Both curves in each panel use the full spatial discretization. The dashed curves use azimuth-averaged dynamic operators.}\label{fig:campaignsweep}\end{figure}")
(folder/"speed_sweep.tex").write_text("\n".join(parts)+"\n")
