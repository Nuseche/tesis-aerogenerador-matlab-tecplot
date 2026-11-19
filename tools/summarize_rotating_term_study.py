"""Summarize the complex tower-base moment sensitivity on the archived sweep."""
import csv
from pathlib import Path

DATA = Path(__file__).resolve().parents[1] / "runs" / "rotating_term_study"


def load_result(name):
    with (DATA / name).open() as f:
        return list(csv.DictReader(f))


def save_result(name, rows):
    with (DATA / name).open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=rows[0])
        w.writeheader()
        w.writerows(rows)


def phasor(row):
    return complex(float(row["real3P"]), float(row["imag3P"]))


def main():
    sweep = load_result("term_sweep_266_5.csv")
    refs = {r["rpm"]: r for r in sweep if r["variant"] == "complete"}
    ref_peak = max(refs.values(), key=lambda r: float(r["amplitude"]))
    ref_scale = float(ref_peak["amplitude"])
    summary = []
    for name in ("complete", "omitG", "omitKg", "omitBoth"):
        branch = [r for r in sweep if r["variant"] == name]
        peak = max(branch, key=lambda r: float(r["amplitude"]))
        def relative_to_peak(row):
            return 100 * abs(phasor(row) - phasor(refs[row["rpm"]])) / ref_scale
        critical = max(branch, key=relative_to_peak)
        summary.append(dict(variant=name, samples=len(branch),
                            peakRpm=peak["rpm"], peakAmplitude=peak["amplitude"],
                            shiftRpm=float(peak["rpm"]) - float(ref_peak["rpm"]),
                            maxPeakNormalizedDifferencePct=relative_to_peak(critical),
                            rpmOfMaxDifference=critical["rpm"]))
    save_result("summary_peaks.csv", summary)

    checks = []
    for mesh, z10 in ((133,5), (266,5), (532,5), (266,10), (266,20), (266,50)):
        coarse = {(r["rpm"],r["variant"]): r for r in load_result(f"term_sweep_{mesh}_{z10}.csv")}
        fine = load_result(f"term_H12_{mesh}_{z10}.csv")
        for r in fine:
            a = coarse[r["rpm"], r["variant"]]
            checks.append(dict(elements=mesh, dampingPct=z10/10, rpm=r["rpm"], variant=r["variant"],
                               h6To12ComplexDifferencePct=100*abs(phasor(a)/phasor(r)-1),
                               changeInHistoryMetricPercentagePoints=abs(float(a["historyChangePct"])-float(r["historyChangePct"]))))
    save_result("summary_harmonic_checks.csv", checks)

    meshes = {}
    for n in (133, 266, 532):
        for r in load_result(f"term_H12_{n}_5.csv"):
            meshes[(n,r["rpm"],r["variant"])] = float(r["historyChangePct"])
    comparison = []
    for rpm in ("3.394", "3.4", "3.4445"):
        for name in ("omitG", "omitKg", "omitBoth"):
            values = [meshes[n,rpm,name] for n in (133,266,532)]
            comparison.append(dict(rpm=rpm, variant=name, historyChangePct133=values[0],
                                   historyChangePct266=values[1], historyChangePct532=values[2],
                                   rangePercentagePoints=max(values)-min(values)))
    save_result("summary_mesh_checks.csv", comparison)


if __name__ == "__main__":
    main()
