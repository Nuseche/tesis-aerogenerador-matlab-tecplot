"""Read the supplied MATLAB data as text; do not execute external scripts."""
from pathlib import Path
import json
import re
import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / 'data/aerodynamics/snl100_00'


def main():
    folder = DATA / 'supplied_linear_model'
    blade = (folder / 'blade_source.m').read_text(encoding='latin1')
    generator = (folder / 'generator_source.m').read_text(encoding='latin1')
    matrix = re.search(r'A\s*=\s*\[(.*?)\]', blade, re.S).group(1)
    rows = []
    for row in matrix.splitlines():
        row = row.replace('...', '').replace(';', '').strip()
        if row:
            rows.append([float(x) for x in row.split()])
    values = np.asarray(rows)
    assert values.shape == (34, 7) and np.all(np.diff(values[:, 0]) > 0)
    geometry = pd.read_csv(DATA / 'geometry.csv')
    constants = {}
    for text in (blade, generator):
        for key, value in re.findall(r'^\s*(\w+)\s*=\s*([-+\d.]+)\s*;', text, re.M):
            constants[key] = float(value)
    report = {
        'stations': len(values),
        'maximum_span_difference_m': float(np.max(abs(values[:, 0] - geometry.span_m))),
        'maximum_chord_difference_m': float(np.max(abs(values[:, 1] - geometry.chord_m))),
        'maximum_beta_plus_report_twist_deg': float(np.max(abs(values[:, 6] + geometry.twist_deg))),
        'nonzero_lift_slope_per_degree': sorted(set(values[values[:, 2] != 0, 2])),
        'nonzero_lift_slope_per_radian': sorted(set(values[values[:, 2] != 0, 2] * 180 / np.pi)),
        'all_drag_entries_zero': bool(np.all(values[:, 4:6] == 0)),
        'lifting_span_start_m': float(values[-1, 0] - constants['Lss']),
        'constants_as_supplied': constants,
        'interpretation': 'Linear coefficient parameters, not full-angle Cl/Cd/Cm polars. '
            'The source calling code is needed to establish pitch/angle conventions and '
            'the action at limAng. Negative beta alone does not establish a physical sign error.',
        'simulation_inputs_changed': False,
    }
    print(json.dumps(report, indent=2))
    assert report['maximum_span_difference_m'] < 1e-10
    assert report['maximum_chord_difference_m'] == 0
    assert report['maximum_beta_plus_report_twist_deg'] == 0


if __name__ == '__main__':
    main()
