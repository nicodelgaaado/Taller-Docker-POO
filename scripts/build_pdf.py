from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    HRFlowable,
    KeepTogether,
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)


ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "Informe.pdf"
FONT = Path("C:/Windows/Fonts/arial.ttf")
BOLD = Path("C:/Windows/Fonts/arialbd.ttf")
if FONT.exists() and BOLD.exists():
    pdfmetrics.registerFont(TTFont("ArialLocal", str(FONT)))
    pdfmetrics.registerFont(TTFont("ArialLocalBold", str(BOLD)))
    body_font, bold_font = "ArialLocal", "ArialLocalBold"
else:
    body_font, bold_font = "Helvetica", "Helvetica-Bold"

navy = colors.HexColor("#17324D")
gray = colors.HexColor("#566573")
pale = colors.HexColor("#F3F6F8")
line = colors.HexColor("#D8E0E6")

styles = getSampleStyleSheet()
styles.add(ParagraphStyle(name="DocTitle", fontName=bold_font, fontSize=17, leading=21, textColor=navy, spaceAfter=6))
styles.add(ParagraphStyle(name="Deck", fontName=body_font, fontSize=10, leading=14, textColor=gray, spaceAfter=11))
styles.add(ParagraphStyle(name="SectionCustom", fontName=bold_font, fontSize=11.5, leading=15, textColor=navy, spaceBefore=13, spaceAfter=6))
styles.add(ParagraphStyle(name="BodyCustom", fontName=body_font, fontSize=9.3, leading=13.5, spaceAfter=7))
styles.add(ParagraphStyle(name="SmallCustom", fontName=body_font, fontSize=8.1, leading=11, spaceAfter=5))
styles.add(ParagraphStyle(name="TinyCustom", fontName=body_font, fontSize=7.4, leading=9.8))
styles.add(ParagraphStyle(name="CodeCustom", fontName="Courier", fontSize=7.8, leading=11, spaceAfter=5))


def p(text, style="BodyCustom"):
    return Paragraph(text, styles[style])


def table(rows, widths, header=True):
    result = Table(rows, colWidths=widths, repeatRows=1 if header else 0, hAlign="LEFT")
    commands = [
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("LEFTPADDING", (0, 0), (-1, -1), 7),
        ("RIGHTPADDING", (0, 0), (-1, -1), 7),
        ("TOPPADDING", (0, 0), (-1, -1), 6),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
        ("LINEBELOW", (0, 0), (-1, -1), 0.35, line),
    ]
    if header:
        commands += [
            ("BACKGROUND", (0, 0), (-1, 0), navy),
            ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
            ("FONTNAME", (0, 0), (-1, 0), bold_font),
        ]
    for row in range(1, len(rows)):
        if row % 2 == 0:
            commands.append(("BACKGROUND", (0, row), (-1, row), pale))
    result.setStyle(TableStyle(commands))
    return result


story = [
    p("Taller Docker  Informe y justificación", "DocTitle"),
    p("Eco Air Backend  |  Estudiante: Nicolas Federico Delgado Perez  |  Código: 841024  |  20 de octubre de 2026", "Deck"),
    HRFlowable(width="100%", thickness=0.7, color=line),
    p("Resumen del resultado", "SectionCustom"),
    p(
        "Se construyó una imagen de dos etapas con Maven 3.9.6 y Java 17. "
        "El runtime contiene el JRE y el JAR ejecutable, ejecuta Java con UID 10001 y recibe "
        "<b>OPERATOR_ID=841024</b>. La API respondió desde el contenedor. En la prueba de 48 MiB, "
        "Docker informó <b>ExitCode 137</b> y <b>OOMKilled: true</b>. El menor límite que arrancó "
        "en menos de 15 segundos y siguió activo tras 45 segundos, confirmado en dos ejecuciones, "
        "fue <b>89 MiB</b> en este equipo."
    ),
    p("Origen del proyecto y diseño de la imagen", "SectionCustom"),
    p(
        "El repositorio inicial solo tenía un README. Se añadió una aplicación Spring Boot 3.3.4 "
        "con Hibernate, H2 en memoria y una API mínima de alertas para poder construir y auditar "
        "la imagen. En el Dockerfile, el archivo pom.xml se copia antes de src/ y se ejecuta "
        "mvn dependency:go-offline antes de compilar; por ello la descarga queda en caché cuando "
        "cambia el código. La etapa final usa eclipse-temurin:17-jre-alpine y copia únicamente "
        "el JAR. La propiedad del directorio /app y el proceso pertenecen a sensor_user."
    ),
    p("Identidad y control de privilegios", "SectionCustom"),
    table(
        [
            ["Comprobación", "Evidencia obtenida"],
            ["Hash de imagen", p("sha256:c0d483fd40797eb21dabf25c22ad32bb2e6f0ce509fb2995b35c2cf4042e6fb2", "TinyCustom")],
            ["Proceso Java", "docker top: USER 10001; id: sensor_user / sensorgroup"],
            ["Escritura en /etc", "Permission denied; código de salida 1"],
            ["Herramientas y fuentes", "which mvn sin salida; find no devolvió archivos .java"],
            ["Operador", "OPERATOR_ID=841024"],
        ],
        [135, 360],
    ),
    p(
        "La denegación de escritura demuestra que el proceso no puede modificar ese directorio "
        "del sistema. La ausencia de Maven concuerda con la separación de etapas. El comando find "
        "terminó con código 1 porque el usuario carece de acceso a algunos directorios; el "
        "Dockerfile confirma además que no copia src/ al runtime.",
        "SmallCustom",
    ),
    PageBreak(),
    p("Memoria y arranque", "SectionCustom"),
    table(
        [
            ["Límite", "Estado", "Inicio", "Memoria al medir"],
            ["48 MiB", "OOMKilled", "Sin inicio", "ExitCode 137"],
            ["88 MiB", "OOMKilled", "Sin inicio", "0B tras salir"],
            ["89 MiB", "Activo a 45 s", "13.364 s / 12.823 s", "83.05 / 89 MiB en repetición"],
            ["100 MiB", "Activo a 45 s", "9.349 s", "88.12 / 100 MiB"],
            ["256 MiB", "Activo", "7.046 s", "157.9 / 256 MiB"],
            ["384 MiB", "Activo", "4.756 s", "167.4 / 384 MiB"],
            ["512 MiB", "Activo", "5.134 s", "175.3 / 512 MiB"],
        ],
        [63, 102, 145, 185],
    ),
    p(
        "El resultado de 48 MiB no fue instantáneo: la inspección a los 10 segundos aún mostró "
        "running; la consulta posterior mostró OOMKilled: true. El límite de 87 MiB cumplió "
        "en un intento y tardó 16.341 segundos en otro. Por eso se fijó 89 MiB como el mínimo "
        "observado y repetido con resolución de 1 MiB. En producción conviene dejar margen: "
        "100 MiB consumió menos proporción del cgroup y arrancó más rápido."
    ),
    p("Salidas decisivas de Docker", "SectionCustom"),
    p("docker inspect eco_air_crash", "CodeCustom"),
    p("Status: exited | ExitCode: 137 | OOMKilled: true", "CodeCustom"),
    p("docker top eco_air_active -o pid,user,comm", "CodeCustom"),
    p("PID  USER  COMMAND", "CodeCustom"),
    p("2996 10001 java", "CodeCustom"),
    p("docker exec eco_air_active touch /etc/crontab_fake", "CodeCustom"),
    p("touch: cannot touch '/etc/crontab_fake': Permission denied", "CodeCustom"),
    p("Comprobación final", "SectionCustom"),
    p(
        "El contenedor final eco_air_active quedó activo con -m 89m y puerto 8080. Docker "
        "registró <b>Started EcoAirApplication in 14.234 seconds</b>. Las columnas principales "
        "de docker stats --no-stream fueron:"
    ),
    p("CONTAINER ID   NAME             CPU %   MEM USAGE / LIMIT   MEM %", "CodeCustom"),
    p("bbba1e768bad   eco_air_active   0.16%   82.02MiB / 89MiB   92.16%", "CodeCustom"),
    p(
        "La API devolvió [] en GET /alerts. Los comandos, timestamps, IDs de contenedor, "
        "hashes de capas y salidas íntegras están en FORENSIC_REPORT.md y audit_session.log. "
        "El umbral medido depende del motor Docker, la carga y la configuración de la JVM; "
        "no debe tomarse como una garantía universal."
    ),
]


def footer(canvas, doc):
    canvas.saveState()
    canvas.setStrokeColor(line)
    canvas.line(0.72 * inch, 0.6 * inch, 7.78 * inch, 0.6 * inch)
    canvas.setFont(body_font, 8)
    canvas.setFillColor(gray)
    canvas.drawString(0.72 * inch, 0.43 * inch, "Nicolas Federico Delgado Perez  |  Código: 841024")
    canvas.drawRightString(7.78 * inch, 0.43 * inch, f"Página {doc.page}")
    canvas.restoreState()


doc = SimpleDocTemplate(
    str(OUT),
    pagesize=letter,
    rightMargin=0.72 * inch,
    leftMargin=0.72 * inch,
    topMargin=0.7 * inch,
    bottomMargin=0.75 * inch,
    title="Informe",
    author="Nicolas Federico Delgado Perez",
)
doc.build(story, onFirstPage=footer, onLaterPages=footer)
print(OUT)
