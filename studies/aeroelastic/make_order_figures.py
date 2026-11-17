"""Render monochrome scientific figures from the executed MATLAB studies."""
from pathlib import Path
import argparse
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.ticker import MaxNLocator

ROOT = Path(__file__).resolve().parents[2]
plt.rcParams.update({'font.family': 'DejaVu Serif', 'font.size': 10,
                     'axes.spines.top': False, 'axes.spines.right': False,
                     'legend.frameon': False, 'savefig.facecolor': 'white',
                     'axes.formatter.use_mathtext': True})


def save(fig, folder, name):
    fig.savefig(folder / f'{name}.pdf', bbox_inches='tight')
    fig.savefig(folder / f'{name}.png', dpi=190, bbox_inches='tight')
    plt.close(fig)


def main(folder, convergence):
    campbell = pd.read_csv(folder / 'campbell.csv')
    peaks = pd.read_csv(folder / 'resolved_peaks.csv')
    three = peaks[peaks.order == 3]
    peak = three.loc[three.hub_axial_m_per_N.idxmax()]
    fig, ax = plt.subplots(figsize=(7.1, 4.2), layout='constrained')
    for col in campbell.columns[1:]:
        ax.plot(campbell.rpm, campbell[col], 'k-', lw=.8)
    for order, style in [(1, '--'), (3, '-.'), (6, ':'), (9, '--')]:
        ax.plot(campbell.rpm, order * campbell.rpm / 60, color='.45', ls=style,
                lw=1.2, label=f'{order}P')
    ax.plot(peak.rpm, peak.frequency_hz, 'ko', ms=5, mfc='white')
    ax.annotate('3P response peak', (peak.rpm, peak.frequency_hz), xytext=(4.25, .125),
                arrowprops={'arrowstyle': '-', 'color': '.2'}, fontsize=9)
    ax.set(xlabel='Rotor speed (rpm)', ylabel='Frequency (Hz)', xlim=(.5, 7.44), ylim=(0, 1.2))
    ax.legend(ncol=4, loc='upper left')
    save(fig, folder, 'campbell_orders')

    coarse = pd.read_csv(folder / 'hub_receptance.csv')
    fine = pd.read_csv(folder / 'peak_neighborhoods.csv')
    curves = pd.concat([coarse, fine]).sort_values('rpm').drop_duplicates(['rpm', 'order'])
    fig, axes = plt.subplots(1, 2, figsize=(9.2, 3.6), layout='constrained')
    for order, style in [(1, '-.'), (3, '-'), (6, '--')]:
        c = curves[curves.order == order]
        axes[0].semilogy(c.rpm, c.hub_axial_m_per_N, color='k', ls=style, lw=1, label=f'{order}P')
    axes[0].set(xlabel='Rotor speed (rpm)', ylabel='Axial hub receptance (m/N)', xlim=(.5, 7.44))
    axes[0].legend(loc='upper right')
    c = curves[(curves.order == 3) & curves.rpm.between(3.28, 3.6)]
    for field, label, style in [('hub_axial_m_per_N', 'Hub', '-'),
                               ('nacelle_axial_m_per_N', 'Nacelle', '--'),
                               ('tower_top_axial_m_per_N', 'Tower top', ':')]:
        axes[1].plot(c.rpm, c[field] * 1e6, color='k', ls=style, lw=1.2, label=label,
                     marker='o' if label == 'Nacelle' else None, markevery=9, ms=3, mfc='white')
    axes[1].set(xlabel='Rotor speed (rpm)', ylabel=r'3P axial receptance ($\mu$m/N)')
    axes[1].xaxis.set_major_locator(MaxNLocator(5))
    axes[1].legend(loc='upper right')
    for i, ax in enumerate(axes):
        ax.text(.02, .04, f'({chr(97+i)})', transform=ax.transAxes)
    save(fig, folder, 'hub_and_support_orders')

    orders = pd.read_csv(folder / 'rigid_rotor_load_orders.csv')
    c = orders[(orders.geometry == 'inherited') & (orders.angular_samples == 384) &
               (orders.shear_exponent == .2)]
    ideal = orders[(orders.geometry == 'cyclic_control') & (orders.angular_samples == 384) &
                   (orders.shear_exponent == .2)]
    fig, axes = plt.subplots(1, 2, figsize=(9.2, 3.5), layout='constrained')
    for field, label, marker in [('blade1_thrust_N', 'Blade 1', 'o'), ('hub_thrust_N', 'Hub sum', 's')]:
        axes[0].semilogy(c.order, c[field], color='k', marker=marker, mfc='white', ls='none', label=label)
    axes[0].set(ylabel='Axial force amplitude (N)', xlabel='Rotor order (P)', xticks=range(1, 10))
    axes[0].legend()
    axes[1].semilogy(c.order, c.hub_pitch_moment_Nm, 'ko', mfc='white', label='Inherited geometry')
    use = ideal.hub_pitch_moment_Nm > 1e-5
    axes[1].semilogy(ideal.order[use], ideal.hub_pitch_moment_Nm[use], 'ks', mfc='white',
                     label='Exact cyclic control')
    axes[1].set(ylabel='Hub pitching-moment amplitude (N m)', xlabel='Rotor order (P)', xticks=range(1, 10))
    axes[1].legend(fontsize=8)
    for i, ax in enumerate(axes):
        ax.text(.02, .04, f'({chr(97+i)})', transform=ax.transAxes)
    save(fig, folder, 'blade_to_hub_orders')

    metrics_path = convergence / 'temporal_convergence.csv'
    if metrics_path.exists():
        metrics = pd.read_csv(metrics_path)
        spatial = pd.read_csv(convergence / 'stability_refinement.csv')
        fig, axes = plt.subplots(1, 2, figsize=(9.2, 3.5), layout='constrained')
        for channel, label, marker in [('tip_displacement', 'Tip displacement', 'o'),
                                       ('tip_twist', 'Tip twist', 's'),
                                       ('aerodynamic_force', 'Aerodynamic force', '^'),
                                       ('aerodynamic_moment', 'Aerodynamic moment', 'd')]:
            c = metrics[(metrics.channel == channel) & (metrics.relative_L2 > 0)].sort_values('dt_s')
            axes[0].loglog(c.dt_s, 100*c.relative_L2, color='k', marker=marker, mfc='white', lw=.9, label=label)
        axes[0].axhline(1, color='.5', ls=':', lw=.9)
        axes[0].set(xlabel='Time step (s)', ylabel='History change relative to finest (%)')
        axes[0].legend(fontsize=8, loc='lower left', bbox_to_anchor=(0, 1.02), ncol=2)
        c = spatial[spatial.difference_step == 1e-5]
        axes[1].plot(c.elements, c.frequency_hz, 'ko-', mfc='white')
        axes[1].set(xlabel='Blade elements', ylabel='Growing-mode frequency (Hz)', xticks=[35, 70, 140])
        axes[1].ticklabel_format(axis='y', useOffset=False)
        for i, ax in enumerate(axes):
            ax.text(.02, .94 if i == 0 else .04, f'({chr(97+i)})', transform=ax.transAxes)
        save(fig, convergence, 'numerical_convergence')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--folder', type=Path, default=ROOT / 'runs/rotor_orders_20261117')
    parser.add_argument('--convergence', type=Path, default=ROOT / 'runs/aeroelastic_convergence_20261117')
    args = parser.parse_args()
    main(args.folder, args.convergence)
