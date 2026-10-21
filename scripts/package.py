from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile


root = Path(__file__).resolve().parent.parent
archive = root / "taller_docker_semana13.zip"
files = [
    root / ".dockerignore",
    root / "Dockerfile",
    root / "pom.xml",
    root / "README.md",
    root / "FORENSIC_REPORT.md",
    root / "audit_session.log",
    *sorted((root / "src").rglob("*")),
    *sorted((root / "scripts").glob("*.ps1")),
]
with ZipFile(archive, "w", ZIP_DEFLATED, compresslevel=9) as output:
    for file in files:
        if file.is_file():
            output.write(file, "taller-docker-semana13/" + file.relative_to(root).as_posix())
print(f"{archive} ({archive.stat().st_size} bytes)")
