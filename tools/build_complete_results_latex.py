#!/usr/bin/env python3
"""Generate the comprehensive results report as native LaTeX in MECOM style.

The technical content lives in ``docs/resultados_integrales/INFORME_RESULTADOS_COMPLETOS.md``.
This builder converts the results source to a readable ``.tex`` file while preserving
display mathematics, tables, code fragments and scientific figures.
"""

from __future__ import annotations

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "docs" / "resultados_integrales" / "INFORME_RESULTADOS_COMPLETOS.md"
LATEX_DIR = ROOT / "docs" / "resultados_integrales" / "latex"
OUTPUT = LATEX_DIR / "INFORME_RESULTADOS_COMPLETOS_MECOM.tex"


PREAMBLE = r"""\documentclass[oneside,a4paper,spanish,links]{amca}

\usepackage{graphicx}
\usepackage{amsmath,amssymb,bm}
\usepackage{booktabs,array,longtable,tabularx}
\usepackage{fancyvrb}
\usepackage[section]{placeins}
\usepackage{xurl}
\usepackage{microtype}

\graphicspath{{../figures/}}
\setcounter{tocdepth}{2}
\setcounter{secnumdepth}{3}
\emergencystretch=2em
\renewcommand{\contentsname}{CONTENIDO}
\renewcommand{\listfigurename}{ÍNDICE DE FIGURAS}
\newcolumntype{Y}{>{\raggedright\arraybackslash}X}

\title{INFORME INTEGRAL DE RESULTADOS DEL MODELO ESTRUCTURAL,\\
ROTODINÁMICO Y SÍSMICO DE UN AEROGENERADOR}
\englishtitle{COMPREHENSIVE RESULTS REPORT FOR THE STRUCTURAL,\\
ROTORDYNAMIC AND SEISMIC MODEL OF A WIND TURBINE}
\author{Nicolás A. Useche Castillo}
\affil{Departamento de Ingeniería Mecánica, Universidad de los Andes, Bogotá D.C., Colombia,\\
n.useche@uniandes.edu.co}

\hypersetup{
  pdftitle={Informe integral de resultados del modelo estructural, rotodinámico y sísmico},
  pdfauthor={Nicolás A. Useche Castillo},
  colorlinks=true,
  linkcolor=blue,
  citecolor=blue,
  urlcolor=blue
}

\begin{document}
\vspace{3cm}
\maketitle

\begin{keywords}
turbina eólica, elementos finitos, viga de Timoshenko,
conversión de mallas, modos rígidos, frecuencias naturales, giroscopía, Campbell,
transformación multiblade, excitación sísmica, problema de autovalores.
\end{keywords}

\begin{abstract}
Este informe presenta e interpreta los resultados del modelo estructural,
rotodinámico y sísmico de un aerogenerador. Se describe la conversión de la malla
heredada, la formulación del elemento de viga de Timoshenko tridimensional, la
condensación por restricciones multipunto y la incorporación de masas rígidas. El
espectro del elemento libre aislado contiene exactamente seis modos de cuerpo rígido y
seis frecuencias naturales deformacionales; el ensamblaje global libre conserva seis
modos rígidos, mientras que la base fija elimina los modos nulos. Se interpretan además
el equilibrio con gravedad y centrifugación, la giroscopía, el amortiguamiento de
Rayleigh, la inserción de cargas aerodinámicas, la transformación multiblade, el problema
cuadrático de autovalores, el diagrama de Campbell y la respuesta sísmica integrada con
Newmark. Cada resultado se acompaña de su error relativo o criterio esperado. Los
parámetros de tren, amortiguamiento y excitación sísmica empleados son casos de
referencia numérica; no constituyen una predicción calibrada de una turbina comercial.

\vspace{6pt}
\noindent\textbf{Abstract.} This report presents and interprets the results of a
structural, rotordynamic and seismic wind-turbine model. It describes legacy-mesh
conversion, the three-dimensional Timoshenko beam formulation, exact multi-point
condensation and rigid-mass insertion. The isolated free element contains exactly six
rigid-body modes and six positive deformational natural frequencies; the complete free
assembly retains six global rigid-body modes, whereas the fixed-base model has no null
modes. The report also explains equilibrium under gravity and centrifugal loading,
gyroscopic coupling, Rayleigh damping, aerodynamic-load insertion, multiblade
transformation, the quadratic eigenvalue problem, Campbell tracking and Newmark seismic
integration. Every result is reported together with its relative error or expected
numerical target. Drivetrain, damping and earthquake inputs are numerical reference
cases rather than a calibrated commercial-turbine prediction.
\end{abstract}

\tableofcontents
\clearpage
\listoffigures
\clearpage

\section*{NOMENCLATURA Y CONVENCIONES}
\addcontentsline{toc}{section}{Nomenclatura y convenciones}
\begin{center}
\small
\begin{tabularx}{\textwidth}{@{}p{0.19\textwidth}Y@{}}
\toprule
\textbf{Símbolo} & \textbf{Definición} \\
\midrule
$\bm q$, $\dot{\bm q}$, $\ddot{\bm q}$ & desplazamiento, velocidad y aceleración generalizados \\
$\bm M$ & matriz de masa consistente \\
$\bm C_s$, $\bm C_a$, $\bm G$ & amortiguamiento estructural, amortiguamiento aerodinámico y matriz giroscópica \\
$\bm K_e$, $\bm K_g$, $\bm K_\Omega$, $\bm K_a$ & rigidez elástica, geométrica, centrífuga y tangente aerodinámica \\
$\bm T_c$, $\bm P$ & transformación de restricciones y transformación multiblade compuesta \\
$\bm R_{\mathrm{full}}$, $\bm\Gamma_{\mathrm{eff}}$, $\bm\Gamma_{\mathrm{kin}}$ & influencia del terreno en coordenadas completas, efectiva y cinemática \\
$\bm f_a$, $\bm K_a$, $\bm C_a$ & carga aerodinámica y sus tangentes respecto a posición y velocidad \\
$\mu$, $s$, $\omega$, $f$ & autovalor conservativo, raíz temporal compleja, frecuencia angular y frecuencia cíclica \\
$\Omega$, $\psi$ & velocidad angular y azimut del rotor \\
$\bm D$, $\bm K$ & operador total de velocidad y rigidez tangente del punto operativo \\
MPC / MBC & restricción multipunto / transformación multiblade \\
QEP / MAC & problema cuadrático de autovalores / criterio de correlación modal \\
\bottomrule
\end{tabularx}
\end{center}

Salvo indicación contraria, todas las magnitudes se expresan en unidades SI. La
formulación de vigas y la comprobación del límite esbelto siguen la base clásica
de elementos finitos \citep{reddy2006}; la dinámica rotatoria y giroscópica se
interpreta con \citet{meirovitch1997}, \citet{geradin2015}, \citet{yoo1995} y
\citet{chung2002}; la cinemática rígido--flexible con \citet{shabana2013}; la
transformación multiblade con \citet{bir2008}; y la integración temporal con la
familia de métodos descrita por \citet{newmark1971}.

\clearpage
"""


POSTAMBLE = r"""
\FloatBarrier
\bibliography{MECOM_2026_Useche}
\end{document}
"""


def latex_escape(text: str) -> str:
    replacements = {
        "\\": r"\textbackslash{}",
        "&": r"\&",
        "%": r"\%",
        "#": r"\#",
        "_": r"\_",
        "{": r"\{",
        "}": r"\}",
        "~": r"\textasciitilde{}",
        "^": r"\textasciicircum{}",
        "–": "--",
        "−": "$-$",
        "·": r"\,$\cdot$\,",
        "²": r"$^2$",
        "³": r"$^3$",
        "→": r"$\rightarrow$",
        "∈": r"$\in$",
        "“": "``",
        "”": "''",
    }
    return "".join(replacements.get(ch, ch) for ch in text)


def inline(text: str) -> str:
    """Convert the small Markdown inline subset used by the audited report."""
    text = text.replace("<br>", "\n").replace("<br/>", "\n")
    tokens: list[str] = []

    def protect(value: str) -> str:
        marker = f"ZZTOKEN{len(tokens)}ZZ"
        tokens.append(value)
        return marker

    def code_repl(match: re.Match[str]) -> str:
        raw = (
            match.group(1)
            .replace("–", "-")
            .replace("−", "-")
            .replace("→", "->")
            .replace("∈", " in ")
            .replace("“", '"')
            .replace("”", '"')
        )
        if len(raw) > 26 or "/" in raw or "_" in raw:
            return protect(r"\nolinkurl{" + raw + "}")
        return protect(r"\texttt{" + latex_escape(raw) + r"}\allowbreak{}")

    text = re.sub(r"`([^`]+)`", code_repl, text)
    text = re.sub(
        r"\$([^$]+)\$",
        lambda m: protect("$" + m.group(1) + "$"),
        text,
    )

    def link_repl(match: re.Match[str]) -> str:
        label, target = match.group(1), match.group(2)
        if re.fullmatch(r"ZZTOKEN\d+ZZ", label):
            return protect(label)
        if target.startswith(("http://", "https://")):
            return protect(r"\href{" + target + "}{" + inline(label) + "}")
        return protect(r"\nolinkurl{" + label.strip("`") + "}")

    text = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", link_repl, text)
    text = re.sub(
        r"\*\*([^*]+)\*\*",
        lambda m: protect(r"\textbf{" + inline(m.group(1)) + "}"),
        text,
    )
    text = re.sub(
        r"(?<!\*)\*([^*]+)\*(?!\*)",
        lambda m: protect(r"\emph{" + inline(m.group(1)) + "}"),
        text,
    )
    converted = latex_escape(text).replace("\n", r"\newline ")
    for _ in range(len(tokens) + 1):
        previous = converted
        for idx, value in enumerate(tokens):
            converted = converted.replace(f"ZZTOKEN{idx}ZZ", value)
        if converted == previous:
            break
    return converted


def strip_heading_number(text: str) -> str:
    return re.sub(r"^\d+(?:\.\d+)*\.?\s+", "", text).strip()


def table_block(rows: list[list[str]]) -> list[str]:
    header, data = rows[0], rows[1:]
    ncols = len(header)
    size = r"\scriptsize" if ncols >= 5 else r"\small"
    out = [r"\begingroup", size, r"\renewcommand{\arraystretch}{1.16}"]
    if len(data) > 18:
        if ncols == 3:
            spec = r"@{}p{0.07\textwidth}p{0.41\textwidth}p{0.44\textwidth}@{}"
        elif ncols == 2:
            spec = r"@{}p{0.31\textwidth}p{0.63\textwidth}@{}"
        else:
            width = max(0.12, 0.92 / ncols)
            spec = "@{}" + "".join(f"p{{{width:.3f}\\textwidth}}" for _ in range(ncols)) + "@{}"
        out.extend([rf"\begin{{longtable}}{{{spec}}}", r"\toprule"])
        out.append(" & ".join(r"\textbf{" + inline(cell) + "}" for cell in header) + r" \\")
        out.extend([r"\midrule", r"\endfirsthead", r"\toprule"])
        out.append(" & ".join(r"\textbf{" + inline(cell) + "}" for cell in header) + r" \\")
        out.extend([r"\midrule", r"\endhead", r"\midrule", rf"\multicolumn{{{ncols}}}{{r}}{{\emph{{Continúa en la página siguiente}}}} \\", r"\endfoot", r"\bottomrule", r"\endlastfoot"])
        for row in data:
            padded = row + [""] * (ncols - len(row))
            out.append(" & ".join(inline(cell) for cell in padded[:ncols]) + r" \\")
        out.append(r"\end{longtable}")
    else:
        spec = "@{}" + "Y" * ncols + "@{}"
        out.extend([r"\begin{center}", rf"\begin{{tabularx}}{{\textwidth}}{{{spec}}}", r"\toprule"])
        out.append(" & ".join(r"\textbf{" + inline(cell) + "}" for cell in header) + r" \\")
        out.append(r"\midrule")
        for row in data:
            padded = row + [""] * (ncols - len(row))
            out.append(" & ".join(inline(cell) for cell in padded[:ncols]) + r" \\")
        out.extend([r"\bottomrule", r"\end{tabularx}", r"\end{center}"])
    out.extend([r"\endgroup", ""])
    return out


def is_special(line: str, next_line: str = "") -> bool:
    stripped = line.strip()
    return bool(
        not stripped
        or stripped.startswith(("#", "```", "![", "\\[", "$$", "---"))
        or re.match(r"^[-*+]\s+", stripped)
        or re.match(r"^\d+\.\s+", stripped)
        or (stripped.startswith("|") and next_line.strip().startswith("|"))
    )


def convert(markdown: str) -> str:
    lines = markdown.splitlines()
    body: list[str] = []
    start = next((i for i, line in enumerate(lines) if re.match(r"^##\s+1\.", line)), 0)
    end = next((i for i, line in enumerate(lines) if re.match(r"^##\s+13\.", line)), len(lines))
    i = start
    while i < end:
        line = lines[i]
        stripped = line.strip()
        nxt = lines[i + 1] if i + 1 < len(lines) else ""

        if not stripped or stripped == "---":
            i += 1
            continue

        heading = re.match(r"^(#{2,4})\s+(.+)$", stripped)
        if heading:
            level = len(heading.group(1))
            title = inline(strip_heading_number(heading.group(2)))
            command = {2: "section", 3: "subsection", 4: "subsubsection"}[level]
            body.extend([rf"\{command}{{{title}}}", ""])
            i += 1
            continue

        if stripped.startswith("\\["):
            equation = [line]
            i += 1
            while i < len(lines):
                equation.append(lines[i])
                if lines[i].strip().endswith("\\]"):
                    i += 1
                    break
                i += 1
            body.extend(equation + [""])
            continue

        if stripped.startswith("$$"):
            equation = [r"\["]
            content = stripped[2:]
            if content.endswith("$$") and len(content) > 2:
                equation.append(content[:-2])
                i += 1
            else:
                if content:
                    equation.append(content)
                i += 1
                while i < len(lines) and not lines[i].strip().endswith("$$"):
                    equation.append(lines[i])
                    i += 1
                if i < len(lines):
                    equation.append(lines[i].strip()[:-2])
                    i += 1
            equation.extend([r"\]", ""])
            body.extend(equation)
            continue

        if stripped.startswith("```"):
            code: list[str] = []
            i += 1
            while i < len(lines) and not lines[i].strip().startswith("```"):
                code.append(lines[i])
                i += 1
            i += 1
            body.extend([r"\begin{Verbatim}[fontsize=\small]"] + code + [r"\end{Verbatim}", ""])
            continue

        image_match = re.match(r"!\[([^\]]*)\]\(([^)]+)\)", stripped)
        if image_match:
            alt, source = image_match.groups()
            caption_parts: list[str] = []
            caption_index = i + 1
            while caption_index < len(lines) and not lines[caption_index].strip():
                caption_index += 1
            if caption_index < len(lines) and lines[caption_index].strip().startswith("*Figura"):
                while caption_index < len(lines):
                    caption_part = lines[caption_index].strip()
                    caption_parts.append(caption_part)
                    if caption_part.endswith("*"):
                        break
                    caption_index += 1
            caption_line = " ".join(caption_parts)
            caption_match = re.match(r"\*Figura\s+(\d+)\.\s*(.*?)\*\s*$", caption_line)
            number = int(caption_match.group(1)) if caption_match else 0
            caption = caption_match.group(2) if caption_match else alt
            if caption_match:
                i = caption_index
            filename = Path(source).name
            body.extend([
                r"\begin{figure}[!htbp]",
                r"\centering",
                rf"\includegraphics[width=\textwidth,height=0.69\textheight,keepaspectratio]{{{filename}}}",
            ])
            body.extend([
                rf"\caption{{{inline(caption)}}}",
                rf"\label{{fig:resultado-origen-{number:02d}}}" if number else r"\label{fig:resultado}",
                r"\end{figure}",
                "",
            ])
            i += 1
            continue

        if stripped.startswith("|") and i + 1 < len(lines) and re.match(r"^\s*\|?\s*:?-+", lines[i + 1]):
            def parse_row(raw: str) -> list[str]:
                cells: list[str] = []
                current: list[str] = []
                in_code = False
                for character in raw.strip().strip("|"):
                    if character == "`":
                        in_code = not in_code
                    if character == "|" and not in_code:
                        cells.append("".join(current).strip())
                        current = []
                    else:
                        current.append(character)
                cells.append("".join(current).strip())
                return cells

            rows = [parse_row(line)]
            i += 2  # Skip Markdown separator row.
            while i < len(lines) and lines[i].strip().startswith("|"):
                rows.append(parse_row(lines[i]))
                i += 1
            body.extend(table_block(rows))
            continue

        bullet = re.match(r"^([-*+])\s+(.+)$", stripped)
        numbered = re.match(r"^(\d+)\.\s+(.+)$", stripped)
        if bullet or numbered:
            env = "itemize" if bullet else "enumerate"
            body.append(rf"\begin{{{env}}}")
            if numbered and int(numbered.group(1)) > 1:
                body.append(rf"\setcounter{{enumi}}{{{int(numbered.group(1)) - 1}}}")
            while i < len(lines):
                current = lines[i].strip()
                match = re.match(r"^[-*+]\s+(.+)$", current) if env == "itemize" else re.match(r"^(\d+)\.\s+(.+)$", current)
                if not match:
                    break
                item_parts = [match.group(1) if env == "itemize" else match.group(2)]
                i += 1
                while i < len(lines):
                    continuation = lines[i].strip()
                    upcoming = lines[i + 1] if i + 1 < len(lines) else ""
                    if not continuation or re.match(r"^[-*+]\s+", continuation) or re.match(r"^\d+\.\s+", continuation) or is_special(lines[i], upcoming):
                        break
                    item_parts.append(continuation)
                    i += 1
                body.append(r"\item " + inline(" ".join(item_parts)))
                if i < len(lines) and not lines[i].strip():
                    i += 1
                    if i >= len(lines):
                        break
                    next_item = re.match(r"^[-*+]\s+", lines[i].strip()) if env == "itemize" else re.match(r"^\d+\.\s+", lines[i].strip())
                    if not next_item:
                        break
            body.extend([rf"\end{{{env}}}", ""])
            continue

        paragraph = [stripped]
        i += 1
        while i < len(lines):
            upcoming = lines[i + 1] if i + 1 < len(lines) else ""
            if is_special(lines[i], upcoming):
                break
            paragraph.append(lines[i].strip())
            i += 1
        body.extend([inline(" ".join(paragraph)), ""])

    return PREAMBLE + "\n".join(body) + POSTAMBLE


def main() -> None:
    LATEX_DIR.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(convert(SOURCE.read_text(encoding="utf-8")), encoding="utf-8")
    print(OUTPUT)


if __name__ == "__main__":
    main()
