"""Check the sign and scale of the archived SIMPACT case-00 base INTERNAL vector.

The three force components of the one-second nacelle pulse are global. The
three couples use the moving nodal frame. Time-averaged cumulative impulses
attenuate the residual angular momentum at the record endpoint. This check
does not resolve which viscous terms contribute to an instantaneous output.
"""
import argparse
from pathlib import Path

import numpy as np
from scipy.integrate import cumulative_trapezoid, trapezoid
from scipy.spatial.transform import Rotation

from audit_nonlinear_reference import read_history


def node_history(folder, suffix, node):
    parts = []
    for stage in range(1, 6):
        nodes, times, values = read_history(folder / f"snl.@{stage}.{suffix}")
        parts.append(np.column_stack((times, values[:, list(nodes).index(node)])))
    history = np.concatenate(parts)
    if not np.all(np.diff(history[:, 0]) > 0):
        raise ValueError(f"Non-increasing joined times for node {node} in {suffix}")
    return history


def impulse_report(folder):
    base = node_history(folder, "p12", 400000)
    velocity = node_history(folder, "p19", 400000)
    nacelle = node_history(folder, "p11", 2)
    pulse_time = np.linspace(20, 21, 501)
    nacelle_origin = np.array([-2.9886, 0, 141.54])  # case-00 deck, metres
    position = nacelle_origin + np.column_stack([
        np.interp(pulse_time, nacelle[:, 0], component)
        for component in nacelle[:, 1:4].T
    ])
    force = np.full(3, 1e7)  # positive global components, N
    local_couple = np.full(3, 1e7)  # positive local components, N m
    couple_global = Rotation.from_euler("ZXZ", nacelle[:, 4:]).apply(local_couple)
    applied_couple = np.column_stack([
        np.interp(pulse_time, nacelle[:, 0], component)
        for component in couple_global.T
    ])
    expected_force = -force * (pulse_time[-1] - pulse_time[0])
    expected_moment = -trapezoid(np.cross(position, force) + applied_couple,
                                 pulse_time, axis=0)
    times = base[:, 0]
    accumulated = cumulative_trapezoid(base[:, 1:], times, axis=0, initial=0)
    frame = Rotation.from_euler("ZXZ", [90, 90, 90], degrees=True)

    def vector(values):
        return " ".join(f"{value:.6g}" for value in values)

    late = (times > 1000) & (times < 1100)
    mean = accumulated[late].mean(axis=0)
    measured_moment = frame.apply(mean[3:])
    lines = [
        "Case 00; base node 400000; nacelle node 2",
        f"Records: {len(times)}",
        "Base velocity absolute peaks: " + vector(np.abs(velocity[:, 1:]).max(axis=0)),
        "Expected global reaction force impulse (MN s): " + vector(expected_force / 1e6),
        "Expected global reaction moment impulse (MN m s): " + vector(expected_moment / 1e6),
        "Mean cumulative impulse, endpoints 1000<t<1100 s",
        "Observed global force (MN s): " + vector(mean[:3] / 1e6),
        "Observed local moment (MN m s): " + vector(mean[3:] / 1e6),
        "Observed global moment (MN m s): " + vector(measured_moment / 1e6),
        "Absolute moment discrepancy by component (%): "
        + vector(100 * np.abs((measured_moment - expected_moment) / expected_moment)),
        "Endpoint sensitivity, local C5 cumulative impulse (MN m s), mean and SD:",
    ]
    for lo, hi in [(200, 400), (400, 600), (800, 1000), (1000, 1100)]:
        values = accumulated[(times > lo) & (times < hi), 4] / 1e6
        lines.append(f"{lo}<t<{hi}: {values.mean():.5f} {values.std():.5f}")
    lines.append("Support-on-structure global My convention: minus local INTERNAL component 5.")
    lines.append("Agreement of mean impulse does not establish pointwise reaction accuracy.")
    return "\n".join(lines) + "\n"


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True, help="Case-00 folder with all five stages.")
    parser.add_argument("--output", type=Path, help="Optional text report; stdout also receives the result.")
    args = parser.parse_args()
    report = impulse_report(args.source)
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(report, encoding="utf-8")
    print(report, end="")
