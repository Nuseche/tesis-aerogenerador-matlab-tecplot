"""Audit supplied SIMPACT histories without executing external scripts.

The reader accepts the little-endian, sequential-record format observed in this
campaign. It checks every record marker, dimensions, finite values and time order.
Rotations in p11 remain Euler parameters, not elastic rotation components.
"""
from pathlib import Path
import argparse
import csv
import hashlib
import json
import re
import struct

import numpy as np
from scipy.signal import find_peaks


ROOT = Path(__file__).resolve().parents[1]
KINDS = {'p11': 'displacement_and_euler', 'p19': 'velocity',
         'p20': 'acceleration', 'p12': 'internal_output'}
NODES = {'1035': 100035, '2035': 200035, '3035': 300035, '4019': 400019}


def read_history(path):
    """Return node IDs, time and [sample, node, component] raw values."""
    with Path(path).open('rb') as stream:
        prefix = stream.read(4)
        if len(prefix) != 4:
            raise ValueError(f'{path}: missing header')
        size = struct.unpack('<I', prefix)[0]
        if size < 9 or size > 100000:
            raise ValueError(f'{path}: unsupported header length')
        header = stream.read(size)
        if stream.read(4) != prefix or header[:1] != b'T':
            raise ValueError(f'{path}: unsupported header/record marker')
        fields = np.frombuffer(header[1:], dtype='<i4')
        count, components = fields[:2]
        nodes = fields[2:].copy()
        if count != len(nodes) or components != 6 or len(set(nodes)) != count:
            raise ValueError(f'{path}: invalid node/component table')
        dtype = np.dtype([('start', '<u4'), ('values', '<f8', (1+count*6,)),
                          ('end', '<u4')])
        remaining = Path(path).stat().st_size - stream.tell()
        if remaining % dtype.itemsize:
            raise ValueError(f'{path}: truncated record')
        records = np.fromfile(stream, dtype=dtype)
    payload_size = (1+count*6)*8
    if not len(records) or not np.all(records['start'] == payload_size) or not np.all(records['end'] == payload_size):
        raise ValueError(f'{path}: invalid data record markers')
    values = records['values'].copy()
    if not np.isfinite(values).all() or np.any(np.diff(values[:, 0]) <= 0):
        raise ValueError(f'{path}: nonfinite data or unordered time')
    return nodes, values[:, 0], values[:, 1:].reshape(-1, count, 6)


def active_input(path):
    return '\n'.join(part for line in path.read_text(encoding='latin1').splitlines()
                     if (part := re.split(r'[!/$]', line)[0].strip()))


def checksum(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def write_table(path, rows):
    with path.open('w', newline='') as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


def compare_export(path, time, values):
    exported = np.loadtxt(path)
    recovered = np.column_stack((time, values))
    if exported.shape != recovered.shape:
        return {'file': path.name, 'matches': False, 'reason': 'shape mismatch',
                'export_shape': list(exported.shape), 'raw_shape': list(recovered.shape)}
    # ASCII output has seven significant decimal digits; binary preserves more.
    matches = np.allclose(exported, recovered, rtol=6e-7, atol=6e-12)
    return {'file': path.name, 'matches': bool(matches),
            'max_absolute_difference': float(np.max(abs(exported-recovered)))}


def audit(source, destination):
    destination.mkdir(parents=True, exist_ok=True)
    summaries, peaks, reports = [], [], []
    spectral = {}
    for case in ('00', '03', '05', '06', '07', '09'):
        folder = source / f'12_NG_NA_NS_R_{case}_DASHPOT'
        text = active_input(folder/'snl.dat')
        amplitude = float(re.search(r'VEL_SET=\s*1.*?AMPLI\s*=\s*([-+.\deE]+)', text, re.S)[1])
        torque = float(re.search(r'LOAD_SET\s*=\s*3.*?POINT_LOAD\s+1\s+\S+\s+\S+\s+\S+\s+(\S+)', text, re.S)[1])
        # Preserve normalized input and file hashes so every interpretation is auditable.
        (destination/f'case_{case}_active_input.txt').write_text(text+'\n')
        report = {'case': case, 'source': str(folder), 'files': [], 'exports': [],
                  'streams': {}, 'unexported_displacement_aliases': []}
        for path in sorted(folder.iterdir()):
            if path.is_file():
                report['files'].append({'name': path.name, 'bytes': path.stat().st_size,
                                        'sha256': checksum(path)})
        raw = {}
        for ext, name in KINDS.items():
            times, blocks = [], []
            ids = None
            for stage in range(1, 6):
                node_ids, time, values = read_history(folder/f'snl.@{stage}.{ext}')
                if ids is not None and not np.array_equal(ids, node_ids):
                    raise ValueError(f'{folder}: node order changed between stages')
                ids = node_ids
                times.append(time)
                blocks.append(values)
                checks = NODES.items() if ext == 'p11' else [('v', 1)] if ext == 'p19' else []
                for alias, node in checks:
                    export = folder/(f'v{stage}.dat' if alias == 'v' else f'u_{alias}_{stage}.dat')
                    if export.exists():
                        report['exports'].append(compare_export(export, time, values[:, list(ids).index(node)]))
                    elif ext == 'p11' and stage == 1:
                        report['unexported_displacement_aliases'].append(alias)
            time, values = np.concatenate(times), np.concatenate(blocks)
            if np.any(np.diff(time) <= 0):
                raise ValueError(f'{folder}: overlapping stages')
            raw[ext] = (ids, time, values)
            report['streams'][name] = {'nodes': ids.tolist(), 'samples': len(time),
                'start_s': float(time[0]), 'end_s': float(time[-1]),
                'min_output_step_s': float(np.diff(time).min()),
                'max_output_step_s': float(np.diff(time).max())}
        ids, time, velocity = raw['p19']
        hub = velocity[:, list(ids).index(1), 3:]
        late = time >= 100
        d_ids, d_time, displacement = raw['p11']
        tower = displacement[:, list(d_ids).index(400019), :3]
        timing = (folder/'snl.@5.tim').read_text(encoding='latin1')
        cpu = float(re.search(r'T O T A L\s+([\deE+.-]+)', timing)[1])
        row = {'case': case, 'nominal_speed_rad_s': abs(amplitude),
               'drive_torque_input': torque,
               'hub_spin_component_mean_100_1100_rad_s': float(hub[late, 0].mean()),
               'hub_spin_component_std_100_1100_rad_s': float(hub[late, 0].std()),
               'tower_top_max_abs_x_m': float(abs(tower[:, 0]).max()),
               'tower_top_max_abs_y_m': float(abs(tower[:, 1]).max()),
               'tower_top_max_abs_z_m': float(abs(tower[:, 2]).max()),
               'stage5_cpu_seconds': cpu,
               'ascii_exports_checked': len(report['exports']),
               'ascii_export_mismatches': sum(not r['matches'] for r in report['exports'])}
        summaries.append(row)
        # A documented, common post-pulse window; interpolate slight output-time jitter.
        grid = np.arange(2501, 110000)*0.01
        if grid[0] < d_time[0] or grid[-1] > d_time[-1]:
            raise ValueError('Spectrum grid exceeds available history')
        frequency = np.fft.rfftfreq(len(grid), 0.01)
        keep = frequency <= 2
        for node, label in ((400019, 'tower_top'), (2, 'nacelle'), (1, 'hub')):
            signal = displacement[:, list(d_ids).index(node), :3]
            uniform = np.column_stack([np.interp(grid, d_time, signal[:, k]) for k in range(3)])
            transform = np.fft.rfft(uniform-uniform.mean(axis=0), axis=0)/len(grid)
            magnitude = abs(transform)
            magnitude[1:] *= 2  # Odd sample count: no Nyquist-only bin.
            spectral[f'case{case}_{label}_amplitude_m'] = magnitude[keep]
            spectral[f'case{case}_{label}_complex_m'] = transform[keep]
            for k, axis in enumerate('xyz'):
                found, _ = find_peaks(magnitude[:, k])
                found = found[(frequency[found] >= 0.05) & (frequency[found] <= 1.0)]
                ranked = sorted(found, key=lambda i: magnitude[i, k], reverse=True)[:8]
                for rank, index in enumerate(ranked, 1):
                    peaks.append({'case': case, 'node': node, 'location': label, 'axis': axis,
                                  'amplitude_rank_not_mode': rank,
                                  'frequency_hz': float(frequency[index]),
                                  'one_sided_amplitude_m': float(magnitude[index, k])})
        spectral['frequency_hz'] = frequency[keep]
        report['spectrum'] = {'start_s': float(grid[0]), 'end_s': float(grid[-1]),
            'samples': len(grid), 'step_s': 0.01, 'bin_hz': float(frequency[1]),
            'preprocessing': 'Linear interpolation to common grid, mean removed, rectangular window. '
                             'Output amplitude spectrum, not FRF or identified eigenmodes. '
                             'Complex coefficients are normalized two-sided FFT values.'}
        reports.append(report)
        print(json.dumps(row), flush=True)
    write_table(destination/'case_summary.csv', summaries)
    write_table(destination/'support_spectral_peaks.csv', peaks)
    np.savez_compressed(destination/'support_spectra.npz', **spectral)
    (destination/'audit.json').write_text(json.dumps(reports, indent=2)+'\n')
    return summaries


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, required=True)
    parser.add_argument('--output', type=Path, default=ROOT/'output/nonlinear_reference')
    args = parser.parse_args()
    audit(args.source, args.output)
