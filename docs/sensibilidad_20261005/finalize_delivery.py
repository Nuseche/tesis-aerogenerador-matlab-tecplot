"""Audit stored results and write the final delivery checksums; no model solves."""
import csv
import hashlib
import json
import tarfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DOCS = Path(__file__).resolve().parent
RUNS = ROOT / "runs/sensitivity/initial_20261005"


def digest(path):
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


expected = {
    "local": 52,
    "connections": 10,
    "foundation": 12,
    "mesh": 3,
    "seismic": 6,
    "interactions": 4,
    "temporal_parameters": 12,
}
counts = {}
for phase, number in expected.items():
    folder = RUNS / phase
    with (folder / "case_status.csv").open(newline="") as stream:
        rows = list(csv.DictReader(stream))
    assert len(rows) == number, (phase, len(rows))
    assert all(row["status"] == "success" and not row["error"] for row in rows)
    assert all((folder / (row["caseId"] + ".mat")).is_file() for row in rows)
    counts[phase] = len(rows)

prior_files = 0
with tarfile.open(ROOT / "runs/gyro_revision_20260919_comparison/source_after.tar.gz") as archive:
    for member in archive.getmembers():
        if not member.isfile() or not member.name.endswith(".m"):
            continue
        data = archive.extractfile(member).read()
        assert hashlib.sha256(data).hexdigest() == digest(ROOT / member.name), member.name
        prior_files += 1
assert prior_files == 148, prior_files

data_files = 0
with (RUNS / "local/source_hashes.csv").open(newline="") as stream:
    for row in csv.DictReader(stream):
        if row["paths"].startswith("data/"):
            assert digest(ROOT / row["paths"]) == row["hashes"], row["paths"]
            data_files += 1
assert data_files > 0

final_archive = DOCS / "source_snapshot_final_20261005.tar.gz"
with tarfile.open(final_archive) as archive:
    for member in archive.getmembers():
        if member.isfile():
            assert hashlib.sha256(archive.extractfile(member).read()).hexdigest() == digest(ROOT / member.name)
snapshot_hash = digest(final_archive)
(DOCS / "source_snapshot_final_20261005.sha256").write_text(
    snapshot_hash + "  " + final_archive.name + "\n", encoding="utf-8"
)

regression = json.loads((DOCS / "regression_summary_final.json").read_text())
assert regression["passed"] == 155 and regression["failed"] == 0 and regression["incomplete"] == 0
latex = json.loads((DOCS / "latex_compilation.json").read_text())
assert latex["status"] == "success"
latex["sourceSHA256"] = digest(DOCS / latex["file"])
(DOCS / "latex_compilation.json").write_text(json.dumps(latex, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

audit = {
    "date": "2026-10-05",
    "successfulModelEvaluations": sum(counts.values()),
    "phases": counts,
    "previousMatlabFilesUnchanged": prior_files,
    "rawInputFilesUnchanged": data_files,
    "regressionPassed": regression["passed"],
    "regressionFailed": regression["failed"],
    "finalSourceArchiveSHA256": snapshot_hash,
    "standaloneLatexCompilation": latex["status"],
    "note": "The deliberately failed equilibrium-tolerance probe is retained separately; raw campaign snapshots and final postprocessing versions are distinguished.",
}
(DOCS / "delivery_audit.json").write_text(json.dumps(audit, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

paths = {p for folder in (DOCS, RUNS, ROOT / "+sensitivity") for p in folder.rglob("*") if p.is_file()}
paths.update(ROOT / "cases" / name for name in ("config_sensitivity_local.m", "config_sensitivity_extended_pending.m"))
paths.add(ROOT / "tests/test_sensitivity.m")
paths.add(ROOT / "README.md")
manifest = DOCS / "DELIVERY_MANIFEST.csv"
paths.discard(manifest)
with manifest.open("w", newline="", encoding="utf-8") as stream:
    writer = csv.writer(stream)
    writer.writerow(("file", "bytes", "sha256"))
    for path in sorted(paths):
        writer.writerow((str(path.relative_to(ROOT)), path.stat().st_size, digest(path)))
print(json.dumps(audit, ensure_ascii=False, indent=2))
print(f"Manifest: {len(paths)} files.")
