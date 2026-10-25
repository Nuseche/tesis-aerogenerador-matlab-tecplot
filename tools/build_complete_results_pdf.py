#!/usr/bin/env python3
"""Build the complete results report PDF from its Markdown source."""

from __future__ import annotations

import html
import re
from datetime import date
from pathlib import Path

from PIL import Image as PILImage
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    BaseDocTemplate,
    Frame,
    Image,
    KeepTogether,
    LongTable,
    PageBreak,
    PageTemplate,
    Paragraph,
    Spacer,
    Table,
    TableStyle,
)
from reportlab.platypus.tableofcontents import TableOfContents


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "docs" / "resultados_integrales" / "INFORME_RESULTADOS_COMPLETOS.md"
OUTPUT = ROOT / "output" / "pdf" / "INFORME_RESULTADOS_COMPLETOS.pdf"
TMP = ROOT / "tmp" / "pdfs" / "informe_resultados_completos"
REPORT_DIR = SOURCE.parent

PAGE_WIDTH, PAGE_HEIGHT = A4
LEFT_MARGIN = 19 * mm
RIGHT_MARGIN = 17 * mm
TOP_MARGIN = 19 * mm
BOTTOM_MARGIN = 18 * mm
CONTENT_WIDTH = PAGE_WIDTH - LEFT_MARGIN - RIGHT_MARGIN
CONTENT_HEIGHT = PAGE_HEIGHT - TOP_MARGIN - BOTTOM_MARGIN

NAVY = colors.HexColor("#17324D")
BLUE = colors.HexColor("#1E6FA8")
TEAL = colors.HexColor("#2A8C82")
LIGHT_BLUE = colors.HexColor("#EAF3F8")
LIGHT_GREY = colors.HexColor("#F2F4F6")
MID_GREY = colors.HexColor("#CBD3D9")
TEXT = colors.HexColor("#202A33")
MUTED = colors.HexColor("#5B6872")
WHITE = colors.white


def register_fonts() -> None:
    font_dir = Path("/System/Library/Fonts/Supplemental")
    font_files = {
        "Arial": font_dir / "Arial.ttf",
        "Arial-Bold": font_dir / "Arial Bold.ttf",
        "Arial-Italic": font_dir / "Arial Italic.ttf",
        "Arial-BoldItalic": font_dir / "Arial Bold Italic.ttf",
    }
    for name, path in font_files.items():
        if not path.exists():
            raise FileNotFoundError(f"Required font is missing: {path}")
        pdfmetrics.registerFont(TTFont(name, str(path)))
    pdfmetrics.registerFontFamily(
        "Arial",
        normal="Arial",
        bold="Arial-Bold",
        italic="Arial-Italic",
        boldItalic="Arial-BoldItalic",
    )


def build_styles() -> dict[str, ParagraphStyle]:
    base = getSampleStyleSheet()
    return {
        "body": ParagraphStyle(
            "BodyCustom",
            parent=base["BodyText"],
            fontName="Arial",
            fontSize=9.15,
            leading=12.3,
            textColor=TEXT,
            alignment=TA_JUSTIFY,
            spaceAfter=5.5,
            allowWidows=0,
            allowOrphans=0,
        ),
        "h1": ParagraphStyle(
            "Heading1Custom",
            parent=base["Heading1"],
            fontName="Arial-Bold",
            fontSize=16.5,
            leading=20,
            textColor=NAVY,
            spaceBefore=2,
            spaceAfter=9,
            keepWithNext=True,
        ),
        "h2": ParagraphStyle(
            "Heading2Custom",
            parent=base["Heading2"],
            fontName="Arial-Bold",
            fontSize=12.5,
            leading=15.5,
            textColor=BLUE,
            spaceBefore=10,
            spaceAfter=6,
            keepWithNext=True,
        ),
        "caption": ParagraphStyle(
            "CaptionCustom",
            parent=base["BodyText"],
            fontName="Arial-Italic",
            fontSize=8.1,
            leading=10.2,
            textColor=MUTED,
            alignment=TA_CENTER,
            spaceBefore=4,
            spaceAfter=9,
        ),
        "bullet": ParagraphStyle(
            "BulletCustom",
            parent=base["BodyText"],
            fontName="Arial",
            fontSize=9.05,
            leading=12,
            textColor=TEXT,
            leftIndent=15,
            firstLineIndent=0,
            bulletIndent=3,
            spaceAfter=3,
        ),
        "numbered": ParagraphStyle(
            "NumberedCustom",
            parent=base["BodyText"],
            fontName="Arial",
            fontSize=9.05,
            leading=12,
            textColor=TEXT,
            leftIndent=18,
            firstLineIndent=0,
            bulletIndent=1,
            spaceAfter=3,
        ),
        "code": ParagraphStyle(
            "CodeCustom",
            parent=base["Code"],
            fontName="Courier",
            fontSize=7.8,
            leading=10.2,
            textColor=TEXT,
            backColor=LIGHT_GREY,
            borderColor=MID_GREY,
            borderWidth=0.5,
            borderPadding=6,
            leftIndent=3,
            rightIndent=3,
            spaceBefore=4,
            spaceAfter=8,
        ),
        "equation": ParagraphStyle(
            "EquationFallback",
            parent=base["BodyText"],
            fontName="Arial",
            fontSize=10.5,
            leading=14,
            textColor=TEXT,
            alignment=TA_CENTER,
            leftIndent=10,
            rightIndent=10,
            spaceBefore=5,
            spaceAfter=8,
        ),
        "table_header": ParagraphStyle(
            "TableHeader",
            parent=base["BodyText"],
            fontName="Arial-Bold",
            fontSize=7.4,
            leading=9.1,
            textColor=WHITE,
            alignment=TA_LEFT,
        ),
        "table_cell": ParagraphStyle(
            "TableCell",
            parent=base["BodyText"],
            fontName="Arial",
            fontSize=7.25,
            leading=9.0,
            textColor=TEXT,
            alignment=TA_LEFT,
        ),
        "toc_title": ParagraphStyle(
            "TocTitle",
            parent=base["Heading1"],
            fontName="Arial-Bold",
            fontSize=18,
            leading=22,
            textColor=NAVY,
            spaceAfter=12,
        ),
        "cover_title": ParagraphStyle(
            "CoverTitle",
            parent=base["Title"],
            fontName="Arial-Bold",
            fontSize=27,
            leading=32,
            textColor=NAVY,
            alignment=TA_LEFT,
            spaceAfter=10,
        ),
        "cover_subtitle": ParagraphStyle(
            "CoverSubtitle",
            parent=base["BodyText"],
            fontName="Arial",
            fontSize=13,
            leading=18,
            textColor=BLUE,
            alignment=TA_LEFT,
            spaceAfter=14,
        ),
        "cover_note": ParagraphStyle(
            "CoverNote",
            parent=base["BodyText"],
            fontName="Arial",
            fontSize=9.2,
            leading=12.5,
            textColor=MUTED,
            alignment=TA_LEFT,
        ),
        "stat_value": ParagraphStyle(
            "StatValue",
            parent=base["BodyText"],
            fontName="Arial-Bold",
            fontSize=21,
            leading=23,
            textColor=NAVY,
            alignment=TA_CENTER,
        ),
        "stat_label": ParagraphStyle(
            "StatLabel",
            parent=base["BodyText"],
            fontName="Arial",
            fontSize=8.2,
            leading=10,
            textColor=MUTED,
            alignment=TA_CENTER,
        ),
    }


def footer_and_header(canvas, doc) -> None:
    canvas.saveState()
    page = canvas.getPageNumber()
    if page > 1:
        canvas.setStrokeColor(MID_GREY)
        canvas.setLineWidth(0.5)
        canvas.line(LEFT_MARGIN, PAGE_HEIGHT - 13 * mm, PAGE_WIDTH - RIGHT_MARGIN, PAGE_HEIGHT - 13 * mm)
        canvas.setFont("Arial", 7.5)
        canvas.setFillColor(MUTED)
        canvas.drawString(LEFT_MARGIN, PAGE_HEIGHT - 10.2 * mm, "Informe integral de resultados - Aerogenerador")
        canvas.drawRightString(PAGE_WIDTH - RIGHT_MARGIN, PAGE_HEIGHT - 10.2 * mm, "Tesis | Evidencia numérica reproducible")
        canvas.line(LEFT_MARGIN, 12 * mm, PAGE_WIDTH - RIGHT_MARGIN, 12 * mm)
        canvas.drawString(LEFT_MARGIN, 8.5 * mm, "Acciones 02-10 | MATLAB R2026a")
        canvas.drawRightString(PAGE_WIDTH - RIGHT_MARGIN, 8.5 * mm, f"Página {page}")
    canvas.restoreState()


class ReportDocTemplate(BaseDocTemplate):
    def __init__(self, filename: str):
        super().__init__(
            filename,
            pagesize=A4,
            leftMargin=LEFT_MARGIN,
            rightMargin=RIGHT_MARGIN,
            topMargin=TOP_MARGIN,
            bottomMargin=BOTTOM_MARGIN,
            title="Informe integral de resultados, metodología y conclusiones",
            author="Proyecto de tesis",
            subject="Modelo estructural, rotodinámico y sísmico de un aerogenerador",
        )
        frame = Frame(
            LEFT_MARGIN,
            BOTTOM_MARGIN,
            CONTENT_WIDTH,
            CONTENT_HEIGHT,
            id="normal",
            leftPadding=0,
            rightPadding=0,
            topPadding=0,
            bottomPadding=0,
        )
        self.addPageTemplates(PageTemplate(id="content", frames=[frame], onPage=footer_and_header))
        self._bookmark_counter = 0

    def beforeDocument(self) -> None:
        super().beforeDocument()
        self._bookmark_counter = 0

    def afterFlowable(self, flowable) -> None:
        if not isinstance(flowable, Paragraph):
            return
        style_name = flowable.style.name
        if style_name not in {"Heading1Custom", "Heading2Custom"}:
            return
        level = 0 if style_name == "Heading1Custom" else 1
        text = flowable.getPlainText()
        key = f"section-{self._bookmark_counter}"
        self._bookmark_counter += 1
        self.canv.bookmarkPage(key)
        self.canv.addOutlineEntry(text, key, level=level, closed=False)
        self.notify("TOCEntry", (level, text, self.page, key))


def inline_markup(text: str) -> str:
    text = html.escape(text.strip(), quote=False)
    text = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", r"<u>\1</u>", text)
    text = re.sub(r"`([^`]+)`", r'<font name="Arial-Bold">\1</font>', text)
    text = re.sub(r"\*\*([^*]+)\*\*", r"<b>\1</b>", text)
    text = re.sub(r"(?<!\*)\*([^*]+)\*(?!\*)", r"<i>\1</i>", text)
    return text


def strip_markdown(text: str) -> str:
    text = re.sub(r"!\[([^\]]*)\]\([^)]+\)", r"\1", text)
    text = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", text)
    text = text.replace("**", "").replace("`", "").replace("*", "")
    return text.strip()


def prepare_figure(source: Path, index: int) -> tuple[Path, float, float]:
    if not source.exists():
        raise FileNotFoundError(f"Figure referenced by Markdown does not exist: {source}")
    destination = TMP / "figures" / f"figure_{index:02d}.jpg"
    destination.parent.mkdir(parents=True, exist_ok=True)
    with PILImage.open(source) as original:
        original.load()
        if original.mode in {"RGBA", "LA"}:
            background = PILImage.new("RGB", original.size, "white")
            alpha = original.getchannel("A")
            background.paste(original.convert("RGB"), mask=alpha)
            converted = background
        else:
            converted = original.convert("RGB")
        converted.thumbnail((2200, 1800), PILImage.Resampling.LANCZOS)
        converted.save(destination, "JPEG", quality=93, subsampling=0, optimize=True)
        pixel_width, pixel_height = converted.size
    max_width = CONTENT_WIDTH
    max_height = 158 * mm
    ratio = min(max_width / pixel_width, max_height / pixel_height)
    return destination, pixel_width * ratio, pixel_height * ratio


def equation_flowable(latex: str, _index: int, styles: dict[str, ParagraphStyle]):
    expression = html.escape(" ".join(part.strip() for part in latex.splitlines()).strip(), quote=False)
    replacements = {
        r"\frac12": "1/2",
        r"\varepsilon": "ε",
        r"\lambda": "λ",
        r"\phi": "φ",
        r"\Gamma": "Γ",
        r"\alpha": "α",
        r"\beta": "β",
        r"\Omega": "Ω",
        r"\theta": "θ",
        r"\partial": "∂",
        r"\int": "∫",
        r"\times": "×",
        r"\approx": "≈",
        r"\infty": "∞",
        r"\qquad": "   ",
        r"\quad": "  ",
        r"\,": "",
        r"\;": " ",
    }
    for source, target in replacements.items():
        expression = expression.replace(source, target)
    expression = re.sub(r"\\bar\s*([A-Za-z])", r"\1&#772;", expression)
    expression = re.sub(r"\\ddot\s*([A-Za-z])", r"\1&#776;", expression)
    expression = re.sub(r"\\dot\s*([A-Za-z])", r"\1&#775;", expression)
    expression = re.sub(r"_\{([^{}]+)\}", r"<sub>\1</sub>", expression)
    expression = re.sub(r"\^\{([^{}]+)\}", r"<super>\1</super>", expression)
    expression = re.sub(r"_([A-Za-z0-9]+)", r"<sub>\1</sub>", expression)
    expression = re.sub(r"\^([T0-9+-]+)", r"<super>\1</super>", expression)
    expression = expression.replace("{", "").replace("}", "")
    return Paragraph(expression, styles["equation"])


def table_widths(rows: list[list[str]]) -> list[float]:
    columns = len(rows[0])
    weights = []
    for column in range(columns):
        lengths = [len(strip_markdown(row[column])) for row in rows if column < len(row)]
        weight = max(8.0, min(48.0, max(lengths, default=8)))
        weights.append(weight)
    total = sum(weights)
    return [CONTENT_WIDTH * value / total for value in weights]


def table_flowable(rows: list[list[str]], styles: dict[str, ParagraphStyle]):
    normalized_columns = max(len(row) for row in rows)
    normalized = [row + [""] * (normalized_columns - len(row)) for row in rows]
    parsed = []
    for row_index, row in enumerate(normalized):
        style = styles["table_header"] if row_index == 0 else styles["table_cell"]
        parsed.append([Paragraph(inline_markup(cell), style) for cell in row])
    table = LongTable(
        parsed,
        colWidths=table_widths(normalized),
        repeatRows=1,
        hAlign="LEFT",
        splitByRow=1,
    )
    commands = [
        ("BACKGROUND", (0, 0), (-1, 0), NAVY),
        ("TEXTCOLOR", (0, 0), (-1, 0), WHITE),
        ("FONTNAME", (0, 0), (-1, 0), "Arial-Bold"),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 4),
        ("RIGHTPADDING", (0, 0), (-1, -1), 4),
        ("TOPPADDING", (0, 0), (-1, -1), 3.2),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 3.2),
        ("LINEBELOW", (0, 0), (-1, 0), 0.7, NAVY),
        ("GRID", (0, 0), (-1, -1), 0.35, MID_GREY),
    ]
    for row_index in range(1, len(parsed)):
        if row_index % 2 == 0:
            commands.append(("BACKGROUND", (0, row_index), (-1, row_index), LIGHT_GREY))
    table.setStyle(TableStyle(commands))
    return table


def cover_story(styles: dict[str, ParagraphStyle]):
    status_data = [
        [Paragraph("126/126", styles["stat_value"]), Paragraph("649/649", styles["stat_value"]), Paragraph("39", styles["stat_value"])],
        [Paragraph("pruebas aprobadas", styles["stat_label"]), Paragraph("requisitos aprobados", styles["stat_label"]), Paragraph("figuras verificadas", styles["stat_label"])],
    ]
    status = Table(status_data, colWidths=[CONTENT_WIDTH / 3] * 3, rowHeights=[16 * mm, 11 * mm])
    status.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, -1), LIGHT_BLUE),
                ("BOX", (0, 0), (-1, -1), 0.7, MID_GREY),
                ("INNERGRID", (0, 0), (-1, -1), 0.5, MID_GREY),
                ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                ("LEFTPADDING", (0, 0), (-1, -1), 5),
                ("RIGHTPADDING", (0, 0), (-1, -1), 5),
            ]
        )
    )
    return [
        Spacer(1, 22 * mm),
        Table([[""]], colWidths=[34 * mm], rowHeights=[3.2 * mm], style=TableStyle([("BACKGROUND", (0, 0), (-1, -1), TEAL)])),
        Spacer(1, 8 * mm),
        Paragraph("Informe integral de resultados, metodología y conclusiones", styles["cover_title"]),
        Paragraph("Modelo estructural, rotodinámico y sísmico de un aerogenerador", styles["cover_subtitle"]),
        Spacer(1, 6 * mm),
        status,
        Spacer(1, 15 * mm),
        Paragraph(
            "Documento consolidado de conversión de malla, formulación Timoshenko 3D, demostración modal, restricciones, masas, equilibrio, operadores dinámicos, MBC, QEP, Campbell y respuesta sísmica con Newmark.",
            styles["cover_note"],
        ),
        Spacer(1, 7 * mm),
        Paragraph(
            "Alcance: aceptación numérica reproducible de las Acciones 02-10. Los parámetros no calibrados y el movimiento sísmico sintético permanecen identificados; los resultados no se presentan como diseño de una turbina comercial.",
            styles["cover_note"],
        ),
        Spacer(1, 18 * mm),
        Paragraph("Evidencia canónica: 31 de agosto de 2026", styles["cover_note"]),
        Paragraph(f"Edición PDF: {date(2026, 9, 2).strftime('%d/%m/%Y')}", styles["cover_note"]),
        Paragraph("MATLAB R2026a Update 4, MACA64", styles["cover_note"]),
        Spacer(1, 12 * mm),
        Paragraph("/Users/nuseche/Desktop/Tesis_codigos", styles["cover_note"]),
        PageBreak(),
    ]


def toc_story(styles: dict[str, ParagraphStyle]):
    toc = TableOfContents()
    toc.levelStyles = [
        ParagraphStyle(
            "TOCLevel1",
            fontName="Arial-Bold",
            fontSize=10.2,
            leading=14,
            textColor=NAVY,
            leftIndent=0,
            firstLineIndent=0,
            spaceBefore=4,
        ),
        ParagraphStyle(
            "TOCLevel2",
            fontName="Arial",
            fontSize=8.8,
            leading=11.5,
            textColor=TEXT,
            leftIndent=14,
            firstLineIndent=0,
            spaceBefore=1,
        ),
    ]
    return [Paragraph("Contenido", styles["toc_title"]), toc, PageBreak()]


def parse_markdown(styles: dict[str, ParagraphStyle]):
    lines = SOURCE.read_text(encoding="utf-8").splitlines()
    start = next(index for index, line in enumerate(lines) if line.startswith("## 1."))
    lines = lines[start:]
    story = []
    paragraph_buffer: list[str] = []
    figure_index = 0
    equation_index = 0
    first_major_heading = True

    def flush_paragraph() -> None:
        if paragraph_buffer:
            text = " ".join(part.strip() for part in paragraph_buffer)
            story.append(Paragraph(inline_markup(text), styles["body"]))
            paragraph_buffer.clear()

    index = 0
    while index < len(lines):
        line = lines[index]
        stripped = line.strip()

        if not stripped:
            flush_paragraph()
            index += 1
            continue

        if stripped.startswith("```"):
            flush_paragraph()
            code_lines = []
            index += 1
            while index < len(lines) and not lines[index].strip().startswith("```"):
                code_lines.append(lines[index])
                index += 1
            code = "<br/>".join(html.escape(item, quote=False).replace(" ", "&nbsp;") for item in code_lines)
            story.append(Paragraph(code, styles["code"]))
            index += 1
            continue

        if stripped == "\\[":
            flush_paragraph()
            equation_lines = []
            index += 1
            while index < len(lines) and lines[index].strip() != "\\]":
                equation_lines.append(lines[index])
                index += 1
            equation_index += 1
            story.append(Spacer(1, 2 * mm))
            story.append(equation_flowable("\n".join(equation_lines), equation_index, styles))
            story.append(Spacer(1, 2 * mm))
            index += 1
            continue

        if stripped.startswith("## "):
            flush_paragraph()
            if not first_major_heading:
                story.append(PageBreak())
            first_major_heading = False
            story.append(Paragraph(inline_markup(stripped[3:]), styles["h1"]))
            index += 1
            continue

        if stripped.startswith("### "):
            flush_paragraph()
            story.append(Paragraph(inline_markup(stripped[4:]), styles["h2"]))
            index += 1
            continue

        image_match = re.fullmatch(r"!\[([^\]]*)\]\(([^)]+)\)", stripped)
        if image_match:
            flush_paragraph()
            figure_index += 1
            image_path = (REPORT_DIR / image_match.group(2)).resolve()
            prepared, width, height = prepare_figure(image_path, figure_index)
            figure = Image(str(prepared), width=width, height=height, hAlign="CENTER")
            figure._restrictSize(CONTENT_WIDTH, 158 * mm)
            next_index = index + 1
            while next_index < len(lines) and not lines[next_index].strip():
                next_index += 1
            caption = None
            if next_index < len(lines):
                candidate = lines[next_index].strip()
                if candidate.startswith("*") and candidate.endswith("*"):
                    caption = candidate[1:-1]
            block = [figure]
            if caption:
                block.append(Paragraph(inline_markup(caption), styles["caption"]))
                index = next_index + 1
            else:
                block.append(Paragraph(inline_markup(image_match.group(1)), styles["caption"]))
                index += 1
            story.append(KeepTogether(block))
            continue

        if stripped.startswith("|") and index + 1 < len(lines) and re.match(r"^\s*\|?\s*:?-+", lines[index + 1]):
            flush_paragraph()
            table_lines = [stripped]
            index += 2
            while index < len(lines) and lines[index].strip().startswith("|"):
                table_lines.append(lines[index].strip())
                index += 1
            rows = []
            for table_line in table_lines:
                cells = [cell.strip() for cell in table_line.strip().strip("|").split("|")]
                rows.append(cells)
            story.append(Spacer(1, 2 * mm))
            story.append(table_flowable(rows, styles))
            story.append(Spacer(1, 4 * mm))
            continue

        bullet_match = re.match(r"^-\s+(.+)$", stripped)
        number_match = re.match(r"^(\d+)\.\s+(.+)$", stripped)
        if bullet_match:
            flush_paragraph()
            story.append(Paragraph(inline_markup(bullet_match.group(1)), styles["bullet"], bulletText="•"))
            index += 1
            continue
        if number_match:
            flush_paragraph()
            story.append(Paragraph(inline_markup(number_match.group(2)), styles["numbered"], bulletText=f"{number_match.group(1)}."))
            index += 1
            continue

        paragraph_buffer.append(stripped)
        index += 1

    flush_paragraph()
    if figure_index != 39:
        raise RuntimeError(f"Expected 39 embedded figures, found {figure_index}")
    return story


def build() -> Path:
    register_fonts()
    styles = build_styles()
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    TMP.mkdir(parents=True, exist_ok=True)
    story = cover_story(styles) + toc_story(styles) + parse_markdown(styles)
    document = ReportDocTemplate(str(OUTPUT))
    document.multiBuild(story)
    if not OUTPUT.exists() or OUTPUT.stat().st_size == 0:
        raise RuntimeError("PDF generation did not produce a non-empty file")
    print(OUTPUT)
    return OUTPUT


if __name__ == "__main__":
    build()
