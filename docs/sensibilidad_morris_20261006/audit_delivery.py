"""Audit actual second-stage cases, preserved physical sources, and checksums."""
import csv
import hashlib
import json
import tarfile
from pathlib import Path

DOCS = Path(__file__).resolve().parent
ROOT = DOCS.parents[1]
RUNS = ROOT / "runs/sensitivity/morris_20261006"


def sha(path):
    h = hashlib.sha256()
    with path.open("rb") as f:
        for block in iter(lambda: f.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


meta = json.loads((DOCS / "report_data.json").read_text())
with (RUNS / "case_status.csv").open(newline="") as f:
    cases = list(csv.DictReader(f))
successful = [r for r in cases if r["status"] == "success"]
assert len(successful) == meta["savedSuccessCases"]
for r in cases:
    if r["status"] != "pending":
        assert (RUNS / (r["caseId"] + ".mat")).is_file()

old = 0
with tarfile.open(ROOT / "runs/gyro_revision_20260919_comparison/source_after.tar.gz") as archive:
    for member in archive.getmembers():
        if member.isfile() and member.name.endswith(".m"):
            assert hashlib.sha256(archive.extractfile(member).read()).hexdigest() == sha(ROOT / member.name)
            old += 1
assert old == 148

with (RUNS / "source_hashes.csv").open(newline="") as f:
    source_rows = list(csv.DictReader(f))
for row in source_rows:
    assert sha(ROOT / row["paths"]) == row["hashes"], row["paths"]
with tarfile.open(DOCS / "source_snapshot.tar.gz") as archive:
    for member in archive.getmembers():
        if member.isfile():
            assert hashlib.sha256(archive.extractfile(member).read()).hexdigest() == sha(ROOT / member.name)

latex = json.loads((DOCS / "latex_compilation.json").read_text())
assert latex["status"] == "success"
assert latex["sourceSHA256"] == sha(DOCS / "SECCION_MORRIS_REVISION.tex")
audit = {
    "date": latex.get("date", "2026-10-06"),
    "originalCampaignDate": "2026-10-06",
    "caseCount": len(cases),
    "successfulCases": len(successful),
    "failedCases": sum(r["status"] == "failed" for r in cases),
    "pendingCases": sum(r["status"] == "pending" for r in cases),
    "completedTrajectories": meta["completedTrajectories"],
    "previousPhysicalMatlabFilesUnchanged": old,
    "campaignSourceHashesVerified": len(source_rows),
    "moduleTestsPassed": meta["modulePassed"],
    "moduleTestsFailed": meta["moduleFailed"],
    "latexCompilation": "success",
    "sourceSnapshotSHA256": sha(DOCS / "source_snapshot.tar.gz"),
    "note": "The initial setup abort and its preflight source snapshot are retained separately. No failed model case is replaced or silently omitted.",
}
(DOCS / "delivery_audit.json").write_text(json.dumps(audit, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
(DOCS / "source_snapshot.sha256").write_text(audit["sourceSnapshotSHA256"] + "  source_snapshot.tar.gz\n", encoding="utf-8")
paths = {p for folder in (DOCS, RUNS) for p in folder.rglob("*") if p.is_file() and "__pycache__" not in p.parts}
paths.update(p for p in (ROOT / "+sensitivity").glob("*.m"))
paths.add(ROOT / "tests/test_sensitivity_morris.m")
paths.add(ROOT / "cases/config_sensitivity_morris_approved.m")
paths.add(ROOT / "README.md")
manifest = DOCS / "DELIVERY_MANIFEST.csv"
paths.discard(manifest)
with manifest.open("w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow(("file", "bytes", "sha256"))
    for p in sorted(paths):
        writer.writerow((str(p.relative_to(ROOT)), p.stat().st_size, sha(p)))
print(json.dumps(audit, ensure_ascii=False, indent=2))
print(f"Manifest: {len(paths)} files")
