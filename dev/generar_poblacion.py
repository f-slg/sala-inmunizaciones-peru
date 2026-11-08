# Development convenience wrapper; R is the authoritative workbook generator.
from pathlib import Path
import subprocess
root=Path(__file__).resolve().parents[1]
subprocess.run(["Rscript","-e",'pkgload::load_all("."); write_population_template(file.path("entregables","Plantilla_poblacion.xlsx"))'],cwd=root,check=True)
