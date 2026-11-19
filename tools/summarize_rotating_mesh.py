"""Extract sampled 3P maxima and interpolated half-power widths from paired meshes."""
import csv
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "runs" / "periodic_loads_20261118"


def half_power_band(rows, amplitude):
    peak_index = max(range(len(rows)), key=lambda i: rows[i][amplitude])
    peak = rows[peak_index]
    threshold = peak[amplitude] / math.sqrt(2)

    def crossing(step):
        i = peak_index
        while 0 <= i + step < len(rows):
            j = i + step
            if rows[j][amplitude] <= threshold:
                if abs(rows[j]["rpm"] - rows[i]["rpm"]) > 0.00201:
                    raise ValueError("Half-power crossing outside the densely sampled speed window")
                fraction = (threshold - rows[i][amplitude]) / (rows[j][amplitude] - rows[i][amplitude])
                return rows[i]["rpm"] + fraction * (rows[j]["rpm"] - rows[i]["rpm"])
            i = j
        raise ValueError("Half-power crossing outside sampled interval")

    left, right = crossing(-1), crossing(1)
    return peak["rpm"], peak[amplitude], left, right, right - left


def main():
    with (OUT / "rotating_mesh_sweep.csv").open() as source:
        sweep = [{k: float(v) for k, v in row.items()} for row in csv.DictReader(source)]
    with (OUT / "rotating_mesh_bands.csv").open("w", newline="") as stream:
        writer = csv.writer(stream)
        writer.writerow(["elements", "channel", "model", "peakRpm", "peakAmplitude", "lowerHalfPowerRpm",
                         "upperHalfPowerRpm", "bandwidthRpm", "separationRpm", "separationOverBandwidth"])
        for mesh in (133, 266):
            for channel in (1, 4):
                rows = sorted((v for v in sweep if v["elements"] == mesh and v["channel"] == channel),
                              key=lambda row: row["rpm"])
                bands = {m: half_power_band(rows, m + "Abs") for m in ("periodic", "average")}
                separation = bands["average"][0] - bands["periodic"][0]
                for model, band in bands.items():
                    writer.writerow([mesh, channel, model, *band, separation, separation / band[-1]])


    third_mesh = OUT / "rotating_mesh_532_average.csv"
    if third_mesh.exists():
        with third_mesh.open() as source:
            sweep = [{k: float(v) for k, v in row.items()} for row in csv.DictReader(source)]
        with (OUT / "rotating_mesh_532_band.csv").open("w", newline="") as stream:
            writer = csv.writer(stream)
            writer.writerow(["elements", "channel", "peakRpm", "peakAmplitude",
                             "lowerHalfPowerRpm", "upperHalfPowerRpm", "bandwidthRpm"])
            for channel in (1, 4):
                rows = sorted((v for v in sweep if v["channel"] == channel), key=lambda row: row["rpm"])
                writer.writerow([532, channel, *half_power_band(rows, "averageAbs")])


if __name__ == "__main__":
    main()
