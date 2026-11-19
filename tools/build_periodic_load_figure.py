"""Generate the manuscript's paired mesh comparison of the 3P tower-base moment."""
import csv
from pathlib import Path

folder = Path(__file__).resolve().parents[1] / "runs" / "periodic_loads_20261118"
with (folder / "rotating_mesh_sweep.csv").open() as stream:
    sweeps = [{k: float(v) for k, v in row.items()} for row in csv.DictReader(stream)
              if row["channel"] == "4" and 3.32 <= float(row["rpm"]) <= 3.54]

with (folder / "rotating_mesh_532_average.csv").open() as stream:
    sweeps.extend({k: float(v) for k, v in row.items()} for row in csv.DictReader(stream)
                  if row["channel"] == "4" and 3.32 <= float(row["rpm"]) <= 3.62)
with (folder / "rotating_mesh_532_periodic.csv").open() as stream:
    sweeps.extend({k: float(v) for k, v in row.items()} for row in csv.DictReader(stream)
                  if row["channel"] == "4" and row["H"] == "12")

figure = [
    r"\begin{figure}[tbp]\centering",
    r"\pgfplotslegendfromname{momentMeshLegend}\par\smallskip",
]
panels = [
    ("Abs", 1e-3, r"$|M_{y,3P}/F_{3P}|$ (kN\,m/N)", "ymin=0,ymax=15,ytick={0,3,6,9,12,15}"),
    ("Phase", 1, r"$\arg(M_{y,3P}/F_{3P})$ (deg)", "ymin=0,ymax=180,ytick={0,45,90,135,180}"),
]
# Periodic responses on the two meshes coincide at plotting resolution.
# Open markers keep the coarse black curve visible through the refined samples.
series = [
    (133, "periodic", "black,thick,solid", "Periodic, 133 elements"),
    (133, "average", "black,thick,dashed", "Averaged, 133 elements"),
    (266, "periodic", "black!60,thin,solid,mark=o,mark repeat=8,mark size=1.9pt",
     "Periodic, 266 elements"),
    (266, "average", "black!60,thin,dashed,mark=triangle,mark repeat=8,mark size=2.2pt",
     "Averaged, 266 elements"),
    (532, "periodic", "black,only marks,mark=square*,mark size=1.9pt", "Periodic, 532 elements"),
    (532, "average", "black,thick,dashdotted", "Averaged, 532 elements"),
]
for panel_index, (field, scale, ylabel, limits) in enumerate(panels):
    if panel_index:
        figure.append(r"\hfill")
    figure.extend([
        r"\begin{tikzpicture}",
        r"\begin{axis}[width=.485\textwidth,height=5.7cm," + limits + ",",
        r"xmin=3.32,xmax=3.62,xtick={3.35,3.45,3.55},",
        r"xlabel={Rotor speed (rpm)},ylabel={" + ylabel + "},",
        r"legend columns=2,legend to name=momentMeshLegend]" if panel_index == 0 else "]",
    ])
    for elements, prefix, style, label in series:
        rows = sorted((r for r in sweeps if r["elements"] == elements and prefix + field in r), key=lambda r: r["rpm"])
        if not rows or (elements < 532 and (rows[0]["rpm"] != 3.32 or rows[-1]["rpm"] != 3.54)):
            raise ValueError(f"Incomplete mesh sweep for {elements} elements")
        points = " ".join(f"({r['rpm']:.5f},{r[prefix + field] * scale:.8g})" for r in rows)
        figure.append(r"\addplot[" + style + "] coordinates {" + points + "};")
        if panel_index == 0:
            figure.append(r"\addlegendentry{" + label + "}")
    figure.extend([r"\end{axis}", r"\end{tikzpicture}%"])
figure.append(
    r"\caption{Amplitude and phase of the tower-base reaction moment about global $Y$ "
    r"at the forcing order (3P), relative to an axial hub force. All solutions retain "
    r"all independent coordinates of the indicated mesh. The 532-element periodic system was solved at "
    r"the two marked speeds. The 133- and 266-element periodic curves overlap at this scale.}\label{fig:campaignsweep}\end{figure}"
)
(folder / "speed_sweep.tex").write_text("\n".join(figure) + "\n")
