"""Measure repeatability of the case 00 tower-top/p12 transfer during free decay.

The scalar output is raw basal INTERNAL component 5. A proportional low-amplitude
transfer estimated from SIMPACT is not an independently predicted linear response.
"""
import argparse
import csv
from pathlib import Path
import numpy as np
from scipy.signal import periodogram

from audit_nonlinear_reference import read_history

ROOT = Path(__file__).resolve().parents[1]


def channel(folder, extension, node, component):
    times, values = [], []
    for stage in (4, 5):
        nodes, time, raw = read_history(folder / f"snl.@{stage}.{extension}")
        times.append(time)
        values.append(raw[:, list(nodes).index(node), component - 1])
    t = np.concatenate(times)
    if not np.all(np.diff(t) > 0):
        raise ValueError("Stage times overlap")
    return t, np.concatenate(values)


def write_csv(path, rows):
    with path.open("w", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=rows[0].keys())
        writer.writeheader()
        writer.writerows(rows)


def crossings(time, x):
    i = np.flatnonzero((x[:-1] <= 0) & (x[1:] > 0))
    return time[i] - x[i] * np.diff(time)[i] / np.diff(x)[i]


def fundamental(t, y, f):
    angle = 2 * np.pi * f * (t - t[0])
    design = np.column_stack([np.ones_like(t), np.cos(angle), np.sin(angle)])
    coefficients = np.linalg.lstsq(design, y, rcond=None)[0]
    return coefficients[1] - 1j * coefficients[2]


def analyze(folder, output):
    t, x = channel(folder, "p11", 400019, 1)
    tm, m = channel(folder, "p12", 400000, 5)
    if not np.array_equal(t, tm):
        raise ValueError("Noncoincident sampling")
    # A small transfer phase is estimated independently from the amplitude.
    # The signed through-origin tail fit provides an additional raw-curve check.
    fit = (t >= 800) & (t < 950)
    slope = np.dot(x[fit], m[fit]) / np.dot(x[fit], x[fit])
    output.mkdir(parents=True, exist_ok=True)
    windows, summaries = [], []
    for direction, count in [(1, 1), (-1, 1), (1, 3), (-1, 3)]:
        boundaries = crossings(t, direction * x)
        boundaries = boundaries[boundaries >= 21]
        data = []
        for i in range(0, len(boundaries)-count, count):
            a, b = boundaries[i], boundaries[i+count]
            section = (t >= a) & (t < b)
            f = count / (b-a)
            x1 = fundamental(t[section], x[section], f)
            m1 = fundamental(t[section], m[section], f)
            g = m1 / x1
            raw_residual = 100*np.linalg.norm(m[section]-slope*x[section])/np.linalg.norm(m[section])
            data.append((a, b, f, abs(x1), max(abs(x[section])), g, raw_residual))
        train = [v[5] for v in data if v[0]>=800 and v[1]<=950]
        ref = np.median(np.real(train)) + 1j*np.median(np.imag(train))
        batch = []
        for a,b,f,amp,peak,g,residual in data:
            row = dict(crossing_sign=direction,cycles=count,t0_s=a,t1_s=b,
                       x_fundamental_m=amp,x_peak_m=peak,frequency_Hz=f,
                       c5_per_m_magnitude=abs(g),c5_to_x_phase_deg=np.angle(g,deg=True),
                       transfer_change_percent=100*abs(g/ref-1),raw_residual_percent=residual)
            windows.append(row)
            batch.append(row)
        for name, a, b in [('early',21,100),('calibration',800,950),('heldout',950,1100),('all',21,1100.01)]:
            selected = [r for r in batch if r['t0_s']>=a and r['t1_s']<=b]
            summaries.append(dict(crossing_sign=direction,cycles=count,segment=name,
                n=len(selected), min_x_m=min(r['x_fundamental_m'] for r in selected),
                max_x_m=max(r['x_fundamental_m'] for r in selected),
                min_f_Hz=min(r['frequency_Hz'] for r in selected),max_f_Hz=max(r['frequency_Hz'] for r in selected),
                median_ref_magnitude=abs(ref),ref_phase_deg=np.angle(ref,deg=True),
                max_complex_difference_percent=max(r['transfer_change_percent'] for r in selected),
                max_raw_residual_percent=max(r['raw_residual_percent'] for r in selected)))
    write_csv(output/'case00_decay_windows.csv',windows)
    write_csv(output/'case00_decay_segments.csv',summaries)
    # Cover the initial fraction of a cycle omitted by the crossing analysis.
    segments=[]
    for a,b in [(21,27),(21,100),(100,300),(300,550),(550,800),(800,950),(950,1100)]:
        keep=(t>=a)&(t<b)
        q=m[keep]; v=x[keep]
        segments.append(dict(t0_s=a,t1_s=b,x_maxabs_m=max(abs(v)),slope_raw_per_m=slope,
            raw_residual_L2_percent=100*np.linalg.norm(q-slope*v)/np.linalg.norm(q),
            raw_peak_delta_percent=100*(max(abs(q))-max(abs(slope*v)))/max(abs(q))))
    write_csv(output/'case00_decay_raw_check.csv',segments)
    # Independent measures of concentration in the first-response band and
    # contamination at other frequencies. A broad band admits nearby modes.
    t_y, y = channel(folder, "p11", 400019, 2)
    if not np.array_equal(t_y, t):
        raise ValueError("Noncoincident sampling for the transverse axis")
    diagnostic = []
    for a,b in [(25,100),(100,300),(300,550),(550,800),(800,950),(950,1100)]:
        grid = np.arange(a*100+1,b*100)*0.01
        for label,signal in [("top_x",x),("top_y",y),("base_c5",m)]:
            f,power=periodogram(np.interp(grid,t,signal),fs=100,window="hann")
            first=(f>=0.12)&(f<=0.22)
            peak=f[np.argmax(power)]
            diagnostic.append(dict(t0_s=a,t1_s=b,channel=label,bin_width_Hz=f[1],
                peak_Hz=peak, first_band_power_percent=100*power[first].sum()/power.sum()))
    write_csv(output/'case00_decay_spectra.csv',diagnostic)


if __name__ == "__main__":
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('case',type=Path)
    parser.add_argument('--out',type=Path,default=ROOT/'runs/case00_decay')
    args=parser.parse_args()
    analyze(args.case,args.out)
