#!/usr/bin/env python3
"""Generate the complete static figure catalog from accepted CSV evidence."""

from __future__ import annotations

import csv
import math
import re
import shutil
from collections import Counter, defaultdict
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
from matplotlib.colors import LogNorm
from matplotlib.ticker import EngFormatter, MaxNLocator


ROOT = Path(__file__).resolve().parents[1]
REPORT = ROOT / "docs" / "resultados_integrales"
EVIDENCE = REPORT / "evidence"
OUT = REPORT / "figures"
OUT.mkdir(parents=True, exist_ok=True)

RUNS = {
    2: ROOT / "runs" / "run_20260826_210833_538_action02_timoshenko",
    3: ROOT / "runs" / "run_20260826_231211_426_action03_rigid_constraints",
    4: ROOT / "runs" / "run_20260826_232027_996_action04_rigid_bodies",
    5: ROOT / "runs" / "run_20260826_232719_219_action05_mass_formulation",
    6: ROOT / "runs" / "run_20260826_234708_429_action06_equilibrium",
    7: ROOT / "runs" / "run_20260827_000911_242_action07_dynamic_operators",
    8: ROOT / "runs" / "run_20260827_090201_148_action08_mbc_qep_campbell",
    9: ROOT / "runs" / "run_20260831_163238_997_action09_seismic_newmark",
    10: ROOT / "runs" / "run_20260831_165045_307_action10_full_acceptance",
}

COLORS = ["#0072B2", "#D55E00", "#009E73", "#CC79A7", "#E69F00", "#56B4E9"]
plt.rcParams.update(
    {
        "figure.facecolor": "white",
        "axes.facecolor": "white",
        "axes.grid": True,
        "grid.alpha": 0.25,
        "axes.spines.top": False,
        "axes.spines.right": False,
        "font.size": 10,
        "axes.titlesize": 11,
        "axes.labelsize": 10,
        "legend.fontsize": 8,
        "savefig.facecolor": "white",
        "savefig.bbox": "tight",
    }
)


def rows(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8-sig") as handle:
        return list(csv.DictReader(handle))


def number(row: dict[str, str], key: str) -> float:
    value = row.get(key, "")
    try:
        return float(value)
    except (TypeError, ValueError):
        return math.nan


def values(items: list[dict[str, str]], key: str) -> np.ndarray:
    return np.array([number(item, key) for item in items], dtype=float)


def finish(fig: plt.Figure, name: str) -> None:
    fig.tight_layout()
    fig.savefig(OUT / name, dpi=190)
    plt.close(fig)


def copy_canonical_figures() -> None:
    copies = {
        RUNS[2] / "figures" / "geometry.png": "01_geometria_modelo.png",
        RUNS[2] / "figures" / "action02_local_axes.png": "02_ejes_locales.png",
        RUNS[2] / "figures" / "action02_mesh_convergence.png": "06_convergencia_malla_original.png",
    }
    for source, destination in copies.items():
        shutil.copy2(source, OUT / destination)
    for mode in range(1, 7):
        shutil.copy2(
            RUNS[10] / "figures" / f"mode_{mode:02d}.png",
            OUT / f"{33 + mode:02d}_forma_modal_{mode:02d}.png",
        )


def plot_mesh_topology() -> None:
    data = rows(RUNS[2] / "action02_component_summary.csv")
    labels = [r["component"].replace("blade_", "pala ").replace("tower", "torre").replace("transition", "transición") for r in data]
    fig, axes = plt.subplots(1, 3, figsize=(12, 4.1))
    metrics = [
        ("elementCount", "Elementos", 1.0),
        ("totalLengthM", "Longitud [m]", 1.0),
        ("distributedMassKg", "Masa distribuida [t]", 1e-3),
    ]
    for ax, (key, ylabel, scale) in zip(axes, metrics):
        y = values(data, key) * scale
        bars = ax.bar(labels, y, color=COLORS[: len(labels)])
        ax.set_ylabel(ylabel)
        ax.tick_params(axis="x", rotation=35)
        ax.set_title(ylabel.split(" [")[0] + " por componente")
        for bar, val in zip(bars, y):
            ax.text(bar.get_x() + bar.get_width() / 2, val, f"{val:.3g}", ha="center", va="bottom", fontsize=8)
    fig.suptitle("Malla flexible convertida: 133 elementos activos")
    finish(fig, "03_topologia_malla.png")


def plot_primitive_spectrum() -> None:
    spectrum = rows(EVIDENCE / "primitive_element_spectrum.csv")
    singular = rows(EVIDENCE / "primitive_element_singular_values.csv")
    mode = values(spectrum, "mode")
    frequency = np.abs(values(spectrum, "frequencyHz"))
    rigid = np.array([r["classification"] == "rigid_numerical_zero" for r in spectrum])
    fig, axes = plt.subplots(1, 2, figsize=(11, 4.2))
    axes[0].scatter(mode[rigid], np.maximum(frequency[rigid], 1e-12), s=55, color=COLORS[1], label="6 modos rígidos")
    axes[0].scatter(mode[~rigid], frequency[~rigid], s=55, color=COLORS[0], label="6 modos deformacionales")
    axes[0].axhline(1e-4, color="black", linestyle="--", linewidth=1, label="tolerancia 10⁻⁴ Hz")
    axes[0].set_yscale("log")
    axes[0].set_xlabel("Índice del autovalor")
    axes[0].set_ylabel("|frecuencia| [Hz]")
    axes[0].set_title("Problema generalizado Kφ=λMφ")
    axes[0].legend()
    sidx = values(singular, "singularIndex")
    sval = values(singular, "normalizedSingularValue")
    axes[1].semilogy(sidx, np.maximum(sval, 1e-20), "o-", color=COLORS[2])
    axes[1].axvline(6.5, color="black", linestyle="--", linewidth=1)
    axes[1].set_xlabel("Índice singular, orden descendente")
    axes[1].set_ylabel("σ(K)/σ₁(K)")
    axes[1].set_title("Rango 6 y nulidad 6 de K elemental")
    fig.suptitle("Elemento Timoshenko 3D primitivo: 12 GDL")
    finish(fig, "04_espectro_elemento_primitivo.png")


def plot_global_rigid_modes() -> None:
    free = rows(EVIDENCE / "global_free_free_spectrum.csv")
    fixed = rows(EVIDENCE / "global_fixed_base_spectrum.csv")
    fig, axes = plt.subplots(1, 2, figsize=(11, 4.2), sharey=True)
    for ax, data, title in [
        (axes[0], free, "Libre–libre: 810 GDL"),
        (axes[1], fixed, "Base fija: 804 GDL"),
    ]:
        idx = values(data, "mode")
        freq = np.abs(values(data, "frequencyHz"))
        rigid = np.array([r["classification"] == "rigid_numerical_zero" for r in data])
        ax.scatter(idx[rigid], np.maximum(freq[rigid], 1e-12), color=COLORS[1], s=45, label="rígido")
        ax.scatter(idx[~rigid], freq[~rigid], color=COLORS[0], s=45, label="flexible")
        ax.axhline(1e-4, color="black", linestyle="--", linewidth=1)
        ax.set_yscale("log")
        ax.set_xlabel("Modo entre los 18 menores")
        ax.set_title(title)
        ax.xaxis.set_major_locator(MaxNLocator(integer=True))
    axes[0].set_ylabel("|frecuencia| [Hz]")
    axes[0].legend(loc="best")
    fig.suptitle("Espectro global: seis ceros físicos y ninguno tras fijar la base")
    finish(fig, "05_espectro_global_modos_rigidos.png")


def plot_mesh_convergence() -> None:
    data = rows(RUNS[2] / "action02_mesh_convergence.csv")
    ne = values(data, "elementCount")
    fig, axes = plt.subplots(1, 3, figsize=(13, 4.2))
    axes[0].semilogx(ne, values(data, "tipDisplacement") * 1e6, "o-", color=COLORS[0])
    axes[0].set_ylabel("Desplazamiento de punta [µm]")
    axes[0].set_title("Respuesta estática")
    axes[1].semilogx(ne, values(data, "frequency1Hz"), "o-", color=COLORS[1], label="modo 1")
    axes[1].semilogx(ne, values(data, "frequency2Hz"), "s-", color=COLORS[2], label="modo 2")
    axes[1].set_ylabel("Frecuencia [Hz]")
    axes[1].set_yscale("log")
    axes[1].set_title("Frecuencias de flexión")
    axes[1].legend()
    for key, label, color, marker in [
        ("tipRelativeError", "punta", COLORS[0], "o"),
        ("frequency1RelativeError", "f₁", COLORS[1], "s"),
        ("frequency2RelativeError", "f₂", COLORS[2], "^"),
    ]:
        axes[2].loglog(ne, values(data, key), marker + "-", color=color, label=label)
    axes[2].set_ylabel("Error relativo")
    axes[2].set_title("Error frente a solución analítica")
    axes[2].legend()
    for ax in axes:
        ax.set_xlabel("Número de elementos")
    fig.suptitle("Convergencia de una viga uniforme de 12 m: 1–64 elementos")
    finish(fig, "07_convergencia_malla_detallada.png")


def plot_subsystem_modes() -> None:
    data = rows(RUNS[2] / "action02_subsystem_modal.csv")
    groups: dict[str, list[dict[str, str]]] = defaultdict(list)
    for row in data:
        groups[row["subsystem"]].append(row)
    fig, ax = plt.subplots(figsize=(8.5, 5.1))
    translations = {"tower": "torre", "blade_1": "pala 1", "blade_2": "pala 2", "blade_3": "pala 3"}
    for i, (name, group) in enumerate(groups.items()):
        ax.plot(values(group, "mode"), values(group, "frequencyHz"), "o-", color=COLORS[i], label=translations.get(name, name))
    ax.set_xlabel("Modo aislado")
    ax.set_ylabel("Frecuencia [Hz]")
    ax.set_title("Seis primeras frecuencias de los voladizos aislados")
    ax.legend(ncol=2)
    finish(fig, "08_frecuencias_subsistemas_aislados.png")


def plot_blade_equivalence() -> None:
    data = rows(RUNS[2] / "action02_subsystem_modal.csv")
    blade_rows = [r for r in data if r["subsystem"].startswith("blade_")]
    by_blade: dict[str, list[dict[str, str]]] = defaultdict(list)
    for row in blade_rows:
        by_blade[row["subsystem"]].append(row)
    modes = sorted({int(number(r, "mode")) for r in blade_rows})
    matrix = np.array([[number(next(r for r in by_blade[b] if int(number(r, "mode")) == m), "frequencyHz") for b in sorted(by_blade)] for m in modes])
    spread = (matrix.max(axis=1) - matrix.min(axis=1)) / matrix.mean(axis=1)
    fig, axes = plt.subplots(1, 2, figsize=(11, 4.2))
    for i, blade in enumerate(sorted(by_blade)):
        axes[0].plot(modes, matrix[:, i], "o-", color=COLORS[i], label=blade.replace("blade_", "pala "))
    axes[0].set_xlabel("Modo")
    axes[0].set_ylabel("Frecuencia [Hz]")
    axes[0].set_title("Frecuencias homólogas")
    axes[0].legend()
    axes[1].semilogy(modes, spread, "o-", color=COLORS[3])
    axes[1].set_xlabel("Modo")
    axes[1].set_ylabel("Dispersión relativa")
    axes[1].set_title("Dispersión entre palas")
    fig.suptitle("Frecuencias y diferencias geométricas de las tres palas")
    finish(fig, "09_equivalencia_modal_palas.png")


def plot_constraints() -> None:
    data = rows(RUNS[3] / "action03_constraint_map.csv")
    fig = plt.figure(figsize=(8, 6))
    ax = fig.add_subplot(111, projection="3d")
    ax.scatter([0], [0], [0], s=100, color=COLORS[1], label="maestro 130")
    for i, row in enumerate(data):
        xyz = [number(row, "dx"), number(row, "dy"), number(row, "dz")]
        ax.plot([0, xyz[0]], [0, xyz[1]], [0, xyz[2]], color=COLORS[i], linewidth=2)
        ax.scatter(*xyz, s=70, color=COLORS[i])
        ax.text(*xyz, f" raíz {row['slaveNode']}", fontsize=9)
    ax.set_xlabel("Δx [m]")
    ax.set_ylabel("Δy [m]")
    ax.set_zlabel("Δz [m]")
    ax.set_title("MPC exacta: raíces de pala esclavas del rotor")
    ax.legend()
    finish(fig, "10_geometria_restricciones_mpc.png")


def plot_dof_reduction() -> None:
    data = rows(EVIDENCE / "mesh_and_dof_reduction.csv")
    mapping = {r["stage"]: number(r, "count") for r in data}
    labels = ["GDL nodales\ncompletos", "Tras MPC\nexactas", "Base fija\n(análisis)"]
    counts = [mapping["full_nodal_dofs"], mapping["independent_after_mpc"], mapping["analysis_after_fixed_base"]]
    fig, ax = plt.subplots(figsize=(8, 4.8))
    bars = ax.bar(labels, counts, color=[COLORS[0], COLORS[2], COLORS[1]], width=0.62)
    for bar, count in zip(bars, counts):
        ax.text(bar.get_x() + bar.get_width() / 2, count + 5, f"{int(count)}", ha="center", fontweight="bold")
    ax.annotate("−18 GDL dependientes\n(3 raíces × 6)", xy=(1, counts[1]), xytext=(0.25, 730), arrowprops={"arrowstyle": "->"})
    ax.annotate("−6 GDL de apoyo", xy=(2, counts[2]), xytext=(1.25, 665), arrowprops={"arrowstyle": "->"})
    ax.set_ylim(0, 900)
    ax.set_ylabel("Número de coordenadas")
    ax.set_title("Reducción cinemática sin penalizaciones")
    finish(fig, "11_reduccion_grados_libertad.png")


def plot_mass_breakdown() -> None:
    components = rows(RUNS[2] / "action02_component_summary.csv")
    bodies = rows(RUNS[4] / "action04_body_matrices.csv")
    names = [r["component"].replace("blade_", "pala ").replace("tower", "torre").replace("transition", "transición") for r in components]
    masses = list(values(components, "distributedMassKg") / 1000)
    names += ["góndola", "cubo"]
    masses += [number(bodies[0], "massKg") / 1000, number(bodies[1], "massKg") / 1000]
    fig, axes = plt.subplots(1, 2, figsize=(11, 4.5))
    bars = axes[0].bar(names, masses, color=(COLORS * 2)[: len(names)])
    axes[0].set_ylabel("Masa [t]")
    axes[0].tick_params(axis="x", rotation=35)
    axes[0].set_title("Contribuciones por componente")
    for bar, val in zip(bars, masses):
        axes[0].text(bar.get_x() + bar.get_width() / 2, val, f"{val:.1f}", ha="center", va="bottom", fontsize=8)
    flexible = sum(masses[:5])
    rigid = sum(masses[5:])
    axes[1].pie([flexible, rigid], labels=["distribuida", "cuerpos rígidos"], autopct="%1.1f%%", colors=[COLORS[0], COLORS[1]], startangle=90)
    axes[1].set_title(f"Masa total = {flexible + rigid:.1f} t")
    fig.suptitle("Distribución de masa del modelo aceptado")
    finish(fig, "12_descomposicion_masa.png")


def plot_mass_formulations() -> None:
    data = rows(RUNS[5] / "action05_modal_comparison.csv")
    mode = values(data, "mode")
    fc = values(data, "consistentFrequencyHz")
    fh = values(data, "hrzFrequencyHz")
    diff = np.abs(values(data, "frequencyRelativeDifference")) * 100
    mac = values(data, "matchedMAC")
    fig, axes = plt.subplots(1, 2, figsize=(11, 4.2))
    axes[0].plot(mode, fc, "o-", color=COLORS[0], label="consistente")
    axes[0].plot(mode, fh, "s--", color=COLORS[1], label="HRZ")
    axes[0].set_xlabel("Modo de torre")
    axes[0].set_ylabel("Frecuencia [Hz]")
    axes[0].set_title("Sensibilidad modal")
    axes[0].legend()
    axes[1].bar(mode, diff, width=0.58, color=COLORS[1], alpha=0.75, label="|Δf| [%]")
    axes[1].set_xlabel("Modo")
    axes[1].set_ylabel("|Δf| [%]", color=COLORS[1])
    axes[1].tick_params(axis="y", labelcolor=COLORS[1])
    mac_axis = axes[1].twinx()
    mac_axis.plot(mode, mac, "o-", color=COLORS[2], label="MAC")
    mac_axis.set_ylabel("MAC", color=COLORS[2])
    mac_axis.tick_params(axis="y", labelcolor=COLORS[2])
    mac_axis.set_ylim(0.88, 1.01)
    axes[1].set_title("Diferencia de frecuencia y asociación modal")
    handles1, labels1 = axes[1].get_legend_handles_labels()
    handles2, labels2 = mac_axis.get_legend_handles_labels()
    axes[1].legend(handles1 + handles2, labels1 + labels2, loc="best")
    fig.suptitle("Masa consistente de producción frente a HRZ opcional")
    finish(fig, "13_comparacion_masa_consistente_hrz.png")


def plot_equilibrium() -> None:
    data = rows(RUNS[6] / "action06_equilibrium.csv")
    rpm = values(data, "speedRPM")
    fig, axes = plt.subplots(1, 2, figsize=(10.5, 4.3))
    panels = [
        ("maximumDisplacement", "Desplazamiento máximo [m]", "Deformación de equilibrio", 1.0),
        ("centrifugalLoadNorm", "Norma centrífuga [MN]", "Carga proporcional a Ω²", 1e-6),
    ]
    for ax, (key, ylabel, title, scale) in zip(axes, panels):
        ax.plot(rpm, values(data, key) * scale, "o-", color=COLORS[0])
        ax.set_xlabel("Velocidad [RPM]")
        ax.set_ylabel(ylabel)
        ax.set_title(title)
    fig.suptitle("Resultado del equilibrio corrotacional a 0, 6 y 12 RPM")
    finish(fig, "14_equilibrio_por_velocidad.png")


def plot_axial_forces() -> None:
    data = rows(RUNS[6] / "action06_axial_forces.csv")
    components = ["tower", "blade", "transition"]
    titles = ["Torre", "Palas", "Transición"]
    fig, axes = plt.subplots(3, 1, figsize=(10.5, 9), sharex=False)
    for ax, component, title in zip(axes, components, titles):
        subset = [r for r in data if r["component"] == component]
        for i, rpm in enumerate(sorted({number(r, "speedRPM") for r in subset})):
            group = [r for r in subset if number(r, "speedRPM") == rpm]
            ax.plot(values(group, "elementId"), values(group, "totalAxialN") * 1e-6, ".-", color=COLORS[i], label=f"{rpm:g} RPM")
        ax.axhline(0, color="black", linewidth=0.8)
        ax.set_ylabel("Axial total [MN]")
        ax.set_title(title)
        ax.legend(ncol=3)
    axes[-1].set_xlabel("ID de elemento heredado")
    fig.suptitle("Fuerzas axiales: gravedad más incremento centrífugo")
    finish(fig, "15_fuerzas_axiales_equilibrio.png")


def plot_gyroscopy() -> None:
    operating = rows(RUNS[7] / "action07_operating_points.csv")
    rpm = values(operating, "speedRPM")
    fig, ax = plt.subplots(figsize=(8.8, 4.8))
    ax.plot(rpm, values(operating, "normG") * 1e-6, "o-", color=COLORS[0], label="total")
    ax.plot(rpm, values(operating, "distributedGyroNorm") * 1e-6, "s--", color=COLORS[2], label="palas distribuidas")
    ax.plot(rpm, values(operating, "rigidGyroNorm") * 1e-6, "^--", color=COLORS[1], label="cubo rígido")
    ax.set_xlabel("Velocidad [RPM]")
    ax.set_ylabel(r"$\|\mathbf{G}\|_F$ [$10^6$]")
    ax.set_title("Composición del operador giroscópico")
    ax.legend()
    finish(fig, "16_operador_giroscopico.png")


def plot_rayleigh() -> None:
    data = rows(RUNS[7] / "action07_damping.csv")[0]
    alpha = number(data, "alpha")
    beta = number(data, "beta")
    f = np.logspace(-2, 1.2, 400)
    omega = 2 * np.pi * f
    zeta = alpha / (2 * omega) + beta * omega / 2
    targets_f = np.array([number(data, "frequency1"), number(data, "frequency2")])
    targets_z = np.array([number(data, "zeta1"), number(data, "zeta2")])
    fig, ax = plt.subplots(figsize=(8.5, 4.8))
    ax.semilogx(f, 100 * zeta, color=COLORS[0], linewidth=2)
    ax.scatter(targets_f, 100 * targets_z, color=COLORS[1], s=65, zorder=3, label="objetivos")
    ax.set_xlabel("Frecuencia [Hz]")
    ax.set_ylabel("Amortiguamiento modal [%]")
    ax.set_title("Curva de Rayleigh: αM + βKe")
    ax.legend()
    finish(fig, "17_amortiguamiento_rayleigh.png")


def plot_aerodynamic_benchmark() -> None:
    data = rows(RUNS[7] / "action07_aerodynamic_benchmark.csv")[0]
    names = ["fuerza", "Ka", "Ca"]
    errors = [max(number(data, "forceError"), 1e-18), number(data, "positionError"), number(data, "velocityError")]
    fig, ax = plt.subplots(figsize=(8.5, 4.8))
    bars = ax.bar(names, errors, color=[COLORS[0], COLORS[1], COLORS[2]])
    ax.set_yscale("log")
    ax.set_ylabel("Error relativo")
    ax.set_title("Diferencias finitas centrales para tangentes aerodinámicas")
    for bar, value in zip(bars, errors):
        ax.text(bar.get_x() + bar.get_width() / 2, value * 1.25, f"{value:.2e}", ha="center", fontsize=9)
    ax.text(0.98, 0.94, f"Razón h/(h/2) = {number(data, 'convergenceRatio'):.6f}\n||parte no simétrica|| = {number(data, 'nonsymmetry'):.3f}", transform=ax.transAxes, ha="right", va="top")
    finish(fig, "18_benchmark_tangentes_aerodinamicas.png")


def plot_campbell() -> None:
    data = rows(RUNS[8] / "action08_campbell.csv")
    branches = sorted({int(number(r, "branch")) for r in data})
    fig, ax = plt.subplots(figsize=(10.5, 6.1))
    for branch in branches:
        group = [r for r in data if int(number(r, "branch")) == branch]
        ax.plot(
            values(group, "speedRPM"),
            values(group, "frequencyHz"),
            "o-",
            linewidth=1.1,
            markersize=3.4,
            label=f"Rama {branch}",
        )
    rpm = np.linspace(0, 12, 200)
    ax.plot(rpm, rpm / 60, "k--", linewidth=1.7, label="1P")
    ax.plot(rpm, 3 * rpm / 60, "k:", linewidth=1.9, label="3P")
    ax.set_xlabel("Velocidad del rotor [RPM]")
    ax.set_ylabel("Frecuencia amortiguada [Hz]")
    ax.set_xlim(0, 12)
    ax.set_ylim(0, 1.7)
    ax.set_title("Diagrama de Campbell: 12 ramas y excitaciones 1P/3P")
    ax.legend(ncol=4, fontsize=7)
    finish(fig, "19_diagrama_campbell.png")


def plot_tracking() -> None:
    data = rows(RUNS[8] / "action08_tracking.csv")
    speeds = sorted({number(r, "speedRPM") for r in data})
    branches = sorted({int(number(r, "branch")) for r in data})
    fields = [("effectiveMAC", "MAC efectivo"), ("individualMAC", "MAC individual")]
    fig, axes = plt.subplots(1, 2, figsize=(12, 4.8), sharey=True)
    for ax, (field, title) in zip(axes, fields):
        grid = np.full((len(branches), len(speeds)), np.nan)
        for row in data:
            grid[branches.index(int(number(row, "branch"))), speeds.index(number(row, "speedRPM"))] = number(row, field)
        image = ax.imshow(grid, origin="lower", aspect="auto", vmin=0.4, vmax=1.0, cmap="viridis", extent=[min(speeds), max(speeds), min(branches) - 0.5, max(branches) + 0.5])
        ax.set_xlabel("Velocidad [RPM]")
        ax.set_title(title)
        fig.colorbar(image, ax=ax, shrink=0.9)
    axes[0].set_ylabel("Rama")
    fig.suptitle("Calidad del seguimiento Campbell: MAC individual o subespacial")
    finish(fig, "20_seguimiento_mac_campbell.png")


def plot_qep() -> None:
    roots = rows(RUNS[8] / "action08_qep.csv")
    campbell = rows(RUNS[8] / "action08_campbell.csv")
    speeds = sorted({number(r, "speedRPM") for r in campbell})
    fig, axes = plt.subplots(1, 3, figsize=(13, 4.1))
    for branch in sorted({int(number(r, "branch")) for r in campbell}):
        group = [r for r in campbell if int(number(r, "branch")) == branch]
        axes[0].plot(
            values(group, "speedRPM"),
            values(group, "frequencyHz"),
            "o-",
            linewidth=0.9,
            markersize=2.8,
            label=f"R{branch}",
        )
    axes[0].set_xlabel("Velocidad [RPM]")
    axes[0].set_ylabel(r"$f_d$ [Hz]")
    axes[0].set_title("Frecuencias amortiguadas")
    axes[0].legend(ncol=3, fontsize=6)
    for rpm in speeds:
        group = [r for r in campbell if number(r, "speedRPM") == rpm]
        axes[1].plot(
            values(group, "frequencyHz"),
            100 * values(group, "dampingRatio"),
            "o",
            color=plt.cm.viridis(rpm / max(speeds)),
            markersize=3.5,
        )
    axes[1].set_xlabel(r"$f_d$ [Hz]")
    axes[1].set_ylabel(r"$\zeta$ [%]")
    axes[1].set_title("Amortiguamiento modal")
    scatter = axes[2].scatter(
        values(roots, "realLambda"),
        values(roots, "imagLambda"),
        c=values(roots, "speedRPM"),
        cmap="viridis",
        s=20,
    )
    axes[2].axvline(0, color="black", linewidth=0.8)
    axes[2].set_xlabel(r"Re$(s)$ [s$^{-1}$]")
    axes[2].set_ylabel(r"Im$(s)$ [rad/s]")
    axes[2].set_title("Plano complejo QEP")
    fig.colorbar(scatter, ax=axes[2], label="Velocidad [RPM]")
    fig.suptitle("Resultados del problema cuadrático de autovalores")
    finish(fig, "21_calidad_qep.png")


def plot_mbc() -> None:
    data = rows(RUNS[8] / "action08_mbc_transforms.csv")
    azimuth = values(data, "azimuths") * 180 / np.pi
    fig, ax = plt.subplots(figsize=(8.5, 4.8))
    ax.semilogy(azimuth, values(data, "inverseError"), "o-", color=COLORS[0], label="P⁻¹P")
    ax.semilogy(azimuth, values(data, "frameError"), "s-", color=COLORS[1], label="marcos H")
    ax.set_xlabel("Azimut [°]")
    ax.set_ylabel("Error relativo")
    ax.set_title("Condicionamiento de la transformación MBC compuesta")
    ax.legend()
    finish(fig, "22_errores_transformacion_mbc.png")


def plot_ground_motion() -> None:
    data = rows(RUNS[9] / "action09_ground_motion.csv")
    t = values(data, "time_s")
    fig, axes = plt.subplots(3, 1, figsize=(10.5, 8), sharex=True)
    panels = [
        ("ag_1_mps2", "ag_2_mps2", "Aceleración [m/s²]"),
        ("vg_1_mps", "vg_2_mps", "Velocidad [m/s]"),
        ("ug_1_m", "ug_2_m", "Desplazamiento [m]"),
    ]
    for ax, (key1, key2, ylabel) in zip(axes, panels):
        ax.plot(t, values(data, key1), color=COLORS[0], label="dirección x")
        ax.plot(t, values(data, key2), color=COLORS[1], label="dirección y")
        ax.set_ylabel(ylabel)
        ax.legend(ncol=2)
    axes[-1].set_xlabel("Tiempo [s]")
    fig.suptitle("Entrada sísmica sintética")
    finish(fig, "23_movimiento_sismico_entrada.png")


def plot_response_history() -> None:
    history = rows(RUNS[9] / "time_history.csv")
    ground = rows(RUNS[9] / "action09_ground_motion.csv")
    t = values(history, "time_s")
    fig, axes = plt.subplots(2, 1, figsize=(10.5, 7.1), sharex=True)
    for i, node in enumerate([129, 130, 56, 92, 128]):
        axes[0].plot(
            t,
            1000 * values(history, f"relative_uy_node{node}_m"),
            linewidth=1.25,
            label=f"nodo {node}",
            color=plt.cm.viridis(i / 4),
        )
    axes[0].set_ylabel(r"$u_y$ relativo [mm]")
    axes[0].set_title("Góndola, rotor y puntas de pala")
    axes[0].legend(ncol=3)
    axes[1].plot(
        values(ground, "time_s"),
        values(ground, "ag_1_mps2"),
        color=COLORS[0],
        label="terreno x",
    )
    axes[1].plot(
        values(ground, "time_s"),
        values(ground, "ag_2_mps2"),
        color=COLORS[1],
        label="terreno y",
    )
    axes[1].set_xlabel("Tiempo [s]")
    axes[1].set_ylabel(r"$a_g$ [m/s²]")
    axes[1].set_title("Aceleración aplicada")
    axes[1].legend(ncol=2)
    fig.suptitle("Respuesta relativa del modelo rotante a 12 RPM")
    finish(fig, "24_respuesta_sismica.png")


def plot_response_extrema() -> None:
    data = rows(RUNS[9] / "action09_response_extrema.csv")
    selected = [r for r in data if r["component"] == "uy" and int(number(r, "nodeId")) != 1]
    nodes = sorted({int(number(r, "nodeId")) for r in selected})
    cases = sorted({r["caseName"] for r in selected})
    fig, axes = plt.subplots(1, 2, figsize=(12, 4.5))
    width = 0.36
    x = np.arange(len(nodes))
    for i, case in enumerate(cases):
        group = {int(number(r, "nodeId")): r for r in selected if r["caseName"] == case}
        case_label = "12 RPM" if case == "rotating" else "0 RPM"
        axes[0].bar(x + (i - 0.5) * width, [number(group[n], "maximumAbsolute") * 1000 for n in nodes], width=width, color=COLORS[i], label=case_label)
        axes[1].bar(x + (i - 0.5) * width, [number(group[n], "maximumAbsAcceleration") for n in nodes], width=width, color=COLORS[i], label=case_label)
    for ax in axes:
        ax.set_xticks(x, [str(n) for n in nodes])
        ax.set_xlabel("Nodo, componente uy")
        ax.legend()
    axes[0].set_ylabel("|u|max [mm]")
    axes[0].set_title("Desplazamiento relativo")
    axes[1].set_ylabel("|a absoluta|max [m/s²]")
    axes[1].set_title("Aceleración absoluta")
    fig.suptitle("Envolventes sísmicas a 0 y 12 RPM")
    finish(fig, "25_extremos_respuesta_sismica.png")


def plot_newmark_convergence() -> None:
    sdof = rows(RUNS[9] / "action09_sdof_benchmark.csv")
    full = rows(RUNS[9] / "action09_time_convergence.csv")
    fig, axes = plt.subplots(1, 2, figsize=(11, 4.3))
    dt = values(sdof, "dt_s")
    err = values(sdof, "maximumDisplacementError")
    axes[0].loglog(dt, err, "o-", color=COLORS[0], label="error SDOF")
    reference = err[-1] * (dt / dt[-1]) ** 2
    axes[0].loglog(dt, reference, "--", color="black", label="pendiente 2")
    axes[0].invert_xaxis()
    axes[0].set_xlabel("Δt [s]")
    axes[0].set_ylabel("Error máximo")
    axes[0].set_title("Oscilador analítico de referencia")
    axes[0].legend()
    dtf = values(full, "dt_s")
    wave = values(full, "relativeWaveformDifferenceToNext")
    finite = np.isfinite(wave)
    axes[1].loglog(dtf[finite], wave[finite], "o-", color=COLORS[1], label="diferencia de forma")
    ref = wave[finite][-1] * (dtf[finite] / dtf[finite][-1]) ** 2
    axes[1].loglog(dtf[finite], ref, "--", color="black", label="pendiente 2")
    axes[1].axhline(1e-3, color=COLORS[2], linestyle=":", label="criterio esperado")
    axes[1].invert_xaxis()
    axes[1].set_xlabel("Δt [s]")
    axes[1].set_ylabel("Diferencia relativa")
    axes[1].set_title("Modelo completo, nodo 129 uy")
    axes[1].legend()
    fig.suptitle("Convergencia temporal de Newmark: segundo orden")
    finish(fig, "26_convergencia_temporal_newmark.png")


def plot_reactions() -> None:
    data = rows(RUNS[9] / "action09_reactions.csv")
    labels = [r["component"] for r in data]
    vals = values(data, "maximumAbsolute")
    scale = np.array([1e-3 if r["unit"] == "N" else 1e-6 for r in data])
    scaled = vals * scale
    fig, ax = plt.subplots(figsize=(8.5, 4.8))
    bars = ax.bar(labels, scaled, color=COLORS[: len(labels)])
    ax.set_yscale("log")
    ax.set_ylabel("kN para fuerzas; MN·m para momentos")
    ax.set_title("Envolvente de reacciones sísmicas en el nodo 1")
    for bar, val in zip(bars, scaled):
        ax.text(bar.get_x() + bar.get_width() / 2, val * 1.08, f"{val:.3g}", ha="center", fontsize=8)
    finish(fig, "27_reacciones_base.png")


def plot_element_force_envelopes() -> None:
    data = rows(RUNS[9] / "action09_element_forces.csv")
    components = ["tower", "blade", "transition"]
    fields = ["maximumAbsAxial", "maximumAbsShear2", "maximumAbsShear3", "maximumAbsTorsion", "maximumAbsMoment2", "maximumAbsMoment3"]
    labels = ["N", "V₂", "V₃", "T", "M₂", "M₃"]
    matrix = np.zeros((len(components), len(fields)))
    for i, component in enumerate(components):
        group = [r for r in data if r["component"] == component]
        for j, field in enumerate(fields):
            matrix[i, j] = np.nanmax(values(group, field))
    fig, ax = plt.subplots(figsize=(10, 4.5))
    image = ax.imshow(matrix, aspect="auto", cmap="magma", norm=LogNorm(vmin=max(matrix.min(), 1), vmax=matrix.max()))
    ax.set_xticks(range(len(fields)), labels)
    ax.set_yticks(range(len(components)), ["torre", "palas", "transición"])
    ax.set_title("Máximo absoluto por familia de fuerza incremental")
    for i in range(matrix.shape[0]):
        for j in range(matrix.shape[1]):
            ax.text(j, i, f"{matrix[i, j]:.2e}", ha="center", va="center", color="white", fontsize=8)
    fig.colorbar(image, ax=ax, label="Magnitud [N o N·m]")
    finish(fig, "28_envolventes_fuerzas_elementales.png")


def plot_validation_coverage() -> None:
    counts = []
    passes = []
    for action in range(2, 10):
        data = rows(RUNS[action] / f"action{action:02d}_validation.csv")
        counts.append(len(data))
        passes.append(sum(str(r.get("pass", "")).lower() in {"1", "true"} for r in data))
    counts.append(len(rows(RUNS[10] / "action10_requirement_matrix.csv")))
    passes.append(sum(r["status"] == "passed" for r in rows(RUNS[10] / "action10_requirement_matrix.csv")))
    actions = np.arange(2, 11)
    fig, ax = plt.subplots(figsize=(9.5, 4.8))
    ax.bar(actions, counts, color=COLORS[0], label="evaluadas")
    ax.bar(actions, passes, color=COLORS[2], alpha=0.8, label="aprobadas")
    ax.set_yscale("log")
    ax.set_xticks(actions)
    ax.set_xlabel("Acción")
    ax.set_ylabel("Número de puertas (escala log)")
    ax.set_title("Cobertura especializada e integral")
    ax.legend()
    for x, total in zip(actions, counts):
        ax.text(x, total * 1.08, str(total), ha="center", fontsize=8)
    finish(fig, "29_cobertura_validacion.png")


def plot_action10_audit() -> None:
    evidence = rows(RUNS[10] / "action10_evidence.csv")
    artifacts = rows(RUNS[10] / "action10_artifacts.csv")
    actions = [int(number(r, "action")) for r in evidence]
    suite = [number(r, "suitePassed") for r in evidence]
    complete = [number(next(a for a in artifacts if int(number(a, "action")) == action), "complete") for action in actions]
    hashes = [number(next(a for a in artifacts if int(number(a, "action")) == action), "hashVerified") for action in actions]
    fig, ax = plt.subplots(figsize=(9.5, 4.8))
    x = np.arange(len(actions))
    width = 0.25
    ax.bar(x - width, suite, width, color=COLORS[0], label="suite aprobada")
    ax.bar(x, complete, width, color=COLORS[2], label="artefacto completo")
    ax.bar(x + width, hashes, width, color=COLORS[1], label="hash verificado")
    ax.set_xticks(x, [str(a) for a in actions])
    ax.set_ylim(0, 1.15)
    ax.set_xlabel("Acción recargada")
    ax.set_ylabel("Estado binario")
    ax.set_title("Recarga independiente de ocho corridas canónicas")
    ax.legend(ncol=3)
    finish(fig, "30_auditoria_artefactos_action10.png")


def plot_matrix_checks() -> None:
    data = rows(RUNS[10] / "action10_matrix_properties.csv")
    operators = ["M", "C", "D", "G", "Ke", "Kg", "KOmega", "Kaero", "Caero", "K", "Tc"]
    counts = Counter()
    for row in data:
        tokens = re.split(r"[.\[\]()]+", row["name"])
        for op in operators:
            if op in tokens:
                counts[op] += 1
                break
    labels = [op for op in operators if counts[op] > 0]
    vals = [counts[op] for op in labels]
    fig, ax = plt.subplots(figsize=(9.5, 5))
    bars = ax.barh(labels, vals, color=COLORS[0])
    ax.set_xlabel("Comprobaciones aprobadas")
    ax.set_title("620 propiedades matriciales agrupadas por operador")
    for bar, val in zip(bars, vals):
        ax.text(val + 0.5, bar.get_y() + bar.get_height() / 2, str(val), va="center", fontsize=8)
    finish(fig, "32_comprobaciones_por_operador.png")


def plot_requirement_phases() -> None:
    data = rows(RUNS[10] / "action10_requirement_matrix.csv")
    phases = [phase for phase in ["preflight", "postflight"] if any(r["phase"] == phase for r in data)]
    statuses = ["passed", "unverified", "failed", "not_applicable"]
    fig, ax = plt.subplots(figsize=(8.5, 4.8))
    bottom = np.zeros(len(phases))
    for i, status in enumerate(statuses):
        vals = np.array([sum(r["phase"] == phase and r["status"] == status for r in data) for phase in phases])
        ax.bar(phases, vals, bottom=bottom, color=COLORS[i], label=status)
        bottom += vals
    ax.set_ylabel("Requisitos")
    ax.set_title("Matriz integral por fase y estado")
    ax.legend()
    for i, total in enumerate(bottom):
        ax.text(i, total + 2, str(int(total)), ha="center")
    finish(fig, "33_requisitos_integrales_por_fase.png")


def main() -> None:
    copy_canonical_figures()
    plot_mesh_topology()
    plot_primitive_spectrum()
    plot_global_rigid_modes()
    plot_mesh_convergence()
    plot_subsystem_modes()
    plot_blade_equivalence()
    plot_constraints()
    plot_dof_reduction()
    plot_mass_breakdown()
    plot_mass_formulations()
    plot_equilibrium()
    plot_axial_forces()
    plot_gyroscopy()
    plot_rayleigh()
    plot_aerodynamic_benchmark()
    plot_campbell()
    plot_tracking()
    plot_qep()
    plot_mbc()
    plot_ground_motion()
    plot_response_history()
    plot_response_extrema()
    plot_newmark_convergence()
    plot_reactions()
    plot_element_force_envelopes()
    plot_validation_coverage()
    plot_action10_audit()
    plot_matrix_checks()
    plot_requirement_phases()
    print(f"Generated {len(list(OUT.glob('*.png')))} figures in {OUT}")


if __name__ == "__main__":
    main()
