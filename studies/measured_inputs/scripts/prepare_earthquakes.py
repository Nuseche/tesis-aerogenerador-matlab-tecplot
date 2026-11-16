"""Strict PEER/AT2 import. Keep supplied processing and amplitudes unchanged."""
import csv
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def parse_peer(path):
    lines = path.read_text().splitlines()
    index, match = next((i, m) for i, line in enumerate(lines)
                        if (m := re.search(r'NPTS\s*=\s*(\d+)\s*,?\s*DT\s*=\s*([.\dEe+-]+)', line)))
    n, dt = int(match[1]), float(match[2])
    header = '\n'.join(lines[:index+1])
    if not ('UNITS OF G' in header.upper() or 'units are (g)' in header):
        raise ValueError(f'Acceleration unit not established: {path}')
    values = [float(x.replace('D', 'E')) for x in ' '.join(lines[index+1:]).split()]
    assert len(values) == n and dt > 0, (path, n, len(values), dt)
    return values, dt, header


def main():
    output = []
    provenance = json.loads((ROOT/'sources/earthquake_provenance.json').read_text())
    for p in provenance:
        path = ROOT/'sources'/p['file']
        assert hashlib.sha256(path.read_bytes()).hexdigest() == p['sha256']
        values, dt, header = parse_peer(path)
        destination = ROOT/'tables'/(path.stem+'_SI.csv')
        with destination.open('w') as handle:
            w = csv.writer(handle)
            w.writerow(['timeSeconds', 'groundAccelerationMps2'])
            w.writerows((format(i*dt, '.12g'), format(v*9.80665, '.16g')) for i,v in enumerate(values))
        output.append(dict(p, header=header, dt=dt, npts=len(values),
                           durationSeconds=(len(values)-1)*dt, pgaG=max(map(abs, values)),
                           amplitudeScale=1, additionalBaselineCorrection='none',
                           outputCsv=str(destination),
                           outputSha256=hashlib.sha256(destination.read_bytes()).hexdigest(),
                           status='recorded_processed_acceleration_not_site_design_record',
                           absoluteGroundDisplacementValidated=False))
    (ROOT/'tables/earthquake_catalog.json').write_text(json.dumps(output, indent=2))
    print(json.dumps([{k:r[k] for k in ['file','dt','npts','durationSeconds','pgaG']} for r in output], indent=2))


if __name__ == '__main__': main()
