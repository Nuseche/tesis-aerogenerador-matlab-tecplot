"""Inspect all channels; export measured 70 m sonic along-wind velocity.

Choose the sonic s70u (25 Hz) rather than cup ws70 for fluctuations. The
selection is fixed by measurement type, not favorable output or amplitude.
"""
from pathlib import Path
import csv
import hashlib
import io
import json
import numpy as np
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def main():
    with zipfile.ZipFile(ROOT/'sources/nm92_first_member') as archive:
        assert len(archive.namelist()) == 1
        raw = archive.read(archive.namelist()[0])
    (ROOT/'sources/nm92_20051119_0000_250.dat').write_bytes(raw)
    header, body = raw.decode().split('[data field]')
    stats = header.split('[sensor statistics]')[1].split('[Additional Statistics]')[0]
    metadata = [line.split() for line in stats.splitlines() if line.strip()]
    names = [line[4] for line in metadata]
    values = np.loadtxt(io.StringIO(body))
    assert values.shape == (15000, 59) and len(names) == 59
    assert np.isfinite(values).all()
    checks = []
    for j, line in enumerate(metadata):
        # Header values are rounded. Record every difference, not only successes.
        checks.append({'channel': line[4], 'unit': line[-1], 'heightM':float(line[2]),
                       'observedMean':float(values[:,j].mean()), 'headerMean':float(line[5]),
                       'meanDifference':float(values[:,j].mean()-float(line[5])),
                       'observedStdPopulation':float(values[:,j].std()), 'headerStd':float(line[6]),
                       'observedMin':float(values[:,j].min()),'observedMax':float(values[:,j].max())})
    selected = values[:, names.index('s70u')]
    assert selected.min() > 0
    item = next(c for c in checks if c['channel']=='s70u')
    assert abs(item['meanDifference']) < .0005
    assert abs(item['observedStdPopulation']-item['headerStd']) < .0005
    t = np.arange(len(selected))/25.
    with (ROOT/'tables/wind_DTU_s70u_SI.csv').open('w') as handle:
        writer=csv.writer(handle);writer.writerow(['timeSeconds','alongWindSpeedMps'])
        writer.writerows(zip(t, selected))
    (ROOT/'tables/wind_channel_audit.json').write_text(json.dumps(checks, indent=2))
    catalog = dict(doi='10.11583/DTU.16743739', channel='s70u', heightM=70,
        samplingHz=25, samples=len(t), firstToLastSampleSeconds=float(t[-1]),
        acquisitionDurationSeconds=600, date='2005-11-19', localTimeInHeader='00:00:00',
        timeZone='not specified in raw file; no simultaneity claim',
        turbine='NEG-Micon NM92/2750 kW', measuredRotorSpeedRpm=14.65,
        meanMps=float(selected.mean()), stdPopulationMps=float(selected.std()),
        turbulenceIntensity=float(selected.std()/selected.mean()),
        minMps=float(selected.min()), maxMps=float(selected.max()),
        meanSquaredSpeed=float(np.mean(selected**2)),
        originalSha256=hashlib.sha256(raw).hexdigest(),
        shapeDefinition='U(t)^2 / mean_sample(U^2); force = meanThrust * shape',
        measuredForce=False, jointEarthquakeObservation=False,
        warnings=['DTU web documentation says 8 Hz in one final line; raw file header, 15000 samples and 600 s establish 25 Hz.',
                  'No spatial wind field, hub-height extrapolation, aerodynamic feedback, or turbine-to-turbine load scaling is inferred.',
                  'Measured turbine rpm is context; structural scenario retains prescribed 12 rpm.',
                  'Published blade/shaft/tower moments are measured internal responses, not applied nodal loads.'])
    # Direct check of the two lower sonic vectors using channel names.
    catalog['lowerSonicsDuplicated']=all(np.array_equal(values[:,names.index(a)],values[:,names.index(b)])
        for a,b in [('s47x','s24x'),('s47y','s24y'),('s47z','s24z')])
    (ROOT/'tables/wind_catalog.json').write_text(json.dumps(catalog, indent=2))
    print(json.dumps(catalog, indent=2))


if __name__ == '__main__': main()
